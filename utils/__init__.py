"""
Utils Package - Core utilities for DinoAir
Contains configuration, logging, and enumeration utilities
"""

from typing import TYPE_CHECKING, Any

from .config_loader import ConfigLoader
from .dependency_container import (
    CircularDependencyError,
    DependencyContainer,
    DependencyInfo,
    DependencyResolutionError,
    LifecycleState,
    Scope,
    ScopeContext,
)

# Import globals directly to avoid circular imports
from .dependency_globals import get_container, resolve, resolve_type
from .enums import Enums
from .logger import Logger as _Logger
from .safe_pdf_extractor import SafePDFProcessor, extract_pdf_text_safe
from .sql import enforce_limit, normalize_like_pattern
from .state_machine import StateMachine

__all__ = [
    "ConfigLoader",
    "Logger",
    "Enums",
    "SafePDFProcessor",
    "extract_pdf_text_safe",
    "enforce_limit",
    "normalize_like_pattern",
    "StateMachine",
    "DependencyContainer",
    "Scope",
    "LifecycleState",
    "DependencyInfo",
    "DependencyResolutionError",
    "CircularDependencyError",
    "ScopeContext",
    "get_container",
    "resolve",
    "resolve_type",
]

# Type-checker-only import to provide symbol visibility without runtime side effects
if TYPE_CHECKING:
    from .logger import Logger  # pragma: no cover  # pylint: disable=reimported

# Explicit export map to avoid dynamic globals() lookups
_EXPORTS: dict[str, Any] = {
    "ConfigLoader": ConfigLoader,
    "Logger": _Logger,
    "Enums": Enums,
    "SafePDFProcessor": SafePDFProcessor,
    "extract_pdf_text_safe": extract_pdf_text_safe,
    "enforce_limit": enforce_limit,
    "normalize_like_pattern": normalize_like_pattern,
    "StateMachine": StateMachine,
    "DependencyContainer": DependencyContainer,
    "Scope": Scope,
    "LifecycleState": LifecycleState,
    "DependencyInfo": DependencyInfo,
    "DependencyResolutionError": DependencyResolutionError,
    "CircularDependencyError": CircularDependencyError,
    "ScopeContext": ScopeContext,
    "get_container": get_container,
    "resolve": resolve,
    "resolve_type": resolve_type,
}


def __getattr__(name: str) -> Any:
    """
    Module attribute access backed by an explicit export map.
    Eliminates dynamic globals() lookups and preserves the public API.
    """
    if name in _EXPORTS:
        return _EXPORTS[name]
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


def __dir__() -> list[str]:
    # Keep introspection consistent with declared public API without using globals()
    return sorted(set(__all__) | set(_EXPORTS.keys()))
