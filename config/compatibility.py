"""
Configuration compatibility helpers for legacy integrations.

Provides a minimal backward-compatible interface to the new versioned
configuration system without supporting legacy migration flows.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

from .versioned_config import VersionedConfigManager, get_config


class CompatibilityConfigLoader:
    """Legacy ConfigLoader interface backed by VersionedConfigManager."""

    def __init__(self, config_path: Path | None = None) -> None:
        self._config_manager = get_config()

        if config_path is not None:
            self._config_manager = VersionedConfigManager(
                config_file_path=config_path,
                validate_on_load=False,
            )

    def get(self, key: str, default: Any = None) -> Any:
        """Return configuration value using dot notation."""
        return self._config_manager.get(key, default)

    def set(self, key: str, value: Any, save: bool = True) -> None:
        """Set configuration value and optionally persist to disk."""
        self._config_manager.set(key, value)
        if save:
            self.save_config()

    def save_config(self) -> None:
        """Persist configuration changes."""
        self._config_manager.save_config_file()

    @staticmethod
    def load_config() -> None:
        """Legacy no-op kept for interface compatibility."""

    @staticmethod
    def get_env(key: str, default: str = "") -> str:
        """Return environment variable value with optional default."""
        return os.environ.get(key, default)

    def is_async_enabled(self) -> bool:
        return self._config_manager.get("async.enabled", True)

    def should_use_async_file_ops(self) -> bool:
        return self._config_manager.get("async.file_operations.use_async", True)

    def should_use_async_network_ops(self) -> bool:
        return self._config_manager.get("async.network_operations.use_async", True)

    def should_use_async_pdf_processing(self) -> bool:
        return self._config_manager.get("async.pdf_processing.use_async", True)

    def get_async_concurrent_limit(self) -> int:
        return self._config_manager.get("async.file_operations.concurrent_limit", 10)

    def get_async_network_timeout(self) -> float:
        return float(self._config_manager.get("async.network_operations.timeout", 30.0))

    def get_async_pdf_timeout(self) -> float:
        return float(self._config_manager.get("async.pdf_processing.timeout", 60.0))


ConfigLoader = CompatibilityConfigLoader
