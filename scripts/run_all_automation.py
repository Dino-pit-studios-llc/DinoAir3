#!/usr/bin/env python3
"""
Master Automation Runner

Runs all automation scripts in sequence with validation.
Provides a single entry point for fixing all automated issues.

Usage:
    python scripts/run_all_automation.py [--dry-run] [--skip-tests]
"""

import argparse
import subprocess
import sys
import time
from pathlib import Path


def run_script(script_name: str, args: list, description: str) -> bool:
    """Run a script and return success status."""
    print("\n" + "=" * 70)
    print(f"Running: {description}")
    print("=" * 70)

    cmd = [sys.executable, script_name] + args

    try:
        # Safe: sys.executable is Python interpreter, script_name and args are controlled
        result = subprocess.run(cmd, check=False)  # nosec B603
        success = result.returncode == 0

        if success:
            print(f"\n✅ {description} completed successfully")
        else:
            print(f"\n❌ {description} failed with exit code {result.returncode}")

        return success

    except Exception as e:
        print(f"\n❌ Error running {description}: {e}")
        return False


def run_tests() -> bool:
    """Run test suite to verify changes."""
    print("\n" + "=" * 70)
    print("Running Tests")
    print("=" * 70)

    try:
        # Try pytest first
        # Safe: hardcoded pytest command, no user input, development environment only
        result = subprocess.run(["pytest", "--tb=short"], check=False)  # nosec B603 B607
        if result.returncode == 0:
            print("\n✅ All tests passed")
            return True
        print("\n⚠️  Some tests failed")
        return False
    except FileNotFoundError:
        print("\n⚠️  pytest not found, skipping tests")
        return True


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Run all automation scripts")
    parser.add_argument(
        "--dry-run", action="store_true", help="Run in dry-run mode (no changes made)"
    )
    parser.add_argument(
        "--skip-tests", action="store_true", help="Skip running tests after automation"
    )
    parser.add_argument(
        "--scripts-dir",
        type=Path,
        default=Path(__file__).parent,
        help="Directory containing automation scripts",
    )

    args = parser.parse_args()

    scripts_dir = args.scripts_dir.resolve()

    print("=" * 70)
    print("AUTOMATED CODE QUALITY FIXES")
    print("=" * 70)
    print(f"Scripts directory: {scripts_dir}")
    print(f"Mode: {'DRY RUN' if args.dry_run else 'APPLY CHANGES'}")
    print(f"Tests: {'DISABLED' if args.skip_tests else 'ENABLED'}")
    print("=" * 70)

    if args.dry_run:
        print("\n⚠️  DRY RUN MODE - No files will be modified")
        print("Remove --dry-run flag to apply changes")
    else:
        print("\n⚠️  THIS WILL MODIFY FILES")
        print("Make sure you have committed your changes to git!")
        response = input("\nContinue? (yes/no): ")
        if response.lower() not in ["yes", "y"]:
            print("Aborted.")
            sys.exit(0)

    start_time = time.time()
    results = {}

    # List of scripts to run
    scripts = [
        {
            "name": "fix_powershell_writehost.py",
            "description": "PowerShell Write-Host Fixer (~1000 issues)",
            "expected_fixes": 1000,
        },
        {
            "name": "fix_naming_conventions.py",
            "description": "Python Naming Conventions Fixer (~82 issues)",
            "expected_fixes": 82,
        },
    ]

    # Run each script
    script_args = ["--dry-run"] if args.dry_run else []

    for script in scripts:
        script_path = scripts_dir / script["name"]

        if not script_path.exists():
            print(f"\n⚠️  Script not found: {script_path}")
            results[script["name"]] = False
            continue

        success = run_script(str(script_path), script_args, script["description"])
        results[script["name"]] = success

        if not success and not args.dry_run:
            print(f"\n❌ {script['name']} failed. Stopping automation.")
            break

    # Run tests if not skipped and not dry-run
    if not args.skip_tests and not args.dry_run:
        test_success = run_tests()
        results["tests"] = test_success

        if not test_success:
            print("\n⚠️  Tests failed after automation.")
            print("Review the changes and restore from backups if needed:")
            print("  Get-ChildItem -Recurse -Filter '*.bak'")

    # Print summary
    elapsed_time = time.time() - start_time

    print("\n" + "=" * 70)
    print("AUTOMATION SUMMARY")
    print("=" * 70)

    successful = sum(1 for v in results.values() if v)
    total = len(results)

    print(f"Scripts run:      {total}")
    print(f"Successful:       {successful}")
    print(f"Failed:           {total - successful}")
    print(f"Time elapsed:     {elapsed_time:.1f}s")

    if args.dry_run:
        print("\nMode:             DRY RUN (no changes made)")
        print("\nTo apply changes, run:")
        print("  python scripts/run_all_automation.py")
    else:
        print("\nMode:             CHANGES APPLIED")

        if successful == total:
            print("\n✅ All automation completed successfully!")
            print("\nNext steps:")
            print("1. Review the changes: git diff")
            print("2. Run full test suite: pytest")
            print("3. Commit changes: git add . && git commit -m 'Apply automated fixes'")
            print("4. Proceed to Phase 1: Fix critical issues")
        else:
            print("\n⚠️  Some automation failed")
            print("\nReview errors above and check:")
            print("1. Backup files (*.bak)")
            print("2. Error messages")
            print("3. File permissions")

    print("=" * 70)

    # Exit with appropriate code
    sys.exit(0 if successful == total else 1)


if __name__ == "__main__":
    main()
