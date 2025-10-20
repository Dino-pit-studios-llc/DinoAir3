"""
Configuration Compatibility Layer for DinoAir

Provides backward-compatible imports for configuration management
"""

import os
from pathlib import Path
from typing import Any

from .versioned_config import VersionedConfigManager, get_config


class CompatibilityConfigLoader:
    """
    Backward-compatible wrapper around VersionedConfigManager.
    
    Provides the same interface as the old ConfigLoader class.
    """

    def __init__(self, config_path: Path | None = None):
        """
        Initialize compatibility loader.

        Args:
            config_path: Path to configuration file (optional)
        """
        self._config_manager = get_config()
        
        # If a custom config path is provided, initialize with it
        if config_path is not None:
            base_dir = Path(__file__).parent.parent
            self._config_manager = VersionedConfigManager(
                base_dir=base_dir,
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

    # Async-specific compatibility methods
    def is_async_enabled(self) -> bool:
        """Check if async operations are enabled globally."""
        return self._config_manager.get("async.enabled", True)

    def should_use_async_file_ops(self) -> bool:
        """Check if async file operations should be used."""
        return self._config_manager.get("async.file_operations.use_async", True)

    def should_use_async_network_ops(self) -> bool:
        """Check if async network operations should be used."""
        return self._config_manager.get("async.network_operations.use_async", True)

    def should_use_async_pdf_processing(self) -> bool:
        """Check if async PDF processing should be used."""
        return self._config_manager.get("async.pdf_processing.use_async", True)

    def get_async_concurrent_limit(self) -> int:
        """Get the concurrent limit for async file operations."""
        return self._config_manager.get("async.file_operations.concurrent_limit", 10)

    def get_async_network_timeout(self) -> float:
        """Get the timeout for async network operations."""
        return float(self._config_manager.get("async.network_operations.timeout", 30.0))

    def get_async_pdf_timeout(self) -> float:
        """Get the timeout for async PDF processing."""
        return float(self._config_manager.get("async.pdf_processing.timeout", 60.0))


# Backward compatibility alias
ConfigLoader = CompatibilityConfigLoader
