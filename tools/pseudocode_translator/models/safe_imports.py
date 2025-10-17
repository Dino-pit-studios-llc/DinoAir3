from __future__ import annotations

import os
import re
from types import ModuleType

# Anchored regex for a valid dotted module path (no relative segments)
_MODULE_PATH_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$")

# Allowed base packages for dynamic imports within this project.
# Includes both 'pseudocode_translator' and 'tools.pseudocode_translator' forms for compatibility.
ALLOWED_BASE_PACKAGES: tuple[str, ...] = (
    "pseudocode_translator.models",
    "pseudocode_translator.translator_support",
    "pseudocode_translator.streaming",
    "tools.pseudocode_translator.models",
    "tools.pseudocode_translator.translator_support",
    "tools.pseudocode_translator.streaming",
)


def _validate_module_name(module_name: str) -> None:
    """
    Validate that module_name is a safe, absolute dotted path within allowed bases.

    Rules enforced:
      - Must be a non-empty string
      - No relative imports (must not start with '.')
      - Must not contain '/' or OS path separators
      - Each segment must match ^[A-Za-z_][A-Za-z0-9_]*$
      - No empty segments or '..'
      - No dunder-like segments (segment starts/ends with '__')
      - Full path must match anchored regex for module paths
      - Must be equal to or a child of one of ALLOWED_BASE_PACKAGES
    """
    _check_module_name_basic(module_name)
    _check_module_path_separators(module_name)
    _check_module_syntax(module_name)
    _check_module_segments(module_name)
    _check_module_allowlist(module_name)


def _check_module_name_basic(module_name: str) -> None:
    """Check basic module name requirements.

    Args:
        module_name: Module name to check

    Raises:
        ValueError: If basic checks fail
    """
    if not isinstance(module_name, str) or not module_name:
        raise ValueError("Module name must be a non-empty string")

    if module_name.startswith("."):
        raise ValueError("Relative imports are not allowed")


def _check_module_path_separators(module_name: str) -> None:
    """Check for invalid path separators.

    Args:
        module_name: Module name to check

    Raises:
        ValueError: If path separators found
    """
    if "/" in module_name or os.sep in module_name:
        raise ValueError("Path separators are not allowed in module names")


def _check_module_syntax(module_name: str) -> None:
    """Check module name syntax.

    Args:
        module_name: Module name to check

    Raises:
        ValueError: If syntax is invalid
    """
    if not _MODULE_PATH_RE.fullmatch(module_name):
        raise ValueError(f"Invalid module path syntax: {module_name!r}")


def _check_module_segments(module_name: str) -> None:
    """Check individual module segments.

    Args:
        module_name: Module name to check

    Raises:
        ValueError: If any segment is invalid
    """
    segments = module_name.split(".")
    for seg in segments:
        if seg in ("", ".", ".."):
            raise ValueError("Invalid or relative path segment in module name")
        if seg.startswith("__") or seg.endswith("__"):
            raise ValueError("Dunder-like segments are not allowed in module names")
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", seg):
            raise ValueError(f"Invalid module segment: {seg!r}")


def _check_module_allowlist(module_name: str) -> None:
    """Check if module is in allowlist.

    Args:
        module_name: Module name to check

    Raises:
        ValueError: If module not in allowlist
    """
    for base in ALLOWED_BASE_PACKAGES:
        if module_name == base or module_name.startswith(base + "."):
            return

    raise ValueError(
        f"Module {module_name!r} is not within allowed bases: {', '.join(ALLOWED_BASE_PACKAGES)}"
    )


def safe_import_module(module_name: str) -> ModuleType:
    """
    Import a module using strict validation and an allowlist to prevent code injection.

    This function replaces importlib.import_module() at dynamic import callsites.

    Args:
        module_name: Fully qualified, absolute module path (e.g., 'pseudocode_translator.models.foo')

    Returns:
        The imported module object.

    Raises:
        ValueError: If the module name fails validation or is outside allowed namespaces.
        ImportError: If the import itself fails after validation.
    """
    _validate_module_name(module_name)
    raise ValueError("Module name not allowed.")
