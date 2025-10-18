from __future__ import annotations

from importlib import import_module
from types import ModuleType
from typing import Any

# Prefer project logger if available; fall back to stdlib logging.
try:
    # tools/common/logging_utils may provide get_logger in some environments
    from tools.common.logging_utils import get_logger  # type: ignore[attr-defined]
except Exception:
    try:
        # Enhanced logger used elsewhere in the repo
        from utils.enhanced_logger import get_logger  # type: ignore
    except Exception:
        import logging

        def get_logger(name: str):  # type: ignore[misc]
            """Fallback logger factory using the standard library logging module.

            Args:
                name: Name of the logger to retrieve.

            Returns:
                A logger instance from the standard library.
            """
            return logging.getLogger(name)


logger = get_logger("utils.safe_imports")


# New specific exception for import hardening
class SafeImportError(ImportError):
    """Raised when a safe import or attribute load is rejected by policy."""

    pass


def safe_import(key: str, allowed: dict[str, str]) -> ModuleType:
    """Safely import a module using an explicit allowlist mapping.

    Args:
        key: Logical key identifying the target module. This value is matched
             exactly against the keys of the 'allowed' mapping. Callers must
             NOT pass dotted import paths directly.
        allowed: Mapping of allowed keys to fully-qualified module names to import.

    Returns:
        The imported module object.

    Raises:
        SafeImportError: If the key is not allowed, the mapping is invalid, or the import fails.

    Notes:
        - Rejects unknown keys with a debug log.
        - Enforces a minimal sanity check on the mapped module string.
    """
    k = str(key or "").strip()
    if not k or k not in allowed:
        logger.debug("safe_import rejected module key", extra={"key": k})
        raise SafeImportError(f"module not allowed: {k!r}")

    module_name = str(allowed[k]).strip()
    # Disallow oddities; only dotted absolute module names are permitted.
    if not module_name or module_name.startswith((".", "/")) or ":" in module_name:
        logger.debug(
            "safe_import invalid module mapping",
            extra={"key": k, "module": module_name},
        )
        raise SafeImportError(f"invalid module mapping for key: {k!r}")

    try:
        module = import_module(module_name)
        return module
    except Exception as exc:
        logger.debug(
            "safe_import import failed",
            extra={"key": k, "module": module_name, "error": str(exc)},
        )
        raise SafeImportError(f"import failed for allowed module: {module_name!r}") from exc


def safe_load_attr(module: ModuleType, name: str, allowed: set[str]) -> Any:
    """Safely load an attribute from a module using an explicit allowlist.

    Args:
        module: Imported module to read from.
        name: Attribute name to retrieve. Dotted attribute lookups are not supported.
        allowed: Set of allowed attribute names for this module.

    Returns:
        The attribute value.

    Raises:
        AttributeError: If the attribute is not allowed or not present.
    """
    n = str(name or "").strip()
    if not n or n not in allowed:
        logger.debug(
            "safe_load_attr rejected attribute",
            extra={"module": getattr(module, "__name__", repr(module)), "name": n},
        )
        raise AttributeError(f"attribute not allowed: {n!r}")

    # Prevent nested or path-like attribute access.
    if "." in n or "/" in n or ":" in n:
        logger.debug(
            "safe_load_attr invalid attribute name",
            extra={"module": getattr(module, "__name__", repr(module)), "name": n},
        )
        raise AttributeError(f"invalid attribute name: {n!r}")

    try:
        return getattr(module, n)
    except AttributeError:
        logger.debug(
            "safe_load_attr missing attribute",
            extra={"module": getattr(module, "__name__", repr(module)), "name": n},
        )
        raise


def safe_import_from_map(specs: dict[str, tuple[str, str]], key: str) -> Any:
    """Safely import an object using a key -> (module, attr) specification map.

    Args:
        specs: Mapping of logical keys to (module_name, attr_name).
        key: Logical key to resolve.

    Returns:
        The resolved attribute object.

    Raises:
        SafeImportError: If the key is not in the map, mapping is invalid, or import fails.
        AttributeError: If the attribute is not present on the imported module.
    """
    k = str(key or "").strip()
    if not k or k not in specs:
        logger.debug("safe_import_from_map rejected key", extra={"key": k})
        raise SafeImportError(f"spec not allowed: {k!r}")

    module_name, attr_name = specs[k]
    # Import only the module for this key
    module = safe_import(k, {k: module_name})
    # Allow only the one expected attribute
    return safe_load_attr(module, attr_name, {attr_name})
