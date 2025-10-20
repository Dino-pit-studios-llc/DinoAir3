"""
Configuration Compatibility Layer for DinoAir

Provides backward-compatible imports for configuration management
"""

import os
from pathlib import Path
from typing import Any

from .versioned_config import VersionedConfigManager, get_config


class CompatibilityConfigLoader:
    """Legacy ConfigLoader interface for backward compatibility with existing code."""

    def __init__(self, config_path: Path | None = None):
        """Initialize compatibility loader."""
        self._config_manager = get_config()
        base_dir = Path(__file__).parent.parent
        if config_path is not None:
            self._config_manager = VersionedConfigManager(
                base_dir=base_dir,
                config_file_path=config_path,
                validate_on_load=False,
            )
        self.old_config_path = base_dir / "config" / "app_config.json"
        self.new_config_path = base_dir / "config" / "app_config.json"
        self.backup_path = base_dir / "config" / "app_config.json.backup"

    def get(self, key: str, default: Any = None) -> Any:
        """Get configuration value using dot notation (backward compatible)."""
        return self._config_manager.get(key, default)

    def set(self, key: str, value: Any, save: bool = True) -> None:
        """Set configuration value (backward compatible)."""
        self._config_manager.set(key, value)
        if save:
            self.save_config()

    def save_config(self) -> None:
        """Save configuration to file (backward compatible)."""
        self._config_manager.save_config_file()

    @staticmethod
    def migrate() -> bool:
        """Check if migration is needed."""
        return False

    def load_config() -> None:        """Migrate old configuration to new format.

        """Load configuration (no-op for compatibility)"""

        # The new system loads automatically        Currently always returns True as no migration is implemented yet.

        Future implementations should perform actual migration steps.

    @staticmethod

    def get_env(key: str, default: str = "") -> str:        Returns:

        """Get environment variable value"""            True if migration was successful (always True in current version)

        return os.environ.get(key, default)        """

        if not ConfigMigrator.needs_migration():

    # Async-specific compatibility methods            return True

    def is_async_enabled(self) -> bool:

        """Check if async operations are enabled globally"""        # noqa: PLR2004 - Placeholder for future migration logic

        return self._config_manager.get("async.enabled", True)        # Migration logic would go here when old format files need conversion

        return True

    def should_use_async_file_ops(self) -> bool:

        """Check if async file operations should be used"""

        return self._config_manager.get("async.file_operations.use_async", True)class CompatibilityConfigLoader:

    """

    def should_use_async_network_ops(self) -> bool:    Backward-compatible wrapper around VersionedConfigManager

        """Check if async network operations should be used"""    Provides the same interface as the old ConfigLoader class

        return self._config_manager.get("async.network_operations.use_async", True)    """



    def should_use_async_pdf_processing(self) -> bool:    def __init__(self, config_path: Path | None = None):

        """Check if async PDF processing should be used"""        """

        return self._config_manager.get("async.pdf_processing.use_async", True)        Initialize compatibility loader



    def get_async_concurrent_limit(self) -> int:        Args:

        """Get the concurrent limit for async file operations"""            config_path: Path to configuration file (optional)

        return self._config_manager.get("async.file_operations.concurrent_limit", 10)        """

        self._config_manager = get_config()

    def get_async_network_timeout(self) -> float:

        """Get the timeout for async network operations"""        # If a custom config path is provided, initialize with it

        return self._config_manager.get("async.network_operations.timeout", 30.0)        if config_path is not None:

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
