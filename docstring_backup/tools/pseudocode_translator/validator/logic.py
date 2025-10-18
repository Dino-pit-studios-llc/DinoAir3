"""
Logic validation module for Python code.

This module handles logic validation, runtime risk detection,
and validation of code semantics beyond syntax.
"""

import ast
from typing import TYPE_CHECKING

from ..ast_cache import parse_cached
from .constants import get_builtin_names
from .result import ValidationResult
from .runtime_checkers import RuntimeRiskChecker
from .type_checkers import TypeConsistencyChecker
from .variable_trackers import UndefinedVariableChecker

if TYPE_CHECKING:
    from .scope import Scope


class LogicValidator:
    """Handles logic validation and runtime risk analysis."""

    def __init__(self, config):
        """Initialize with translator configuration."""
        self.config = config
        self.check_undefined = config.check_undefined_vars

    def validate_logic(self, code: str) -> ValidationResult:
        """
        Validate code logic and potential runtime issues.

        Args:
            code: Python code to validate

        Returns:
            ValidationResult with logic validation details
        """
        # Parse using helper
        tree, parse_error_result = LogicValidator(self.config)._try_parse_tree_for_logic(code)
        if parse_error_result is not None:
            return parse_error_result

        result = ValidationResult(is_valid=True)

        # At this point, parsing succeeded; tree must be non-None
        if tree is None:
            raise AssertionError("Tree must not be None")

        # Collect logic issues
        logic_issues = self._collect_logic_issues(tree)
        for issue in logic_issues:
            result.add_warning(issue)

        # Check for potential runtime errors
        runtime_risks = LogicValidator._check_runtime_risks(tree)
        for risk in runtime_risks:
            result.add_warning(f"Potential runtime error: {risk}")

        return result

    @staticmethod
    def _try_parse_tree_for_logic(
        code: str,
    ) -> tuple[ast.AST | None, ValidationResult | None]:
        """Parse tree for logic validation with error handling."""
        try:
            tree = parse_cached(code)
            return tree, None
        except SyntaxError:
            result = ValidationResult(is_valid=False)
            result.add_error("Cannot validate logic: syntax errors present")
            return None, result
        except Exception as e:
            result = ValidationResult(is_valid=False)
            result.add_error(f"Cannot validate logic: parsing failed ({e})")
            return None, result

    def _collect_logic_issues(self, tree: ast.AST) -> list[str]:
        """Collect various logic-related issues."""
        issues = []

        # Check undefined variables if enabled
        if self.check_undefined:
            undefined_issues = self._check_undefined_names(tree)
            issues.extend(undefined_issues)

        # Basic type consistency checks
        issues.extend(LogicValidator._check_basic_type_consistency(tree))

        # Other logic checks
        issues.extend(self._find_unreachable_code(tree))
        issues.extend(self._find_unused_variables(tree))
        issues.extend(self._detect_infinite_loops(tree))
        issues.extend(self._check_missing_returns(tree))

        return issues

    def _check_undefined_names(self, tree: ast.AST) -> list[str]:
        """Check for undefined variable names (instance method wrapper)."""
        return LogicValidator.check_undefined_names(tree)

    @staticmethod
    def check_undefined_names(tree: ast.AST) -> list[str]:
        """Check for undefined variable names."""
        checker = UndefinedVariableChecker()
        checker.visit(tree)

        # Check for star imports that prevent reliable checking
        module_scope = LogicValidator._get_module_scope(checker.current_scope)
        if LogicValidator._has_star_import(module_scope):
            return ["Star import prevents reliable undefined-name checking"]

        # Process undefined names
        return LogicValidator._process_undefined_names(
            checker.undefined_names, checker.defined_names
        )

    @staticmethod
    def _get_module_scope(current_scope: "Scope") -> "Scope":
        """Discover the module scope by walking parent chain."""
        module_scope = current_scope
        while module_scope.parent is not None:
            module_scope = module_scope.parent
        return module_scope

    @staticmethod
    def _has_star_import(module_scope: "Scope") -> bool:
        """Check if module has star import present."""
        return getattr(module_scope, "star_import_present", False)

    @staticmethod
    def _process_undefined_names(undefined_names: list, defined_names: set) -> list[str]:
        """Process undefined names and generate issue messages."""
        builtin_names = get_builtin_names()
        normalized = LogicValidator._normalize_undefined_names(undefined_names)
        unique_items = LogicValidator._filter_and_deduplicate(normalized, builtin_names)
        return LogicValidator._generate_undefined_issues(unique_items, defined_names)

    @staticmethod
    def _normalize_undefined_names(
        undefined_names: list,
    ) -> list[tuple[str, int, int | None]]:
        """Normalize undefined name tuples to consistent (name, line, col) format."""
        normalized = []
        for tup in undefined_names:
            if len(tup) == 2:
                name, line = tup
                col = None
            else:
                name, line, col = tup
            normalized.append((name, line, col))
        return normalized

    @staticmethod
    def _filter_and_deduplicate(
        normalized: list[tuple[str, int, int | None]], builtin_names: set
    ) -> list[tuple[str, int, int | None]]:
        """Filter out builtins and deduplicate undefined names."""
        seen = set()
        for name, line, col in normalized:
            if LogicValidator._should_keep_undefined_name(name, builtin_names):
                key = (name, line, col)
                if key not in seen:
                    seen.add(key)

        # Sort by (line, name)
        return sorted(seen, key=lambda x: (x[1], x[0]))

    @staticmethod
    def _should_keep_undefined_name(name: str, builtin_names: set) -> bool:
        """Check if undefined name should be kept (not a builtin)."""
        return name not in builtin_names

    @staticmethod
    def _generate_undefined_issues(
        sorted_items: list[tuple[str, int, int | None]], defined_names: set
    ) -> list[str]:
        """Generate issue messages for undefined variables."""
        issues = []
        for name, line, col in sorted_items:
            issue_msg = LogicValidator._format_undefined_issue(name, line, col, defined_names)
            issues.append(issue_msg)
        return issues

    @staticmethod
    def _format_undefined_issue(name: str, line: int, col: int | None, defined_names: set) -> str:
        """Format a single undefined variable issue message."""
        similar = LogicValidator._find_similar_name(name, defined_names)
        loc = LogicValidator._format_location(line, col)

        if similar:
            return f"Undefined variable '{name}' at {loc}. Did you mean '{similar}'?"
        return f"Undefined variable '{name}' at {loc}"

    @staticmethod
    def _format_location(line: int, col: int | None) -> str:
        """Format location string with line and optional column."""
        base = f"line {line}"
        return base if col is None else f"{base}, col {col}"

    @staticmethod
    def _find_similar_name(target: str, candidates: set) -> str | None:
        """Find similar variable names for suggestions."""
        for candidate in candidates:
            if LogicValidator._is_similar_name(target, candidate):
                return candidate
        return None

    @staticmethod
    def _is_similar_name(name1: str, name2: str) -> bool:
        """Check if two names are similar (for typo suggestions)."""
        if abs(len(name1) - len(name2)) > 2:
            return False

        if len(name1) == len(name2):
            return LogicValidator._check_same_length_similarity(name1, name2)

        return LogicValidator._check_different_length_similarity(name1, name2)

    @staticmethod
    def _check_same_length_similarity(name1: str, name2: str) -> bool:
        """Check similarity for names of same length (single char substitution)."""
        diff_count = sum(c1 != c2 for c1, c2 in zip(name1, name2, strict=False))
        return diff_count <= 1

    @staticmethod
    def _check_different_length_similarity(name1: str, name2: str) -> bool:
        """Check similarity for names of different length (single char insertion/deletion)."""
        shorter, longer = (name1, name2) if len(name1) < len(name2) else (name2, name1)
        return any(longer[:i] + longer[i + 1 :] == shorter for i in range(len(longer)))

    @staticmethod
    def _check_basic_type_consistency(tree: ast.AST) -> list[str]:
        """Check for basic type consistency issues."""
        checker = TypeConsistencyChecker()
        checker.visit(tree)
        return checker.issues

    @staticmethod
    def _check_runtime_risks(tree: ast.AST) -> list[str]:
        """Check for potential runtime errors."""
        checker = RuntimeRiskChecker()
        checker.visit(tree)
        return checker.risks

    @staticmethod
    def _find_unreachable_code(tree: ast.AST) -> list[str]:
        """Find unreachable code after return statements."""

        class UnreachableCodeFinder(ast.NodeVisitor):
            """Detects and reports unreachable code after return statements.
            Traverses function definitions and records statements that occur after a return.
            """

            def __init__(self):
                self.issues = []

            def visit_FunctionDef(self, node: ast.FunctionDef):
                found_return = False
                for stmt in node.body:
                    if found_return and not isinstance(stmt, ast.Pass):
                        self.issues.append(f"Unreachable code after return at line {stmt.lineno}")
                        break
                    if isinstance(stmt, ast.Return):
                        found_return = True
                self.generic_visit(node)

        finder = UnreachableCodeFinder()
        finder.visit(tree)
        return finder.issues

    @staticmethod
    def _find_unused_variables(tree: ast.AST) -> list[str]:
        """Find variables that are assigned but never used."""

        class UnusedVariableFinder(ast.NodeVisitor):
            """Visitor that tracks assigned variables and identifies unused ones in the AST."""

            def __init__(self):
                self.assigned = set()
                self.used = set()
                self.issues = []

            def visit_Assign(self, node: ast.Assign):
                for target in node.targets:
                    if isinstance(target, ast.Name):
                        self.assigned.add(target.id)
                self.generic_visit(node)

            def visit_Name(self, node: ast.Name):
                if isinstance(node.ctx, ast.Load):
                    self.used.add(node.id)

        finder = UnusedVariableFinder()
        finder.visit(tree)

        unused = finder.assigned - finder.used - {"_"}  # Exclude underscore convention
        return [f"Unused variable: {var}" for var in sorted(unused)]

    @staticmethod
    def _detect_infinite_loops(tree: ast.AST) -> list[str]:
        """Detect potential infinite loops."""

        class InfiniteLoopDetector(ast.NodeVisitor):
            """AST NodeVisitor that detects potential infinite loops by finding while True loops without break statements."""

            def __init__(self):
                self.issues = []

            def visit_While(self, node: ast.While):
                # Check for simple infinite loops
                if isinstance(node.test, ast.Constant) and node.test.value is True:
                    # Check if there's a break statement
                    has_break = any(isinstance(stmt, ast.Break) for stmt in ast.walk(node))
                    if not has_break:
                        self.issues.append(f"Potential infinite loop at line {node.lineno}")
                self.generic_visit(node)

        detector = InfiniteLoopDetector()
        detector.visit(tree)
        return detector.issues

    def _check_missing_returns(self, tree: ast.AST) -> list[str]:
        """Check for functions missing return statements."""

        class MissingReturnChecker(ast.NodeVisitor):
            """Visitor that checks function definitions for missing return statements."""

            def __init__(self):
                self.issues = []

            def visit_FunctionDef(self, node: ast.FunctionDef):
                if not node.body:
                    return

                # Check if function has any return statements
                has_return = any(isinstance(stmt, ast.Return) for stmt in ast.walk(node))

                # Skip if function name suggests it doesn't return anything
                if not has_return and not node.name.startswith(
                    ("print", "show", "display", "save", "write")
                ):
                    self.issues.append(
                        f"Function '{node.name}' at line {node.lineno} may be missing return statement"
                    )

                self.generic_visit(node)

        checker = MissingReturnChecker()
        checker.visit(tree)
        return checker.issues
