"""Interactive translation helpers extracted from StreamingTranslator."""

from __future__ import annotations

import asyncio
import logging
from collections.abc import AsyncIterator, Callable, Iterator

from ..models import BlockType
from ..models.base_model import TranslationResult as ModelTranslationResult
from .events import TranslationUpdate
from .streaming_translator import StreamingTranslator


def process_interactive_input(
    translator: StreamingTranslator,
    user_input: str,
    session_context: list[str],
    interaction_count: int,
    on_update: Callable[[TranslationUpdate], None] | None,
) -> str | None:
    """Process interactive input and return translated code.

    Args:
        translator: StreamingTranslator instance
        user_input: User's input text
        session_context: Session history
        interaction_count: Current interaction count
        on_update: Optional callback for updates

    Returns:
        Translated code or None if parsing failed
    """
    context = {
        "mode": "interactive",
        "session_history": "\n".join(session_context[-5:]),
        "interaction_count": interaction_count,
    }

    try:
        parse_result = translator.parser.get_parse_result(user_input)
        if not _is_parse_successful(parse_result):
            return None

        translations = _translate_blocks(
            translator,
            parse_result.blocks,
            context,
            interaction_count,
            user_input,
            on_update,
        )
        return "\n".join(translations)

    except Exception as e:
        logging.error("Error in interactive translation: %s", e)
        return f"Error: {str(e)}"


def _is_parse_successful(parse_result) -> bool:
    """Check if parse was successful.

    Args:
        parse_result: Parser result object

    Returns:
        True if parsing succeeded
    """
    success_attr = getattr(parse_result, "success", None)
    return success_attr if isinstance(success_attr, bool) else (len(parse_result.errors) == 0)


def _translate_blocks(
    translator: StreamingTranslator,
    blocks,
    context: dict,
    interaction_count: int,
    user_input: str,
    on_update: Callable[[TranslationUpdate], None] | None,
) -> list[str]:
    """Translate all blocks and return results.

    Args:
        translator: StreamingTranslator instance
        blocks: Blocks to translate
        context: Translation context
        interaction_count: Current interaction count
        user_input: Original user input
        on_update: Optional callback for updates

    Returns:
        List of translated code strings
    """
    translations: list[str] = []

    for block in blocks:
        if block.type == BlockType.ENGLISH:
            translated = _translate_english_block(translator, block, context)
        else:
            translated = block.content

        translations.append(translated)

        if on_update:
            on_update(
                TranslationUpdate(
                    chunk_index=interaction_count,
                    block_index=0,
                    original_content=user_input,
                    translated_content=translated,
                    metadata={"interactive": True},
                )
            )

    return translations


def _translate_english_block(translator: StreamingTranslator, block, context: dict) -> str:
    """Translate a single English block.

    Args:
        translator: StreamingTranslator instance
        block: Block to translate
        context: Translation context

    Returns:
        Translated code

    Raises:
        RuntimeError: If translation fails
    """
    manager = translator.translation_manager
    if manager is None:
        raise RuntimeError("Translation manager is not initialized")

    res = manager.translate_text_block(text=block.content, context=context)

    if not isinstance(res, ModelTranslationResult):
        raise RuntimeError("Translation failed: Invalid result type")

    if not getattr(res, "success", False):
        errors = getattr(res, "errors", [])
        error_msg = ", ".join(errors) if errors else "Translation failed"
        raise RuntimeError(f"Translation failed: {error_msg}")

    code = getattr(res, "code", None)
    if code is None:
        raise RuntimeError("Translation failed: No code returned")

    return str(code)


def interactive_translate(
    translator: StreamingTranslator,
        """Interactive Translate function."""
    input_stream: Iterator[str],
    on_update=None,
):
    session_context: list[str] = []
    interaction_count = 0
    for user_input in input_stream:
        if translator.check_cancelled():
            break
        translator.wait_if_paused()
        session_context.append(f"# User input {interaction_count}:\n{user_input}")
        response = process_interactive_input(
            translator, user_input, session_context, interaction_count, on_update
        )
        if response:
            yield f"# Translation {interaction_count}:\n{response}\n\n"
            session_context.append(f"# Translation {interaction_count}:\n{response}")
        interaction_count += 1


async def interactive_translate_async(
    translator: StreamingTranslator,
        """Interactive Translate Async function."""
    input_stream: AsyncIterator[str],
    on_update=None,
):
    session_context: list[str] = []
    interaction_count = 0
    async for user_input in input_stream:
        if translator.check_cancelled():
            break
        translator.wait_if_paused()
        loop = asyncio.get_event_loop()
        response = await loop.run_in_executor(
            None,
            process_interactive_input,
            translator,
            user_input,
            session_context,
            interaction_count,
            on_update,
        )
        if response:
            yield f"# Translation {interaction_count}:\n{response}\n\n"
            session_context.append(f"# User {interaction_count}: {user_input}")
            session_context.append(f"# Assistant {interaction_count}: {response}")
        interaction_count += 1