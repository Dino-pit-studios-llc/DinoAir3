#!/usr/bin/env python3
"""
SonarQube CI Setup Verification Script

This script checks if SonarQube CI integration is properly configured.
"""

import subprocess
import sys
from pathlib import Path


def check_file_exists(filepath: str, description: str) -> bool:
    """Check if a required file exists."""
    if Path(filepath).exists():
        print(f"✅ {description}: {filepath}")
        return True
    print(f"❌ {description}: {filepath} (missing)")
    return False


def check_sonar_properties() -> bool:
    """Check SonarQube properties configuration."""
    sonar_file = "sonar-project.properties"
    if not Path(sonar_file).exists():
        print(f"❌ SonarQube configuration: {sonar_file} (missing)")
        return False

    with open(sonar_file) as f:
        content = f.read()

    required_keys = [
        "sonar.projectKey",
        "sonar.organization",
        "sonar.sources",
        "sonar.python.coverage.reportPaths",
    ]

    missing_keys = []
    for key in required_keys:
        if key not in content:
            missing_keys.append(key)

    if missing_keys:
        print(f"❌ SonarQube configuration: Missing keys: {missing_keys}")
        return False
    print(f"✅ SonarQube configuration: {sonar_file}")
    return True


def check_github_workflows() -> bool:
    """Check GitHub Actions workflows."""
    workflows = [
        (".github/workflows/ci.yml", "Main CI workflow"),
        (".github/workflows/sonarcloud.yml", "SonarCloud workflow"),
    ]

    all_exist = True
    for filepath, description in workflows:
        if not check_file_exists(filepath, description):
            all_exist = False
        else:
            # Check if workflow contains SonarQube steps
            with open(filepath) as f:
                content = f.read()
            if "sonar" in content.lower():
                print("   ✅ Contains SonarQube integration")
            else:
                print("   ⚠️  No SonarQube integration found")

    return all_exist


def check_python_dependencies() -> bool:
    """Check if required Python packages are available."""
    required_packages = [("pytest", "pytest"), ("pytest-cov", "pytest-cov"), ("bandit", "bandit")]

    missing_packages = []
    for package, import_name in required_packages:
        try:
            subprocess.run(  # nosec B603
                [sys.executable, "-c", f"import {import_name}"], check=True, capture_output=True
            )
            print(f"✅ Python package: {package}")
        except subprocess.CalledProcessError:
            print(f"❌ Python package: {package} (not installed)")
            missing_packages.append(package)

    if missing_packages:
        print("\n📦 Install missing packages:")
        print(f"   pip install {' '.join(missing_packages)}")
        return False

    return True


def check_environment_variables() -> bool:
    """Check environment setup."""
    print("\n🔍 Environment Check:")

    # Check if we're in the right directory
    if not Path("sonar-project.properties").exists():
        print("❌ Not in project root directory (no sonar-project.properties found)")
        return False

    print("✅ Project root directory detected")

    # Check Python version
    python_version = sys.version_info
    if python_version >= (3, 8):
        print(f"✅ Python version: {python_version.major}.{python_version.minor}")
    else:
        print(f"⚠️  Python version: {python_version.major}.{python_version.minor} (3.8+ recommended)")

    return True


def generate_test_coverage() -> bool:
    """Generate test coverage for SonarQube."""
    print("\n🧪 Generating test coverage...")

    try:
        # Run pytest with coverage
        result = subprocess.run(  # nosec B603
            [
                sys.executable,
                "-m",
                "pytest",
                "--cov=.",
                "--cov-report=xml",
                "--cov-report=term-missing",
                "--junitxml=test-results.xml",
            ],
            capture_output=True,
            text=True,
        )

        if result.returncode == 0:
            print("✅ Test coverage generated successfully")
            if Path("coverage.xml").exists():
                print("✅ coverage.xml created")
            if Path("test-results.xml").exists():
                print("✅ test-results.xml created")
            return True

        print(f"❌ Test execution failed: {result.stderr}")
        return False

    except FileNotFoundError:
        print("❌ pytest not found - install with: pip install pytest pytest-cov")
        return False


def main():
    """Main verification function."""
    print("🔍 SonarQube CI Setup Verification")
    print("=" * 50)

    checks = [
        ("Environment", check_environment_variables),
        ("SonarQube Properties", check_sonar_properties),
        ("GitHub Workflows", check_github_workflows),
        ("Python Dependencies", check_python_dependencies),
        ("Test Coverage", generate_test_coverage),
    ]

    passed = 0
    total = len(checks)

    for check_name, check_func in checks:
        print(f"\n📋 {check_name}:")
        if check_func():
            passed += 1
        else:
            print(f"   ❌ {check_name} check failed")

    print("\n" + "=" * 50)
    print(f"📊 Results: {passed}/{total} checks passed")

    if passed == total:
        print("🎉 SonarQube CI setup is ready!")
        print("\n📝 Next steps:")
        print("1. Add SONAR_TOKEN to GitHub repository secrets")
        print("2. Push changes to trigger SonarCloud analysis")
        print("3. Check results at: https://sonarcloud.io/project/overview?id=Dino-pit-studios-llc_DinoAir3")
    else:
        print("⚠️  Some configuration issues need to be resolved")
        print("📖 See docs/SONARQUBE_CI_SETUP.md for detailed setup instructions")

    return passed == total


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
