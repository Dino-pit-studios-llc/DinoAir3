#!/usr/bin/env python3
"""
Automated Python Naming Convention Fixer

Fixes naming convention issues by renaming:
- PascalCase fields/variables to snake_case
- camelCase methods to snake_case
- camelCase parameters to snake_case

Includes validation to ensure files remain syntactically correct.

Usage:
    python scripts/fix_naming_conventions.py [--dry-run] [--file FILE]
"""

import argparse
import ast
import re
import shutil
import sys
import tempfile
from pathlib import Path

# Regex patterns for naming detection
CAMEL_CASE_PATTERN = r"^[a-z]+[A-Z]"
PASCAL_CASE_PATTERN = r"^[A-Z][a-z]+[A-Z]"


class NamingFixer:
    """Fixes Python naming convention issues."""

    # Common PascalCase names that should be snake_case
    field_renames = {
        "AppState": "app_state",
        "LogLevel": "log_level",
        "NoteStatus": "note_status",
        "InputType": "input_type",
        "ToolType": "tool_type",
        "UITheme": "ui_theme",
        "AgentType": "agent_type",
        "ProcessingStage": "processing_stage",
        "DatabaseState": "database_state",
    }

    # camelCase method renames
    method_renames = {
        "setSingleShot": "set_single_shot",
    }

    # camelCase parameter renames
    param_renames = {
        "singleShot": "single_shot",
        "SD": "sd",
    }

    def __init__(self, dry_run: bool = False, project_root: Path | None = None):
        self.dry_run = dry_run
        self.project_root = (project_root or Path.cwd()).resolve()
        self.stats = {
            "files_processed": 0,
            "files_modified": 0,
            "files_failed_validation": 0,
            "replacements": 0,
            "errors": [],
        }

    @staticmethod
    def find_python_files(root_dir: Path) -> list[Path]:
        """Find all Python source files in the given root directory, excluding common build and virtual environment folders."""
        py_files = list(root_dir.rglob("*.py"))
        # Exclude common directories
        excluded = {"__pycache__", ".venv", "venv", "env", ".tox", "build", "dist"}
        return [f for f in py_files if not any(ex in f.parts for ex in excluded)]

    def validate_python_syntax(self, file_path: Path) -> tuple[bool, str]:
        """
        Validate Python syntax and ensure file is within project bounds.

        Returns:
            Tuple of (is_valid, error_message)
        """
        try:
            # Resolve path to absolute, canonical form
            safe_path = file_path.resolve()

            # Verify the file is within the project root to prevent path traversal
            try:
                # This will raise ValueError if safe_path is not relative to project_root
                safe_path.relative_to(self.project_root)
            except ValueError:
                return False, f"File is outside project bounds: {safe_path.name}"

            # Read and parse content
            with open(safe_path, encoding="utf-8") as f:
                content = f.read()
            ast.parse(content)
            return True, ""
        except SyntaxError as e:
            return False, f"Syntax error at line {e.lineno}: {e.msg}"
        except Exception as e:
            return False, str(e)

    @staticmethod
    def camel_to_snake(name: str) -> str:
        """Convert camelCase or PascalCase to snake_case."""
        # Insert underscore before uppercase letters
        s1 = re.sub("(.)([A-Z][a-z]+)", r"\1_\2", name)
        return re.sub("([a-z0-9])([A-Z])", r"\1_\2", s1).lower()

    def should_rename(self, name: str, context: str) -> bool:
        """
        Determine if a name should be renamed based on context.

        Args:
            name: The identifier name
            context: 'field', 'method', 'param', 'auto'
        """
        if context == "auto":
            # Auto-detect: rename if PascalCase or camelCase
            return bool(re.match(CAMEL_CASE_PATTERN, name) or re.match(PASCAL_CASE_PATTERN, name))

        if context == "field":
            return name in self.field_renames or bool(re.match(r"^[A-Z]", name))

        if context == "method":
            return name in self.method_renames or bool(re.match(CAMEL_CASE_PATTERN, name))

        if context == "param":
            return name in self.param_renames or bool(re.match(CAMEL_CASE_PATTERN, name))

        return False

    def get_renamed_name(self, name: str, context: str) -> str:
        """Get the renamed version of a name based on context mappings or auto-conversion."""
        if context == "field" and name in self.field_renames:
            return self.field_renames[name]
        if context == "method" and name in self.method_renames:
            return self.method_renames[name]
        if context == "param" and name in self.param_renames:
            return self.param_renames[name]

        # Auto-convert using camel_to_snake
        return self.camel_to_snake(name)

    @staticmethod
    def _get_field_names(item: ast.AST) -> list[str]:
        """Get field names from an AST assignment or annotated assignment node."""
        if isinstance(item, ast.AnnAssign) and isinstance(item.target, ast.Name):
            return [item.target.id]
        if isinstance(item, ast.Assign):
            return [target.id for target in item.targets if isinstance(target, ast.Name)]
        return []

    def _process_class(self, node: ast.ClassDef, renames: dict[str, str]) -> None:
        """Process a class AST node to collect field renames into the renames dict."""
        for item in node.body:
            for name in self._get_field_names(item):
                if self.should_rename(name, "field"):
                    renames[name] = self.get_renamed_name(name, "field")

    def _process_function(self, node: ast.AST, renames: dict[str, str]) -> None:
        """Process a function AST node to collect method and parameter renames into the renames dict."""
        if self.should_rename(node.name, "method"):
            renames[node.name] = self.get_renamed_name(node.name, "method")
        for arg in node.args.args:
            if self.should_rename(arg.arg, "param"):
                renames[arg.arg] = self.get_renamed_name(arg.arg, "param")

    def find_identifiers_to_rename(self, content: str) -> dict[str, str]:
        """
        Find all identifiers that need renaming in the provided Python source content.

        Returns:
            Dict mapping old_name -> new_name
        """
        renames = {}

        try:
            tree = ast.parse(content)

            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    self._process_class(node, renames)
                elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    self._process_function(node, renames)
        except SyntaxError:
            pass  # File may have syntax errors, skip AST analysis

        return renames

    @staticmethod
    def apply_renames(content: str, renames: dict[str, str]) -> tuple[str, int]:
        """
        Apply renames to content using word boundaries.

        Returns:
            Tuple of (new_content, replacement_count)
        """
        if not renames:
            return content, 0

        count = 0
        for old_name, new_name in renames.items():
            # Use word boundaries to avoid partial matches
            pattern = r"\b" + re.escape(old_name) + r"\b"
            new_content, num_replacements = re.subn(pattern, new_name, content)
            if num_replacements > 0:
                content = new_content
                count += num_replacements

        return content, count

    @staticmethod
    def _sanitize_path_for_logging(file_path: Path) -> str:
        """Sanitize file path for logging by returning only the filename or 'unknown'."""
        return file_path.name if file_path else "unknown"

    def process_file(self, file_path: Path) -> bool:
        """
        Process a single Python file to apply naming convention fixes.

        Returns:
            True if file was successfully processed, False otherwise
        """
        # Sanitize path for logging - only show filename
        safe_log_path = self._sanitize_path_for_logging(file_path)
        print(f"\nProcessing: {safe_log_path}")
        self.stats["files_processed"] += 1

        try:
            # Read original content
            with open(file_path, encoding="utf-8") as f:
                original_content = f.read()

            # Validate original file first
            is_valid, error = self.validate_python_syntax(file_path)
            if not is_valid:
                msg = f"  ⚠ Original file has syntax errors, skipping: {error}"
                print(msg)
                self.stats["errors"].append((safe_log_path, msg))
                return False

            # Find identifiers to rename
            renames = self.find_identifiers_to_rename(original_content)

            if not renames:
                print("  ✓ No naming issues found")
                return True

            print(f"  Found {len(renames)} identifier(s) to rename:")
            for old, new in renames.items():
                print(f"    {old} -> {new}")

            # Apply renames
            new_content, total_replacements = self.apply_renames(original_content, renames)

            if total_replacements == 0:
                print("  ✓ No changes needed")
                return True

            # Create temporary file with fixed content
            with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", suffix=".py", delete=False) as tmp_file:
                tmp_path = Path(tmp_file.name)
                tmp_file.write(new_content)

            # Validate fixed content
            is_valid, error = self.validate_python_syntax(tmp_path)

            if not is_valid:
                msg = f"  ✗ Fixed file failed validation: {error}"
                print(msg)
                self.stats["errors"].append((safe_log_path, msg))
                self.stats["files_failed_validation"] += 1
                tmp_path.unlink()
                return False

            # Apply changes if not dry-run
            if self.dry_run:
                print(f"  ✓ [DRY RUN] Would make {total_replacements} replacement(s)")
                tmp_path.unlink()
            else:
                # Backup original file
                backup_path = file_path.with_suffix(file_path.suffix + ".bak")
                shutil.copy2(file_path, backup_path)

            # Apply changes
            shutil.copy2(tmp_path, file_path)
            tmp_path.unlink()

            print(f"  ✓ Made {total_replacements} replacement(s)")
            print(f"  ✓ Backup saved to: {backup_path}")

            self.stats["files_modified"] += 1
            self.stats["replacements"] += total_replacements

            return True

        except Exception as e:
            msg = f"  ✗ Error processing file: {str(e)}"
            print(msg)
            self.stats["errors"].append((safe_log_path, msg))
            return False

    def print_summary(self):
        """Print summary statistics."""
        print("\n" + "=" * 70)
        print("SUMMARY")
        print("=" * 70)
        print(f"Files processed:           {self.stats['files_processed']}")
        print(f"Files modified:            {self.stats['files_modified']}")
        print(f"Files failed validation:   {self.stats['files_failed_validation']}")
        print(f"Total replacements:        {self.stats['replacements']}")

        if self.stats["errors"]:
            print(f"\nErrors encountered:        {len(self.stats['errors'])}")
            for safe_path, error in self.stats["errors"][:10]:  # Show first 10, paths already sanitized
                print(f"  - {safe_path}")
                print(f"    {error}")

        if self.dry_run:
            print("\n[DRY RUN MODE - No files were actually modified]")

        print("=" * 70)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Fix Python naming convention issues")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without modifying files",
    )
    parser.add_argument(
        "--file",
        type=Path,
        help="Process a single file instead of scanning the entire project",
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=Path("."),
        help="Root directory to scan (default: current directory)",
    )

    args = parser.parse_args()

    # Determine project root
    root_dir = args.root.resolve()

    fixer = NamingFixer(dry_run=args.dry_run, project_root=root_dir)

    if args.file:
        # Process single file
        file_path_resolved = args.file.resolve()
        try:
            # Python 3.9+: is_relative_to
            is_within_root = file_path_resolved.is_relative_to(root_dir)
        except AttributeError:
            # For Python <3.9, use manual comparison
            is_within_root = str(file_path_resolved).startswith(str(root_dir))
        if not is_within_root:
            print(f"Error: File {file_path_resolved} is outside the root directory {root_dir}")
            sys.exit(1)
        if not args.file.exists():
            print(f"Error: File not found: {args.file}")
            sys.exit(1)

        success = fixer.process_file(args.file)
        fixer.print_summary()
        sys.exit(0 if success else 1)

    else:
        # Scan and process all Python files
        print(f"Scanning for Python files in: {root_dir}")

        py_files = fixer.find_python_files(root_dir)
        print(f"Found {len(py_files)} Python file(s)")

        if not py_files:
            print("No Python files found.")
            sys.exit(0)

        # Process each file
        for py_file in py_files:
            fixer.process_file(py_file)

        fixer.print_summary()

        # Exit with error if any files failed validation
        sys.exit(1 if fixer.stats["files_failed_validation"] > 0 else 0)


if __name__ == "__main__":
    main()
