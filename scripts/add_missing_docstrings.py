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
from typing import Any


@dataclass
class FunctionInfo:
    """Information about a function or method."""

    name: str
    lineno: int
    col_offset: int
    args: list[str]
    return_type: str | None
    is_async: bool
    is_method: bool
    is_property: bool
    is_classmethod: bool
    is_staticmethod: bool
    decorators: list[str]
    parent_class: str | None = None


@dataclass
class ClassInfo:
    """Information about a class."""

    name: str
    lineno: int
    col_offset: int
    bases: list[str]
    decorators: list[str]
    methods: list[FunctionInfo]
    properties: list[str]


@dataclass
class ModuleInfo:
    """Information about a module."""

    filepath: Path
    classes: list[ClassInfo]
    functions: list[FunctionInfo]
    imports: list[str]
    has_module_docstring: bool


class DocstringGenerator:
    """Generates appropriate docstring templates based on code analysis."""

    def __init__(self, templates_dir: Path | None = None):
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
        if func_info.args and not (len(func_info.args) == 1 and func_info.args[0] in ("self", "cls")):
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
                if not func_info.name.startswith("_"):
                    func_desc = self._generate_function_summary(func_info)
                    lines.append(f"    {func_info.name}(): {func_desc}")
        lines.append('"""')
        return "\n".join(lines)

    def _generate_function_summary(self, func_info: FunctionInfo) -> str:
        """Generate a summary line for a function."""
        name = func_info.name
        # Common patterns for function names
        if name.startswith("get_"):
            return f"Get {self._humanize_name(name[4:])}."
        elif name.startswith("set_"):
            return f"Set {self._humanize_name(name[4:])}."
        elif name.startswith("create_"):
            return f"Create {self._humanize_name(name[7:])}."
        elif name.startswith("build_"):
            return f"Build {self._humanize_name(name[6:])}."
        elif name.startswith("init_") or name == "__init__":
            return f"Initialize {self._humanize_name(func_info.parent_class or 'instance')}."
        elif name.startswith("validate_"):
            return f"Validate {self._humanize_name(name[9:])}."
        elif name.startswith("process_"):
            return f"Process {self._humanize_name(name[8:])}."
        elif name.startswith("handle_"):
            return f"Handle {self._humanize_name(name[7:])}."
        elif name.startswith("parse_"):
            return f"Parse {self._humanize_name(name[6:])}."
        elif name.startswith("load_"):
            return f"Load {self._humanize_name(name[5:])}."
        elif name.startswith("save_"):
            return f"Save {self._humanize_name(name[5:])}."
        elif name.startswith("update_"):
            return f"Update {self._humanize_name(name[7:])}."
        elif name.startswith("delete_") or name.startswith("remove_"):
            prefix_len = 7 if name.startswith("delete_") else 7
            return f"Delete {self._humanize_name(name[prefix_len:])}."
        elif name.startswith("is_") or name.startswith("has_"):
            prefix_len = 3 if name.startswith("is_") else 4
            return f"Check if {self._humanize_name(name[prefix_len:])}."
        elif name.startswith("can_"):
            return f"Check if can {self._humanize_name(name[4:])}."
        elif name == "__str__":
            return "Return string representation."
        elif name == "__repr__":
            return "Return detailed string representation."
        elif name == "__call__":
            return "Make instance callable."
        elif name.startswith("__") and name.endswith("__"):
            return f"Implement {name} magic method."
        else:
            return f"{self._humanize_name(name).capitalize()}."

    def _generate_class_summary(self, class_info: ClassInfo) -> str:
        """Generate a summary line for a class."""
        name = class_info.name
        # Common patterns for class names
        if name.endswith("Manager"):
            return f"Manages {self._humanize_name(name[:-7])} operations."
        elif name.endswith("Handler"):
            return f"Handles {self._humanize_name(name[:-7])} events."
        elif name.endswith("Controller"):
            return f"Controls {self._humanize_name(name[:-10])} behavior."
        elif name.endswith("Service"):
            return f"Provides {self._humanize_name(name[:-7])} services."
        elif name.endswith("Factory"):
            return f"Creates {self._humanize_name(name[:-7])} instances."
        elif name.endswith("Builder"):
            return f"Builds {self._humanize_name(name[:-7])} objects."
        elif name.endswith("Parser"):
            return f"Parses {self._humanize_name(name[:-6])} data."
        elif name.endswith("Validator"):
            return f"Validates {self._humanize_name(name[:-9])} input."
        elif name.endswith("Exception") or name.endswith("Error"):
            return (
                f"Exception for {self._humanize_name(name[:-9] if name.endswith('Exception') else name[:-5])} errors."
            )
        elif name.endswith("Config") or name.endswith("Configuration"):
            suffix_len = 6 if name.endswith("Config") else 13
            return f"Configuration for {self._humanize_name(name[:-suffix_len])}."
        elif name.endswith("Proto") or name.endswith("Protocol"):
            suffix_len = 5 if name.endswith("Proto") else 8
            return f"Protocol defining {self._humanize_name(name[:-suffix_len])} interface."
        else:
            return f"{self._humanize_name(name)} implementation."

    def _generate_module_summary(self, module_name: str, module_info: ModuleInfo) -> str:
        """Generate a summary for a module."""
        humanized = self._humanize_name(module_name)
        if len(module_info.classes) > len(module_info.functions):
            return f"{humanized.capitalize()} classes and utilities."
        elif len(module_info.functions) > 0:
            return f"{humanized.capitalize()} utility functions."
        else:
            return f"{humanized.capitalize()} module."

    def _humanize_name(self, name: str) -> str:
        """Convert snake_case or CamelCase to human readable form."""
        name = re.sub(r"([A-Z])", r" \1", name).strip()
        name = name.replace("_", " ")
        name = re.sub(r"\s+", " ", name)
        return name.lower()

    def _generate_arg_description(self, arg_name: str, func_name: str) -> str:
        """Generate description for a function argument."""
        if arg_name in ("data", "content"):
            return "The data to process"
        elif arg_name in ("filename", "filepath", "path"):
            return "Path to the file"
        elif arg_name in ("config", "configuration"):
            return "Configuration parameters"
        elif arg_name in ("timeout", "delay"):
            return "Timeout in seconds"
        elif arg_name in ("max_size", "limit", "max_length"):
            return "Maximum size or limit"
        elif arg_name in ("callback", "handler"):
            return "Callback function to execute"
        elif arg_name.endswith("_id") or arg_name == "id":
            return "Unique identifier"
        elif arg_name.endswith("_name") or arg_name == "name":
            return "Name of the item"
        elif arg_name in ("value", "val"):
            return "Value to process"
        else:
            return f"{self._humanize_name(arg_name).capitalize()}"

    def _generate_return_description(self, return_type: str, func_name: str) -> str:
        """Generate description for return value."""
        if return_type in ("bool", "Boolean"):
            return "True if successful, False otherwise"
        elif return_type in ("str", "string", "String"):
            return "Processed string result"
        elif return_type in ("int", "Integer"):
            return "Numeric result"
        elif return_type in ("list", "List"):
            return "List of results"
        elif return_type in ("dict", "Dict"):
            return "Dictionary containing results"
        elif "Optional" in return_type:
            return "Result if successful, None otherwise"
        else:
            return f"{return_type} result"

    def _generate_exception_description(self, exc_name: str, func_name: str) -> str:
        """Generate description for potential exceptions."""
        if exc_name == "ValueError":
            return "If input values are invalid"
        elif exc_name == "TypeError":
            return "If arguments are of wrong type"
        elif exc_name == "KeyError":
            return "If required key is missing"
        elif exc_name == "FileNotFoundError":
            return "If file cannot be found"
        elif exc_name == "ConnectionError":
            return "If connection fails"
        elif exc_name == "TimeoutError":
            return "If operation times out"
        else:
            return f"If {self._humanize_name(exc_name.replace('Error', '').replace('Exception', ''))} error occurs"

    def _generate_attribute_description(self, attr_name: str, class_name: str) -> str:
        """Generate description for class attributes."""
        return f"{self._humanize_name(attr_name).capitalize()} attribute"

    @staticmethod
    def _generate_class_example(class_info: ClassInfo) -> list[str]:
        """Generate usage example for a class."""
        class_name = class_info.name
        instance_name = class_name.lower()
        lines = [f"{instance_name} = {class_name}()", f"result = {instance_name}.method()"]
        return lines

    @staticmethod
    def _detect_potential_exceptions(func_info: FunctionInfo) -> list[str]:
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

    @staticmethod
    def _detect_class_attributes(class_info: ClassInfo) -> list[str]:
        """Detect likely class attributes from method names."""
        attributes = []
        for method in class_info.methods:
            if method.name.startswith("get_") and len(method.args) <= 1:
                attr_name = method.name[4:]
                if attr_name not in attributes:
                    attributes.append(attr_name)
        return attributes[:5]


class DocstringAnalyzer:
    """Analyzes Python files to find missing docstrings."""

    def __init__(self):
        """Initialize the analyzer."""
        self.generator = DocstringGenerator()

    def analyze_file(self, filepath: Path) -> ModuleInfo:
        """Analyze a Python file for missing docstrings."""
        try:
            with open(filepath, encoding="utf-8") as f:
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

    def _analyze_class(self, class_node: ast.ClassDef) -> ClassInfo:
        """Analyze a class definition."""
        methods = []
        properties = []
        for node in class_node.body:
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                method_info = self._analyze_function(node, parent_class=class_node.name)
                methods.append(method_info)
                if any(isinstance(d, ast.Name) and d.id == "property" for d in node.decorator_list):
                    properties.append(node.name)
        bases = [ast.unparse(base) for base in class_node.bases]
        decorators = [ast.unparse(d) for d in class_node.decorator_list]
        return ClassInfo(
            name=class_node.name,
            lineno=class_node.lineno,
            col_offset=class_node.col_offset,
            bases=bases,
            decorators=decorators,
            methods=methods,
            properties=properties,
        )


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
        """Fix missing docstrings in a single file."""
        print(f"Processing {filepath}")

        try:
            with open(filepath, encoding="utf-8") as f:
                original_content = f.read()

            tree = ast.parse(original_content, filename=str(filepath))
            module_info = self.analyzer.analyze_file(filepath)

            # Track line adjustments as we add docstrings
            line_offset = 0
            lines = original_content.splitlines()
            changes_made = False

            # Add module docstring if missing
            if not module_info.has_module_docstring and (module_info.classes or module_info.functions):
                if self._should_add_docstring("module", filepath.stem):
                    module_docstring = self.generator.generate_module_docstring(module_info)
                    lines.insert(0, module_docstring)
                    lines.insert(1, "")  # Add blank line after module docstring
                    line_offset += 2
                    changes_made = True
                    self.stats["modules_fixed"] += 1
                    self.stats["docstrings_added"] += 1

            # Process classes and functions in reverse order (bottom to top)
            # to maintain correct line numbers
            all_items = []

            for class_info in module_info.classes:
                if not self._has_docstring_at_line(lines, class_info.lineno + line_offset):
                    all_items.append(("class", class_info))

                for method in class_info.methods:
                    if not self._has_docstring_at_line(lines, method.lineno + line_offset):
                        all_items.append(("method", method))

            for func_info in module_info.functions:
                if not self._has_docstring_at_line(lines, func_info.lineno + line_offset):
                    all_items.append(("function", func_info))

            # Sort by line number in reverse order
            all_items.sort(key=lambda x: x[1].lineno, reverse=True)

            for item_type, item_info in all_items:
                if self._should_add_docstring(item_type, item_info.name):
                    docstring = self._generate_docstring(item_type, item_info, module_info)
                    insert_line = item_info.lineno + line_offset

                    # Find the correct position to insert docstring
                    # (after the function/class definition line)
                    while insert_line < len(lines) and lines[insert_line - 1].strip().endswith(":"):
                        break

                    # Insert docstring
                    lines.insert(insert_line, docstring)
                    lines.insert(insert_line + 1, "")  # Add blank line
                    line_offset += 2
                    changes_made = True

                    if item_type == "class":
                        self.stats["classes_fixed"] += 1
                    else:
                        self.stats["functions_fixed"] += 1
                    self.stats["docstrings_added"] += 1

            if changes_made:
                new_content = "\n".join(lines)

                if self.dry_run:
                    print(f"  [DRY RUN] Would add {self.stats['docstrings_added']} docstrings")
                else:
                    with open(filepath, "w", encoding="utf-8") as f:
                        f.write(new_content)
                    print("  ✓ Added docstrings")
            else:
                print("  No missing docstrings found")

            self.stats["files_processed"] += 1
            return changes_made

        except Exception as e:
            print(f"  Error processing {filepath}: {e}")
            return False

    @staticmethod
    def _has_docstring_at_line(lines: list[str], lineno: int) -> bool:
        """Check if there's already a docstring at the given line."""
        if lineno >= len(lines):
            return False

        # Look for docstring in the next few lines after the definition
        for i in range(lineno, min(lineno + 5, len(lines))):
            line = lines[i].strip()
            if line.startswith('"""') or line.startswith("'''"):
                return True
            if line and not line.startswith("#"):
                # Found non-comment, non-docstring code
                break

        return False

    def _should_add_docstring(self, item_type: str, name: str) -> bool:
        """Check if we should add a docstring for this item."""
        # Skip private functions/methods (but not __init__, __str__, etc.)
        if name.startswith("_") and not (name.startswith("__") and name.endswith("__")):
            return False

        # Skip test functions
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
            return '    """TODO: Add description.""'

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

    parser.add_argument("--dry-run", action="store_true", help="Show what would be changed without making changes")
    parser.add_argument("--files", type=str, help="Process only files matching pattern (glob)")
    parser.add_argument("--fix-all", action="store_true", help="Process all Python files in the project")
    parser.add_argument("--interactive", action="store_true", help="Ask for confirmation before each change")
    parser.add_argument("--templates", type=str, help="Use custom template directory")

    args = parser.parse_args()

    if not args.files and not args.fix_all:
        print("Error: Must specify --files PATTERN or --fix-all")
        parser.print_help()
        return 1

    # Find files to process
    files_to_process = []

    if args.fix_all:
        # Find all Python files in the project
        for root, dirs, files in os.walk("."):
            # Skip common non-source directories
            dirs[:] = [
                d
                for d in dirs
                if d
                not in {
                    ".git",
                    "__pycache__",
                    ".pytest_cache",
                    "node_modules",
                    ".venv",
                    "venv",
                    "build",
                    "dist",
                }
            ]

            for file in files:
                if file.endswith(".py"):
                    filepath = Path(root) / file
                    files_to_process.append(filepath)

    elif args.files:
        # Use glob pattern
        files_to_process = [Path(f) for f in glob.glob(args.files, recursive=True)]
        files_to_process = [f for f in files_to_process if f.suffix == ".py"]

    if not files_to_process:
        print("No Python files found to process.")
        return 1

    print(f"Found {len(files_to_process)} Python files to process.")

    if args.dry_run:
        print("[DRY RUN MODE] No files will be modified.")

    # Create fixer and process files
    fixer = DocstringFixer(dry_run=args.dry_run, interactive=args.interactive)

    for filepath in files_to_process:
        fixer.fix_file(filepath)

    fixer.print_stats()
    return 0


if __name__ == "__main__":
    sys.exit(main())
