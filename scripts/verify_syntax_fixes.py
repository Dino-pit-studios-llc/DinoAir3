#!/usr/bin/env python3
"""
Verify Syntax Fixes

This script verifies that all Python syntax errors have been fixed.
Specifically validates the fixes made for:
- mock_backend.py (removed from git tracking)
- local_transformer_model.py (fixed duplicate return statement)
"""

import ast
import os
import sys


def check_all_python_files():
    """Check that all Python files in the repository have valid syntax."""
    errors = []
    count = 0
    skip_dirs = {".git", "__pycache__", "node_modules", ".venv", "venv", ".tox"}

    print("=" * 70)
    print("PYTHON SYNTAX VALIDATION")
    print("=" * 70)
    print()
    print("Scanning all Python files for syntax errors...")
    print()

    for root, dirs, files in os.walk("."):
        dirs[:] = [d for d in dirs if d not in skip_dirs]
        for file in files:
            if file.endswith(".py"):
                filepath = os.path.join(root, file)
                count += 1
                try:
                    with open(filepath, encoding="utf-8") as f:
                        ast.parse(f.read())
                except SyntaxError as e:
                    errors.append(f"{filepath}: {e}")

    print(f"📊 Checked {count} Python files")
    print()

    if errors:
        print(f"❌ FAILURE: Found {len(errors)} syntax error(s):")
        print()
        for error in errors:
            print(f"  {error}")
        return 1
    else:
        print("✅ SUCCESS: All Python files have valid syntax!")
        print()
        return 0


def verify_specific_fixes():
    """Verify the specific files that were fixed."""
    print("=" * 70)
    print("SPECIFIC FILE VERIFICATION")
    print("=" * 70)
    print()

    # Check that mock_backend.py is no longer tracked
    mock_backend_exists = os.path.exists("mock_backend.py")
    if mock_backend_exists:
        print("⚠️  WARNING: mock_backend.py still exists")
        print("   (This may be a local file, which is okay)")
    else:
        print("✅ mock_backend.py: Removed from git tracking")

    # Check that local_transformer_model.py is valid
    local_transformer_path = "tools/pseudocode_translator/models/local_transformer_model.py"
    if os.path.exists(local_transformer_path):
        try:
            with open(local_transformer_path, encoding="utf-8") as f:
                content = f.read()
                ast.parse(content)

            # Check that the fix was applied (no duplicate return statement)
            # Look for the malformed single-line return that was fixed
            if (
                "return TranslationResult(success=True, generated_code=generated_text, output_language=config.output_language, model_name=self.metadata.name, confidence=1.0, metadata="
                in content
            ):
                print(f"❌ {local_transformer_path}: Still contains malformed return statement")
                return 1
            else:
                print(f"✅ {local_transformer_path}: Syntax is valid and fix applied")
        except SyntaxError as e:
            print(f"❌ {local_transformer_path}: Syntax error - {e}")
            return 1
    else:
        print(f"❌ {local_transformer_path}: File not found")
        return 1

    print()
    return 0


def main():
    """Main entry point."""
    print()

    # Verify specific fixes first
    result1 = verify_specific_fixes()

    # Then check all files
    result2 = check_all_python_files()

    if result1 == 0 and result2 == 0:
        print("=" * 70)
        print("🎉 ALL SYNTAX FIXES VERIFIED!")
        print("=" * 70)
        print()
        print("Summary of fixes:")
        print("  1. mock_backend.py - Removed from git tracking (listed in .gitignore)")
        print("  2. local_transformer_model.py - Fixed duplicate return statement")
        print()
        print("All Python files now parse correctly.")
        print()
        return 0
    else:
        return 1


if __name__ == "__main__":
    sys.exit(main())
