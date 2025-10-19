"""
Async translation helpers extracted from StreamingTranslator.

Provides thread-pool offloading for synchronous translation methods and exposes
async-friendly wrappers that yield translated chunks while respecting cancel/pause.
"""

from __future__ import annotations

import asyncio
from typing import TYPE_CHECKING, Protocol

from .translator_core import process_accumulated_blocks, process_statement

if TYPE_CHECKING:
    from collections.abc import AsyncIterator, Callable, Iterator

    from .events import TranslationUpdate


"""Module for streaming translation operations.

This module defines the StreamingTranslatorProto protocol with methods to
check cancellation, handle pausing, detect complete statements, and perform
streaming translation of full documents.
"""


class StreamingTranslatorProto(Protocol):
    """Protocol defining the interface for streaming translators.

    Provides methods to manage cancellation and pausing, detect complete statements,
    and translate full documents in a streaming context.
    """

    def _check_cancelled(self) -> bool:
        """Check if the translation process has been cancelled.

        Returns:
            bool: True if the translation has been cancelled, False otherwise.
        """
        ...

    def _wait_if_paused(self) -> None:
        """Block execution while the translation process is paused."""
        ...

    def _is_complete_statement(self, text: str) -> bool:
        """Determine if the provided text constitutes a complete statement.

        Args:
            text (str): The text fragment to evaluate.

        Returns:
            bool: True if the text ends with a complete statement, False otherwise.
        """
        ...

    def _translate_full_document(
        self,
        full_text: str,
        on_update: Callable[[TranslationUpdate], None] | None = None,
    ) -> Iterator[str]:
        """Translate the entire document in a streaming manner.

        Args:
            full_text (str): The complete source text to translate.
            on_update (Callable[[TranslationUpdate], None], optional): Callback for incremental translation updates.

        Yields:
            str: Chunks of translated text as they become available.
        """
        ...


async def async_translate_line_by_line(
    translator: StreamingTranslatorProto,
    input_stream: AsyncIterator[str],
    on_update: Callable[[TranslationUpdate], None] | None = None,
) -> AsyncIterator[str]:
    """Async Translate Line By Line function."""
    line_buffer: list[str] = []
    chunk_index = 0
    async for line in input_stream:
        if translator.check_cancelled():
            break
        translator.wait_if_paused()
        line_buffer.append(line)
        if translator.is_complete_statement("".join(line_buffer)):
            statement = "".join(line_buffer)
            line_buffer.clear()
            loop = asyncio.get_running_loop()
            translated = await loop.run_in_executor(
                None, process_statement, translator, statement, chunk_index, on_update
            )
            if translated:
                yield translated
            chunk_index += 1


async def async_translate_block_by_block(
    translator: StreamingTranslatorProto,
    input_stream: AsyncIterator[str],
    on_update: Callable[[TranslationUpdate], None] | None = None,
) -> AsyncIterator[str]:
    """Async Translate Block By Block function."""
    accumulated_input: list[str] = []
    async for chunk in input_stream:
        if translator.check_cancelled():
            break
        translator.wait_if_paused()
        accumulated_input.append(chunk)
        loop = asyncio.get_running_loop()
        result = await loop.run_in_executor(
            None, process_accumulated_blocks, translator, accumulated_input, on_update
        )
        if result:
            translated_chunks, remaining = result
            if translated_chunks:
                for t in translated_chunks:
                    yield t
            accumulated_input = remaining


async def async_translate_full_document(
    translator: StreamingTranslatorProto,
    full_text: str,
    on_update: Callable[[TranslationUpdate], None] | None = None,
) -> AsyncIterator[str]:
    """Run synchronous full-document translation in a thread pool and stream results."""
    loop = asyncio.get_running_loop()

    def collect() -> list[str]:
        """Collect translations by running translate_full_document and returning the results as a list."""
        return list(translator.translate_full_document(full_text, on_update))

    results = await loop.run_in_executor(None, collect)
    for r in results:
        if translator.check_cancelled():
            break
        yield r
