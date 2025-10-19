""""""

Configuration Compatibility Layer for DinoAirConfiguration Compatibility Layer for DinoAir

Provides backward-compatible imports for configuration managementProvides backward-compatible imports for configuration management

""""""



from pathlib import Path
from typing import Any

import get_config
import import
import osfrom
import VersionedConfigManager

import .versioned_config
from .versioned_config import (ConfigLoader:, VersionedConfigManager,
                               get_configclass)

# Backward-compatible ConfigLoader class (delegates to VersionedConfigManager)


    """Legacy ConfigLoader interface for backward compatibility with existing code."""



class CompatibilityConfigLoader:import os

    """from pathlib import Path

    Backward-compatible wrapper around VersionedConfigManagerfrom typing import Any

    Provides the same interface as the old ConfigLoader class

    """from .versioned_config import VersionedConfigManager, get_config



    def __init__(self, config_path: Path | None = None):

        """class ConfigMigrator:

        Initialize compatibility loader    """Handles migration from old configuration format to new versioned system"""



        Args:    def __init__(self, old_config_path: Path | None = None):

            config_path: Path to configuration file (optional)        """

        """        Initialize migrator

        self._config_manager = get_config()

        Args:

        # If a custom config path is provided, initialize with it            old_config_path: Path to old configuration file

        if config_path is not None:        """

            self._config_manager = VersionedConfigManager(        base_dir = Path(__file__).parent.parent

                config_file_path=config_path,        self.old_config_path = old_config_path or (base_dir / "config" / "app_config.json")

                validate_on_load=False,  # More permissive for compatibility        self.new_config_path = base_dir / "config" / "app_config.json"

            )        self.backup_path = base_dir / "config" / "app_config.json.backup"



    def get(self, key: str, default: Any = None) -> Any:    @staticmethod

        """Get configuration value using dot notation (backward compatible)"""    def needs_migration() -> bool:

        return self._config_manager.get(key, default)        """Check if migration is needed.



    def set(self, key: str, value: Any, save: bool = True) -> None:        Currently returns False as no legacy formats exist yet.

        """Set configuration value (backward compatible)"""        Future implementations should check for old format files and return True if found.

        self._config_manager.set(key, value)

        if save:        Returns:

            self.save_config()            False - no migration needed in current version

        """

    def save_config(self) -> None:        # noqa: PLR2004 - Intentional constant return for future extensibility

        """Save configuration to file (backward compatible)"""        return False

        self._config_manager.save_config_file()

    @staticmethod

    @staticmethod    def migrate() -> bool:

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

    def get_async_pdf_timeout(self) -> float:                config_file_path=config_path,

        """Get the timeout for async PDF processing"""                validate_on_load=False,  # More permissive for compatibility

        return self._config_manager.get("async.pdf_processing.timeout", 60.0)            )



    def get(self, key: str, default: Any = None) -> Any:

# Create compatibility alias        """Get configuration value using dot notation (backward compatible)"""

ConfigLoader = CompatibilityConfigLoader        return self._config_manager.get(key, default)


    def set(self, key: str, value: Any, save: bool = True) -> None:
        """Set configuration value (backward compatible)"""
        self._config_manager.set(key, value)
        if save:
            self.save_config()

    def save_config(self) -> None:
        """Save configuration to file (backward compatible)"""
        self._config_manager.save_config_file()

    @staticmethod
    def load_config() -> None:
        """Load configuration (no-op for compatibility)"""
        # The new system loads automatically

    @staticmethod
    def get_env(key: str, default: str = "") -> str:
        """Get environment variable value"""
        return os.environ.get(key, default)

    # Async-specific compatibility methods
    def is_async_enabled(self) -> bool:
        """Check if async operations are enabled globally"""
        return self._config_manager.get("async.enabled", True)

    def should_use_async_file_ops(self) -> bool:
        """Check if async file operations should be used"""
        return self._config_manager.get("async.file_operations.use_async", True)

    def should_use_async_network_ops(self) -> bool:
        """Check if async network operations should be used"""
        return self._config_manager.get("async.network_operations.use_async", True)

    def should_use_async_pdf_processing(self) -> bool:
        """Check if async PDF processing should be used"""
        return self._config_manager.get("async.pdf_processing.use_async", True)

    def get_async_concurrent_limit(self) -> int:
        """Get the concurrent limit for async file operations"""
        return self._config_manager.get("async.file_operations.concurrent_limit", 10)

    def get_async_network_timeout(self) -> float:
        """Get the timeout for async network operations"""
        return self._config_manager.get("async.network_operations.timeout", 30.0)

    def get_async_pdf_timeout(self) -> float:
        """Get the timeout for async PDF processing"""
        return self._config_manager.get("async.pdf_processing.timeout", 60.0)


def migrate_configuration(force: bool = False) -> bool:
    """
    Migrate configuration to new versioned system

    Args:
        force: Force migration even if not needed

    Returns:
        True if migration was successful
    """
    migrator = ConfigMigrator()

    if force or migrator.needs_migration():
        return migrator.migrate()

    return True


# Create compatibility instance
ConfigLoader = CompatibilityConfigLoader
