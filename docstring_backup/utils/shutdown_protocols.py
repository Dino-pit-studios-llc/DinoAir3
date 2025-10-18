"""Utility mixins for graceful shutdown semantics.

This module provides a lightweight :class:`ShutdownMixin` that offers
thread-safe shutdown coordination for long-lived services. Classes that
inherit from this mixin gain an idempotent :meth:`shutdown` method,
optional callback registration, and convenient context-manager support.
"""

from __future__ import annotations

import logging
import threading
from collections.abc import Callable
from typing import Any

logger = logging.getLogger(__name__)

ShutdownCallback = Callable[[], Any]


class ShutdownMixin:
    """Mixin that standardises shutdown behaviour for services."""

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)
        self._shutdown_lock = threading.RLock()
        self._shutdown_callbacks: list[ShutdownCallback] = []
        self._is_shutdown = False

    @property
    def is_shutdown(self) -> bool:
        """Return ``True`` when shutdown has already completed."""

        return self._is_shutdown

    def register_shutdown_callback(self, callback: ShutdownCallback) -> None:
        """Register a callback executed after primary cleanup.

        Callbacks are invoked in *last-in, first-out* order once the
        shutdown sequence completes successfully. If the component was
        already shut down, the callback executes immediately to guarantee
        consistent semantics.
        """

        if not callable(callback):
            raise TypeError("callback must be callable")

        with self._shutdown_lock:
            if self._is_shutdown:
                ShutdownMixin._invoke_callback(callback)
                return
            self._shutdown_callbacks.append(callback)

    def shutdown(self) -> None:
        """Perform shutdown exactly once, swallowing non-critical errors."""

        with self._shutdown_lock:
            if self._is_shutdown:
                return

            self._run_cleanup()
            self._run_callbacks()
            self._is_shutdown = True

    # Alias used throughout the codebase where ``close`` is expected.
    close = shutdown

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb) -> None:  # type: ignore[override]
        self.shutdown()
        return False

    def _run_cleanup(self) -> None:
        """Invoke ``_cleanup_resources`` if implemented by the subclass."""

        cleanup = getattr(self, "_cleanup_resources", None)
        if cleanup is None:
            return

        try:
            cleanup()
        except Exception:  # pragma: no cover - defensive logging only
            logger.exception("Error while cleaning up resources during shutdown")

    def _run_callbacks(self) -> None:
        """Invoke registered shutdown callbacks in LIFO order."""

        while self._shutdown_callbacks:
            callback = self._shutdown_callbacks.pop()
            ShutdownMixin._invoke_callback(callback)

    @staticmethod
    def _invoke_callback(callback: ShutdownCallback) -> None:
        try:
            callback()
        except Exception:  # pragma: no cover - defensive logging only
            logger.exception("Error while executing shutdown callback %r", callback)


__all__ = ["ShutdownMixin", "ShutdownCallback"]
