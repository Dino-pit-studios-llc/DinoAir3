#!/usr/bin/env python3
"""
Test script to verify CodeQL security fixes work correctly.
Tests path sanitization and validates no sensitive paths are logged.
"""

import sys
import io
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from scripts.fix_naming_conventions import NamingFixer


def test_path_sanitization():
    """Test that paths are sanitized in logs."""
    print("Testing path sanitization...")
    
    # Create a fixer instance
    fixer = NamingFixer(dry_run=True)
    
    # Test the sanitization method
    test_path = Path("C:/Users/kevin/sensitive/directory/script.py")
    sanitized = fixer._sanitize_path_for_logging(test_path)
    
    # Verify only filename is returned
    assert sanitized == "script.py", f"Expected 'script.py', got '{sanitized}'"
    print(f"✓ Path sanitization works correctly: {test_path} -> {sanitized}")
    
    # Test with None
    sanitized_none = fixer._sanitize_path_for_logging(None)
    assert sanitized_none == "unknown", f"Expected 'unknown', got '{sanitized_none}'"
    print(f"✓ None handling works correctly: None -> {sanitized_none}")
    
    # Test that error messages don't contain full paths
    test_file = Path(__file__).parent.parent / "tests" / "test_data" / "sample.py"
    
    # Capture stdout
    old_stdout = sys.stdout
    sys.stdout = captured_output = io.StringIO()
    
    # This should log only the filename
    fixer.stats["errors"].append((fixer._sanitize_path_for_logging(test_file), "Test error"))
    fixer.print_summary()
    
    # Restore stdout
    sys.stdout = old_stdout
    output = captured_output.getvalue()
    
    # Verify no full paths in output
    if "kevin" in output.lower() or "users" in output.lower():
        print(f"✗ FAILED: Full path found in output:")
        print(output)
        return False
    
    if "sample.py" in output:
        print(f"✓ Only filename appears in output (no full path)")
    
    print("\n✓ All path sanitization tests passed!")
    return True


def test_path_validation():
    """Test that path validation still works."""
    print("\nTesting path validation...")
    
    fixer = NamingFixer(dry_run=True)
    
    # Test with this script file (should be valid Python)
    test_file = Path(__file__)
    is_valid, error = fixer.validate_python_syntax(test_file)
    
    if is_valid:
        print(f"✓ Valid Python file correctly validated")
    else:
        print(f"✗ FAILED: Valid file rejected: {error}")
        return False
    
    print("✓ Path validation tests passed!")
    return True


def main():
    """Run all tests."""
    print("=" * 70)
    print("CodeQL Security Fixes - Verification Tests")
    print("=" * 70)
    print()
    
    try:
        test1 = test_path_sanitization()
        test2 = test_path_validation()
        
        print("\n" + "=" * 70)
        if test1 and test2:
            print("✓ ALL TESTS PASSED - Security fixes verified!")
            return 0
        else:
            print("✗ SOME TESTS FAILED - Review output above")
            return 1
    except Exception as e:
        print(f"\n✗ TEST ERROR: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
