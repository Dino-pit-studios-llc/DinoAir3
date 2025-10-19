#!/usr/bin/env python3
"""
Check for dependency conflicts between global and virtual environment installations.

This script compares packages installed globally vs in the venv and identifies:
- Version mismatches
- Packages installed globally that might interfere
- Missing packages in venv
"""

import subprocess
import sys
from pathlib import Path


def get_pip_list(python_path: str) -> dict[str, str]:
    """Get list of installed packages from a Python installation."""
    result = subprocess.run(
        [python_path, "-m", "pip", "list", "--format=json"],
        capture_output=True,
        text=True,
        check=False,
    )

    if result.returncode != 0:
        return {}

    import json

    packages = json.loads(result.stdout)
    return {pkg["name"].lower(): pkg["version"] for pkg in packages}


def main():
    """Check for dependency conflicts."""
    venv_python = Path(__file__).parent / ".venv" / "Scripts" / "python.exe"

    if not venv_python.exists():
        print("❌ Virtual environment not found!")
        print(f"   Expected: {venv_python}")
        return 1

    print("🔍 Checking for dependency conflicts...\n")

    # Get global packages
    print("📦 Scanning global Python packages...")
    global_packages = get_pip_list("python")

    # Get venv packages
    print("📦 Scanning venv packages...")
    venv_packages = get_pip_list(str(venv_python))

    if not global_packages or not venv_packages:
        print("❌ Failed to retrieve package lists")
        return 1

    print(f"\n✅ Found {len(global_packages)} global packages")
    print(f"✅ Found {len(venv_packages)} venv packages\n")

    # Find conflicts
    conflicts = []
    for pkg, global_version in global_packages.items():
        if pkg in venv_packages:
            venv_version = venv_packages[pkg]
            if global_version != venv_version:
                conflicts.append((pkg, global_version, venv_version))

    # Check critical packages
    critical_packages = {"pytest", "ruff", "fastapi", "httpx", "aiofiles", "pydantic", "starlette", "anyio", "coverage"}

    print("=" * 70)
    print("📊 DEPENDENCY ANALYSIS")
    print("=" * 70)

    # Show version conflicts
    if conflicts:
        print(f"\n⚠️  VERSION MISMATCHES ({len(conflicts)}):")
        print("-" * 70)
        for pkg, global_ver, venv_ver in sorted(conflicts):
            is_critical = pkg in critical_packages
            marker = "🔴" if is_critical else "⚪"
            print(f"{marker} {pkg:25} Global: {global_ver:15} venv: {venv_ver}")
    else:
        print("\n✅ No version conflicts detected!")

    # Show critical packages status
    print(f"\n🎯 CRITICAL PACKAGES STATUS:")
    print("-" * 70)
    for pkg in sorted(critical_packages):
        if pkg in venv_packages:
            print(f"✅ {pkg:25} {venv_packages[pkg]:15} (in venv)")
        elif pkg in global_packages:
            print(f"⚠️  {pkg:25} {global_packages[pkg]:15} (global only - should be in venv!)")
        else:
            print(f"❌ {pkg:25} NOT INSTALLED")

    # Show packages only in global
    global_only = set(global_packages.keys()) - set(venv_packages.keys())
    if global_only:
        print(f"\n📌 Packages in global but not in venv ({len(global_only)}):")
        print("   (This is normal - venv should be isolated)")
        # Show only first 10 to avoid clutter
        for pkg in sorted(global_only)[:10]:
            print(f"   • {pkg}")
        if len(global_only) > 10:
            print(f"   ... and {len(global_only) - 10} more")

    print("\n" + "=" * 70)
    print("💡 RECOMMENDATION:")
    print("=" * 70)
    if conflicts or any(pkg not in venv_packages for pkg in critical_packages):
        print("⚠️  Some issues detected. Make sure to:")
        print("   1. Always activate venv before installing packages")
        print("   2. Use: .venv\\Scripts\\python.exe -m pip install <package>")
        print("   3. Avoid using global 'pip install' for project dependencies")
    else:
        print("✅ Your virtual environment is properly isolated!")
        print("   Keep using the venv for all project work.")

    print("\n🔧 To activate venv:")
    print("   PowerShell: .\\activate_venv.ps1")
    print("   Or: .\\.venv\\Scripts\\Activate.ps1")

    return 0


if __name__ == "__main__":
    sys.exit(main())
