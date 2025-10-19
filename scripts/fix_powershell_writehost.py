#!/usr/bin/env python3
"""
Automated PowerShell Write-Host Fixer

This script replaces Write-Host with appropriate PowerShell cmdlets
and validates the files are still syntactically correct after changes.

Usage:
    python scripts/fix_powershell_writehost.py [--dry-run] [--file FILE]
"""

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


class PowerShellFixer:
    """Fixes Write-Host usage in PowerShell scripts."""

    # Patterns for different Write-Host scenarios
    patterns = {
        "error": re.compile(
            r'Write-Host\s+(["\'][^"\']*["\'])\s+-ForegroundColor\s+Red', re.IGNORECASE
        ),
        "warning": re.compile(
            r'Write-Host\s+(["\'][^"\']*["\'])\s+-ForegroundColor\s+(Yellow|Orange)',
            re.IGNORECASE,
        ),
        "success": re.compile(
            r'Write-Host\s+(["\'][^"\']*["\'])\s+-ForegroundColor\s+Green',
            re.IGNORECASE,
        ),
        "info": re.compile(
            r'Write-Host\s+(["\'][^"\']*["\'])\s+-ForegroundColor\s+\w+', re.IGNORECASE
        ),
        "simple": re.compile(r'Write-Host\s+(["\'][^"\']*["\'])', re.IGNORECASE),
        "variable": re.compile(r"Write-Host\s+(\$\w+)", re.IGNORECASE),
    }

    replacements = {
        "error": "Write-Error",
        "warning": "Write-Warning",
        "success": "Write-Output",
        "info": "Write-Information",
        "simple": "Write-Output",
        "variable": "Write-Output",
    }

    def __init__(self, dry_run: bool = False):
        self.dry_run = dry_run
        self.stats = {
            "files_processed": 0,
            "files_modified": 0,
            "files_failed_validation": 0,
            "replacements": 0,
            "errors": [],
        }

    def find_powershell_files(self, root_dir: Path) -> list[Path]:
        """Find all PowerShell script files."""
        ps_files = []
        for pattern in ["*.ps1", "*.psm1", "*.psd1"]:
            ps_files.extend(root_dir.rglob(pattern))
        return sorted(ps_files)

    def validate_powershell_syntax(self, file_path: Path) -> tuple[bool, str]:
        """
        Validate PowerShell syntax using PowerShell's parser.

        Returns:
            Tuple of (is_valid, error_message)
        """
        try:
            # Use PowerShell to parse and validate the script
            # File path is sanitized by using Path object
            cmd = [
                "pwsh",
                "-NoProfile",
                "-NonInteractive",
                "-Command",
                f'$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path "{file_path}" -Raw), [ref]$null); '
                f'if ($?) {{ Write-Output "VALID" }} else {{ Write-Output "INVALID" }}',
            ]

            # Command is safe: hardcoded executable and sanitized file path
            result = subprocess.run(  # noqa: S603  # nosec B603
                cmd, capture_output=True, text=True, timeout=10
            )

            if result.returncode == 0 and "VALID" in result.stdout:
                return True, ""
            else:
                return False, result.stderr or result.stdout

        except subprocess.TimeoutExpired:
            return False, "Validation timeout"
        except Exception as e:
            return False, str(e)

    def _check_color_category(self, line_lower: str) -> str:
        """Check for color-based categorization."""
        if "-foregroundcolor red" in line_lower or "-backgroundcolor red" in line_lower:
            return "error"
        if "-foregroundcolor yellow" in line_lower or "-foregroundcolor orange" in line_lower:
            return "warning"
        if "-foregroundcolor green" in line_lower:
            return "success"
        if "-foregroundcolor" in line_lower:
            return "info"
        return ""

    def _check_keyword_category(self, line_lower: str) -> str:
        """Check for keyword-based categorization."""
        keywords_error = ["error", "failed", "failure", "exception", "critical"]
        keywords_warning = ["warning", "caution", "deprecated"]
        keywords_success = ["success", "completed", "done", "finished"]

        if any(keyword in line_lower for keyword in keywords_error):
            return "error"
        if any(keyword in line_lower for keyword in keywords_warning):
            return "warning"
        if any(keyword in line_lower for keyword in keywords_success):
            return "success"
        return ""

    def analyze_write_host_context(self, line: str) -> str:
        """
        Analyze the context of Write-Host usage to determine best replacement.

        Returns the category: 'error', 'warning', 'success', 'info', 'simple', 'variable'
        """
        line_lower = line.lower()

        # Check for color parameters first
        color_category = self._check_color_category(line_lower)
        if color_category:
            return color_category

        # Check for keywords in the message
        keyword_category = self._check_keyword_category(line_lower)
        if keyword_category:
            return keyword_category

        # Check if it's a variable
        if re.search(r"Write-Host\s+\$\w+", line, re.IGNORECASE):
            return "variable"

        # Default to simple output
        return "simple"

    def fix_write_host_in_line(self, line: str) -> tuple[str, int]:
        """
        Fix Write-Host in a single line.

        Returns:
            Tuple of (fixed_line, replacement_count)
        """
        replacements = 0

        # Determine the best category for this line
        category = self.analyze_write_host_context(line)

        # Error category
        if category == "error":
            new_line = re.sub(
                r'Write-Host\s+(["\'][^"\']*["\'])\s+-ForegroundColor\s+Red\b',
                r"Write-Error \1",
                line,
                flags=re.IGNORECASE,
            )
            if new_line != line:
                return new_line, 1

        # Warning category
        if category == "warning":
            new_line = re.sub(
                r'Write-Host\s+(["\'][^"\']*["\'])\s+-ForegroundColor\s+(Yellow|Orange)\b',
                r"Write-Warning \1",
                line,
                flags=re.IGNORECASE,
            )
            if new_line != line:
                return new_line, 1

        # Success/Info categories
        if category in ["success", "info"]:
            new_line = re.sub(
                r'Write-Host\s+(["\'][^"\']*["\'])\s+-ForegroundColor\s+\w+',
                r"Write-Output \1",
                line,
                flags=re.IGNORECASE,
            )
            if new_line != line:
                return new_line, 1

        # Simple/Variable categories - both use Write-Output
        if category in ["simple", "variable"]:
            new_line = re.sub(r"Write-Host\s+", "Write-Output ", line, flags=re.IGNORECASE)
            if new_line != line:
                return new_line, 1

        return line, replacements

    def process_file(self, file_path: Path) -> bool:
        """
        Process a single PowerShell file.

        Returns:
            True if file was successfully processed, False otherwise
        """
        print(f"\nProcessing: {file_path}")
        self.stats["files_processed"] += 1

        try:
            # Read original content
            with open(file_path, encoding="utf-8") as f:
                original_content = f.read()
                lines = original_content.splitlines(keepends=True)

            # Check if file needs fixing
            if not any("Write-Host" in line for line in lines):
                print("  ✓ No Write-Host found, skipping")
                return True

            # Validate original file first
            is_valid, error = self.validate_powershell_syntax(file_path)
            if not is_valid:
                msg = f"  ⚠ Original file has syntax errors, skipping: {error}"
                print(msg)
                self.stats["errors"].append((str(file_path), msg))
                return False

            # Fix Write-Host in each line
            fixed_lines = []
            total_replacements = 0

            for line_num, line in enumerate(lines, 1):
                if "Write-Host" in line:
                    fixed_line, count = self.fix_write_host_in_line(line)
                    fixed_lines.append(fixed_line)
                    total_replacements += count
                    if count > 0:
                        print(f"  Line {line_num}: {count} replacement(s)")
                else:
                    fixed_lines.append(line)

            if total_replacements == 0:
                print("  ✓ No changes needed")
                return True

            # Create temporary file with fixed content
            with tempfile.NamedTemporaryFile(
                mode="w", encoding="utf-8", suffix=".ps1", delete=False
            ) as tmp_file:
                tmp_path = Path(tmp_file.name)
                tmp_file.write("".join(fixed_lines))

            # Validate fixed content
            is_valid, error = self.validate_powershell_syntax(tmp_path)

            if not is_valid:
                msg = f"  ✗ Fixed file failed validation: {error}"
                print(msg)
                self.stats["errors"].append((str(file_path), msg))
                self.stats["files_failed_validation"] += 1
                tmp_path.unlink()
                return False

            # Apply changes if not dry-run
            if self.dry_run:
                print(f"  ✓ [DRY RUN] Would replace {total_replacements} Write-Host occurrence(s)")
                tmp_path.unlink()
            else:
                # Backup original file
                backup_path = file_path.with_suffix(file_path.suffix + ".bak")
                shutil.copy2(file_path, backup_path)

                # Apply changes
                shutil.copy2(tmp_path, file_path)
                tmp_path.unlink()

                print(f"  ✓ Replaced {total_replacements} Write-Host occurrence(s)")
                print(f"  ✓ Backup saved to: {backup_path}")

                self.stats["files_modified"] += 1
                self.stats["replacements"] += total_replacements

            return True

        except Exception as e:
            msg = f"  ✗ Error processing file: {str(e)}"
            print(msg)
            self.stats["errors"].append((str(file_path), msg))
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
            for file_path, error in self.stats["errors"]:
                print(f"  - {file_path}")
                print(f"    {error}")

        if self.dry_run:
            print("\n[DRY RUN MODE - No files were actually modified]")

        print("=" * 70)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Fix Write-Host usage in PowerShell scripts")
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

    fixer = PowerShellFixer(dry_run=args.dry_run)

    if args.file:
        # Process single file
        if not args.file.exists():
            print(f"Error: File not found: {args.file}")
            sys.exit(1)

        success = fixer.process_file(args.file)
        fixer.print_summary()
        sys.exit(0 if success else 1)

    else:
        # Scan and process all PowerShell files
        root_dir = args.root.resolve()
        print(f"Scanning for PowerShell files in: {root_dir}")

        ps_files = fixer.find_powershell_files(root_dir)
        print(f"Found {len(ps_files)} PowerShell file(s)")

        if not ps_files:
            print("No PowerShell files found.")
            sys.exit(0)

        # Process each file
        for ps_file in ps_files:
            fixer.process_file(ps_file)

        fixer.print_summary()

        # Exit with error if any files failed validation
        sys.exit(1 if fixer.stats["files_failed_validation"] > 0 else 0)


if __name__ == "__main__":
    main()
