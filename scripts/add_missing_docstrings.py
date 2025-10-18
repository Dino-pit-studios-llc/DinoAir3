#!/usr/bin/env python3
"""
Automated Docstring Generator
Fixes PY-D0003 warnings by automatically adding missing docstrings to functions, classes, and methods.

This script analyzes Python files and adds appropriate docstring templates for:
- Functions and methods (with parameters, return types, exceptions)
- Classes (with attributes and purpose)
- Modules (with overview and main components)

Usage:
    python scripts/add_missing_docstrings.py [options]

Options:
    --dry-run        Show what would be changed without making changes
    --files PATTERN  Process only files matching pattern (glob)
    --fix-all        Process all Python files in the project
    --interactive    Ask for confirmation before each change
    --templates DIR  Use custom template directory
"""

import argparse
import ast
import glob
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple, Union


@dataclass
class FunctionInfo:
    """Information about a function or method."""

    name: str
    lineno: int
    col_offset: int
    args: List[str]
    return_type: Optional[str]
    is_async: bool
    is_method: bool
    is_property: bool
    is_classmethod: bool
    is_staticmethod: bool
    decorators: List[str]
    parent_class: Optional[str] = None


@dataclass
class ClassInfo:
    """Information about a class."""

    name: str
    lineno: int
    col_offset: int
    bases: List[str]
    decorators: List[str]
    methods: List[FunctionInfo]
    properties: List[str]


@dataclass
class ModuleInfo:
    """Information about a module."""

    filepath: Path
    classes: List[ClassInfo]
    functions: List[FunctionInfo]
    imports: List[str]
    has_module_docstring: bool


class DocstringGenerator:
    """Generates appropriate docstring templates based on code analysis."""

    def __init__(self, templates_dir: Optional[Path] = None):
        """Initialize the docstring generator."""
        self.templates_dir = templates_dir
        self.common_exceptions = {
            "ValueError",
            "TypeError",
            "KeyError",
            "AttributeError",
            "FileNotFoundError",
            "ConnectionError",
            "TimeoutError",
        }

    def generate_function_docstring(self, func_info: FunctionInfo) -> str:
        """Generate a docstring for a function or method."""
        lines = []

        # Generate summary based on function name and context
        summary = self._generate_function_summary(func_info)
        lines.append(f'    """{summary}')

        # Add parameter documentation if function has parameters
        if func_info.args and not (
            len(func_info.args) == 1 and func_info.args[0] in ("self", "cls")
        ):
            lines.append("")
            lines.append("    Args:")
            for arg in func_info.args:
                if arg not in ("self", "cls"):
                    arg_desc = self._generate_arg_description(arg, func_info.name)
                    lines.append(f"        {arg}: {arg_desc}")

        # Add return documentation if function has return type annotation
        if func_info.return_type and func_info.return_type != "None":
            lines.append("")
            lines.append("    Returns:")
            return_desc = self._generate_return_description(func_info.return_type, func_info.name)
            lines.append(f"        {return_desc}")

        # Add raises section for common exception patterns
        potential_exceptions = self._detect_potential_exceptions(func_info)
        if potential_exceptions:
            lines.append("")
            lines.append("    Raises:")
            for exc in potential_exceptions:
                exc_desc = self._generate_exception_description(exc, func_info.name)
                lines.append(f"        {exc}: {exc_desc}")

        lines.append('    """')
        return "\n".join(lines)

    def generate_class_docstring(self, class_info: ClassInfo) -> str:
        """Generate a docstring for a class."""
        lines = []

        # Generate summary based on class name and structure
        summary = self._generate_class_summary(class_info)
        lines.append(f'    """{summary}')

        # Add attributes section if class likely has important attributes
        attributes = self._detect_class_attributes(class_info)
        if attributes:
            lines.append("")
            lines.append("    Attributes:")
            for attr in attributes:
                attr_desc = self._generate_attribute_description(attr, class_info.name)
                lines.append(f"        {attr}: {attr_desc}")

        # Add usage example for complex classes
        if len(class_info.methods) > 3:
            lines.append("")
            lines.append("    Example:")
            example = self._generate_class_example(class_info)
            for line in example:
                lines.append(f"        {line}")

        lines.append('    """')
        return "\n".join(lines)

    def generate_module_docstring(self, module_info: ModuleInfo) -> str:
        """Generate a docstring for a module."""
        lines = []

        # Generate module summary
        module_name = module_info.filepath.stem
        summary = self._generate_module_summary(module_name, module_info)
        lines.append(f'"""{summary}')

        # Add main components
        if module_info.classes or module_info.functions:
            lines.append("")
            lines.append("Main components:")

            for class_info in module_info.classes:
                class_desc = self._generate_class_summary(class_info)
                lines.append(f"    {class_info.name}: {class_desc}")

            for func_info in module_info.functions:
                if not func_info.name.startswith("_"):  # Skip private functions
                    func_desc = self._generate_function_summary(func_info)
                    lines.append(f"    {func_info.name}(): {func_desc}")

        lines.append('"""')
        return "\n".join(lines)

    def _generate_function_summary(self, func_info: FunctionInfo) -> str:
        """Generate a summary line for a function."""
        name = func_info.name

        # Rules for function summary generation
        function_summary_rules = [
            {"type": "prefix", "key": "get_", "template": "Get {noun}.", "slice": 4},
            {"type": "prefix", "key": "set_", "template": "Set {noun}.", "slice": 4},
            {"type": "prefix", "key": "create_", "template": "Create {noun}.", "slice": 7},
            {"type": "prefix", "key": "build_", "template": "Build {noun}.", "slice": 6},
            {"type": "prefix", "key": "init_", "template": "Initialize {target}.", "use_parent": True},
            {"type": "exact",  "key": "__init__", "template": "Initialize {target}.", "use_parent": True},
            {"type": "prefix", "key": "validate_", "template": "Validate {noun}.", "slice": 9},
            {"type": "prefix", "key": "process_", "template": "Process {noun}.", "slice": 8},
            {"type": "prefix", "key": "handle_", "template": "Handle {noun}.", "slice": 7},
            {"type": "prefix", "key": "parse_", "template": "Parse {noun}.", "slice": 6},
            {"type": "prefix", "key": "load_", "template": "Load {noun}.", "slice": 5},
            {"type": "prefix", "key": "save_", "template": "Save {noun}.", "slice": 5},
            {"type": "prefix", "key": "update_", "template": "Update {noun}.", "slice": 7},
            {"type": "prefix", "key": "delete_", "template": "Delete {noun}.", "slice": 7},
            {"type": "prefix", "key": "remove_", "template": "Delete {noun}.", "slice": 7},
            {"type": "prefix", "key": "is_", "template": "Check if {noun}.", "slice": 3},
            {"type": "prefix", "key": "has_", "template": "Check if {noun}.", "slice": 4},
            {"type": "prefix", "key": "can_", "template": "Check if can {noun}.", "slice": 4},
            {"type": "exact",  "key": "__str__", "template": "Return string representation."},
            {"type": "exact",  "key": "__repr__", "template": "Return detailed string representation."},
            {"type": "exact",  "key": "__call__", "template": "Make instance callable."},
        ]
        for rule in function_summary_rules:
            if rule["type"] == "prefix" and name.startswith(rule["key"]):
                if rule.get("use_parent"):
                    target = self._humanize_name(func_info.parent_class or 'instance')
                    return rule["template"].format(target=target)
                noun = self._humanize_name(name[rule["slice"]:])
                return rule["template"].format(noun=noun)
            if rule["type"] == "exact" and name == rule["key"]:
                if rule.get("use_parent"):
                    target = self._humanize_name(func_info.parent_class or 'instance')
                    return rule["template"].format(target=target)
                return rule["template"]
        if name.startswith("__") and name.endswith("__"):
            return f"Implement {name} magic method."
        return f"{self._humanize_name(name).capitalize()}."

    def _generate_class_summary(self, class_info: ClassInfo) -> str:
        """Generate a summary line for a class."""
        name = class_info.name

        # Rules for class summary generation
        class_summary_rules = [
            {"suffix": "Manager",       "length": 7,  "template": "Manages {noun} operations."},
            {"suffix": "Handler",       "length": 7,  "template": "Handles {noun} events."},
            {"suffix": "Controller",    "length": 10, "template": "Controls {noun} behavior."},
            {"suffix": "Service",       "length": 7,  "template": "Provides {noun} services."},
            {"suffix": "Factory",       "length": 7,  "template": "Creates {noun} instances."},
            {"suffix": "Builder",       "length": 7,  "template": "Builds {noun} objects."},
            {"suffix": "Parser",        "length": 6,  "template": "Parses {noun} data."},
            {"suffix": "Validator",     "length": 9,  "template": "Validates {noun} input."},
            {"suffix": "Exception",     "length": 9,  "template": "Exception for {noun} errors."},
            {"suffix": "Error",         "length": 5,  "template": "Exception for {noun} errors."},
            {"suffix": "Config",        "length": 6,  "template": "Configuration for {noun}."},
            {"suffix": "Configuration", "length": 13, "template": "Configuration for {noun}."},
            {"suffix": "Proto",         "length": 5,  "template": "Protocol defining {noun} interface."},
            {"suffix": "Protocol",      "length": 8,  "template": "Protocol defining {noun} interface."},
        ]
        for rule in class_summary_rules:
            if name.endswith(rule["suffix"]):
                noun = self._humanize_name(name[:-rule["length"]])
                return rule["template"].format(noun=noun)
        return f"{self._humanize_name(name)} implementation."

    def _generate_module_summary(self, module_name: str, module_info: ModuleInfo) -> str:
        """Generate a summary for a module."""
        humanized = self._humanize_name(module_name)

        if len(module_info.classes) > len(module_info.functions):
            return f"{humanized.capitalize()} classes and utilities."
        if len(module_info.functions) > 0:
            return f"{humanized.capitalize()} utility functions."
        return f"{humanized.capitalize()} module."

    def _humanize_name(self, name: str) -> str:
        """Convert snake_case or CamelCase to human readable form."""
        # Handle CamelCase
        name = re.sub(r"([A-Z])", r" \1", name).strip()
        # Handle snake_case
        name = name.replace("_", " ")
        # Clean up multiple spaces
        name = re.sub(r"\s+", " ", name)
        return name.lower()

    def _generate_arg_description(self, arg_name: str, func_name: str) -> str:
        """Generate description for a function argument."""
        # Common argument patterns
        if arg_name in ("data", "content"):
            return "The data to process"
        if arg_name in ("filename", "filepath", "path"):
            return "Path to the file"
        if arg_name in ("config", "configuration"):
            return "Configuration parameters"
        if arg_name in ("timeout", "delay"):
            return "Timeout in seconds"
        if arg_name in ("max_size", "limit", "max_length"):
            return "Maximum size or limit"
        if arg_name in ("callback", "handler"):
            return "Callback function to execute"
        if arg_name.endswith("_id") or arg_name == "id":
            return f"Unique identifier"
        if arg_name.endswith("_name") or arg_name == "name":
            return f"Name of the item"
        if arg_name in ("value", "val"):
            return "Value to process"
        return f"{self._humanize_name(arg_name).capitalize()}"

    def _generate_return_description(self, return_type: str, func_name: str) -> str:
        """Generate description for return value."""
        if return_type in ("bool", "Boolean"):
            return "True if successful, False otherwise"
        if return_type in ("str", "string", "String"):
            return "Processed string result"
        if return_type in ("int", "Integer"):
            return "Numeric result"
        if return_type in ("list", "List"):
            return "List of results"
        if return_type in ("dict", "Dict"):
            return "Dictionary containing results"
        if "Optional" in return_type:
            return "Result if successful, None otherwise"
        return f"{return_type} result"

    def _generate_exception_description(self, exc_name: str, func_name: str) -> str:
        """Generate description for potential exceptions."""
        if exc_name == "ValueError":
            return "If input values are invalid"
        if exc_name == "TypeError":
            return "If arguments are of wrong type"
        if exc_name == "KeyError":
            return "If required key is missing"
        if exc_name == "FileNotFoundError":
            return "If file cannot be found"
        if exc_name == "ConnectionError":
            return "If connection fails"
        if exc_name == "TimeoutError":
            return "If operation times out"
        return f"If {self._humanize_name(exc_name.replace('Error', '').replace('Exception', ''))} error occurs"

    def _generate_attribute_description(self, attr_name: str, class_name: str) -> str:
        """Generate description for class attributes."""
        return f"{self._humanize_name(attr_name).capitalize()} attribute"

    @staticmethod
    def _generate_class_example(class_info: ClassInfo) -> List[str]:
        """Generate usage example for a class."""
        class_name = class_info.name
        instance_name = class_name.lower()

        lines = [f"{instance_name} = {class_name}()", f"result = {instance_name}.method()"]
        return lines

    def _detect_potential_exceptions(self, func_info: FunctionInfo) -> List[str]:
        """Detect potential exceptions based on function patterns."""
        exceptions = []
        name = func_info.name

        if "validate" in name or any("validate" in arg for arg in func_info.args):
            exceptions.append("ValueError")

        if "file" in name or any("file" in arg for arg in func_info.args):
            exceptions.append("FileNotFoundError")

        if "connect" in name or "network" in name:
            exceptions.extend(["ConnectionError", "TimeoutError"])

        return exceptions

    def _detect_class_attributes(self, class_info: ClassInfo) -> List[str]:
        """Detect likely class attributes from method names."""
        attributes = []

        for method in class_info.methods:
            if method.name.startswith("get_") and len(method.args) <= 1:
                attr_name = method.name[4:]
                if attr_name not in attributes:
                    attributes.append(attr_name)

        return attributes[:5]  # Limit to 5 most likely attributes


class DocstringAnalyzer:
    """Analyzes Python files to find missing docstrings."""

    def __init__(self):
        """Initialize the analyzer."""
        self.generator = DocstringGenerator()

    def analyze_file(self, filepath: Path) -> ModuleInfo:
        """Analyze a Python file for missing docstrings."""
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()

            tree = ast.parse(content, filename=str(filepath))

            # Check for module docstring
            has_module_docstring = (
                len(tree.body) > 0
                and isinstance(tree.body[0], ast.Expr)
                and isinstance(tree.body[0].value, ast.Constant)
                and isinstance(tree.body[0].value.value, str)
            )

            classes = []
            functions = []
            imports = []

            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    class_info = self._analyze_class(node)
                    classes.append(class_info)
                elif isinstance(node, ast.FunctionDef) or isinstance(node, ast.AsyncFunctionDef):
                    if not self._is_nested_function(node, tree):
                        func_info = self._analyze_function(node)
                        functions.append(func_info)
                elif isinstance(node, (ast.Import, ast.ImportFrom)):
                    imports.append(ast.unparse(node))

            return ModuleInfo(
                filepath=filepath,
                classes=classes,
                functions=functions,
                imports=imports,
                has_module_docstring=has_module_docstring,
            )

        except Exception as e:
            print(f"Error analyzing {filepath}: {e}")
            return ModuleInfo(filepath, [], [], [], True)


class DocstringFixer:
    """Fixes missing docstrings by adding them to Python files."""

    def __init__(self, dry_run: bool = False, interactive: bool = False):
        """Initialize the fixer."""
        self.dry_run = dry_run
        self.interactive = interactive
        self.analyzer = DocstringAnalyzer()
        self.generator = DocstringGenerator()
        self.stats = {
            "files_processed": 0,
            "docstrings_added": 0,
            "functions_fixed": 0,
            "classes_fixed": 0,
            "modules_fixed": 0,
        }

    def fix_file(self, filepath: Path) -> bool:
        print(f"Processing {filepath}")
        try:
            content = self._read_file(filepath)
            module_info = self.analyzer.analyze_file(filepath)
            lines = content.splitlines()
            line_offset = 0
            changes_made = False

            # Add module docstring if needed
            module_changed, offset = self._add_module_docstring(module_info, filepath.stem, lines)
            changes_made |= module_changed
            line_offset += offset

            # Collect items without docstrings
            items = self._collect_undoc_items(module_info, lines, line_offset)

            # Process collected items
            items_changed, offset = self._process_items(items, lines, line_offset, module_info)
            changes_made |= items_changed
            line_offset += offset

            # Finalize: write or dry-run
            self._finalize_file(changes_made, filepath, lines)

            self.stats["files_processed"] += 1
            return changes_made
        except Exception as e:
            print(f"  Error processing {filepath}: {e}")
            return False

    def _read_file(self, filepath: Path) -> str:
        with open(filepath, "r", encoding="utf-8") as f:
            return f.read()

    def _add_module_docstring(self, module_info: ModuleInfo, name: str, lines: List[str]) -> (bool, int):
        if not module_info.has_module_docstring and (module_info.classes or module_info.functions):
            if self._should_add_docstring("module", name):
                docstring = self.generator.generate_module_docstring(module_info)
                lines.insert(0, docstring)
                lines.insert(1, "")
                self.stats["modules_fixed"] += 1
                self.stats["docstrings_added"] += 1
                return True, 2
        return False, 0

    def _collect_undoc_items(self, module_info: ModuleInfo, lines: List[str], offset: int):
        items = []
        for class_info in module_info.classes:
            if not self._has_docstring_at_line(lines, class_info.lineno + offset):
                items.append(("class", class_info))
            for method in class_info.methods:
                if not self._has_docstring_at_line(lines, method.lineno + offset):
                    items.append(("method", method))
        for func_info in module_info.functions:
            if not self._has_docstring_at_line(lines, func_info.lineno + offset):
                items.append(("function", func_info))
        items.sort(key=lambda x: x[1].lineno, reverse=True)
        return items

    def _process_items(self, items, lines: List[str], offset: int, module_info: ModuleInfo) -> (bool, int):
        changed = False
        added = 0
        for item_type, item_info in items:
            if self._should_add_docstring(item_type, item_info.name):
                docstring = self._generate_docstring(item_type, item_info, module_info)
                insert_line = item_info.lineno + offset
                # Insert after definition
                while insert_line < len(lines) and lines[insert_line - 1].strip().endswith(":"):
                    break
                lines.insert(insert_line, docstring)
                lines.insert(insert_line + 1, "")
                offset += 2
                added += 2
                changed = True
                key = "classes_fixed" if item_type == "class" else "functions_fixed"
                self.stats[key] += 1
                self.stats["docstrings_added"] += 1
        return changed, added

    def _finalize_file(self, changes_made: bool, filepath: Path, lines: List[str]) -> None:
        if changes_made:
            content = "\n".join(lines)
            if self.dry_run:
                print(f"  [DRY RUN] Would add {self.stats['docstrings_added']} docstrings")
            else:
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(content)
                print("  ✓ Added docstrings")
        else:
            print("  No missing docstrings found")

    def _has_docstring_at_line(self, lines: List[str], lineno: int) -> bool:
        """Check if there's already a docstring at the given line."""
        if lineno >= len(lines):
            return False

        for i in range(lineno, min(lineno + 5, len(lines))):
            line = lines[i].strip()
            if line.startswith('"""') or line.startswith("'''"):
                return True
            if line and not line.startswith("#"):
                break

        return False

    def _should_add_docstring(self, item_type: str, name: str) -> bool:
        """Check if we should add a docstring for this item."""
        if name.startswith("_") and not (name.startswith("__") and name.endswith("__")):
            return False
        if name.startswith("test_"):
            return False
        if self.interactive:
            response = input(f"Add docstring to {item_type} '{name}'? [y/N]: ")
            return response.lower() in ("y", "yes")
        return True

    def _generate_docstring(self, item_type: str, item_info: Any, module_info: ModuleInfo) -> str:
        """Generate appropriate docstring for the item."""
        if item_type == "class":
            return self.generator.generate_class_docstring(item_info)
        elif item_type in ("function", "method"):
            return self.generator.generate_function_docstring(item_info)
        elif item_type == "module":
            return self.generator.generate_module_docstring(module_info)
        else:
            return '    """TODO: Add description."""'

    def print_stats(self):
        """Print statistics about the fixing process."""
        print("\n" + "=" * 50)
        print("DOCSTRING FIXING STATISTICS")
        print("=" * 50)
        print(f"Files processed: {self.stats['files_processed']}")
        print(f"Total docstrings added: {self.stats['docstrings_added']}")
        print(f"  - Modules: {self.stats['modules_fixed']}")
        print(f"  - Classes: {self.stats['classes_fixed']}")
        print(f"  - Functions/Methods: {self.stats['functions_fixed']}")

        if self.dry_run:
            print("\n[DRY RUN] No changes were made to files.")
        else:
            print("\n✓ All changes have been applied!")


def find_all_python_files() -> List[Path]:
    files = []
    for root, dirs, filenames in os.walk("."):
        dirs[:] = [d for d in dirs if d not in {".git", "__pycache__", ".pytest_cache", "node_modules", ".venv", "venv", "build", "dist"}]
        for file in filenames:
            if file.endswith(".py"):
                files.append(Path(root) / file)
    return files


def find_glob_files(pattern: str) -> List[Path]:
    matched = [Path(f) for f in glob.glob(pattern, recursive=True)]
    return [f for f in matched if f.suffix == ".py"]


def get_files_to_process(args) -> List[Path]:
    if args.fix_all:
        return find_all_python_files()
    if args.files:
        return find_glob_files(args.files)
    return []


def main():
    """Main entry point for the docstring fixer."""
    parser = argparse.ArgumentParser(
        description="Automatically add missing docstrings to Python files",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python scripts/add_missing_docstrings.py --dry-run --fix-all
  python scripts/add_missing_docstrings.py --files "utils/*.py"
  python scripts/add_missing_docstrings.py --interactive --files "core/*.py"
        """,
    )

    parser.add_argument(
        "--dry-run", action="store_true", help="Show what would be changed without making changes"
    )
    parser.add_argument("--files", type=str, help="Process only files matching pattern (glob)")
    parser.add_argument(
        "--fix-all", action="store_true", help="Process all Python files in the project"
    )
    parser.add_argument(
        "--interactive", action="store_true", help="Ask for confirmation before each change"
    )
    parser.add_argument("--templates", type=str, help="Use custom template directory")

    args = parser.parse_args()
    if not args.files and not args.fix_all:
        print("Error: Must specify --files PATTERN or --fix-all")
        parser.print_help()
        return 1

    files_to_process = get_files_to_process(args)
    if not files_to_process:
        print("No Python files found to process.")
        return 1

    print(f"Found {len(files_to_process)} Python files to process.")
    if args.dry_run:
        print("[DRY RUN MODE] No files will be modified.")

    fixer = DocstringFixer(dry_run=args.dry_run, interactive=args.interactive)
    for filepath in files_to_process:
        fixer.fix_file(filepath)

    fixer.print_stats()
    return 0


if __name__ == "__main__":
    sys.exit(main())
