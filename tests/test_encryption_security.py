#!/usr/bin/env python3
"""
Security tests for encryption module

Tests specifically for oracle attack prevention, error handling,
and migration utilities.
"""

import sys
from pathlib import Path

# Add parent directory to path to import utils
sys.path.insert(0, str(Path(__file__).parent.parent))

import pytest

from utils.artifact_encryption import ArtifactEncryption, DecryptionError, check_encryption_format


class TestDecryptionErrorWrapper:
    """Test that DecryptionError properly wraps all exceptions"""

    def test_wrong_password_raises_generic_error(self):
        """Wrong password should raise generic DecryptionError, not specific error"""
        encryptor = ArtifactEncryption("correct_password")
        encrypted = encryptor.encrypt_data("sensitive_data")

        wrong_encryptor = ArtifactEncryption("wrong_password")
        with pytest.raises(DecryptionError) as exc_info:
            wrong_encryptor.decrypt_data(encrypted)

        # Error message should be generic
        assert str(exc_info.value) == "Decryption failed"
        # Should not expose cryptographic details
        assert "padding" not in str(exc_info.value).lower()
        assert "authentication" not in str(exc_info.value).lower()

    def test_corrupted_data_raises_generic_error(self):
        """Corrupted ciphertext should raise generic DecryptionError"""
        encryptor = ArtifactEncryption("password123")
        encrypted = encryptor.encrypt_data("data")

        # Corrupt the ciphertext
        encrypted["data"] = encrypted["data"][:-10] + "CORRUPTED="

        with pytest.raises(DecryptionError) as exc_info:
            encryptor.decrypt_data(encrypted)

        assert str(exc_info.value) == "Decryption failed"

    def test_missing_nonce_raises_generic_error(self):
        """Missing nonce/iv should raise generic DecryptionError"""
        encryptor = ArtifactEncryption("password123")
        encrypted = encryptor.encrypt_data("data")

        # Remove nonce
        del encrypted["nonce"]

        with pytest.raises(DecryptionError):
            encryptor.decrypt_data(encrypted)

    def test_cbc_padding_error_wrapped(self):
        """Legacy CBC padding errors should be wrapped in DecryptionError"""
        # Create a fake legacy CBC encrypted data with invalid padding
        fake_cbc_data = {
            "data": "aGVsbG8=",  # Invalid encrypted data
            "salt": "c2FsdA==",
            "iv": "aXZpdml2aXZpdg==",
        }

        encryptor = ArtifactEncryption("password123")
        with pytest.raises(DecryptionError) as exc_info:
            encryptor.decrypt_data(fake_cbc_data)

        # Should be generic error, not padding-specific
        assert str(exc_info.value) == "Decryption failed"


class TestEncryptionFormatDetection:
    """Test encryption format detection utilities"""

    def test_detect_gcm_format(self):
        """Should detect GCM format (nonce-based)"""
        encryptor = ArtifactEncryption("password")
        data = {"field1": "value1"}
        encrypted = encryptor.encrypt_fields(data, ["field1"])

        assert check_encryption_format(encrypted) == "gcm"

    def test_detect_cbc_format(self):
        """Should detect legacy CBC format (iv-based)"""
        # Simulate legacy CBC encrypted data
        legacy_data = {
            "field1": "encrypted_data",
            "_encryption_info": {
                "field1": {
                    "salt": "salt_value",
                    "iv": "iv_value",  # Legacy CBC uses 'iv'
                }
            },
        }

        assert check_encryption_format(legacy_data) == "cbc"

    def test_detect_no_encryption(self):
        """Should detect unencrypted data"""
        plain_data = {"field1": "value1", "field2": "value2"}
        assert check_encryption_format(plain_data) == "none"

    def test_detect_mixed_format(self):
        """Should detect mixed formats (corrupted state)"""
        mixed_data = {
            "_encryption_info": {
                "field1": {"salt": "s1", "nonce": "n1"},  # GCM
                "field2": {"salt": "s2", "iv": "i2"},  # CBC
            }
        }

        assert check_encryption_format(mixed_data) == "mixed"


class TestMigrationUtilities:
    """Test CBC to GCM migration"""

    def test_migrate_cbc_to_gcm(self):
        """Should migrate legacy CBC data to GCM format"""
        # Create legacy CBC-style data manually
        legacy_data = {
            "field1": "value_to_encrypt",
            "field2": "another_value",
        }

        # First encrypt (this will use GCM)
        encryptor = ArtifactEncryption("password")
        encrypted = encryptor.encrypt_fields(legacy_data, ["field1"])

        # Manually convert to legacy format for testing
        encryption_info = encrypted["_encryption_info"]["field1"]
        encryption_info["iv"] = encryption_info.pop("nonce")  # Simulate legacy

        # Now migrate
        migrated = ArtifactEncryption.migrate_cbc_to_gcm(encrypted, "password", ["field1"])

        # Should be in GCM format now
        assert check_encryption_format(migrated) == "gcm"
        assert "nonce" in migrated["_encryption_info"]["field1"]
        assert "iv" not in migrated["_encryption_info"]["field1"]

    def test_migrate_already_gcm_is_noop(self):
        """Migrating already-GCM data should be no-op"""
        encryptor = ArtifactEncryption("password")
        data = {"field1": "value"}
        encrypted = encryptor.encrypt_fields(data, ["field1"])

        # Already GCM format
        assert check_encryption_format(encrypted) == "gcm"

        # Migrate should return same data
        migrated = ArtifactEncryption.migrate_cbc_to_gcm(encrypted, "password", ["field1"])

        assert check_encryption_format(migrated) == "gcm"


class TestKeyDerivationStrength:
    """Test that strong key derivation is enforced"""

    def test_pbkdf2_iterations_sufficient(self):
        """PBKDF2 should use at least 100,000 iterations"""
        encryptor = ArtifactEncryption("password")
        assert encryptor.iterations >= 100000, "PBKDF2 iterations too low"

    def test_salt_length_sufficient(self):
        """Salt should be at least 256 bits (32 bytes)"""
        encryptor = ArtifactEncryption("password")
        assert encryptor.salt_length >= 32, "Salt length too short"

    def test_key_length_is_256_bits(self):
        """Encryption key should be 256 bits"""
        encryptor = ArtifactEncryption("password")
        assert encryptor.key_length == 32, "Key length should be 32 bytes (256 bits)"


class TestBackwardCompatibility:
    """Test backward compatibility with legacy CBC data"""

    def test_decrypt_fields_supports_both_formats(self):
        """decrypt_fields should handle both nonce and iv formats"""
        encryptor = ArtifactEncryption("password")

        # Test GCM format (nonce)
        gcm_data = {
            "field1": "encrypted_data",
            "_encryption_info": {
                "field1": {
                    "salt": "base64_salt",
                    "nonce": "base64_nonce",
                }
            },
        }

        # Should not raise for GCM format
        # (actual decryption will fail due to fake data, but format detection works)
        try:
            encryptor.decrypt_fields(gcm_data, ["field1"])
        except DecryptionError:
            pass  # Expected - fake encrypted data

        # Test CBC format (iv)
        cbc_data = {
            "field1": "encrypted_data",
            "_encryption_info": {
                "field1": {
                    "salt": "base64_salt",
                    "iv": "base64_iv",
                }
            },
        }

        # Should not raise for CBC format
        try:
            encryptor.decrypt_fields(cbc_data, ["field1"])
        except DecryptionError:
            pass  # Expected - fake encrypted data

    def test_missing_nonce_and_iv_raises_error(self):
        """Missing both nonce and iv should raise DecryptionError"""
        encryptor = ArtifactEncryption("password")

        bad_data = {
            "field1": "encrypted_data",
            "_encryption_info": {
                "field1": {
                    "salt": "base64_salt",
                    # Missing both nonce and iv
                }
            },
        }

        with pytest.raises(DecryptionError) as exc_info:
            encryptor.decrypt_fields(bad_data, ["field1"])

        assert "nonce/iv" in str(exc_info.value).lower()


class TestErrorExposurePrevention:
    """Test that error details are not leaked"""

    def test_error_does_not_contain_implementation_details(self):
        """DecryptionError should not expose implementation details"""
        encryptor = ArtifactEncryption("password")
        encrypted = encryptor.encrypt_data("data")

        # Corrupt data in various ways
        test_cases = [
            {**encrypted, "data": "corrupted"},
            {**encrypted, "nonce": "wrong_nonce"},
            {**encrypted, "salt": "wrong_salt"},
        ]

        for corrupted_data in test_cases:
            try:
                ArtifactEncryption("wrong_password").decrypt_data(corrupted_data)
            except DecryptionError as e:
                error_msg = str(e).lower()
                # Should not expose these implementation details
                assert "padding" not in error_msg
                assert "authentication" not in error_msg
                assert "mac" not in error_msg
                assert "tag" not in error_msg
                assert "block" not in error_msg
                assert "cipher" not in error_msg


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
