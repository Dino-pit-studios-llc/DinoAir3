"""
Streaming pipeline for memory-efficient pseudocode translation

This module provides a streaming pipeline that processes code chunks through
the translation stages while maintaining context and handling backpressure.
"""

import threading
import time
from collections.abc import Iterator
from contextlib import suppress
from dataclasses import dataclass, field
from typing import Any

from utils.enhanced_logger import get_logger as _get_logger

# Note on imports: to avoid circular imports with translator.py, we avoid
# importing TranslationManager at module import time. We import it lazily
# inside methods that need it.
from ..config import TranslatorConfig
from ..integration.events import EventType
from ..models import BlockType, CodeBlock
from ..models.base_model import TranslationResult as ModelTranslationResult
from ..telemetry import get_recorder
from .chunker import CodeChunk

logger = _get_logger(__name__)


@dataclass
class StreamConfig:
    """Configuration for streaming pipeline"""

    enable_streaming: bool = True
    min_file_size_for_streaming: int = 1024 * 100  # 100KB
    max_concurrent_chunks: int = 3
    chunk_timeout: float = 30.0
    progress_callback_interval: float = 0.5
    maintain_context_window: bool = True
    context_window_size: int = 1024  # Characters
    enable_backpressure: bool = True
    max_queue_size: int = 10
    thread_pool_size: int = 4


@dataclass
class StreamingProgress:
    """Progress information for streaming operations"""

    total_chunks: int = 0
    processed_chunks: int = 0
    current_chunk: int | None = None
    bytes_processed: int = 0
    total_bytes: int = 0
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

    @property
    def progress_percentage(self) -> float:
        """Get progress as percentage"""
        if self.total_chunks == 0:
            return 0.0
        return (self.processed_chunks / self.total_chunks) * 100

    @property
    def is_complete(self) -> bool:
        """Check if streaming is complete"""
        return self.processed_chunks >= self.total_chunks


@dataclass
class ChunkResult:
    """Result of processing a single chunk"""

    chunk_index: int
    success: bool
    parsed_blocks: list[Any] | None = None
    translated_blocks: list[Any] | None = None
    error: str | None = None
    warnings: list[str] = field(default_factory=list)
    processing_time: float = 0.0


class StreamingPipeline:
    """Manages streaming translation pipeline with backpressure and context"""

    def __init__(self, config: TranslatorConfig, stream_config: StreamConfig | None = None):
        """Initialize streaming pipeline"""
        self.translator = None

    def _dispatch(self, event_type, **data):
        """Best-effort event dispatch via manager's dispatcher; never raises."""
        dispatcher = self._get_dispatcher()
        if dispatcher:
            try:
                dispatcher.dispatch_event(
                    event_type,
                    source=self.__class__.__name__,
                    **data,
                )
            except (AttributeError, RuntimeError, TypeError) as e:
                logger.debug("dispatch failed: %s", e)
            except Exception as e:
                # Catch-all to keep best-effort semantics without raising
                logger.debug("dispatch failed: %s", e)

    def _get_dispatcher(self):
        try:
            return self.translator.get_event_dispatcher()
        except Exception:
            return None

    def _dispatch_decision(self, previous_size: int, next_size: int):
        dispatcher = self._get_dispatcher()
        if dispatcher:
            reason = "increase" if next_size > previous_size else "decrease"
            dispatcher.dispatch_event(
                EventType.STREAM_DECISION,
                source=self.__class__.__name__,
                reason=reason,
                previous_size=previous_size,
                next_size=next_size,
            )

    def _dispatch_chunk_event(self, chunk_idx: int, chunk_length: int, duration: float):
        dispatcher = self._get_dispatcher()
        if dispatcher:
            dispatcher.dispatch_event(
                EventType.STREAM_CHUNK,
                source=self.__class__.__name__,
                chunk_idx=chunk_idx,
                chunk_length=chunk_length,
                duration=duration,
            )

    def _adaptive_sequential_stream(
        self,
        code: str,
        sizer,
        recorder,
    ) -> Iterator[ChunkResult]:
        sc = self.config.streaming
        text = code
        n = len(text)
        pos = 0
        chunk_idx = 0
        prev_size: int | None = None

        hard_cap_max = int(self.config.max_context_length * 2)

        while pos < n and not self._stop_event.is_set():
            desired = self._calculate_desired_chunk_size(sizer, sc, hard_cap_max)

            if prev_size is not None and desired != prev_size:
                self._dispatch_decision(prev_size, desired)

            chunk_result = self._process_adaptive_chunk(text, pos, desired, chunk_idx, recorder)
            chunk_idx += 1
            prev_size = desired
            pos = min(pos + desired, n)
            yield chunk_result

        # Complete the stream
        yield from self._finalize_adaptive_stream(code, sizer, recorder)

    @staticmethod
    def _calculate_desired_chunk_size(sizer, stream_config, hard_cap_max: int) -> int:
        """Calculate the desired chunk size with constraints."""
        desired = int(sizer.get_next_chunk_size(default_chunk_size=stream_config.chunk_size))
        return max(1, min(desired, hard_cap_max))

    def _process_adaptive_chunk(
        self,
        text: str,
        pos: int,
        desired: int,
        chunk_idx: int,
        recorder,
    ) -> ChunkResult:
        """Process a single adaptive chunk."""
        start = pos
        end = min(pos + desired, len(text))
        text_chunk = text[start:end]

        start_time = time.perf_counter()
        try:
            result = self.translator.stream_translate(text_chunk)
        except Exception as e:
            result = self.translator.CodecErrorResult(e)
        duration = time.perf_counter() - start_time

        self._dispatch_chunk_event(chunk_idx + 1, len(text_chunk), duration)
        return self._process_chunk(result, recorder)

    def _finalize_adaptive_stream(self, code: str, sizer, recorder) -> Iterator[ChunkResult]:
        """Finalize the adaptive stream processing."""
        total_start = time.perf_counter()
        try:
            if getattr(self.config.streaming, "adaptive_chunking_enabled", False):
                # Run adaptive sequential path (keep parallel path unchanged/off for adaptive in this version)
                yield from self._adaptive_sequential_stream(code, sizer, recorder)
            else:
                # Existing behavior (precompute chunks via chunker and process)
                chunks = list(self.chunker.stream_chunks(code, None))
                self.progress.total_chunks = len(chunks)

                if self.stream_config.max_concurrent_chunks > 1:
                    # Parallel processing
                    yield from self._process_chunks_parallel(chunks)
                else:
                    # Sequential processing
                    yield from self._process_chunks_sequential(chunks)

        finally:
            self._cleanup_stream(recorder, total_start)

    def _cleanup_stream(self, recorder, start_time: float) -> None:
        """Cleanup after stream processing."""
        # Record total stream time (best-effort)
        with suppress(Exception):
            recorder.record_event("stream.total", (time.perf_counter() - start_time) * 1000.0)

        # Emit STREAM_COMPLETED with processed chunk count
        self._dispatch(EventType.STREAM_COMPLETED, chunks=self.progress.processed_chunks)

        # Cleanup
        self._stop_progress_reporting()
        if self.translator:
            self.translator.shutdown()

    def _process_chunks_sequential(self, chunks: list[CodeChunk]) -> Iterator[ChunkResult]:
        """
        Process chunks sequentially

        Args:
            chunks: List of code chunks

        Yields:
            ChunkResult objects
        """
        for chunk in chunks:
            if self._stop_event.is_set():
                break

            start_time = time.time()
            self.progress.current_chunk = chunk.chunk_index

            try:
                # Process chunk
                result = self._process_single_chunk(chunk)
                result.processing_time = time.time() - start_time
                with suppress(Exception):
                    recorder = get_recorder()
                    recorder.record_event(
                        "stream.chunk",
                        result.processing_time * 1000.0,
                        extra={"chunk_index": chunk.chunk_index, "size": chunk.size},
                    )

                # Update progress
                self.progress.processed_chunks += 1
                self.progress.bytes_processed += chunk.size

                if result.error:
                    self.progress.errors.append(result.error)
                self.progress.warnings.extend(result.warnings)

                # Emit per-chunk event
                self._dispatch(
                    EventType.STREAM_CHUNK_PROCESSED,
                    index=chunk.chunk_index,
                    success=bool(result.success),
                    duration_ms=int(result.processing_time * 1000.0),
                )

                yield result

            except Exception as e:
                logger.error("Error processing chunk %s: %s", chunk.chunk_index, e)
                fail = ChunkResult(
                    chunk_index=chunk.chunk_index,
                    success=False,
                    error=str(e),
                    processing_time=time.time() - start_time,
                )
                # Emit per-chunk event for failure
                self._dispatch(
                    EventType.STREAM_CHUNK_PROCESSED,
                    index=chunk.chunk_index,
                    success=False,
                    duration_ms=int(fail.processing_time * 1000.0),
                )
                yield fail

    def _process_chunks_parallel(self, chunks: list[CodeChunk]) -> Iterator[ChunkResult]:
        """
        Process chunks in parallel with backpressure

        Args:
            chunks: List of code chunks

        Yields:
            ChunkResult objects
        """
        from concurrent.futures import FIRST_COMPLETED, wait

        # Track all outstanding work (running + queued in executor)
        futures: dict[Any, CodeChunk] = {}
        chunk_iter = iter(chunks)

        # Pre-fill initial batch
        self._submit_initial_chunks(futures, chunk_iter, chunks)

        # Calculate combined window limit
        combined_limit = self._calculate_combined_limit()

        # Submission/collection loop
        while True:
            # Submit additional chunks up to limit
            self._submit_pending_chunks(futures, chunk_iter, combined_limit)

            if not futures:
                # No outstanding work and no more chunks to submit
                break

            # Wait for at least one future to complete
            done, _ = wait(futures.keys(), return_when=FIRST_COMPLETED)

            # Process completed futures
            yield from self._process_completed_futures(done, futures)

    def _submit_initial_chunks(
        self,
        futures: dict[Any, CodeChunk],
        chunk_iter: Iterator[CodeChunk],
        chunks: list[CodeChunk],
    ) -> None:
        """Submit initial batch of chunks to executor"""
        initial = min(self.stream_config.max_concurrent_chunks, len(chunks))
        for _ in range(initial):
            try:
                chunk = next(chunk_iter)
            except StopIteration:
                break
            fut = self.executor.submit(self._process_single_chunk, chunk)
            futures[fut] = chunk

    def _calculate_combined_limit(self) -> int:
        """Calculate the combined window limit for outstanding work"""
        if self.stream_config.enable_backpressure:
            return self.stream_config.max_concurrent_chunks + self.stream_config.max_queue_size
        return self.stream_config.max_concurrent_chunks

    def _submit_pending_chunks(
        self,
        futures: dict[Any, CodeChunk],
        chunk_iter: Iterator[CodeChunk],
        combined_limit: int,
    ) -> None:
        """Submit pending chunks up to the combined limit"""
        while len(futures) < combined_limit:
            try:
                next_chunk = next(chunk_iter)
            except StopIteration:
                break
            fut = self.executor.submit(self._process_single_chunk, next_chunk)
            futures[fut] = next_chunk

    def _process_completed_futures(
        self, done: set[Any], futures: dict[Any, CodeChunk]
    ) -> Iterator[ChunkResult]:
        """Process completed futures and yield results"""
        for fut in list(done):
            chunk = futures.pop(fut)
            try:
                result = fut.result(timeout=self.stream_config.chunk_timeout)

                # Record telemetry
                self._record_chunk_telemetry(result, chunk)

                # Update progress tracking
                self._update_chunk_progress(result, chunk)

                # Emit completion event
                self._dispatch(
                    EventType.STREAM_CHUNK_PROCESSED,
                    index=chunk.chunk_index,
                    success=bool(result.success),
                    duration_ms=int(getattr(result, "processing_time", 0.0) * 1000.0),
                )

                yield result
            except Exception as e:
                logger.error("Error processing chunk %s: %s", chunk.chunk_index, e)
                self._dispatch(
                    EventType.STREAM_CHUNK_PROCESSED,
                    index=chunk.chunk_index,
                    success=False,
                )
                yield ChunkResult(chunk_index=chunk.chunk_index, success=False, error=str(e))

    @staticmethod
    def _record_chunk_telemetry(result: ChunkResult, chunk: CodeChunk) -> None:
        """Record telemetry for completed chunk"""
        with suppress(Exception):
            recorder = get_recorder()
            recorder.record_event(
                "stream.chunk",
                getattr(result, "processing_time", 0.0) * 1000.0,
                extra={
                    "chunk_index": chunk.chunk_index,
                    "size": chunk.size,
                },
            )

    def _update_chunk_progress(self, result: ChunkResult, chunk: CodeChunk) -> None:
        """Update progress tracking for completed chunk"""
        self.progress.processed_chunks += 1
        self.progress.bytes_processed += chunk.size

        if result.error:
            self.progress.errors.append(result.error)
        self.progress.warnings.extend(result.warnings)

    def _process_single_chunk(self, chunk: CodeChunk) -> ChunkResult:
        """
        Process a single chunk through the pipeline

        Args:
            chunk: Code chunk to process

        Returns:
            ChunkResult
        """
        start_time = time.time()
        result = ChunkResult(chunk_index=chunk.chunk_index, success=True)

        try:
            # Add context and parse
            chunk_with_context = self._add_context_to_chunk(chunk)
            parse_result = self.parser.get_parse_result(chunk_with_context)

            # Validate parse result
            if not self._validate_parse_result(parse_result, result):
                return result

            # Store parse results
            result.parsed_blocks = parse_result.blocks
            result.warnings.extend(parse_result.warnings)

            # Translate blocks
            translated_blocks = self._translate_blocks(
                parse_result.blocks, chunk.chunk_index, result
            )
            result.translated_blocks = translated_blocks

            # Update context and buffer
            self._update_context_window(chunk, translated_blocks)
            self.buffer.add_chunk(chunk.chunk_index, result)

        except Exception as e:
            logger.error("Error in chunk %s: %s", chunk.chunk_index, e)
            result.success = False
            result.error = str(e)

        result.processing_time = time.time() - start_time
        return result

    @staticmethod
    def _validate_parse_result(parse_result: Any, result: ChunkResult) -> bool:
        """Validate parse result and update result object on failure"""
        success_attr = getattr(parse_result, "success", None)
        parse_success = (
            success_attr if isinstance(success_attr, bool) else (len(parse_result.errors) == 0)
        )
        if not parse_success:
            result.success = False
            result.error = f"Parse error: {parse_result.errors}"
            return False
        return True

    def _translate_blocks(
        self, blocks: list[CodeBlock], chunk_index: int, result: ChunkResult
    ) -> list[CodeBlock]:
        """Translate English blocks to Python code"""
        translated_blocks = []
        for block in blocks:
            if block.type == BlockType.ENGLISH:
                translated_block = self._translate_english_block(block, chunk_index, result)
                translated_blocks.append(translated_block)
            else:
                translated_blocks.append(block)
        return translated_blocks

    def _translate_english_block(
        self, block: CodeBlock, chunk_index: int, result: ChunkResult
    ) -> CodeBlock:
        """Translate a single English block to Python"""
        context = self._build_translation_context(chunk_index)

        try:
            # Get translation result
            translation_result = self._get_translation_result(block, context)

            # Create translated block
            return CodeBlock(
                type=BlockType.PYTHON,
                content=str(translation_result.code),
                line_numbers=block.line_numbers,
                metadata={**block.metadata, "translated": True},
                context=block.context,
            )

        except Exception as e:
            logger.error("Translation error in chunk %s: %s", chunk_index, e)
            result.warnings.append(f"Translation error: {str(e)}")
            return block  # Keep original on error

    def _get_translation_result(
        self, block: CodeBlock, context: dict[str, Any]
    ) -> ModelTranslationResult:
        """Get and validate translation result from translator"""
        translator = self.translator
        if translator is None:
            raise RuntimeError("Translator not initialized")

        res = translator.translate_text_block(text=block.content, context=context)

        # Validate translation result
        if (
            not isinstance(res, ModelTranslationResult)
            or not getattr(res, "success", False)
            or getattr(res, "code", None) is None
        ):
            error_msg = (
                ", ".join(getattr(res, "errors", []))
                if getattr(res, "errors", [])
                else "No code returned"
            )
            raise RuntimeError(f"Translation failed: {error_msg}")

        return res

    def _add_context_to_chunk(self, chunk: CodeChunk) -> str:
        """
        Add context from previous chunks to current chunk

        Args:
            chunk: Current chunk

        Returns:
            Chunk content with context
        """
        if not self.stream_config.maintain_context_window:
            return chunk.content

        # Get context from buffer
        context_lines = []

        # Add previous chunk's tail if available
        if chunk.chunk_index > 0:
            prev_result = self.buffer.get_chunk(chunk.chunk_index - 1)
            if prev_result and prev_result.translated_blocks:
                # Get last few lines from previous chunk
                last_block = prev_result.translated_blocks[-1]
                context_lines.extend(last_block.content.splitlines()[-10:])

        if context_lines:
            context = "\n".join(context_lines)
            return f"{context}\n\n# --- Chunk {chunk.chunk_index} ---\n\n{chunk.content}"

        return chunk.content

    def _build_translation_context(self, chunk_index: int) -> dict[str, Any]:
        """
        Build context for translation

        Args:
            chunk_index: Current chunk index

        Returns:
            Context dictionary
        """
        context = {"chunk_index": chunk_index, "code": "", "before": "", "after": ""}

        # Get previous chunk's code
        if chunk_index > 0:
            prev_result = self.buffer.get_chunk(chunk_index - 1)
            if prev_result and prev_result.translated_blocks:
                prev_code = "\n".join(
                    block.content
                    for block in prev_result.translated_blocks
                    if block.type == BlockType.PYTHON
                )
                context["before"] = prev_code[-self.stream_config.context_window_size :]
                context["code"] = context["before"]

        return context

    def _update_context_window(self, chunk: CodeChunk, blocks: list[Any]):
        """
        Update the context window with processed blocks

        Args:
            chunk: Processed chunk
            blocks: Translated blocks
        """
        # Keep a sliding window of recent code
        for block in blocks:
            if block.type == BlockType.PYTHON:
                self.context_window.append(
                    {
                        "chunk_index": chunk.chunk_index,
                        "content": block.content,
                        "metadata": block.metadata,
                    }
                )

        # Limit context window size
        max_items = 10
        if len(self.context_window) > max_items:
            self.context_window[:] = self.context_window[-max_items:]

    def assemble_streamed_code(self) -> str:
        """
        Assemble all streamed chunks into final code

        Returns:
            Complete assembled code
        """
        all_blocks = []

        # Get all chunks from buffer in order
        for i in range(self.progress.total_chunks):
            result = self.buffer.get_chunk(i)
            if result and result.translated_blocks:
                all_blocks.extend(result.translated_blocks)

        # Use assembler to create final code
        return self.assembler.assemble(all_blocks)

    def _start_progress_reporting(self):
        """Start the progress reporting thread"""
        self._stop_event.clear()
        self._progress_thread = threading.Thread(target=self._progress_reporter, daemon=True)
        self._progress_thread.start()

    def _stop_progress_reporting(self):
        """Stop the progress reporting thread"""
        self._stop_event.set()
        if self._progress_thread:
            self._progress_thread.join(timeout=1)

    def _progress_reporter(self):
        """Thread function for reporting progress"""
        while not self._stop_event.is_set():
            # Report progress to all callbacks
            for callback in self.progress_callbacks:
                try:
                    callback(self.progress)
                except Exception as e:
                    logger.error("Error in progress callback: %s", e)

            # Wait before next update
            self._stop_event.wait(self.stream_config.progress_callback_interval)

    def cancel_streaming(self):
        """Cancel ongoing streaming operation"""
        self._stop_event.set()
        self.executor.shutdown(wait=False)
        logger.info("Streaming operation cancelled")

    def get_memory_usage(self) -> dict[str, int]:
        """
        Get current memory usage statistics

        Returns:
            Memory usage in bytes
        """
        return {
            "buffer_size": self.buffer.get_size(),
            "context_window_size": sum(
                len(item["content"].encode("utf-8")) for item in self.context_window
            ),
            # No internal chunk_queue; queued work is bounded via submission window.
            # Expose 0 to preserve key without referencing removed attribute.
            "queue_size": 0,
        }
