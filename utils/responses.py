"""
Standard Response Utilities

Provides consistent response formatting across database operations and API calls.
Eliminates duplication of {"success": True/False, "error": ...} patterns.
"""

from typing import Any


def success_response(data: Any = None, message: str | None = None) -> dict[str, Any]:
    """
    Create a standard success response.

    Args:
        data: Optional data payload to include in response
        message: Optional success message

    Returns:
        Dictionary with success=True and optional data/message

    Example:
        >>> success_response({"id": "123"})
        {"success": True, "data": {"id": "123"}}

        >>> success_response()
        {"success": True}
    """
    result: dict[str, Any] = {"success": True}

    if data is not None:
        result["data"] = data

    if message is not None:
        result["message"] = message

    return result


def error_response(error: Exception | str, context: str = "", include_type: bool = False) -> dict[str, Any]:
    """
    Create a standard error response.

    Args:
        error: Exception or error message string
        context: Optional context about where/why the error occurred
        include_type: Whether to include the exception type name

    Returns:
        Dictionary with success=False, error message, and optional context

    Example:
        >>> error_response(ValueError("Invalid input"))
        {"success": False, "error": "Invalid input"}

        >>> error_response("Not found", context="User lookup")
        {"success": False, "error": "Not found", "context": "User lookup"}

        >>> error_response(ValueError("Bad"), include_type=True)
        {"success": False, "error": "Bad", "error_type": "ValueError"}
    """
    result: dict[str, Any] = {
        "success": False,
        "error": str(error),
    }

    if context:
        result["context"] = context

    if include_type and isinstance(error, Exception):
        result["error_type"] = type(error).__name__

    return result


def data_response(
    success: bool,
    data: Any = None,
    error: Exception | str | None = None,
    message: str | None = None,
) -> dict[str, Any]:
    """
    Create a flexible response with both data and potential error info.

    Useful for operations that partially succeed or need to return
    data even on failure.

    Args:
        success: Whether the operation succeeded
        data: Optional data payload
        error: Optional error if success=False
        message: Optional message

    Returns:
        Dictionary with success flag, optional data/error/message

    Example:
        >>> data_response(True, data={"count": 5}, message="Found 5 items")
        {"success": True, "data": {"count": 5}, "message": "Found 5 items"}
    """
    result: dict[str, Any] = {"success": success}

    if data is not None:
        result["data"] = data

    if error is not None:
        result["error"] = str(error)

    if message is not None:
        result["message"] = message

    return result
