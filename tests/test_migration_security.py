"""
Test AddColumnMigration security validations

Validates that SQL injection protections work correctly.
"""

import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from database.migrations.base import AddColumnMigration, MigrationError


def test_valid_identifiers():
    """Test that valid identifiers are accepted."""
    print("Testing valid identifiers...")
    
    # These should all work
    valid_cases = [
        ("my_table", "my_column", "TEXT"),
        ("table123", "column_456", "INTEGER"),
        ("_private", "_col", "REAL"),
        ("TableName", "ColumnName", "BLOB"),
    ]
    
    for table, column, col_type in valid_cases:
        try:
            migration = AddColumnMigration(
                version="001",
                name="test",
                description="Test migration",
                table_name=table,
                column_name=column,
                column_type=col_type,
            )
            print(f"  ✅ Valid: table={table}, column={column}, type={col_type}")
        except MigrationError as e:
            print(f"  ❌ FAIL: Should accept {table}, {column}, {col_type}")
            print(f"     Error: {e}")
            return False
    
    return True


def test_invalid_identifiers():
    """Test that invalid identifiers are rejected (SQL injection protection)."""
    print("\nTesting invalid identifiers (SQL injection attempts)...")
    
    # These should all be rejected
    invalid_cases = [
        ("my-table", "column", "TEXT", "hyphen in name"),
        ("table'; DROP TABLE users; --", "column", "TEXT", "SQL injection attempt"),
        ("table name", "column", "TEXT", "space in name"),
        ("123table", "column", "TEXT", "starts with digit"),
        ("table", "col; DELETE FROM", "TEXT", "SQL in column name"),
        ("table", "column'", "TEXT", "quote in name"),
        ("table.name", "column", "TEXT", "dot in name"),
        ("", "column", "TEXT", "empty table name"),
        ("table", "", "TEXT", "empty column name"),
    ]
    
    for table, column, col_type, reason in invalid_cases:
        try:
            migration = AddColumnMigration(
                version="001",
                name="test",
                description="Test migration",
                table_name=table,
                column_name=column,
                column_type=col_type,
            )
            print(f"  ❌ FAIL: Should reject {table}, {column} ({reason})")
            return False
        except MigrationError:
            print(f"  ✅ Rejected: {reason}")
    
    return True


def test_column_type_whitelist():
    """Test that only whitelisted column types are accepted."""
    print("\nTesting column type whitelist...")
    
    # Valid types
    valid_types = ["TEXT", "INTEGER", "REAL", "BLOB", "VARCHAR", "INT"]
    for col_type in valid_types:
        try:
            migration = AddColumnMigration(
                version="001",
                name="test",
                description="Test",
                table_name="table1",
                column_name="col1",
                column_type=col_type,
            )
            print(f"  ✅ Valid type: {col_type}")
        except MigrationError:
            print(f"  ❌ FAIL: Should accept valid type {col_type}")
            return False
    
    # Invalid types (SQL injection attempts)
    invalid_types = [
        "TEXT; DROP TABLE users; --",
        "INTEGER OR 1=1",
        "TEXT) VALUES ('evil'); --",
        "UNKNOWN_TYPE",
        "",
    ]
    
    for col_type in invalid_types:
        try:
            migration = AddColumnMigration(
                version="001",
                name="test",
                description="Test",
                table_name="table1",
                column_name="col1",
                column_type=col_type,
            )
            print(f"  ❌ FAIL: Should reject invalid type '{col_type}'")
            return False
        except MigrationError:
            print(f"  ✅ Rejected invalid type: {col_type[:30]}")
    
    return True


def test_default_value_validation():
    """Test that default values are properly validated."""
    print("\nTesting default value validation...")
    
    # Valid defaults
    valid_defaults = [
        "DEFAULT 0",
        "DEFAULT 123",
        "DEFAULT NULL",
        "DEFAULT 'text'",
        "DEFAULT 1.5",
        "DEFAULT CURRENT_TIMESTAMP",
    ]
    
    for default in valid_defaults:
        try:
            migration = AddColumnMigration(
                version="001",
                name="test",
                description="Test",
                table_name="table1",
                column_name="col1",
                column_type="TEXT",
                column_default=default,
            )
            print(f"  ✅ Valid default: {default}")
        except MigrationError as e:
            print(f"  ❌ FAIL: Should accept valid default '{default}'")
            print(f"     Error: {e}")
            return False
    
    # Invalid defaults (SQL injection attempts)
    invalid_defaults = [
        "DEFAULT 0; DROP TABLE users; --",
        "DEFAULT (SELECT password FROM users)",
        "DEFAULT 'x' OR 1=1 --",
        "; DELETE FROM users WHERE 1=1; --",
    ]
    
    for default in invalid_defaults:
        try:
            migration = AddColumnMigration(
                version="001",
                name="test",
                description="Test",
                table_name="table1",
                column_name="col1",
                column_type="TEXT",
                column_default=default,
            )
            print(f"  ❌ FAIL: Should reject dangerous default '{default[:30]}'")
            return False
        except MigrationError:
            print(f"  ✅ Rejected dangerous default: {default[:40]}")
    
    return True


def test_identifier_quoting():
    """Test that identifiers are properly quoted."""
    print("\nTesting identifier quoting...")
    
    migration = AddColumnMigration(
        version="001",
        name="test",
        description="Test",
        table_name="my_table",
        column_name="my_column",
        column_type="TEXT",
    )
    
    # Test quote function
    quoted = migration._quote_identifier("my_table")
    if quoted != '"my_table"':
        print(f"  ❌ FAIL: Expected '\"my_table\"', got '{quoted}'")
        return False
    print(f"  ✅ Quoting works: {quoted}")
    
    # Test quote escaping
    quoted = migration._quote_identifier('table"with"quotes')
    if quoted != '"table""with""quotes"':
        print(f"  ❌ FAIL: Quote escaping failed")
        return False
    print(f"  ✅ Quote escaping works: {quoted}")
    
    return True


if __name__ == "__main__":
    print("=" * 70)
    print("MIGRATION SECURITY VALIDATION TESTS")
    print("=" * 70)
    
    tests = [
        test_valid_identifiers,
        test_invalid_identifiers,
        test_column_type_whitelist,
        test_default_value_validation,
        test_identifier_quoting,
    ]
    
    all_passed = True
    for test in tests:
        if not test():
            all_passed = False
            print(f"\n❌ {test.__name__} FAILED")
        else:
            print(f"✅ {test.__name__} passed")
    
    print("\n" + "=" * 70)
    if all_passed:
        print("✅ ALL SECURITY TESTS PASSED!")
        print("=" * 70)
        sys.exit(0)
    else:
        print("❌ SOME TESTS FAILED - Security vulnerabilities may exist")
        print("=" * 70)
        sys.exit(1)
