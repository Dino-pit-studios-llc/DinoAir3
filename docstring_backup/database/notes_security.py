"""
NotesSecurity - Security validation for notes operations.
Handles input validation, sanitization, and security checks.

Custom security policies can be provided either by calling
``register_security_policy`` at runtime or by setting the
``NOTES_SECURITY_POLICY_PATH`` environment variable to a module path.
"""

from __future__ import annotations

import os
from abc import ABC, abstractmethod
from collections.abc import Callable
from typing import Any

from utils.logger import Logger
from utils.safe_imports import safe_import, safe_load_attr

# Allowlisted security policy providers:
# Maps a logical key to (module_path, {allowed_attributes})
# Default allows only this module's get_notes_security factory.
DEFAULT_POLICY_KEY = "default"
DEFAULT_POLICY_ATTRIBUTE = "get_notes_security"
ALLOWED_SECURITY_POLICIES: dict[str, tuple[str, set[str]]] = {
    DEFAULT_POLICY_KEY: ("database.notes_security", {DEFAULT_POLICY_ATTRIBUTE}),
}

SecurityPolicyFactory = Callable[[], "SecurityPolicy"]
_SECURITY_POLICY_FACTORY: SecurityPolicyFactory | None = None


class SecurityPolicy(ABC):
    """Abstract base class for security policies"""

    @abstractmethod
    def validate_note_data(self, title: str, content: str, tags: list[str]) -> dict[str, Any]:
        """Validate note data and return validation result"""

    @abstractmethod
    def escape_sql_wildcards(self, text: str) -> str:
        """Escape SQL wildcard characters for safe queries"""


def register_security_policy(factory: SecurityPolicyFactory) -> None:
    """Register a custom factory that provides a notes SecurityPolicy."""

    global _SECURITY_POLICY_FACTORY
    _SECURITY_POLICY_FACTORY = factory


def _load_policy_from_registry() -> SecurityPolicy | None:
    """Return a registered security policy instance if available."""

    if _SECURITY_POLICY_FACTORY is None:
        return None

    policy = _SECURITY_POLICY_FACTORY()
    if not isinstance(policy, SecurityPolicy):
        raise TypeError("Registered security policy must return a SecurityPolicy instance")
    return policy


def _instantiate_policy_candidate(candidate: Any) -> Any:
    """Instantiate a policy candidate by calling it if it's a callable (up to 2 levels)."""
    if callable(candidate):
        candidate = candidate()
        if callable(candidate):
            candidate = candidate()
    return candidate


def _validate_policy_instance(candidate: Any) -> SecurityPolicy:
    """Validate that a candidate is a SecurityPolicy instance."""
    if not isinstance(candidate, SecurityPolicy):
        raise TypeError("Custom notes security provider must produce a SecurityPolicy instance")
    return candidate


def _load_policy_by_logical_key(key: str, allowed_map: dict[str, str]) -> SecurityPolicy:
    """Load a security policy using a logical key from ALLOWED_SECURITY_POLICIES."""
    module = safe_import(key, allowed_map)
    _mod_path, allowed_attrs = ALLOWED_SECURITY_POLICIES[key]
    attr_name = DEFAULT_POLICY_ATTRIBUTE
    attr = safe_load_attr(module, attr_name, allowed_attrs)
    candidate = _instantiate_policy_candidate(attr)
    return _validate_policy_instance(candidate)


def _find_allowed_module_key(
    module_name: str,
) -> tuple[str | None, set[str] | None]:
    """Find the key and allowed attributes for a module in ALLOWED_SECURITY_POLICIES."""
    for k, (mod, attrs) in ALLOWED_SECURITY_POLICIES.items():
        if mod == module_name:
            return k, attrs
    return None, None


def _load_policy_by_module_spec(
    module_name: str,
    attribute: str,
    allowed_map: dict[str, str],
    logger: Logger,
) -> SecurityPolicy | None:
    """Load a security policy using module[:attribute] specification."""
    key_for_module, allowed_attrs = _find_allowed_module_key(module_name)

    if key_for_module is None:
        logger.warning(
            "NOTES_SECURITY_POLICY_PATH module not allowlisted; falling back to default.",
        )
        return None

    module = safe_import(key_for_module, allowed_map)
    attr_name = (attribute or DEFAULT_POLICY_ATTRIBUTE).strip()
    attr = safe_load_attr(module, attr_name, allowed_attrs or set())
    candidate = _instantiate_policy_candidate(attr)
    return _validate_policy_instance(candidate)


def _load_policy_from_env() -> SecurityPolicy | None:
    """Load a security policy using NOTES_SECURITY_POLICY_PATH environment variable."""
    module_spec = os.environ.get("NOTES_SECURITY_POLICY_PATH", "").strip()
    if not module_spec:
        return None

    allowed_map = {k: mod for k, (mod, _attrs) in ALLOWED_SECURITY_POLICIES.items()}
    logger = Logger()

    # Case 1: policy specified by logical key
    if ":" not in module_spec and module_spec in ALLOWED_SECURITY_POLICIES:
        return _load_policy_by_logical_key(module_spec, allowed_map)

    # Case 2: policy specified as "module[:attribute]"
    module_name, _, attribute = module_spec.partition(":")
    if not module_name:
        raise ImportError("NOTES_SECURITY_POLICY_PATH must be in the format 'module[:attribute]'")

    return _load_policy_by_module_spec(module_name, attribute, allowed_map, logger)


__all__ = [
    "SecurityPolicy",
    "SecurityPolicyFactory",
    "register_security_policy",
    "NotesSecurity",
    "FallbackSecurity",
]


class NotesSecurity:
    """
    Security manager for notes operations.
    Handles validation, sanitization, and security policy enforcement.
    """

    def __init__(self):
        self.logger = Logger()
        self._policy: SecurityPolicy = self._load_security_policy()

    def _load_security_policy(self) -> SecurityPolicy:
        """Load the appropriate security policy"""
        try:
            policy = _load_policy_from_registry()
            if policy:
                self.logger.debug("Loaded notes security policy from registry.")
                return policy
        except Exception as exc:  # pragma: no cover - defensive logging
            self.logger.error("Registered notes security policy failed: %s", exc, exc_info=True)

        try:
            policy = _load_policy_from_env()
            if policy:
                self.logger.debug("Loaded notes security policy from NOTES_SECURITY_POLICY_PATH.")
                return policy
        except Exception as exc:
            self.logger.error(
                "Custom notes security module import failed: %s. "
                "Falling back to built-in safeguards.",
                exc,
            )

        strict = os.environ.get("STRICT_NOTES_SECURITY", "").strip().lower() in (
            "1",
            "true",
            "yes",
        )

        if strict:
            self.logger.critical(
                "STRICT_NOTES_SECURITY enabled but no custom policy available. Aborting."
            )
            raise RuntimeError(
                "Notes security module not available and STRICT_NOTES_SECURITY is enabled."
            )

        # Fallback to conservative security
        self.logger.warning("Using FallbackSecurity for notes validation.")

        return FallbackSecurity()

    def validate_note_data(self, title: str, content: str, tags: list[str]) -> dict[str, Any]:
        """Validate note data using the current security policy"""
        return self._policy.validate_note_data(title, content, tags)

    def escape_sql_wildcards(self, text: str) -> str:
        """Escape SQL wildcards using the current security policy"""
        return self._policy.escape_sql_wildcards(text)

    def can_perform_write_operation(self, operation: str) -> tuple[bool, str | None]:
        """
        Check if write operations are allowed.
        Returns (allowed, error_message)
        """
        # If using fallback security, check environment variable
        if isinstance(self._policy, FallbackSecurity):
            allow = os.environ.get("ALLOW_NOTES_FALLBACK_WRITES", "").strip().lower() in (
                "1",
                "true",
                "yes",
            )

            if not allow:
                error_msg = (
                    f"Write operation '{operation}' blocked: notes_security unavailable. "
                    "Set ALLOW_NOTES_FALLBACK_WRITES=1 to override in non-production."
                )
                self.logger.critical(error_msg)
                return False, "Security module unavailable; write operation blocked"
            self.logger.warning(
                f"Proceeding with '{operation}' under FallbackSecurity. "
                "Not recommended for production."
            )

        return True, None


class FallbackSecurity(SecurityPolicy):
    """
    Conservative fallback security policy.
    Provides basic validation when the main security module is unavailable.
    """

    def validate_note_data(self, title: str, content: str, tags: list[str]) -> dict[str, Any]:
        """Perform basic validation with conservative rules"""
        errors: list[str] = []

        self._validate_title(title, errors)
        self._validate_content(content, errors)
        self._validate_tags(tags, errors)

        return {"valid": len(errors) == 0, "errors": errors}

    @staticmethod
    def _validate_title(title: str, errors: list[str]) -> None:
        """Validate note title.

        Args:
            title: Title string to validate
            errors: List to append error messages to
        """
        if not isinstance(title, str) or not title.strip():
            errors.append("Title is required.")
        elif len(title) > 300:
            errors.append("Title exceeds 300 characters.")

    @staticmethod
    def _validate_content(content: str, errors: list[str]) -> None:
        """Validate note content.

        Args:
            content: Content string to validate
            errors: List to append error messages to
        """
        if content is None:
            content_len = 0
        elif isinstance(content, str):
            content_len = len(content)
        else:
            errors.append("Content must be a string.")
            content_len = 0

        if content_len > 20000:
            errors.append("Content exceeds 20000 characters.")

    @staticmethod
    def _validate_tags(tags: list[str], errors: list[str]) -> None:
        """Validate note tags.

        Args:
            tags: List of tag strings to validate
            errors: List to append error messages to
        """
        if tags is None:
            tags = []
        if not isinstance(tags, list):
            errors.append("Tags must be a list of strings.")
        else:
            if len(tags) > 100:
                errors.append("Too many tags (max 100).")
            for tag in tags:
                if not isinstance(tag, str):
                    errors.append("All tags must be strings.")
                elif len(tag) > 50:
                    errors.append("Tag length exceeds 50 characters.")

    @staticmethod
    def escape_sql_wildcards(text: str) -> str:
        """Escape SQL wildcard characters for LIKE queries"""
        if not text:
            return ""

        # Escape backslashes first, then other wildcards
        return text.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


def get_notes_security() -> SecurityPolicy:
    """Default factory for allowlisted policy resolution."""
    return FallbackSecurity()
