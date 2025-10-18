"""
Common input validators and a lightweight validation decorator.

Provides consistent, unit-friendly validation utilities with strict typing and predictable error messages.
All validation logic is grouped in the Validator class for clarity and maintainability.
"""

import inspect as _inspect
from functools import wraps
from pathlib import Path
from typing import TYPE_CHECKING, Any, ParamSpec, TypeVar

if TYPE_CHECKING:
    from collections.abc import Callable

P = ParamSpec("P")
R = TypeVar("R")


class Validator:
    """
    Namespace for common input validation utilities.
    All methods are static for easy use and testing.
    """

    @staticmethod
    def non_empty_str(name: str, value: str) -> None:
        """Raise ValueError if value is empty or whitespace."""
        if value is None or not str(value).strip():
            raise ValueError(f"{name} is required")

    @staticmethod
    def list_non_empty(name: str, items: list[Any]) -> None:
        """Raise ValueError if list is empty or None."""
        if not items:
            raise ValueError(f"{name} list is required and cannot be empty")

    @staticmethod
    def normalize_to_path(value: Any) -> Path:
        """Convert input to Path, mirroring Path(value) behavior."""
        try:
            return Path(value)
        except TypeError as te:
            raise te

    @staticmethod
    def check_exists(p: Path, raw_value: Any) -> None:
            """Check Exists method."""
        if not p.exists():
            raise ValueError(f"Path does not exist: {raw_value}")

    @staticmethod
    def check_file(p: Path, raw_value: Any) -> None:
            """Check File method."""
        if not p.is_file():
            raise ValueError(f"Path is not a file: {raw_value}")

    @staticmethod
    def check_dir(p: Path, raw_value: Any) -> None:
            """Check Dir method."""
        if not p.is_dir():
            raise ValueError(f"Path is not a directory: {raw_value}")

    @staticmethod
    def validate_path_exists(
        path: str, must_be_file: bool | None = None, must_be_dir: bool | None = None
            """Validate path exists method."""
    ) -> Path:
        p = Validator.normalize_to_path(path)
        Validator.check_exists(p, path)
        if must_be_file:
            Validator.check_file(p, path)
        if must_be_dir:
            Validator.check_dir(p, path)
        return p

    @staticmethod
    def classify_path_error(exc: Exception) -> str:
            """Classify Path Error method."""
        msg = str(exc)
        if msg.startswith("Path does not exist:"):
            return "not_found"
        if msg.startswith("Path is not a file:"):
            return "not_file"
        return "not_dir" if msg.startswith("Path is not a directory:") else "other"


def validate_args(
    mapping: dict[str, tuple["Callable[..., None]", ...]],
) -> "Callable[[Callable[P, R]], Callable[P, R]]":
    """
    Decorator to validate named args before the wrapped function executes.
    mapping: Dict where keys are argument names and values are tuples of validators.
    Each validator is called in order for the argument's value.
    """

    def decorator(func: "Callable[P, R]") -> "Callable[P, R]":
        sig = inspect.signature(func)

        @wraps(func)
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
            bound = sig.bind_partial(*args, **kwargs)
            arguments = bound.arguments
            _validate_all_arguments(mapping, arguments)
            return func(*args, **kwargs)

        return wrapper

    return decorator


def _validate_all_arguments(
    mapping: dict[str, tuple["Callable[..., None]", ...]],
    arguments: dict[str, Any],
) -> None:
    """Validate all arguments using their respective validators"""
    for arg_name, validators in mapping.items():
        if arg_name in arguments:
            _validate_argument(arg_name, arguments[arg_name], validators)


def _validate_argument(
    arg_name: str, value: Any, validators: tuple["Callable[..., None]", ...]
) -> None:
    """Validate a single argument with all its validators"""
    for validator in validators:
        _call_validator(validator, arg_name, value)


def _call_validator(validator: "Callable[..., None]", arg_name: str, value: Any) -> None:
    """Call validator with appropriate signature"""

    try:
        sig = _inspect.signature(validator)
        param_count = len(sig.parameters)
    except (ValueError, TypeError):
        # Fallback if signature inspection fails
        param_count = 1

    if param_count >= 2:
        validator(arg_name, value)  # type: ignore[misc]
    elif param_count == 1:
        validator(value)  # type: ignore[misc]
    else:
        raise TypeError(
            f"Validator {validator} has unexpected signature: expected 1 or 2 parameters, got {param_count}"
        )