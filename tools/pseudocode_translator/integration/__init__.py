"""Integration helpers for the Pseudocode Translator."""

# Lazily expose API symbols to avoid circular imports with translator.py
from .callbacks import (
    CallbackManager,
    ProgressCallback,
    StatusCallback,
    TranslationCallback,
)
from .events import (
    EventDispatcher,
    EventHandler,
    EventType,
    TranslationEvent,
    create_event_dispatcher,
)

_API_EXPORTS = {
    "TranslatorAPI",
    "SimpleTranslator",
    "translate",
    "translate_file",
    "translate_async",
    "batch_translate",
}


def __getattr__(name):
    if name in _API_EXPORTS:
        from . import api as _api

        return getattr(_api, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")


def __dir__():
    return sorted(list(globals().keys()) + list(_API_EXPORTS))


__all__ = [
    # API
    # Callbacks
    "TranslationCallback",
    "ProgressCallback",
    "StatusCallback",
    "CallbackManager",
    # Events
    "TranslationEvent",
    "EventType",
    "EventDispatcher",
    "EventHandler",
    "create_event_dispatcher",
]

# Version info
__version__ = "1.0.0"
