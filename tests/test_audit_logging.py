"""
Tests for audit logging module, focusing on integrity verification and HMAC signature handling.
"""

# Remove the unused import statement
from dataclasses import asdict

import pytest

from utils.audit_logging import AuditEvent, AuditEventType, AuditLogger, SeverityLevel


class TestAuditLoggingIntegrity:
    """Test audit logging integrity features."""

    @staticmethod
    def test_hmac_signature_with_string_secret():
        """Test HMAC signature creation with string secret_key."""
        # Create logger with string secret_key
        logger = AuditLogger("test", secret_key="test_secret_string")

        # Create an event
        event = AuditEvent(
            event_id="test-id",
            timestamp="2023-01-01T00:00:00",
            event_type=AuditEventType.LOGIN_SUCCESS,
            severity=SeverityLevel.INFO,
            user_id="test_user",
            session_id=None,
            source_ip="127.0.0.1",
            user_agent=None,
        )

        # Add integrity check - should handle string secret properly
        event_with_integrity = logger._add_integrity_check(event)

        assert event_with_integrity.signature is not None
        assert event_with_integrity.checksum is not None

    @staticmethod
    def test_hmac_signature_with_bytes_secret():
        """Test HMAC signature creation with bytes secret_key."""
        # Create logger with bytes secret_key
        logger = AuditLogger("test", secret_key=b"test_secret_bytes")

        # Create an event
        event = AuditEvent(
            event_id="test-id",
            timestamp="2023-01-01T00:00:00",
            event_type=AuditEventType.LOGIN_SUCCESS,
            severity=SeverityLevel.INFO,
            user_id="test_user",
            session_id=None,
            source_ip="127.0.0.1",
            user_agent=None,
        )

        # Add integrity check
        event_with_integrity = logger._add_integrity_check(event)

        assert event_with_integrity.signature is not None
        assert event_with_integrity.checksum is not None

    @staticmethod
    def test_verify_integrity_with_secret():
        """Test integrity verification with secret configured."""
        logger = AuditLogger("test", secret_key="test_secret_key")

        # Create and sign an event
        event = AuditEvent(
            event_id="test-id",
            timestamp="2023-01-01T00:00:00",
            event_type=AuditEventType.LOGIN_SUCCESS,
            severity=SeverityLevel.INFO,
            user_id="test_user",
            session_id=None,
            source_ip="127.0.0.1",
            user_agent=None,
        )

        event_with_integrity = logger._add_integrity_check(event)

        # Convert to dict for verification
        event_dict = asdict(event_with_integrity)
        event_dict["event_type"] = event_with_integrity.event_type.value
        event_dict["severity"] = event_with_integrity.severity.value

        # Verify - should return True
        result = logger.verify_integrity(event_dict.copy())
        assert result is True

    @staticmethod
    def test_verify_integrity_without_secret_unsigned_event():
        """Test integrity verification without secret for unsigned event."""
        logger = AuditLogger("test", secret_key=None)
        logger.secret_key = None

        # Create an unsigned event
        event = AuditEvent(
            event_id="test-id",
            timestamp="2023-01-01T00:00:00",
            event_type=AuditEventType.LOGIN_SUCCESS,
            severity=SeverityLevel.INFO,
            user_id="test_user",
            session_id=None,
            source_ip="127.0.0.1",
            user_agent=None,
        )

        event_with_integrity = logger._add_integrity_check(event)

        # Should have checksum but no signature
        assert event_with_integrity.checksum is not None
        assert event_with_integrity.signature is None

        # Convert to dict for verification
        event_dict = asdict(event_with_integrity)
        event_dict["event_type"] = event_with_integrity.event_type.value
        event_dict["severity"] = event_with_integrity.severity.value

        # Verify - should return True for unsigned event when no secret
        result = logger.verify_integrity(event_dict.copy())
        assert result is True

    @staticmethod
    def test_verify_integrity_without_secret_signed_event():
        """Test integrity verification without secret for signed event (should fail)."""
        # Create logger with secret to sign the event
        logger_with_secret = AuditLogger("test", secret_key="test_secret")

        event = AuditEvent(
            event_id="test-id",
            timestamp="2023-01-01T00:00:00",
            event_type=AuditEventType.LOGIN_SUCCESS,
            severity=SeverityLevel.INFO,
            user_id="test_user",
            session_id=None,
            source_ip="127.0.0.1",
            user_agent=None,
        )

        event_with_integrity = logger_with_secret._add_integrity_check(event)

        # Now try to verify with logger that has no secret
        logger_no_secret = AuditLogger("test2", secret_key=None)
        logger_no_secret.secret_key = None

        event_dict = asdict(event_with_integrity)
        event_dict["event_type"] = event_with_integrity.event_type.value
        event_dict["severity"] = event_with_integrity.severity.value

        # Should fail - signed event but no secret to verify
        result = logger_no_secret.verify_integrity(event_dict.copy())
        assert result is False

    @staticmethod
    def test_verify_integrity_invalid_signature():
        """Test integrity verification with invalid signature."""
        logger = AuditLogger("test", secret_key="test_secret")

        event = AuditEvent(
            event_id="test-id",
            timestamp="2023-01-01T00:00:00",
            event_type=AuditEventType.LOGIN_SUCCESS,
            severity=SeverityLevel.INFO,
            user_id="test_user",
            session_id=None,
            source_ip="127.0.0.1",
            user_agent=None,
        )

        event_with_integrity = logger._add_integrity_check(event)

        event_dict = asdict(event_with_integrity)
        event_dict["event_type"] = event_with_integrity.event_type.value
        event_dict["severity"] = event_with_integrity.severity.value

        # Tamper with signature
        event_dict["signature"] = "invalid_signature"

        # Should fail
        result = logger.verify_integrity(event_dict.copy())
        assert result is False

    @staticmethod
    def test_verify_integrity_missing_checksum():
        """Test integrity verification with missing checksum."""
        logger = AuditLogger("test", secret_key="test_secret")

        event_dict = {
            "event_id": "test-id",
            "timestamp": "2023-01-01T00:00:00",
            "event_type": "auth.login.success",
            "severity": "info",
            "user_id": "test_user",
            "session_id": None,
            "source_ip": "127.0.0.1",
            "user_agent": None,
            "signature": "some_signature",
        }

        # Should fail - no checksum
        result = logger.verify_integrity(event_dict.copy())
        assert result is False

    @staticmethod
    def test_verify_integrity_with_string_secret_key():
        """Test verify_integrity handles string secret_key properly."""
        import os

        # Force secret_key to be a string (simulating edge case)
        logger = AuditLogger("test", secret_key="test_secret")
        logger.secret_key = os.getenv("SECRET_KEY")  # Retrieve secret key from environment variable

        event = AuditEvent(
            event_id="test-id",
            timestamp="2023-01-01T00:00:00",
            event_type=AuditEventType.LOGIN_SUCCESS,
            severity=SeverityLevel.INFO,
            user_id="test_user",
            session_id=None,
            source_ip="127.0.0.1",
            user_agent=None,
        )

        # Create signature with proper encoding
        logger.secret_key = b"test_secret_as_string"  # Properly encode it
        event_with_integrity = logger._add_integrity_check(event)

        # Now test with string key
        logger.secret_key = os.environ.get("SECRET_KEY", "default_secret")

        event_dict = asdict(event_with_integrity)
        event_dict["event_type"] = event_with_integrity.event_type.value
        event_dict["severity"] = event_with_integrity.severity.value

        # Should handle string encoding and verify correctly
        result = logger.verify_integrity(event_dict.copy())
        assert result is True


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
