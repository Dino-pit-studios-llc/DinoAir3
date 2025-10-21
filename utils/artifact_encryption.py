#!/usr/bin/env python3
"""
Artifact Encryption Utilities

Provides field-level encryption/decryption for sensitive artifact data using
AES-256-GCM authenticated encryption with PBKDF2 key derivation.

Security Features:
- AES-256-GCM for authenticated encryption (prevents tampering)
- PBKDF2 with SHA-256 for secure key derivation
- Cryptographically secure random nonces and salts
- Generic error handling to prevent oracle attacks

Migration Plan:
- All new data uses AES-GCM exclusively
- Legacy CBC support maintained for backward compatibility only
- TODO: Migrate all legacy ciphertexts to AES-GCM and remove CBC support
"""

import base64
import json
import secrets
from typing import Any

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC


class DecryptionError(Exception):
    """
    Generic decryption error to prevent oracle attacks.

    This single error type is raised for all decryption failures,
    preventing attackers from distinguishing between padding errors,
    authentication failures, or other decryption issues.
    """

    pass


class ArtifactEncryption:
    """
    Handles field-level encryption for artifacts using AES-256-GCM

    Uses authenticated encryption (GCM mode) for security and data integrity.

    Security Considerations:
    ========================
    1. All new encryptions use AES-GCM (authenticated encryption)
    2. Legacy CBC support maintained only for backward compatibility
    3. DecryptionError provides generic error to prevent oracle attacks
    4. Callers MUST NOT expose detailed error information from decryption failures
    5. Strong key derivation enforced: PBKDF2-HMAC-SHA256 with 100,000 iterations

    Migration Plan:
    ===============
    - All NEW data is encrypted with AES-GCM (nonce-based)
    - Legacy CBC data (iv-based) can still be decrypted
    - TODO: Implement batch migration utility to re-encrypt all CBC data to GCM
    - TODO: After migration complete, remove _decrypt_legacy_cbc() method
    - TODO: Add monitoring/alerting for remaining CBC decryptions

    Error Handling Best Practices:
    ===============================
    - NEVER log or expose DecryptionError details to users
    - NEVER distinguish between "wrong password" vs "corrupted data" errors
    - Use generic "Decryption failed" message for ALL failures
    - Log failures to secure audit logs only (not user-facing logs)

    Example Usage:
    ==============
    ```python
    encryptor = ArtifactEncryption(password="secure_password")

    # Encrypt fields
    encrypted = encryptor.encrypt_fields(data, ["sensitive_field"])

    # Decrypt fields
    try:
        decrypted = encryptor.decrypt_fields(encrypted, ["sensitive_field"])
    except DecryptionError:
        # Generic error - do NOT expose details to user
        log_to_audit("Decryption failed for user_id=...")
        return {"error": "Unable to decrypt data"}
    ```
    """

    # Encryption parameters
    key_length = 32  # 256 bits for AES-256
    salt_length = 32  # 256 bits for salt
    iterations = 100000  # PBKDF2 iterations (strong key derivation)

    def __init__(self, password: str | None = None):
        """
        Initialize encryption handler

        Args:
            password: User password for key derivation (optional)
        """
        self.password = password

    def derive_key(self, password: str, salt: bytes) -> bytes:
        """
        Derive encryption key from password using PBKDF2

        Args:
            password: User password
            salt: Random salt for key derivation

        Returns:
            Derived encryption key
        """
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=self.key_length,
            salt=salt,
            iterations=self.iterations,
        )
        return kdf.derive(password.encode())

    def generate_salt(self) -> bytes:
        """Generate a random salt"""
        return secrets.token_bytes(self.salt_length)

    @staticmethod
    def generate_nonce() -> bytes:
        """Generate a random 12-byte nonce for AES-GCM"""
        # GCM mode uses 12-byte nonces for optimal security
        return secrets.token_bytes(12)

    def encrypt_data(self, data: str | bytes, key: bytes | None = None) -> dict[str, str]:
        """
        Encrypt data using AES-256-GCM (authenticated encryption)

        Args:
            data: Data to encrypt (string or bytes)
            key: Optional encryption key (will derive from password if not
                provided)

        Returns:
            Dictionary containing encrypted data, salt, nonce, and auth tag (all base64
            encoded)
        """
        # Ensure input is bytes; avoid implicit bytes() on arbitrary objects
        if isinstance(data, str):
            data_bytes = data.encode("utf-8")
        elif isinstance(data, bytes):
            data_bytes = data
        else:
            raise TypeError("data must be of type str or bytes")

        # Generate salt and derive key if not provided
        salt = self.generate_salt()
        if key is None:
            if not self.password:
                raise ValueError("No password provided for key derivation")
            key = self.derive_key(self.password, salt)

        # Generate nonce and encrypt using AES-GCM
        nonce = self.generate_nonce()
        aesgcm = AESGCM(key)

        # GCM mode provides authentication and encryption in one step
        encrypted = aesgcm.encrypt(nonce, data_bytes, None)

        # Return base64 encoded values
        return {
            "data": base64.b64encode(encrypted).decode("utf-8"),
            "salt": base64.b64encode(salt).decode("utf-8"),
            "nonce": base64.b64encode(nonce).decode("utf-8"),
        }

    def decrypt_data(self, encrypted_data: dict[str, str], key: bytes | None = None) -> bytes:
        """
        Decrypt data encrypted with encrypt_data

        Args:
            encrypted_data: Dictionary with encrypted data, salt, and nonce/iv
            key: Optional encryption key (will derive from password if not
                provided)

        Returns:
            Decrypted data as bytes

        Raises:
            DecryptionError: Generic error for all decryption failures to prevent oracle attacks
        """
        # Check for password/key before any processing
        if key is None and not self.password:
            raise ValueError("No password provided for key derivation")

        try:
            # Support both old (iv) and new (nonce) formats for backward compatibility
            if "nonce" in encrypted_data:
                # New GCM format (preferred)
                encrypted = base64.b64decode(encrypted_data["data"])
                salt = base64.b64decode(encrypted_data["salt"])
                nonce = base64.b64decode(encrypted_data["nonce"])

                # Derive key if not provided
                if key is None:
                    key = self.derive_key(self.password, salt)

                # Decrypt using AES-GCM (authenticated encryption)
                aesgcm = AESGCM(key)
                return aesgcm.decrypt(nonce, encrypted, None)

            # Legacy CBC format - maintain backward compatibility
            # Wrap ALL exceptions from CBC path to prevent oracle leaks
            return self._decrypt_legacy_cbc(encrypted_data, key)

        except DecryptionError:
            # Re-raise our generic error as-is
            raise
        except Exception as e:
            # Convert any other exception to generic DecryptionError
            # This prevents oracle attacks by hiding implementation details
            raise DecryptionError("Decryption failed") from e

    def _decrypt_legacy_cbc(self, encrypted_data: dict[str, str], key: bytes | None) -> bytes:
        """
        Decrypt legacy CBC-encrypted data

        WARNING: This is for backward compatibility only. All new encryptions use GCM.
        TODO: Migrate all legacy ciphertexts to AES-GCM and remove this method.

        Args:
            encrypted_data: Dictionary with encrypted data, salt, and iv
            key: Optional encryption key

        Returns:
            Decrypted data as bytes

        Raises:
            DecryptionError: Generic error for all CBC decryption failures
        """
        try:
            from cryptography.hazmat.backends import default_backend
            from cryptography.hazmat.primitives import padding
            from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

            encrypted = base64.b64decode(encrypted_data["data"])
            salt = base64.b64decode(encrypted_data["salt"])
            iv = base64.b64decode(encrypted_data["iv"])

            # Derive key if not provided
            if key is None:
                key = self.derive_key(self.password, salt)

            # Create cipher and decrypt (legacy CBC mode for backward compatibility)
            # Using CBC with PKCS7 padding is acceptable for legacy compatibility
            # nosec: B305,B413 - CBC mode with PKCS7 padding is used for legacy compatibility
            cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())  # noqa: S5542
            decryptor = cipher.decryptor()
            decrypted_padded = decryptor.update(encrypted) + decryptor.finalize()

            # Remove PKCS7 padding using cryptography unpadder
            unpadder = padding.PKCS7(128).unpadder()
            return unpadder.update(decrypted_padded) + unpadder.finalize()

        except Exception as e:
            # CRITICAL: Convert ALL CBC exceptions to generic DecryptionError
            # This prevents padding oracle attacks and other side-channel leaks
            # Do NOT expose padding errors, MAC failures, or any implementation details
            raise DecryptionError("Decryption failed") from e

    def encrypt_fields(self, data: dict[str, Any], fields: list[str]) -> dict[str, Any]:
        """
        Encrypt specific fields in a dictionary using AES-GCM

        Args:
            data: Dictionary containing data
            fields: List of field names to encrypt

        Returns:
            Dictionary with specified fields encrypted

        Note:
            All new encryptions use AES-GCM format with 'nonce' field.
            Legacy 'iv' field support maintained only for decryption.
        """
        encrypted_data = data.copy()
        encrypted_fields_info = {}

        for field in fields:
            if field in data and data[field] is not None:
                # Convert value to string for encryption
                value = (
                    # sourcery skip: swap-if-expression
                    json.dumps(data[field])
                    if not isinstance(data[field], str)
                    # sourcery skip: swap-if-expression
                    else data[field]
                )

                # Encrypt the field using AES-GCM
                encrypted_info = self.encrypt_data(value)

                # Store encrypted value
                encrypted_data[field] = encrypted_info["data"]

                # Store encryption info (salt and nonce) - CORRECTED from 'iv'
                encrypted_fields_info[field] = {
                    "salt": encrypted_info["salt"],
                    "nonce": encrypted_info["nonce"],  # Fixed: was incorrectly using 'iv'
                }

        # Add encryption metadata
        if encrypted_fields_info:
            encrypted_data["_encryption_info"] = encrypted_fields_info

        return encrypted_data

    def decrypt_fields(self, data: dict[str, Any], fields: list[str]) -> dict[str, Any]:
        """
        Decrypt specific fields in a dictionary

        Args:
            data: Dictionary containing encrypted data
            fields: List of field names to decrypt

        Returns:
            Dictionary with specified fields decrypted

        Raises:
            DecryptionError: Generic error for decryption failures
        """
        decrypted_data = data.copy()
        encryption_info = data.get("_encryption_info", {})

        for field in fields:
            if field in data and field in encryption_info:
                # Reconstruct encrypted data dictionary
                # Support both new 'nonce' and legacy 'iv' formats
                field_info = encryption_info[field]
                encrypted_dict = {
                    "data": data[field],
                    "salt": field_info["salt"],
                }

                # Add nonce or iv field (backward compatibility)
                if "nonce" in field_info:
                    encrypted_dict["nonce"] = field_info["nonce"]
                elif "iv" in field_info:
                    encrypted_dict["iv"] = field_info["iv"]
                else:
                    raise DecryptionError("Missing nonce/iv in encryption metadata")

                # Decrypt (may raise DecryptionError)
                decrypted_bytes = self.decrypt_data(encrypted_dict)
                decrypted_str = decrypted_bytes.decode("utf-8")

                # Try to parse as JSON (for complex types)
                try:
                    decrypted_value = json.loads(decrypted_str)
                except json.JSONDecodeError:
                    decrypted_value = decrypted_str
                decrypted_data[field] = decrypted_value

        # Remove encryption metadata
        if "_encryption_info" in decrypted_data:
            del decrypted_data["_encryption_info"]

        return decrypted_data


def encrypt_artifact_fields(self, artifact_dict: dict[str, Any], fields: list[str]) -> dict[str, Any]:
    """
    Encrypt specific fields in an artifact dictionary

    Args:
        artifact_dict: Artifact data as dictionary
        fields: List of field names to encrypt

    Returns:
        Artifact dictionary with specified fields encrypted
    """
    # Encrypt the specified fields
    encrypted_dict = self.encrypt_fields(artifact_dict, fields)

    # Update encrypted_fields list
    encrypted_dict["encrypted_fields"] = ",".join(fields)

    return encrypted_dict


def decrypt_artifact_fields(self, artifact_dict: dict[str, Any]) -> dict[str, Any]:
    """
    Decrypt encrypted fields in an artifact dictionary

    Args:
        artifact_dict: Artifact data with encrypted fields

    Returns:
        Artifact dictionary with fields decrypted
    """
    # Get list of encrypted fields
    encrypted_fields_str = artifact_dict.get("encrypted_fields", "")
    if not encrypted_fields_str:
        return artifact_dict

    encrypted_fields = [f.strip() for f in encrypted_fields_str.split(",")]

    # Decrypt fields
    decrypted_data = self.decrypt_fields(artifact_dict, encrypted_fields)

    # Remove the encrypted_fields metadata since decryption is complete
    if "encrypted_fields" in decrypted_data:
        del decrypted_data["encrypted_fields"]

    return decrypted_data


@staticmethod
def generate_encryption_key_id() -> str:
    """Generate a unique encryption key ID"""
    return base64.urlsafe_b64encode(secrets.token_bytes(16)).decode("utf-8").rstrip("=")


@staticmethod
def rotate_encryption(
    data: dict[str, Any],
    old_password: str,
    new_password: str,
    fields: list[str],
) -> dict[str, Any]:
    """
    Re-encrypt data with a new password

    Args:
        data: Dictionary containing encrypted data
        old_password: Current password
        new_password: New password
        fields: List of encrypted field names

    Returns:
        Dictionary with fields re-encrypted using new password

    Raises:
        DecryptionError: If decryption with old password fails
    """
    # Create temporary decryption instance with old password
    old_encryptor = ArtifactEncryption(old_password)

    # Decrypt with old password (may raise DecryptionError)
    decrypted_data = old_encryptor.decrypt_fields(data, fields)

    # Create new encryption instance with new password
    new_encryptor = ArtifactEncryption(new_password)

    # Re-encrypt with new password (always uses GCM)
    return new_encryptor.encrypt_fields(decrypted_data, fields)


@staticmethod
def migrate_cbc_to_gcm(
    data: dict[str, Any],
    password: str,
    fields: list[str],
) -> dict[str, Any]:
    """
    Migrate legacy CBC-encrypted data to AES-GCM format

    This utility should be used to migrate all legacy CBC ciphertexts to the
    secure AES-GCM format. After all data is migrated, CBC support can be removed.

    Args:
        data: Dictionary containing CBC-encrypted data (with 'iv' fields)
        password: Password for decryption/re-encryption
        fields: List of encrypted field names

    Returns:
        Dictionary with fields re-encrypted using AES-GCM (with 'nonce' fields)

    Raises:
        DecryptionError: If decryption fails

    Example:
        ```python
        # Migrate a single record
        migrated = ArtifactEncryption.migrate_cbc_to_gcm(
            old_record, password, ["sensitive_field"]
        )

        # Batch migration (pseudo-code)
        for record in database.get_encrypted_records():
            try:
                migrated = ArtifactEncryption.migrate_cbc_to_gcm(
                    record, password, record["encrypted_fields"].split(",")
                )
                database.update(record_id, migrated)
                log_to_audit(f"Migrated record {record_id} from CBC to GCM")
            except DecryptionError:
                log_to_audit(f"Migration failed for record {record_id}")
        ```
    """
    # Check if data is already GCM format
    encryption_info = data.get("_encryption_info", {})
    if encryption_info and all("nonce" in info for info in encryption_info.values()):
        # Already migrated to GCM
        return data

    # Decrypt with CBC support
    encryptor = ArtifactEncryption(password)
    decrypted_data = encryptor.decrypt_fields(data, fields)

    # Re-encrypt with GCM (encrypt_fields always uses GCM now)
    return encryptor.encrypt_fields(decrypted_data, fields)


def check_encryption_format(data: dict[str, Any]) -> str:
    """
    Check which encryption format is used in the data

    Args:
        data: Dictionary potentially containing encrypted data

    Returns:
        "gcm" if using AES-GCM (nonce-based)
        "cbc" if using legacy CBC (iv-based)
        "none" if no encryption metadata found
        "mixed" if different fields use different formats (should not happen)

    Example:
        ```python
        format_type = check_encryption_format(artifact_data)
        if format_type == "cbc":
            # Schedule for migration
            add_to_migration_queue(artifact_id)
        ```
    """
    encryption_info = data.get("_encryption_info", {})
    if not encryption_info:
        return "none"

    has_nonce = any("nonce" in info for info in encryption_info.values())
    has_iv = any("iv" in info for info in encryption_info.values())

    if has_nonce and not has_iv:
        return "gcm"
    if has_iv and not has_nonce:
        return "cbc"
    if has_nonce and has_iv:
        return "mixed"  # Should not happen - indicates data corruption

    return "none"
