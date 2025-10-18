#!/usr/bin/env python3
"""
Local Coverage Runner

Run tests with coverage locally and generate reports.
"""

import sys
from pathlib import Path

from utils.process import safe_run

try:
    from defusedxml import (
        ElementTree as ET,  # Use defusedxml to prevent XXE/entity expansion vulnerabilities
    )
except ImportError as e:
    raise ImportError(
        "defusedxml is required; install with: pip install defusedxml"
    ) from e


def main():
    """Run coverage locally."""
    print("🧪 Running tests with coverage...")

    # Ensure we're in the project root
    project_root = Path(__file__).parent
    print(f"📂 Project root: {project_root}")

    try:
        # Run tests with coverage using pytest configuration
        cmd = [
            sys.executable,
            "-m",
            "pytest",
            "tests/",
            "-v",
        ]

        print(f"🚀 Running command: {' '.join(cmd)}")
        result = safe_run(
            cmd,
            allowed_binaries={Path(sys.executable).name, "python", PYTHON_EXE},
            cwd=project_root,
            timeout=900,
            check=False,
        )

        if result.returncode == 0:
            print("✅ Tests completed successfully")
        else:
            print("⚠️  Some tests failed or no tests found")

        # Check if coverage file was created
        coverage_xml = project_root / "coverage.xml"
        coverage_html = project_root / "htmlcov" / "index.html"

        if coverage_xml.exists():
            print(f"✅ Coverage XML report generated: {coverage_xml}")

            # Show some basic coverage info
            try:
                # XML parsing uses defusedxml (imported at module level) to prevent XXE/entity expansion
                tree = ET.parse(coverage_xml)
                root = tree.getroot()
                line_rate = root.get("line-rate", "unknown")
                branch_rate = root.get("branch-rate", "unknown")
                print(f"📊 Line coverage: {float(line_rate) * 100:.1f}%")
                print(f"📊 Branch coverage: {float(branch_rate) * 100:.1f}%")
            except Exception as e:
                print(f"⚠️  Could not parse coverage data: {e}")
        else:
            print("❌ No coverage XML report generated")

        if coverage_html.exists():
            print(f"📊 HTML report available: {coverage_html}")
        else:
            print("❌ No HTML coverage report generated")

        return result.returncode

    except FileNotFoundError:
        print("❌ pytest not found. Installing...")
        safe_run(
            [sys.executable, "-m", "pip", "install", "pytest", "pytest-cov"],
            allowed_binaries={Path(sys.executable).name, "python", PYTHON_EXE},
            timeout=300,
            check=False,
        )
        return main()


if __name__ == "__main__":
    sys.exit(main())
