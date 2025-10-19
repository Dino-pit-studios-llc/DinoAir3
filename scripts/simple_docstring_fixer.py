#!/usr/bin/env python3
"""
Simple Docstring Automation Script
Fixes PY-D0003 warnings by adding missing docstrings to Python files.

Usage:
    python scripts/simple_docstring_fixer.py [directory_or_file]
"""

import argparse
import ast
import os
import sys
from pathlib import Path


class SimpleDocstringFixer:
    """Simple docstring fixer for Python files."""

    def __init__(self, dry_run: bool = False, root_dir: Path = None):
        """Initialize the fixer.

        Args:
            dry_run: If True, only show what would be changed
            root_dir: Base directory to constrain safe file access
        """
        self.dry_run = dry_run
        self.files_processed = 0
        self.docstrings_added = 0
        # Use root_dir for path validation. Default to cwd if not given.
        # Always use resolved absolute path
        self.root_dir = Path(root_dir or Path.cwd()).resolve()

    def fix_file(self, filepath: Path) -> bool:
        """Fix missing docstrings in a Python file.

        Args:
            filepath: Path to the Python file to process

        Returns:
            True if changes were made, False otherwise
        """
        try:
            # Restrict access to files only within self.root_dir
            abs_filepath = filepath.resolve()
            abs_root_dir = self.root_dir
            # Use os.path.commonpath for robust directory check
            # Both inputs must be strings
            if os.path.commonpath([str(abs_filepath), str(abs_root_dir)]) != str(abs_root_dir):
                print(f"Error: Unsafe file path {abs_filepath} is outside allowed directory {abs_root_dir}")
                return False

            with open(abs_filepath, encoding="utf-8") as f:
                content = f.read()

            tree = ast.parse(content)
            lines = content.splitlines()
            changes_made = False

            # Process from bottom to top to maintain line numbers
            items_to_fix = self._find_missing_docstrings(tree)
            items_to_fix.sort(key=lambda x: x[1], reverse=True)  # Sort by line number desc

            for item_type, lineno, name, indent in items_to_fix:
                docstring = self._generate_simple_docstring(item_type, name, indent)

                # Insert docstring after the definition line
                # Find the end of the function signature (after the colon)
                definition_line_idx = lineno - 1  # Convert to 0-based

                # Look for the function definition line and find the colon
                for i in range(definition_line_idx, min(definition_line_idx + 10, len(lines))):
                    if ":" in lines[i]:
                        insert_pos = i + 1
                        break
                else:
                    insert_pos = definition_line_idx + 1

                lines.insert(insert_pos, docstring)
                changes_made = True
                self.docstrings_added += 1

                if not self.dry_run:
                    print(f"  + Added {item_type} docstring: {name}")

            if changes_made:
                if self.dry_run:
                    print(f"[DRY RUN] {filepath}: Would add {len(items_to_fix)} docstrings")
                else:
                    new_content = "\n".join(lines)
                    with open(filepath, "w", encoding="utf-8") as f:
                        f.write(new_content)
                    print(f"✓ {filepath}: Added {len(items_to_fix)} docstrings")

            self.files_processed += 1
            return changes_made

        except Exception as e:
            print(f"Error processing {filepath}: {e}")
            return False

    def _find_missing_docstrings(self, tree) -> list[tuple]:
        """Find functions and classes missing docstrings.

        Args:
            tree: AST tree of the Python file

        Returns:
            List of tuples: (type, lineno, name, indent_level)
        """
        missing = []

        # Check module level
        has_module_docstring = (
            len(tree.body) > 0
            and isinstance(tree.body[0], ast.Expr)
            and isinstance(tree.body[0].value, ast.Constant)
            and isinstance(tree.body[0].value.value, str)
        )

        if not has_module_docstring:
            missing.append(("module", 0, "module", 0))

        # Walk the AST to find classes and functions
        for node in ast.walk(tree):
            if isinstance(node, ast.ClassDef):
                if not self._has_docstring(node):
                    missing.append(("class", node.lineno, node.name, 8))  # 8 spaces for class docstring

                # Check methods within the class
                for child in node.body:
                    if isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef)):
                        if not self._has_docstring(child) and not child.name.startswith("_"):
                            missing.append(("method", child.lineno, child.name, 12))  # 12 spaces for method docstring

            elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                # Only top-level functions (not nested or methods)
                if (
                    not self._has_docstring(node)
                    and not node.name.startswith("_")
                    and not node.name.startswith("test_")
                    and self._is_top_level(node, tree)
                ):
                    missing.append(("function", node.lineno, node.name, 8))  # 8 spaces for function docstring

        return missing

    @staticmethod
    def _has_docstring(node) -> bool:
        """Check if a node has a docstring.

        Args:
            node: AST node to check

        Returns:
            True if node has a docstring
        """
        return (
            len(node.body) > 0
            and isinstance(node.body[0], ast.Expr)
            and isinstance(node.body[0].value, ast.Constant)
            and isinstance(node.body[0].value.value, str)
        )

    @staticmethod
    def _is_top_level(func_node, tree) -> bool:
        """Check if function is at module level (not nested).

        Args:
            func_node: Function AST node
            tree: Module AST tree

        Returns:
            True if function is at module level
        """
        return func_node in tree.body

    def _generate_simple_docstring(self, item_type: str, name: str, indent: int) -> str:
        """Generate a simple docstring.

        Args:
            item_type: Type of item ('function', 'class', 'method', 'module')
            name: Name of the item
            indent: Indentation level in spaces

        Returns:
            Formatted docstring
        """
        indent_str = " " * indent

        if item_type == "module":
            return f'"""{self._make_readable(name)} module."""'
        elif item_type == "class":
            return f'{indent_str}"""{self._make_readable(name)} class."""'
        elif item_type == "function":
            return f'{indent_str}"""{self._make_readable(name)} function."""'
        elif item_type == "method":
            return f'{indent_str}"""{self._make_readable(name)} method."""'
        else:
            return f'{indent_str}"""TODO: Add description."""'

    @staticmethod
    def _make_readable(name: str) -> str:
        """Convert name to readable format.

        Args:
            name: Variable/function/class name

        Returns:
            Human readable version
        """
        if name == "module":
            return "Module"

        # Handle common patterns
        if name.endswith("_manager"):
            return name.replace("_", " ").replace(" manager", " manager").title()
        elif name.endswith("_handler"):
            return name.replace("_", " ").replace(" handler", " handler").title()
        elif name.startswith("get_"):
            return f"Get {name[4:].replace('_', ' ')}"
        elif name.startswith("set_"):
            return f"Set {name[4:].replace('_', ' ')}"
        elif name.startswith("create_"):
            return f"Create {name[7:].replace('_', ' ')}"
        elif name.startswith("init_"):
            return f"Initialize {name[5:].replace('_', ' ')}"
        elif name.startswith("process_"):
            return f"Process {name[8:].replace('_', ' ')}"
        elif name.startswith("validate_"):
            return f"Validate {name[9:].replace('_', ' ')}"
        else:
            # Convert snake_case to Title Case
            return name.replace("_", " ").title()

    def process_directory(self, directory: Path) -> None:
        """Process all Python files in a directory.

        Args:
            directory: Directory to process recursively
        """
        python_files = list(directory.rglob("*.py"))

        # Filter out common non-source directories
        python_files = [
            f
            for f in python_files
            if not any(
                part in str(f)
                for part in [
                    ".git",
                    "__pycache__",
                    ".pytest_cache",
                    "node_modules",
                    ".venv",
                    "venv",
                    "build",
                    "dist",
                ]
            )
        ]

        print(f"Found {len(python_files)} Python files to process")

        for filepath in python_files:
            self.fix_file(filepath)

    def print_summary(self) -> None:
        """Print processing summary."""
        print("\nSummary:")
        print(f"  Files processed: {self.files_processed}")
        print(f"  Docstrings added: {self.docstrings_added}")

        if self.dry_run:
            print("  [DRY RUN] No files were modified")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Add missing docstrings to Python files")
    parser.add_argument(
        "path",
        nargs="?",
        default=".",
        help="Directory or file to process (default: current directory)",
    )
    parser.add_argument("--dry-run", action="store_true", help="Show what would be changed without making changes")

    args = parser.parse_args()

    target_path = Path(args.path)

    if not target_path.exists():
        print(f"Error: Path {target_path} does not exist")
        return 1

    # Set the safe root directory as the fully resolved start path
    safe_root = target_path.resolve() if target_path.exists() else Path.cwd().resolve()
    fixer = SimpleDocstringFixer(dry_run=args.dry_run, root_dir=safe_root)

    if target_path.is_file():
        if target_path.suffix == ".py":
            fixer.fix_file(target_path)
        else:
            print(f"Error: {target_path} is not a Python file")
            return 1
    else:
        fixer.process_directory(target_path)

    fixer.print_summary()
    return 0


if __name__ == "__main__":
    sys.exit(main())
