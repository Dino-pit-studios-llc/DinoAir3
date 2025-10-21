#!/usr/bin/env python3
"""
Direct test of encryption security improvements

This test file directly imports only the encryption module to avoid
dependency issues with other modules.
"""

import base64
import json
import secrets
import sys
from pathlib import Path
from typing import Any

# Direct imports to avoid utils.__init__ dependency issues
sys.path.insert(0, str(Path(__file__).parent.parent))

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC


# Import the actual module code directly
exec(open("utils/artifact_encryption.py").read())


def test_decryption_error_wrapper():
    """Test that DecryptionError properly wraps exceptions"""
    print("Testing DecryptionError wrapper...")
    
    encryptor = ArtifactEncryption("correct_password")
    encrypted = encryptor.encrypt_data("sensitive_data")
    
    wrong_encryptor = ArtifactEncryption("wrong_password")
    try:
        wrong_encryptor.decrypt_data(encrypted)
        print("  ❌ FAIL: Should have raised DecryptionError")
        return False
    except DecryptionError as e:
        error_msg = str(e)
        if error_msg != "Decryption failed":
            print(f"  ❌ FAIL: Expected generic error, got: {error_msg}")
            return False
        if any(word in error_msg.lower() for word in ["padding", "authentication", "mac", "tag"]):
            print(f"  ❌ FAIL: Error exposes implementation details: {error_msg}")
            return False
        print("  ✅ PASS: Generic DecryptionError raised correctly")
        return True
    except Exception as e:
        print(f"  ❌ FAIL: Wrong exception type: {type(e).__name__}")
        return False


def test_corrupted_data_generic_error():
    """Test that corrupted data raises generic error"""
    print("Testing corrupted data handling...")
    
    encryptor = ArtifactEncryption("password123")
    encrypted = encryptor.encrypt_data("data")
    
    # Corrupt the ciphertext
    encrypted["data"] = encrypted["data"][:-10] + "CORRUPTED="
    
    try:
        encryptor.decrypt_data(encrypted)
        print("  ❌ FAIL: Should have raised DecryptionError")
        return False
    except DecryptionError as e:
        if str(e) == "Decryption failed":
            print("  ✅ PASS: Generic error for corrupted data")
            return True
        print(f"  ❌ FAIL: Non-generic error: {str(e)}")
        return False
    except Exception as e:
        print(f"  ❌ FAIL: Wrong exception type: {type(e).__name__}")
        return False


def test_iv_nonce_fix():
    """Test that encrypt_fields uses 'nonce' not 'iv'"""
    print("Testing iv/nonce field fix...")
    
    encryptor = ArtifactEncryption("password")
    data = {"field1": "value1"}
    encrypted = encryptor.encrypt_fields(data, ["field1"])
    
    # Check that nonce is used, not iv
    encryption_info = encrypted.get("_encryption_info", {})
    field_info = encryption_info.get("field1", {})
    
    if "nonce" not in field_info:
        print(f"  ❌ FAIL: Missing 'nonce' in encryption info: {field_info}")
        return False
    
    if "iv" in field_info:
        print(f"  ❌ FAIL: Still using 'iv' instead of 'nonce': {field_info}")
        return False
    
    print("  ✅ PASS: encrypt_fields correctly uses 'nonce'")
    return True


def test_backward_compatibility():
    """Test that both nonce and iv formats can be decrypted"""
    print("Testing backward compatibility...")
    
    encryptor = ArtifactEncryption("password")
    
    # Test GCM format (nonce) - will fail due to fake data but should reach decrypt
    gcm_data = {
        "field1": "fake_encrypted",
        "_encryption_info": {
            "field1": {
                "salt": base64.b64encode(b"fake_salt").decode(),
                "nonce": base64.b64encode(b"fake_nonce12").decode(),
            }
        }
    }
    
    try:
        encryptor.decrypt_fields(gcm_data, ["field1"])
    except DecryptionError:
        pass  # Expected - fake data
    except KeyError as e:
        print(f"  ❌ FAIL: GCM format not supported: {e}")
        return False
    
    # Test CBC format (iv)
    cbc_data = {
        "field1": "fake_encrypted",
        "_encryption_info": {
            "field1": {
                "salt": base64.b64encode(b"fake_salt").decode(),
                "iv": base64.b64encode(b"fake_iv_16bytes!").decode(),
            }
        }
    }
    
    try:
        encryptor.decrypt_fields(cbc_data, ["field1"])
    except DecryptionError:
        pass  # Expected - fake data
    except KeyError as e:
        print(f"  ❌ FAIL: CBC format not supported: {e}")
        return False
    
    print("  ✅ PASS: Both nonce and iv formats supported")
    return True


def test_encryption_format_detection():
    """Test format detection utility"""
    print("Testing encryption format detection...")
    
    encryptor = ArtifactEncryption("password")
    data = {"field1": "value1"}
    encrypted = encryptor.encrypt_fields(data, ["field1"])
    
    format_type = check_encryption_format(encrypted)
    if format_type != "gcm":
        print(f"  ❌ FAIL: Expected 'gcm', got '{format_type}'")
        return False
    
    # Test legacy format detection
    legacy_data = {
        "_encryption_info": {
            "field1": {
                "salt": "salt",
                "iv": "iv_value",
            }
        }
    }
    
    format_type = check_encryption_format(legacy_data)
    if format_type != "cbc":
        print(f"  ❌ FAIL: Expected 'cbc', got '{format_type}'")
        return False
    
    print("  ✅ PASS: Format detection working correctly")
    return True


def test_key_derivation_strength():
    """Test that strong key derivation is enforced"""
    print("Testing key derivation strength...")
    
    encryptor = ArtifactEncryption("password")
    
    if encryptor.iterations < 100000:
        print(f"  ❌ FAIL: PBKDF2 iterations too low: {encryptor.iterations}")
        return False
    
    if encryptor.salt_length < 32:
        print(f"  ❌ FAIL: Salt length too short: {encryptor.salt_length}")
        return False
    
    if encryptor.key_length != 32:
        print(f"  ❌ FAIL: Key length should be 32 bytes: {encryptor.key_length}")
        return False
    
    print(f"  ✅ PASS: Strong key derivation enforced (PBKDF2 {encryptor.iterations} iterations, 256-bit salt/key)")
    return True


def test_full_encryption_decryption_cycle():
    """Test complete encryption/decryption cycle"""
    print("Testing full encryption/decryption cycle...")
    
    encryptor = ArtifactEncryption("my_secure_password")
    
    original_data = {
        "public_field": "visible",
        "sensitive_field": "secret_data",
        "another_secret": {"nested": "data"}
    }
    
    # Encrypt specific fields
    encrypted = encryptor.encrypt_fields(original_data, ["sensitive_field", "another_secret"])
    
    # Verify public field is not encrypted
    if encrypted["public_field"] != "visible":
        print("  ❌ FAIL: Public field was encrypted")
        return False
    
    # Verify sensitive fields are encrypted
    if encrypted["sensitive_field"] == "secret_data":
        print("  ❌ FAIL: Sensitive field was not encrypted")
        return False
    
    # Decrypt
    decrypted = encryptor.decrypt_fields(encrypted, ["sensitive_field", "another_secret"])
    
    # Verify decryption
    if decrypted["sensitive_field"] != "secret_data":
        print(f"  ❌ FAIL: Decryption failed: {decrypted['sensitive_field']}")
        return False
    
    if decrypted["another_secret"] != {"nested": "data"}:
        print(f"  ❌ FAIL: Decryption failed for nested data: {decrypted['another_secret']}")
        return False
    
    print("  ✅ PASS: Full encryption/decryption cycle successful")
    return True


def main():
    """Run all tests"""
    print("\n" + "="*70)
    print("ENCRYPTION SECURITY IMPROVEMENTS TEST SUITE")
    print("="*70 + "\n")
    
    tests = [
        test_decryption_error_wrapper,
        test_corrupted_data_generic_error,
        test_iv_nonce_fix,
        test_backward_compatibility,
        test_encryption_format_detection,
        test_key_derivation_strength,
        test_full_encryption_decryption_cycle,
    ]
    
    results = []
    for test in tests:
        try:
            result = test()
            results.append(result)
        except Exception as e:
            print(f"  ❌ EXCEPTION: {type(e).__name__}: {e}")
            results.append(False)
        print()
    
    print("="*70)
    passed = sum(results)
    total = len(results)
    print(f"RESULTS: {passed}/{total} tests passed")
    
    if passed == total:
        print("✅ ALL TESTS PASSED")
        print("="*70)
        return 0
    else:
        print(f"❌ {total - passed} TESTS FAILED")
        print("="*70)
        return 1


if __name__ == "__main__":
    sys.exit(main())
