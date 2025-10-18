#!/usr/bin/env python3
"""
Test script for the docstring automation
Tests the add_missing_docstrings.py script on a small test file.
"""

import os
import tempfile
from pathlib import Path

# Create a test Python file with missing docstrings
test_code = """
class TestManager:
    def __init__(self, name):
        self.name = name
    
    def get_status(self):
        return "active"
    
    def process_data(self, data, timeout=30):
        if not data:
            raise ValueError("Data cannot be empty")
        return data.upper()

def create_manager(name):
    return TestManager(name)

def validate_input(value):
    if value is None:
        return False
    return len(str(value)) > 0
"""


def test_docstring_automation():
    """Test the docstring automation script."""
    # Create temporary test file
    with tempfile.NamedTemporaryFile(mode="w", suffix=".py", delete=False) as f:
        f.write(test_code)
        test_file = f.name

    try:
        print(f"Created test file: {test_file}")
        print("Original code:")
        print("-" * 40)
        print(test_code)
        print("-" * 40)

        # Import and run the docstring fixer
        import sys

        sys.path.insert(0, "scripts")

        from add_missing_docstrings import DocstringFixer

        # Run the fixer in dry-run mode first
        print("\nRunning in DRY RUN mode:")
        fixer = DocstringFixer(dry_run=True)
        fixer.fix_file(Path(test_file))

        # Now run it for real
        print("\nRunning with actual changes:")
        fixer = DocstringFixer(dry_run=False)
        fixer.fix_file(Path(test_file))

        # Show the results
        with open(test_file, "r") as f:
            result_code = f.read()

        print("\nModified code:")
        print("-" * 40)
        print(result_code)
        print("-" * 40)

        fixer.print_stats()

    finally:
        # Clean up
        os.unlink(test_file)
        print(f"\nCleaned up test file: {test_file}")


if __name__ == "__main__":
    test_docstring_automation()
