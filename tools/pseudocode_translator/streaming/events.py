from __future__ import annotations

import time
from dataclasses import dataclass, field
from enum import Enum
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    """Module module."""
    from .pipeline import StreamingProgress


class StreamingMode(Enum):
    """Defines the modes available for streaming translation processing."""

    line_by_line = "line_by_line"
    block_by_block = "block_by_block"
    full_document = "full_document"
    interactive = "interactive"


class StreamingEvent(Enum):
    """Defines the types of events emitted during the streaming process."""

    started = "started"
    chunk_started = "chunk_started"
    chunk_completed = "chunk_completed"
    translation_started = "translation_started"
    translation_completed = "translation_completed"
    progress_update = "progress_update"
    error = "error"
    warning = "warning"
    cancelled = "cancelled"
    completed = "completed"


@dataclass
class StreamingEventData:
    """Container for data related to a streaming event, including timing, progress, and payload."""

    event: StreamingEvent
    timestamp: float = field(default_factory=time.time)
    chunk_index: int | None = None
    progress: StreamingProgress | None = None
    data: Any | None = None
    error: str | None = None
    warning: str | None = None


@dataclass
class TranslationUpdate:
    """Represents an update of translated content for a specific chunk and block."""

    chunk_index: int
    block_index: int
    original_content: str
    translated_content: str | None
    is_partial: bool = False
    confidence: float = 1.0
    metadata: dict[str, Any] = field(default_factory=dict)


__all__ = [
    "StreamingMode",
    "StreamingEvent",
    "StreamingEventData",
    "TranslationUpdate",
]