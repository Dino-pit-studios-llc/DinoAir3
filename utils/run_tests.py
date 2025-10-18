#!/usr/bin/env python3
"""
Test runner script for the utils package.
Provides convenient commands for running tests with different options.
"""

import shlex
import sys
from pathlib import Path

from utils.process import safe_run


def run_command(cmd):
    """Run a command and return the result."""
    try:
        # Security: Expect cmd to be a list, not a string
        if not isinstance(cmd, list):
            raise TypeError("Command must be a list, not a string")

        result = safe_run(
            cmd,
            allowed_binaries={Path(sys.executable).name, "python", PYTHON_EXE},
            timeout=900,
            check=False,
            text=True,
        )
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)


def run_tests(args=None):
    """Run pytest with given arguments."""
    cmd = ["python", "-m", "pytest"]
    if args:
        # Security: Split args properly and extend the list
        if isinstance(args, str):
            cmd.extend(shlex.split(args))
        elif isinstance(args, list):
            cmd.extend(args)
        else:
            raise TypeError("args must be a string or list")

    success, _, _ = run_command(cmd)

    return success


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        return

    command = sys.argv[1]

    if command == "all":
        success = run_tests()
    elif command == "unit":
        success = run_tests("-m unit")
    elif command == "coverage":
        success = run_tests("--cov=utils --cov-report=term-missing --cov-report=html")
    elif command == "verbose":
        success = run_tests("-v")
    elif command in [
        "logger",
        "config_loader",
        "error_handling",
        "performance_monitor",
        "dependency_container",
        "artifact_encryption",
    ]:
        success = run_tests(f"tests/test_{command}.py -v")
    else:
        return

    if success:
        pass
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
