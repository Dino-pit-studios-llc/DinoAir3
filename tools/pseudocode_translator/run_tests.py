#!/usr/bin/env python3
"""
Test runner script for pseudocode_translator

This script provides a convenient way to run all tests with various options.
"""

import argparse
import re
import sys
from pathlib import Path

from utils.process import safe_run
from .environment import change_to_project_dir, configure_environment
from .quality import run_quality_checks
from .test_args import add_quality_args

# Safe expression handling for pytest filters (-k / -m)
_SAFE_EXPR = re.compile(r"^[A-Za-z0-9_.:,* -]+$")


def _is_safe_expr(val: str | None) -> bool:
    """Allow only a constrained set of characters for pytest -k/-m filters."""
    return bool(val) and bool(_SAFE_EXPR.fullmatch(val))


def build_pytest_cmd(args):
    cmd = [sys.executable, "-m", "pytest"]
    verbosity_map = {
        "very_verbose": "-vv",
        "verbose": "-v",
        "quiet": "-q",
    }
    for attr, flag in verbosity_map.items():
        if getattr(args, attr):
            cmd.append(flag)
            break
    if args.exitfirst:
        cmd.append("-x")
    if args.keyword and _is_safe_expr(args.keyword):
        cmd.extend(["-k", args.keyword])
    elif args.keyword:
        print("⚠️  Ignoring unsafe -k expression; allowed: [A-Za-z0-9_-. :,*]")
    return cmd


def run_command(cmd, cwd=None, timeout: int = 900):
    """Run a command with hardened execution and return the exit code."""
    allowed = {Path(sys.executable).name, "python", PYTHON_EXE}
    try:
        proc = safe_run(
            cmd,
            allowed_binaries=allowed,
            cwd=cwd,
            timeout=timeout,
            check=False,
            text=True,
        )
        return proc.returncode
    except Exception as e:
        # Surface failure without exposing full command args (may contain secrets/paths)
        print(f"❌ Command failed: {cmd[0]} ({e})")
        return 1


def add_test_selection_args(parser):
    """Add arguments for selecting specific tests or directories to run."""
    parser.add_argument(
        "tests",
        nargs="*",
        default=["tests"],
        help="Specific test files or directories to run (default: all tests)",
    )


def add_test_options_args(parser):
    """Add standard test options like verbosity, exit on first failure, keyword and mark filtering."""
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")
    parser.add_argument("-vv", "--very-verbose", action="store_true", help="Very verbose output")
    parser.add_argument("-q", "--quiet", action="store_true", help="Quiet output")
    parser.add_argument("-x", "--exitfirst", action="store_true", help="Exit on first failure")
    parser.add_argument(
        "-k",
        "--keyword",
        metavar="EXPRESSION",
        help="Only run tests matching the expression",
    )
    parser.add_argument(
        "-m",
        "--mark",
        metavar="MARKEXPR",
        help="Only run tests matching given mark expression",
    )


def add_coverage_args(parser):
    """Add coverage-related arguments to the parser for coverage analysis and reporting."""
    parser.add_argument(
        "--cov", "--coverage", action="store_true", help="Run with coverage analysis"
    )
    parser.add_argument(
        "--cov-report",
        choices=["term", "html", "xml", "json"],
        default="term",
        help="Coverage report format (default: term)",
    )
    parser.add_argument("--cov-html", action="store_true", help="Generate HTML coverage report")


def add_performance_args(parser):
    """Add performance testing arguments for parallel test execution and benchmarks."""
    parser.add_argument(
        "-n",
        "--numprocesses",
        type=int,
        metavar="NUM",
        help="Number of processes to use for parallel testing",
    )
    parser.add_argument("--benchmark", action="store_true", help="Run benchmark tests")


def add_general_args(parser):
    """Add general test and collection options to the parser."""
    parser.add_argument("--pdb", action="store_true", help="Drop into debugger on failures")
    parser.add_argument(
        "--lf",
        "--last-failed",
        action="store_true",
        dest="last_failed",
        help="Rerun only the tests that failed last time",
    )
    parser.add_argument(
        "--ff",
        "--failed-first",
        action="store_true",
        dest="failed_first",
        help="Run all tests but run failed tests first",
    )
    parser.add_argument("--markers", action="store_true", help="Show available markers")
    parser.add_argument("--fixtures", action="store_true", help="Show available fixtures")


def run_post_quality_format_check(args):
    if args.all_checks or args.format:
        return run_command(
            [
                sys.executable,
                "-m",
                "ruff",
                "format",
                "--check",
                ".",
            ]
        )
    return None


def run_pytest_based_on_args(args):
    cmd = build_pytest_cmd(args)
    if args.mark and _is_safe_expr(args.mark):
        cmd.extend(["-m", args.mark])
    elif args.mark:
        print("⚠️  Ignoring unsafe -m expression; allowed: [A-Za-z0-9_-. :,*]")
    if args.pdb:
        cmd.append("--pdb")
    if args.last_failed:
        cmd.append("--lf")
    if args.failed_first:
        cmd.append("--ff")
    if args.markers:
        cmd.append("--markers")
        return run_command(cmd)
    if args.fixtures:
        cmd.append("--fixtures")
        return run_command(cmd)
    if args.collect_only:
        cmd.append("--collect-only")
        return run_command(cmd)
    return run_command(cmd)


def main():
    """Parse command-line arguments, configure the test environment, and execute the test runner."""
    parser = argparse.ArgumentParser(description="Run tests for pseudocode_translator")
    add_test_selection_args(parser)
    add_test_options_args(parser)
    add_coverage_args(parser)
    add_performance_args(parser)
    add_general_args(parser)
    add_quality_args(parser)

    args = parser.parse_args()

    # Auto environment setup for local runs
    configure_environment()
    change_to_project_dir()

    # Track exit codes
    exit_codes = run_quality_checks(args)

    format_exit = run_post_quality_format_check(args)
    if format_exit is not None:
        exit_codes.append(format_exit)

    pytest_exit = run_pytest_based_on_args(args)
    exit_codes.append(pytest_exit)
    return max(exit_codes) if exit_codes else 0


if __name__ == "__main__":
    sys.exit(main())
