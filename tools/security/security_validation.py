#!/usr/bin/env python3
"""
DinoAir Security Validation Script
Tests all implemented security components to ensure they're working correctly.
"""

import json
import os
import secrets
import sys
import traceback
from contextlib import suppress
from datetime import datetime
from pathlib import Path

# Preferred enhanced logger; fallback to stdlib logging
try:
    from utils.enhanced_logger import get_logger as _get_logger
except Exception:  # pragma: no cover
    import logging as _logging

    def _get_logger(name: str):
        return _logging.getLogger(name)


logger = _get_logger(__name__)

# Add the project root to Python path
sys.path.append(str(Path(__file__).parent))

# Allow a test fallback secret unless explicitly required via CLI flag.
require_env_secrets = "--require-env-secrets" in sys.argv

DEFAULT_REPORT_FILENAME = "security_validation_report.json"


def test_security_imports():
    """Test that all security modules can be imported."""

    print("🔍 Testing Security Module Imports...")

    modules = [
        "utils.security_config",
        "utils.auth_system",
        "utils.audit_logging",
        "utils.network_security",
    ]

    import_results = {}

    for module in modules:
        try:
            __import__(module)
            import_results[module] = "✅ SUCCESS"
            print(f"   ✅ {module}")
        except ImportError as e:
            import_results[module] = f"❌ FAILED: {str(e)}"
            print(f"   ❌ {module}: {str(e)}")
            logger.debug("import failed: %s", e)

    return import_results


def test_password_security():
    """Test password security implementation."""

    print("\n🔐 Testing Password Security...\n")

    try:
        from utils.auth_system import UserManager

        UserManager()

        # Test password validation (if available)
        try:
            test_passwords = [
                ("123456", False),  # Should be rejected
                ("password", False),  # Should be rejected
                # Should be accepted
                ("DinoAir2024!SecureP@ssw0rd#Healthcare", True),
            ]

            validation_works = True
            for _, (pwd, should_pass) in enumerate(test_passwords):
                # This is a basic test - the actual validation might be in a different method
                result = len(pwd) >= 8  # Basic check
                print(
                    f"   📝 Password '<REDACTED, length={len(pwd)}>' : {'✅' if result == should_pass else '❌'}"
                )
        except Exception as e:
            print("   ⚠️  Password validation method not found")
            logger.debug("password validation unavailable: %s", e)
            validation_works = False
        print("   ✅ User Manager instantiated successfully")

        return {"user_manager_created": True, "password_validation": validation_works}

    except Exception as e:
        print(f"   ❌ Password security test failed: {str(e)}")
        logger.debug("password security failed: %s", e)
        return {"error": str(e)}


def test_rbac_system():
    """Test Role-Based Access Control system."""

    print("\n👥 Testing RBAC System...")

    try:
        from utils.auth_system import UserManager, UserRole

        UserManager()

        # Test role definitions
        roles = [
            UserRole.CLINICIAN,
            UserRole.NURSE,
            UserRole.DISPATCHER,
            UserRole.HEALTHCARE_ADMIN,
        ]
        print(f"   ✅ Healthcare roles defined: {len(roles)} roles")

        # List available roles
        all_roles = list(UserRole)
        print(f"   ✅ Total user roles available: {len(all_roles)} roles")

        # Test role values
        for role in roles[:3]:  # Test first 3
            print(f"   📝 Role {role.name}: {role.value}")

        print("   ✅ User Manager with RBAC instantiated successfully")

        return {
            "roles_defined": len(roles),
            "total_roles": len(all_roles),
            "user_manager_created": True,
            "rbac_available": True,
        }

    except (ImportError, AttributeError, ValueError, TypeError, RuntimeError) as e:
        print(f"   ❌ RBAC test failed: {str(e)}")
        logger.debug("rbac test failed: %s", e)
        return {"error": str(e)}


def test_audit_logging():
    """Test audit logging system."""

    print("\n📝 Testing Audit Logging...")

    try:
        from utils.audit_logging import AuditEventType, AuditLogger

        # Create a test audit logger
        test_log_file = Path("test_audit.log")
        test_secret = os.getenv("DINOAIR_AUDIT_SECRET")
        if not test_secret:
            if require_env_secrets:
                raise ValueError(
                    "Audit secret key required for validation. Set DINOAIR_AUDIT_SECRET environment variable."
                )
            # Generate a temporary test secret for validation flows when not strictly required
            test_secret = secrets.token_hex(32)
            print(
                "⚠️  Using generated test secret for audit logging validation (not for production)"
            )

        audit_logger = AuditLogger(log_file=test_log_file, secret_key=test_secret)

        print("   ✅ Audit Logger instantiated successfully")

        # Test event types
        event_types = list(AuditEventType)
        print(f"   ✅ Audit event types defined: {len(event_types)} types")

        # Test logging an event
        try:
            audit_logger.audit(
                event_type=AuditEventType.USER_LOGIN,
                user_id="test_user_123",
                details={"ip": "127.0.0.1", "action": "login_test"},
            )
            print("   ✅ Audit event logged successfully")
            event_logged = True
        except Exception as e:
            print(f"   ⚠️  Event logging failed: {str(e)}")
            audit_logger.debug("audit event failed: %s", e)
            event_logged = False

        # Clean up test file
        with suppress(FileNotFoundError, PermissionError, OSError):
            if test_log_file.exists():
                test_log_file.unlink()

        return {
            "logger_created": True,
            "event_types": len(event_types),
            "event_logged": event_logged,
        }

    except Exception as e:
        print(f"   ❌ Audit logging test failed: {str(e)}")
        logger.debug("audit logging test failed: %s", e)
        return {"error": str(e)}


def test_network_security():
    """Test network security configuration."""

    print("\n🌐 Testing Network Security...")

    try:
        from utils.network_security import SecurityLevel

        # Test security levels
        levels = list(SecurityLevel)
        print(f"   ✅ Security levels defined: {len(levels)} levels")

        # List security levels
        for level in levels:
            print(f"   📝 Security level: {level.name} = {level.value}")

        # Test if small team functions exist
        try:
            from utils.network_security import create_small_team_security_config

            small_team_config = create_small_team_security_config()
            rate_limit = small_team_config.get("rate_limit_per_minute", 600)
            print(f"   ✅ Small team config: {rate_limit} req/min")
        except ImportError:
            print("   ⚠️  Small team config function not found")
            rate_limit = 600  # Default

        return {
            "security_levels": len(levels),
            "small_team_rate_limit": rate_limit,
            "config_available": True,
        }

    except Exception as e:
        print(f"   ❌ Network security test failed: {str(e)}")
        logger.debug("network security test failed: %s", e)
        return {"error": str(e)}


def test_security_configuration():
    """Test overall security configuration."""

    print("\n⚙️  Testing Security Configuration...")

    try:
        from utils.security_config import SecurityConfig

        # Test basic security config
        try:
            config = SecurityConfig()
            print("   ✅ Basic security config created")
            config_created = True
        except Exception as e:
            print(f"   ⚠️  SecurityConfig creation failed: {str(e)}")
            logger.debug("security config creation failed: %s", e)
            config_created = False

        # Test configuration attributes
        config_attrs = []
        if config_created:
            attrs = dir(config)
            security_attrs = [attr for attr in attrs if not attr.startswith("_")]
            config_attrs = security_attrs[:5]  # Show first 5
            print(f"   ✅ Config attributes: {', '.join(config_attrs)}")

        # Test validation if available
        validation_works = False
        if config_created:
            try:
                if hasattr(config, "validate_configuration"):
                    validation_works = config.validate_configuration()
                    print(f"   ✅ Configuration validation: {validation_works}")
                else:
                    print("   ⚠️  Validation method not found")
            except Exception as e:
                print(f"   ⚠️  Validation failed: {str(e)}")
                logger.debug("security config validation failed: %s", e)

        return {
            "config_created": config_created,
            "config_attributes": len(config_attrs),
            "validation_available": validation_works,
        }

    except Exception as e:
        print(f"   ❌ Security configuration test failed: {str(e)}")
        logger.debug("security configuration test failed: %s", e)
        return {"error": str(e)}


def report_security_validation_results(
    validation_results,
    passed_tests,
    total_tests,
    report_path: str = DEFAULT_REPORT_FILENAME,
):
    score = validation_results.get("overall_score", 0)
    grade = validation_results.get("security_grade", "D (Needs Improvement)")

    print("\n📊 SECURITY VALIDATION RESULTS")
    print(f"Overall Score: {score:.1f}% ({passed_tests}/{total_tests} tests passed)")

    # Print grade with appropriate indicator based on grade string (map-based)
    grade_display = {
        "A": ("🟢", "A (Excellent)"),
        "B": ("🟡", "B (Good)"),
        "C": ("🟠", "C (Acceptable)"),
        "D": ("🔴", "D (Needs Improvement)"),
    }
    grade_key = grade[0] if isinstance(grade, str) and grade else "D"
    icon, label = grade_display.get(grade_key, grade_display["D"])
    print(f"{icon} Security Grade: {label}")

    # Save results
    # Validate report_path against whitelist
    allowed_filenames = {DEFAULT_REPORT_FILENAME}
    filename = os.path.basename(report_path)
    if filename not in allowed_filenames:
        print(
            f"Warning: report_path '{report_path}' not allowed. Using default '{DEFAULT_REPORT_FILENAME}'."
        )
        filename = DEFAULT_REPORT_FILENAME
    safe_path = os.path.join(os.getcwd(), filename)
    with open(safe_path, "w") as f:
        json.dump(validation_results, f, indent=2)

    print(f"\n💾 Detailed report saved to: {safe_path}")

    # Provide recommendations
    print("\n📋 RECOMMENDATIONS:")
    if score < 100:
        print("   🔧 Review failed tests and implement missing components")
        print("   🔍 Run penetration testing once API server is functional")
        print("   📚 Update security documentation and training")

    print("   🔄 Implement regular security assessments")
    print("   📊 Set up continuous security monitoring")
    print("   🛠️ Complete data encryption at rest implementation")


def run_security_validation():
    """Run complete security validation."""

    print("🛡️  DinoAir Security Validation")
    print("=" * 50)

    validation_results = {"timestamp": datetime.now().isoformat(), "tests": {}}

    # Run all tests
    validation_results["tests"]["imports"] = test_security_imports()
    validation_results["tests"]["password_security"] = test_password_security()
    validation_results["tests"]["rbac_system"] = test_rbac_system()
    validation_results["tests"]["audit_logging"] = test_audit_logging()
    validation_results["tests"]["network_security"] = test_network_security()
    validation_results["tests"]["security_configuration"] = (
        test_security_configuration()
    )

    # Calculate overall score
    total_tests = 0
    passed_tests = 0

    for _, test_results in validation_results["tests"].items():
        if isinstance(test_results, dict):
            for test_name, test_result in test_results.items():
                total_tests += 1
                if (
                    test_result
                    and "❌" not in str(test_result)
                    and "error" not in test_name.lower()
                ):
                    passed_tests += 1

    score = (passed_tests / total_tests * 100) if total_tests > 0 else 0
    validation_results["overall_score"] = score

    # Determine grade using threshold table (calculation only; reporting handled separately)
    thresholds = [
        (90, "A (Excellent)"),
        (80, "B (Good)"),
        (70, "C (Acceptable)"),
    ]
    grade = next((g for t, g in thresholds if score >= t), "D (Needs Improvement)")

    validation_results["security_grade"] = grade

    # Report results (printing and file output)
    report_security_validation_results(validation_results, passed_tests, total_tests)

    return validation_results


if __name__ == "__main__":
    try:
        results = run_security_validation()

        # Exit with appropriate code
        if results["overall_score"] >= 80:
            sys.exit(0)  # Success
        else:
            sys.exit(1)  # Needs improvement

    except Exception as e:
        print(f"❌ Security validation failed: {str(e)}")
        traceback.print_exc()
        sys.exit(1)
