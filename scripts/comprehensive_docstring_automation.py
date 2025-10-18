#!/usr/bin/env python3
"""
Final Docstring Automation Solution

This script combines multiple approaches to handle the ~500 missing docstring warnings:
1. Uses pydocstring for most files (professional quality)
2. Falls back to simple templates for problematic files
3. Provides comprehensive reporting and backup
"""

import ast
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List, Tuple


class ComprehensiveDocstringAutomation:
    """Comprehensive docstring automation using multiple tools and fallbacks."""

    def __init__(self):
        """Initialize the automation system."""
        self.pydocstring_path = Path("C:/Users/kevin/AppData/Roaming/Python/Python314/Scripts/pydocstring.exe")
        self.backup_dir = Path("docstring_backup")
        self.results = {
            "processed_files": [],
            "failed_files": [],
            "total_docstrings_added": 0,
            "backup_created": False
        }

    def create_backup(self) -> bool:
        """Create a backup of the entire workspace before processing."""
        try:
            if self.backup_dir.exists():
                shutil.rmtree(self.backup_dir)

            # Create backup of key directories
            dirs_to_backup = ["utils", "tools", "core_router", "database", "scripts"]
            self.backup_dir.mkdir()

            for dir_name in dirs_to_backup:
                src_dir = Path(dir_name)
                if src_dir.exists():
                    shutil.copytree(src_dir, self.backup_dir / dir_name)

            self.results["backup_created"] = True
            print(f"✓ Backup created in {self.backup_dir}")
            return True

        except Exception as e:
            print(f"✗ Failed to create backup: {e}")
            return False

    def find_functions_without_docstrings(self, file_path: Path) -> List[Tuple[int, str]]:
        """Find functions that need docstrings."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            tree = ast.parse(content)
            functions_without_docstrings = []

            for node in ast.walk(tree):
                if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    # Check if function has a docstring
                    has_docstring = (
                        node.body and
                        isinstance(node.body[0], ast.Expr) and
                        isinstance(node.body[0].value, ast.Constant) and
                        isinstance(node.body[0].value.value, str)
                    )

                    if not has_docstring:
                        functions_without_docstrings.append((node.lineno, node.name))

            return functions_without_docstrings

        except Exception as e:
            print(f"Error analyzing {file_path}: {e}")
            return []

    def try_pydocstring(self, file_path: Path, line_number: int) -> str:
        """Try to generate docstring using pydocstring."""
        try:
            result = subprocess.run([
                str(self.pydocstring_path),
                "--formatter", "google",
                str(file_path),
                f"({line_number}, 0)"
            ], capture_output=True, text=True, timeout=10)

            if result.returncode == 0:
                # Clean the output
                output = result.stdout.strip()
                lines = output.split('\n')

                # Extract content between triple quotes
                content = []
                in_docstring = False

                for line in lines:
                    stripped = line.strip()

                    if stripped.startswith('(') and stripped.endswith(')') and ',' in stripped:
                        continue

                    if stripped.startswith('"""') and not in_docstring:
                        in_docstring = True
                        continue
                    elif stripped.endswith('"""') and in_docstring:
                        break
                    elif in_docstring and stripped:
                        content.append(stripped)

                if content:
                    return '\n'.join(content).strip()

            return ""

        except Exception:
            return ""

    def generate_simple_docstring(self, func_name: str) -> str:
        """Generate a simple fallback docstring."""
        if func_name == "__init__":
            return "Initialize the instance."
        elif func_name.startswith("get_"):
            return f"Get {func_name[4:].replace('_', ' ')}."
        elif func_name.startswith("set_"):
            return f"Set {func_name[4:].replace('_', ' ')}."
        elif func_name.startswith("is_") or func_name.startswith("has_"):
            return f"Check if {func_name[3:].replace('_', ' ')}."
        else:
            return f"TODO: Add docstring for {func_name}."

    def add_docstring_to_file(self, file_path: Path, line_number: int, docstring: str) -> bool:
        """Add docstring to a specific function in a file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()

            func_line_idx = line_number - 1
            insert_line_idx = func_line_idx + 1

            # Get indentation
            func_line = lines[func_line_idx]
            func_indent = len(func_line) - len(func_line.lstrip())
            docstring_indent = " " * (func_indent + 4)

            # Format docstring
            docstring_line = f'{docstring_indent}"""{docstring}"""\n'
            lines.insert(insert_line_idx, docstring_line)

            # Write back
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(lines)

            return True

        except Exception as e:
            print(f"Error adding docstring to {file_path}:{line_number}: {e}")
            return False

    def process_file(self, file_path: Path) -> dict:
        """Process a single file."""
        print(f"Processing {file_path}...")

        functions = self.find_functions_without_docstrings(file_path)
        if not functions:
            return {"file": str(file_path), "functions": 0, "status": "complete"}

        added_count = 0
        for line_num, func_name in functions:
            print(f"  - {func_name} (line {line_num})")

            # Try pydocstring first
            docstring = self.try_pydocstring(file_path, line_num)

            # Fall back to simple docstring
            if not docstring:
                docstring = self.generate_simple_docstring(func_name)
                print("    Using fallback docstring")
            else:
                print("    Using pydocstring")

            # Add the docstring
            if self.add_docstring_to_file(file_path, line_num, docstring):
                added_count += 1
                print(f"    ✓ Added: {docstring[:50]}...")
            else:
                print("    ✗ Failed to add docstring")

        return {
            "file": str(file_path),
            "functions": added_count,
            "status": "processed"
        }

    def run_automation(self, target_dirs: List[str]) -> dict:
        """Run the complete automation process."""
        print("🔧 Starting Comprehensive Docstring Automation")
        print("=" * 50)

        # Create backup
        if not self.create_backup():
            print("❌ Backup failed. Aborting for safety.")
            return self.results

        # Process files
        for dir_name in target_dirs:
            dir_path = Path(dir_name)
            if not dir_path.exists():
                print(f"⚠️  Directory {dir_name} not found, skipping")
                continue

            python_files = list(dir_path.rglob("*.py"))
            print(f"\n📁 Processing {len(python_files)} files in {dir_name}/")

            for file_path in python_files:
                try:
                    result = self.process_file(file_path)
                    self.results["processed_files"].append(result)
                    self.results["total_docstrings_added"] += result["functions"]
                except Exception as e:
                    print(f"❌ Error processing {file_path}: {e}")
                    self.results["failed_files"].append(str(file_path))

        return self.results

    def print_summary(self):
        """Print automation summary."""
        print("\n" + "=" * 50)
        print("📊 AUTOMATION SUMMARY")
        print("=" * 50)
        print(f"Files processed: {len(self.results['processed_files'])}")
        print(f"Files failed: {len(self.results['failed_files'])}")
        print(f"Total docstrings added: {self.results['total_docstrings_added']}")
        print(f"Backup created: {self.results['backup_created']}")

        if self.results["failed_files"]:
            print("\n❌ Failed files:")
            for file_path in self.results["failed_files"]:
                print(f"  - {file_path}")

        print(f"\n✅ Backup location: {self.backup_dir}")
        print("\n🔥 To restore from backup if needed:")
        print("   rm -rf utils tools core_router database scripts")
        print(f"   cp -r {self.backup_dir}/* .")


def main():
    """Main automation function."""
    # Target directories with many missing docstrings
    target_dirs = [
        "utils",
        "tools", 
        "core_router",
        "database",
        "scripts"
    ]

    automation = ComprehensiveDocstringAutomation()

    # Check if --auto-confirm flag was provided
    auto_confirm = "--auto-confirm" in sys.argv

    print("This will process ~500 missing docstring warnings.")
    print("A backup will be created automatically.")

    if not auto_confirm:
        response = input("\nProceed? (y/N): ")
        if response.lower() != 'y':
            print("Automation cancelled.")
            return
    else:
        print("\nAuto-confirming (--auto-confirm flag detected)...")

    # Run the automation
    automation.run_automation(target_dirs)
    automation.print_summary()


if __name__ == "__main__":
    main()