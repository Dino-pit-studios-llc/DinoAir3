#!/usr/bin/env python3
"""
Scan the codebase for unreachable except blocks.

This ensures Issue #346 type problems don't exist anywhere in the codebase.
"""

import ast
import logging
import os
import sys
from pathlib import Path


def _is_general_exception(handler):
    """Check if handler catches a general exception (Exception or BaseException)."""
    if not handler.type:
        return False
    if not isinstance(handler.type, ast.Name):
        return False
    return handler.type.id in ("Exception", "BaseException")


def _get_handler_name(handler):
    """Get the exception name from a handler, or None if not applicable."""
    if not handler.type or not isinstance(handler.type, ast.Name):
        return None
    return handler.type.id


def _find_unreachable_handlers(handlers, general_handler_index):
    """Find handlers that are unreachable after a general exception handler."""
    unreachable = []
    for j in range(general_handler_index + 1, len(handlers)):
        next_handler = handlers[j]
        if next_handler.type:
            unreachable.append(next_handler)
    return unreachable


def _validate_try_node(node, filepath):
    """Validate a single Try node for unreachable except blocks."""
    issues = []

    for i, handler in enumerate(node.handlers):
        if not _is_general_exception(handler):
            continue

        handler_name = _get_handler_name(handler)

        # Check if there are more handlers after this general exception
        if i < len(node.handlers) - 1:
            unreachable_handlers = _find_unreachable_handlers(node.handlers, i)
            for next_handler in unreachable_handlers:
                issues.append(
                    {
                        "file": str(filepath),
                        "line": handler.lineno,
                        "type": handler_name,
                        "unreachable_line": next_handler.lineno,
                    }
                )

    return issues


def check_unreachable_except(filepath):
    """Check a Python file for unreachable except blocks."""
    issues = []
    try:
        with open(filepath, encoding="utf-8") as f:
            content = f.read()
        tree = ast.parse(content, str(filepath))

        for node in ast.walk(tree):
            if isinstance(node, ast.Try) and len(node.handlers) > 1:
                issues.extend(_validate_try_node(node, filepath))
    except Exception as e:
        logging.error(f"Error parsing file {filepath}: {e}")
        # Skip files that can't be parsed

    return issues


def scan_directory(directory):
    """Scan a directory for Python files with unreachable except blocks."""
    all_issues = []
    skip_dirs = {".git", "__pycache__", "node_modules", ".venv", "venv", ".tox"}

    for root, dirs, files in os.walk(directory):
        # Remove skip directories from dirs in-place
        dirs[:] = [d for d in dirs if d not in skip_dirs]

        for file in files:
            if file.endswith(".py"):
                filepath = Path(root) / file
                issues = check_unreachable_except(filepath)
                all_issues.extend(issues)

    return all_issues


def main():
    """Main entry point."""
    print("=" * 70)
    print("UNREACHABLE EXCEPT BLOCK SCANNER")
    print("=" * 70)
    print()
    print("Scanning Python files for unreachable except blocks...")
    print()

    issues = scan_directory(".")

    if issues:
        print(f"❌ FOUND {len(issues)} unreachable except block(s):")
        print()
        for issue in issues:
            print(f"  File: {issue['file']}")
            print(f"    Line {issue['line']}: except {issue['type']} comes before...")
            print(f"    Line {issue['unreachable_line']}: ...this except block")
            print()
        return 1

    print("✅ No unreachable except blocks found in the codebase!")
    print()
    print("All exception handlers are properly ordered.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
