"""
Log sanitization utilities for DinoAir.

Provides simple utilities to sanitize user input before logging
to prevent log injection attacks.
"""

import re
from typing import Any


def sanitize_for_log(value: Any, max_length: int = 200) -> str:
    r"""
    Sanitize a value for safe logging.

    Removes or escapes characters that could be used for log injection attacks:
    - Newlines (\n, \r)
    - Tab characters (\t)
    - Other control characters
    - Limits length to prevent log spam

    Args:
        value: The value to sanitize (will be converted to string)
        max_length: Maximum length of the sanitized output

    Returns:
        Sanitized string safe for logging
    """
    if value is None:
        return "None"

    # Convert to string and limit size immediately to prevent DoS
    str_value = str(value)
    if len(str_value) > max_length * 2:  # Pre-truncate very large input
        str_value = str_value[: max_length * 2]

    # Replace newlines and carriage returns with escaped versions
    sanitized = str_value.replace("\n", "\\n").replace("\r", "\\r")

    # Replace tabs with escaped version
    sanitized = sanitized.replace("\t", "\\t")

    # Remove other control characters - Fixed DoS: limit processing time
    # Keep only printable characters and common safe Unicode
    sanitized = re.sub(r"[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]", "", sanitized)

    # Truncate if too long and add indicator
    if len(sanitized) > max_length:
        sanitized = sanitized[: max_length - 3] + "..."

    return sanitized
