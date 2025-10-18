"""
Input validation module for DinoAir InputSanitizer.

This module provides the first line of defense against security threats by
validating and cleaning user input. It detects and prevents various attack
vectors including path traversal, command injection, and other malicious
patterns.

Classes:
    ValidationError: Custom exception for validation failures
    ThreatLevel: Enum representing threat severity levels
    ValidationResult: Dataclass containing validation results
    InputValidator: Main validation class with configurable security patterns

Example:
    >>> validator = InputValidator()
    >>> result = validator.validate("Hello world")
    >>> print(f"Valid: {result.is_valid}, Threat: {result.threat_level}")
    Valid: True, Threat: ThreatLevel.none
"""

import re
import string
import unicodedata
from dataclasses import dataclass, field
from enum import Enum, auto
from pathlib import Path
from re import Pattern


class ValidationError(Exception):
    """Custom exception raised for validation failures."""


class ThreatLevel(Enum):
    """Threat severity levels for detected security issues."""

    none = auto()
    low = auto()
    medium = auto()
    high = auto()


@dataclass
class ValidationResult:
    """
    Result of input validation containing security assessment.

    Attributes:
        is_valid: Whether the input passed all validation checks
        cleaned_text: Sanitized version of the input text
        threat_level: Highest threat level detected
        issues: List of specific security issues found
    """

    is_valid: bool
    cleaned_text: str
    threat_level: ThreatLevel
    issues: list[str] = field(default_factory=list)


class InputValidator:
    """
    Validates and sanitizes user input for security threats.

    This class implements comprehensive security validation including detection
    of path traversal attempts, command injection, null bytes, control
    characters, and Windows reserved filenames.

    Attributes:
        max_length: Maximum allowed input length (default: 5000)
        dangerous_patterns: Dictionary of pattern categories and their regex
            patterns
        windows_reserved: Set of Windows reserved filenames
    """

    def __init__(self, max_length: int = 5000):
        """
        Initialize the InputValidator with configurable settings.

        Args:
            max_length: Maximum allowed input length (default: 5000)
        """
        self.max_length = max_length
        self._initialize_patterns()
        self._initialize_reserved_names()

    def _initialize_patterns(self) -> None:
        """Initialize dangerous pattern detection regex patterns."""
        self.dangerous_patterns: dict[str, list[tuple[Pattern, ThreatLevel, str]]] = {
            "path_traversal": [
                # Basic path traversal
                (
                    re.compile(r"\.\.[\\/]"),
                    ThreatLevel.high,
                    "Path traversal attempt: ../",
                ),
                (
                    re.compile(r"\.\.\\"),
                    ThreatLevel.high,
                    "Path traversal attempt: ..\\",
                ),
                # Any double dots sequence
                (
                    re.compile(r"\.\."),
                    ThreatLevel.high,
                    "Path traversal sequence detected",
                ),
                # Multiple slashes (obfuscation attempt)
                (
                    re.compile(r"[\\/]{2,}"),
                    ThreatLevel.high,
                    "Multiple slashes detected",
                ),
                # Mixed slashes with dots - Fixed ReDoS: limit repetitions
                (
                    re.compile(r"\.{2,5}[\\/]{1,3}\.{2,5}"),
                    ThreatLevel.high,
                    "Complex path traversal pattern",
                ),
                # URL encoded path traversal
                (
                    re.compile(r"\.\.%2[Ff]"),
                    ThreatLevel.high,
                    "URL encoded path traversal: ..%2F",
                ),
                (
                    re.compile(r"\.\.%5[Cc]"),
                    ThreatLevel.high,
                    "URL encoded path traversal: ..%5C",
                ),
                (re.compile(r"%2[Ee]%2[Ee]"), ThreatLevel.high, "URL encoded dots"),
                # Double encoded - Fixed ReDoS: use literal matching
                (
                    re.compile(r"%252e%252e%252f", re.IGNORECASE),
                    ThreatLevel.high,
                    "Double encoded path traversal",
                ),
                (re.compile(r"%255[Cc]"), ThreatLevel.high, "Double encoded backslash"),
                # Unicode/UTF-8 encoded
                (
                    re.compile(r"\\x2e\\x2e[\\\/]"),
                    ThreatLevel.high,
                    "Hex encoded path traversal",
                ),
                (
                    re.compile(r"\\u002e\\u002e"),
                    ThreatLevel.high,
                    "Unicode encoded path traversal",
                ),
                # Common sensitive paths
                (
                    re.compile(r"etc[\\/]passwd", re.IGNORECASE),
                    ThreatLevel.high,
                    "Attempt to access sensitive file",
                ),
                (
                    re.compile(r"windows[\\/]system", re.IGNORECASE),
                    ThreatLevel.high,
                    "Windows system directory access",
                ),
            ],
            "command_injection": [
                # Shell command separators
                (re.compile(r"[;&|]"), ThreatLevel.high, "Command separator detected"),
                # Command substitution
                (re.compile(r"`"), ThreatLevel.high, "Backtick command substitution"),
                (re.compile(r"\$\("), ThreatLevel.high, "Command substitution: $("),
                (re.compile(r"\$\{"), ThreatLevel.high, "Variable expansion: ${"),
                # Process substitution
                (re.compile(r"<\("), ThreatLevel.high, "Process substitution: <("),
                (re.compile(r">\("), ThreatLevel.high, "Process substitution: >("),
                # Redirection
                (
                    re.compile(r"(?<!\w)[<>]+(?!\w)"),
                    ThreatLevel.medium,
                    "IO redirection detected",
                ),
                # Shell variables
                (
                    re.compile(r"\$[A-Za-z_]"),
                    ThreatLevel.medium,
                    "Shell variable detected",
                ),
            ],
            "null_bytes": [
                # Direct null byte
                (re.compile(r"\x00"), ThreatLevel.high, "Null byte detected"),
                # URL encoded null byte
                (re.compile(r"%00"), ThreatLevel.high, "URL encoded null byte"),
                # Double encoded null byte
                (re.compile(r"%2500"), ThreatLevel.high, "Double encoded null byte"),
            ],
            "control_characters": [
                # Dangerous control characters (excluding \n, \t, \r)
                (
                    re.compile(r"[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]"),
                    ThreatLevel.medium,
                    "Control character detected",
                ),
            ],
            "file_system_abuse": [
                # Absolute paths
                (
                    re.compile(r"^[A-Za-z]:[\\\/]"),
                    ThreatLevel.medium,
                    "Absolute Windows path",
                ),
                (re.compile(r"^[\\\/]"), ThreatLevel.medium, "Absolute Unix path"),
                # UNC paths
                (re.compile(r"^\\\\"), ThreatLevel.high, "UNC path detected"),
                # Device files
                (
                    re.compile(r"[\\\/]dev[\\\/]"),
                    ThreatLevel.high,
                    "Device file access attempt",
                ),
                # Hidden files
                (re.compile(r"[\\\/]\."), ThreatLevel.low, "Hidden file access"),
            ],
        }

    def _initialize_reserved_names(self) -> None:
        """Initialize Windows reserved filename set."""
        # Windows reserved names
        base_reserved = {"CON", "PRN", "AUX", "NUL"}
        # COM1-COM9, LPT1-LPT9
        com_ports = {f"COM{i}" for i in range(1, 10)}
        lpt_ports = {f"LPT{i}" for i in range(1, 10)}

        self.windows_reserved: set[str] = base_reserved | com_ports | lpt_ports

    def validate(self, text: str) -> ValidationResult:
        """
        Validate input text for security threats.

        Performs comprehensive security validation including length checks,
        pattern matching for various attack vectors, and Windows reserved
        filename detection.

        Args:
            text: Input text to validate

        Returns:
            ValidationResult containing validation status, cleaned text,
            threat level, and list of issues found

        Raises:
            ValidationError: If critical validation failure occurs
        """
        if not isinstance(text, str):
            raise ValidationError(f"Input must be string, got {type(text).__name__}")

        issues: list[str] = []
        threat_level = ThreatLevel.none

        # Length validation
        if len(text) > self.max_length:
            issues.append(f"Input exceeds maximum length of {self.max_length} characters")
            threat_level = ThreatLevel.medium
            text = text[: self.max_length]

        # Check for empty or whitespace-only input
        if not text or text.isspace():
            return ValidationResult(
                is_valid=True, cleaned_text="", threat_level=ThreatLevel.none, issues=[]
            )

        # Pattern-based threat detection
        for category, patterns in self.dangerous_patterns.items():
            for pattern, level, description in patterns:
                if pattern.search(text):
                    issues.append(f"{category}: {description}")
                    threat_level = max(threat_level, level, key=lambda x: x.value)

        # Windows reserved filename check
        # Check both the full text and any potential filename components
        potential_filenames = re.findall(r"[A-Za-z0-9_\-\.]+", text)
        for filename in potential_filenames:
            base_name = filename.upper().split(".")[0]
            if base_name in self.windows_reserved:
                issues.append(f"Windows reserved filename detected: {filename}")
                threat_level = max(threat_level, ThreatLevel.medium, key=lambda x: x.value)

        # Unicode normalization check
        normalized = unicodedata.normalize("NFKC", text)
        if normalized != text:
            issues.append("Unicode normalization changed input (possible obfuscation)")
            threat_level = max(threat_level, ThreatLevel.low, key=lambda x: x.value)

        # Clean the text if threats were detected
        cleaned_text = InputValidator._clean_text(text, threat_level) if issues else text

        # Determine validity
        is_valid = threat_level.value <= ThreatLevel.low.value

        return ValidationResult(
            is_valid=is_valid,
            cleaned_text=cleaned_text,
            threat_level=threat_level,
            issues=issues,
        )

    @staticmethod
    def _clean_text(text: str, threat_level: ThreatLevel) -> str:
        """
        Clean dangerous content from text based on threat level.

        Applies different cleaning strategies based on the severity of
        detected threats. High threats result in aggressive cleaning,
        while lower threats receive more targeted cleaning.

        Args:
            text: Text to clean
            threat_level: Detected threat level

        Returns:
            Cleaned text with dangerous content removed or escaped
        """
        if threat_level == ThreatLevel.high:
            # Aggressive cleaning for high threats
            # For path traversal, completely reject the input
            if any(
                pattern in text.lower()
                for pattern in ["..", "etc/passwd", "windows/system", "cmd.exe"]
            ):
                return ""  # Completely reject path traversal attempts
            # Remove special chars except basic punctuation and whitespace
            allowed = string.ascii_letters + string.digits + " .,!?-_\n\r\t"
            allowed_chars = set(allowed)
            cleaned = "".join(c for c in text if c in allowed_chars)
        elif threat_level == ThreatLevel.medium:
            # Moderate cleaning
            # Remove dangerous characters but preserve more formatting
            dangerous_chars = {"&", "|", ";", "`", "$", "<", ">", "\\", "\x00"}
            cleaned = "".join(c for c in text if c not in dangerous_chars)
            # Remove path traversal sequences
            cleaned = re.sub(r"\.\.[\\/]?", "", cleaned)
            cleaned = re.sub(r"%2[Ee]%2[Ee]", "", cleaned)
            cleaned = re.sub(r"%5[Cc]", "", cleaned)
        else:
            # Light cleaning for low threats
            # Just remove null bytes and normalize whitespace
            cleaned = text.replace("\x00", "").replace("%00", "")
            # Normalize multiple spaces
            cleaned = re.sub(r"\s+", " ", cleaned)

        # Final safety: ensure no control characters remain
        cleaned = "".join(c for c in cleaned if c in {"\n", "\r", "\t"} or ord(c) >= 32)

        return cleaned.strip()

    @staticmethod
    def is_safe_path(base_dir: str, user_path: str) -> bool:
        """
        Check if a user-provided path is safe within a base directory.

        Uses path canonicalization to prevent directory traversal attacks.
        This method follows security best practices by resolving both paths
        to absolute form and checking containment.

        Args:
            base_dir: Base directory that should contain the path
            user_path: User-provided path to validate

        Returns:
            True if path is safe, False otherwise
        """
        try:
            base = Path(base_dir).resolve()
            candidate = (base / user_path).resolve()
            # This will raise ValueError if candidate is not relative to base
            candidate.relative_to(base)
            return True
        except (ValueError, OSError):
            return False
