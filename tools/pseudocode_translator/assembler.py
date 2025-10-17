"""
Code Assembler module for the Pseudocode Translator

This module handles the intelligent assembly of code blocks into cohesive
Python scripts, including import organization, function merging, and
consistency checks.
"""

from __future__ import annotations

import ast
import logging
from typing import TYPE_CHECKING, TypedDict

from .ast_cache import parse_cached
from .exceptions import AssemblyError
from .models import BlockType, CodeBlock

if TYPE_CHECKING:
    from collections.abc import Iterator

    from .config import TranslatorConfig

logger = logging.getLogger(__name__)

# Formatting invariants
SECTION_JOIN = "\n\n\n"
DEDENT_KEYWORDS = ("else:", "elif ", "except:", "except ", "finally:", "case ")
GLOBALS_CONSTANTS_HEADER = "# Constants"
GLOBALS_VARIABLES_HEADER = "# Global variables"
CONSTANT_ASSIGNMENT_PATTERN = r"^[A-Z_]+\s*="
IMPORT_GROUPS = ("standard", "third_party", "local")


class CodeSections(TypedDict):
    """
    Type definition for organized code sections returned by _organize_code_sections.

    Attributes:
        module_docstring: Optional module-level docstring
        functions: List of function definition code strings
        classes: List of class definition code strings
        globals: List of global variable assignment code strings
        main: List of main execution code strings
    """

    module_docstring: str | None
    functions: list[str]
    classes: list[str]
    globals: list[str]
    main: list[str]


class CodeAssembler:
    """
    Intelligently combines code segments into complete Python scripts.

    This class handles the assembly of parsed code blocks into cohesive Python
    scripts with proper import organization, function merging, and consistency
    checks. It maintains code structure while ensuring valid Python syntax.
    """

    def __init__(self, config: TranslatorConfig) -> None:
        """
        Initialize the Code Assembler.

        Args:
            config: Translator configuration object containing assembly preferences
                   including indentation, line length, and import behavior.
        """
        self.config: TranslatorConfig = config
        self.indent_size: int = config.indent_size
        self.max_line_length: int = config.max_line_length
        self.preserve_comments: bool = config.preserve_comments
        self.preserve_docstrings: bool = config.preserve_docstrings
        self.auto_import_common: bool = config.auto_import_common

        # Common imports that might be auto-added
        self.common_imports: dict[str, list[str]] = {
            "math": ["sin", "cos", "sqrt", "pi", "tan", "log", "exp"],
            "os": ["path", "getcwd", "listdir", "mkdir", "remove"],
            "sys": ["argv", "exit", "path", "platform"],
            "datetime": ["datetime", "date", "time", "timedelta"],
            "json": ["dumps", "loads", "dump", "load"],
            "re": ["match", "search", "findall", "sub", "compile"],
            "typing": ["List", "Dict", "Tuple", "Optional", "Union", "Any"],
        }

    def assemble(self, blocks: list[CodeBlock]) -> str:
        """
        Assemble code blocks into complete executable Python code.

        Args:
            blocks: List of processed code blocks to assemble into complete Python code.

        Returns:
            Complete assembled Python code as a string, ready for execution.
            Returns empty string if no valid Python blocks are provided.

        Raises:
            AssemblyError: If any step of the assembly process fails.
        """
        # Guard invalid inputs early
        if not blocks:
            return ""

        logger.info("Assembling %d code blocks", len(blocks))

        try:
            # Extract → normalize → collect imports → stitch → postprocess
            python_blocks = CodeAssembler._extract_sections(blocks)
            if not python_blocks:
                # Prior behavior: warn (already logged) and return empty string
                return ""

            imports_section = self._collect_imports(python_blocks)
            main_code_sections = self._normalize_sections(python_blocks)
            assembled_code = self._stitch_sections(main_code_sections, imports_section)
            final_code = self._postprocess_output(assembled_code)

            logger.info("Code assembly complete")
            return final_code

        except Exception as e:
            error = AssemblyError(
                "Failed to assemble code blocks",
                blocks_info=[
                    {"type": b.type.value, "lines": b.line_numbers} for b in blocks
                ],
                assembly_stage="assembly",
                cause=e,
            )
            error.add_suggestion("Check block compatibility")
            error.add_suggestion("Verify all blocks contain valid Python syntax")
            raise error from e

    def assemble_streaming(self, block_iterator: Iterator[CodeBlock]) -> str:
        """
        Assemble code from a streaming iterator of blocks.

        Args:
            block_iterator: Iterator yielding CodeBlock objects to be assembled.

        Returns:
            Complete assembled Python code as a string.

        Raises:
            AssemblyError: If assembly of collected blocks fails.
        """
        # Collect blocks from iterator
        blocks = list(block_iterator)
        # Use regular assemble method
        return self.assemble(blocks)

    @staticmethod
    def _extract_sections(blocks: list[CodeBlock]) -> list[CodeBlock]:
        """
        Filter input to only Python blocks with proper logging.

        Args:
            blocks: List of code blocks to filter for Python content.

        Returns:
            List of Python code blocks, excluding other block types.
        """
        python_blocks = [
            block
            for block in blocks
            if block.type in (BlockType.PYTHON, BlockType.MIXED)
        ]

        if not python_blocks:
            logger.warning("No Python blocks found in input")
        else:
            logger.debug(
                "Found %d Python blocks out of %d total",
                len(python_blocks),
                len(blocks),
            )

        return python_blocks

    def _collect_imports(self, python_blocks: list[CodeBlock]) -> str:
        """
        Collect and organize import statements from code blocks.

        Args:
            python_blocks: List of Python code blocks to extract imports from.

        Returns:
            Organized import section as a string.
        """
        imports: dict[str, set[str]] = {
            "standard": set(),
            "third_party": set(),
            "local": set(),
        }
        from_imports: dict[str, dict[str, set[str]]] = {
            "standard": {},
            "third_party": {},
            "local": {},
        }

        # Extract imports from blocks
        for block in python_blocks:
            self._extract_imports_from_block(block, imports, from_imports)

        # Auto-add common imports if enabled
        if self.auto_import_common:
            self._add_common_imports(python_blocks, imports, from_imports)

        # Build import section
        return CodeAssembler._build_import_section(self, imports, from_imports)

    def _normalize_sections(self, python_blocks: list[CodeBlock]) -> CodeSections:
        """
        Organize code blocks into logical sections.

        Args:
            python_blocks: List of Python code blocks to organize into sections.

        Returns:
            Organized code sections with proper structure and typing.

        Raises:
            AssemblyError: If code section organization fails.
        """
        try:
            return self._organize_code_sections(python_blocks)
        except Exception as e:
            error = AssemblyError(
                "Failed to organize code sections", assembly_stage="sections", cause=e
            )
            error.add_suggestion("Check code block structure")
            error.add_suggestion("Ensure valid Python syntax in all blocks")
            raise error from e

    def _stitch_sections(self, sections: CodeSections, imports_section: str) -> str:
        """
        Combine organized sections into final code string.

        Args:
            sections: Organized code sections with proper structure.
            imports_section: Formatted import statements.

        Returns:
            Complete assembled code as a string.

        Raises:
            AssemblyError: If any step of the stitching process fails.
        """
        try:
            # Merge functions and classes
            merged_functions, merged_classes = self._merge_definitions(
                sections["functions"], sections["classes"]
            )

            # Organize global variables and constants
            globals_section = CodeAssembler._organize_globals(sections["globals"])

            # Organize main execution code
            main_section = self._organize_main_code(sections["main"])

            # Assemble final code
            module_docstring = sections.get("module_docstring")
            sections_list = CodeAssembler._collect_final_sections(
                module_docstring,
                imports_section,
                globals_section,
                merged_functions,
                merged_classes,
                main_section,
            )
            return CodeAssembler._join_sections(sections_list)

        except Exception as e:
            error = AssemblyError(
                "Failed to stitch code sections", assembly_stage="stitching", cause=e
            )
            error.add_suggestion("Check for naming conflicts")
            error.add_suggestion("Ensure function/class definitions are valid")
            raise error from e

    def _postprocess_output(self, code: str) -> str:
        """
        Apply final formatting and consistency checks.

        Args:
            code: Assembled code requiring final processing.

        Returns:
            Final processed code with consistent formatting.

        Raises:
            AssemblyError: If consistency checks or cleanup fails.
        """
        try:
            final_code = self._ensure_consistency(code)
            return self._final_cleanup(final_code)
        except Exception as e:
            logger.error("Consistency check failed: %s", str(e))
            raise AssemblyError("Consistency or cleanup failed") from e

    # === Helper Methods ===

    def _organize_code_sections(self, blocks: list[CodeBlock]) -> CodeSections:
        """
        Organize code into sections (functions, classes, globals, main).

        Args:
            blocks: List of Python code blocks to organize into logical sections.

        Returns:
            Dictionary with categorized code sections, properly typed as CodeSections.
        """
        sections: CodeSections = {
            "module_docstring": None,
            "functions": [],
            "classes": [],
            "globals": [],
            "main": [],
        }

        for block in blocks:
            try:
                tree = parse_cached(block.content)
                if isinstance(tree, ast.Module):
                    CodeAssembler._maybe_set_module_docstring(tree, sections)
                    # Categorize each top-level node
                    for node in tree.body:
                        self._categorize_node(node, block, tree, sections)
            except SyntaxError:
                CodeAssembler._record_block_syntax_failure(block, sections)

        return sections

    def _merge_definitions(
        self, functions: list[str], classes: list[str]
    ) -> tuple[str, str]:
        """
        Merge function and class definitions, handling duplicates.

        Args:
            functions: List of function code strings to merge.
            classes: List of class code strings to merge.

        Returns:
            Tuple of (merged_functions, merged_classes) as strings.
        """
        merged_functions = self._merge_functions(functions)
        merged_classes = self._merge_classes(classes)
        return merged_functions, merged_classes

    @staticmethod
    def _collect_final_sections(
        module_doc: str | None,
        imports_section: str,
        globals_section: str,
        merged_functions: str,
        merged_classes: str,
        main_section: str,
    ) -> list[str]:
        """
        Build list of non-empty sections in proper order.

        Returns:
            List of section strings in order: module docstring, imports, globals, functions, classes, main.
        """
        final_sections: list[str] = []
        if isinstance(module_doc, str) and module_doc:
            final_sections.append(module_doc)
        if imports_section:
            final_sections.append(imports_section)
        if globals_section:
            final_sections.append(globals_section)
        if merged_functions:
            final_sections.append(merged_functions)
        if merged_classes:
            final_sections.append(merged_classes)
        if main_section:
            final_sections.append(main_section)
        return final_sections

    @staticmethod
    def _join_sections(sections: list[str]) -> str:
        """Join sections using the module-level SECTION_JOIN."""
        return SECTION_JOIN.join(sections)

    # === Import Handling ===

    @staticmethod
    def _extract_imports_from_block(
        block: CodeBlock,
        imports: dict[str, set[str]],
        from_imports: dict[str, dict[str, set[str]]],
    ) -> None:
        """Extract import statements from a code block."""
        try:
            tree = parse_cached(block.content)
            if isinstance(tree, ast.Module):
                for node in ast.walk(tree):
                    CodeAssembler._process_import_node(node, imports, from_imports)
        except SyntaxError:
            logger.warning("Could not parse imports from block: %s", block.line_numbers)

    @staticmethod
    def _process_import_node(
        node: ast.AST,
        imports: dict[str, set[str]],
        from_imports: dict[str, dict[str, set[str]]],
    ) -> None:
        """Process a single import node and add to appropriate collection"""
        if isinstance(node, ast.Import):
            CodeAssembler._add_direct_imports(node, imports)
        elif isinstance(node, ast.ImportFrom):
            CodeAssembler._add_from_imports(node, from_imports)

    @staticmethod
    def _add_direct_imports(node: ast.Import, imports: dict[str, set[str]]) -> None:
        """Add direct import statements to imports collection"""
        for alias in node.names:
            category = CodeAssembler._categorize_import(alias.name)
            imports[category].add(f"import {alias.name}")

    @staticmethod
    def _add_from_imports(
        node: ast.ImportFrom, from_imports: dict[str, dict[str, set[str]]]
    ) -> None:
        """Add from-import statements to from_imports collection"""
        module = node.module or ""
        category = CodeAssembler._categorize_import(module)
        if module not in from_imports[category]:
            from_imports[category][module] = set()
        for alias in node.names:
            from_imports[category][module].add(alias.name)

    @staticmethod
    def _categorize_import(module_name: str) -> str:
        """
        Categorize an import into standard, third_party, or local.

        Args:
            module_name: Name of the module to categorize.

        Returns:
            Category string: 'standard', 'third_party', or 'local'.
        """
        # Expanded standard library modules for better categorization
        standard_lib = {
            "abc",
            "argparse",
            "array",
            "ast",
            "asyncio",
            "base64",
            "bisect",
            "builtins",
            "calendar",
            "collections",
            "configparser",
            "contextlib",
            "copy",
            "csv",
            "dataclasses",
            "datetime",
            "decimal",
            "difflib",
            "enum",
            "functools",
            "glob",
            "gzip",
            "hashlib",
            "heapq",
            "html",
            "http",
            "io",
            "itertools",
            "json",
            "logging",
            "math",
            "multiprocessing",
            "operator",
            "os",
            "pathlib",
            "pickle",
            "platform",
            "random",
            "re",
            "shutil",
            "socket",
            "sqlite3",
            "statistics",
            "string",
            "subprocess",
            "sys",
            "tempfile",
            "threading",
            "time",
            "typing",
            "urllib",
            "uuid",
            "warnings",
            "weakref",
            "xml",
            "zipfile",
        }

        # Get top-level module name
        top_level = module_name.split(".")[0]

        if top_level in standard_lib:
            return "standard"
        if module_name.startswith(".") or not module_name:
            return "local"
        return "third_party"
