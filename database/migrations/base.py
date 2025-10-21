"""Base migration classes and utilities for the DinoAir migration system."""

from __future__ import annotations

from abc import ABC, abstractmethod
from datetime import datetime
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    import sqlite3


class MigrationError(Exception):
    """Exception raised during migration execution."""


class BaseMigration(ABC):
    """
    Base class for all database migrations.

    Each migration must implement the `up` method to apply the migration
    and optionally the `down` method to rollback the migration.
    """

    def __init__(self, version: str, name: str, description: str = ""):
        """
        Initialize a migration.

        Args:
            version: Migration version (e.g., "001", "002")
            name: Migration name (e.g., "add_notes_project_id")
            description: Optional description of what the migration does
        """
        self.version = version
        self.name = name
        self.description = description
        self.applied_at: datetime | None = None

    @abstractmethod
    def up(self, conn: sqlite3.Connection) -> None:
        """
        Apply the migration.

        Args:
            conn: Database connection to execute migration on

        Raises:
            MigrationError: If migration fails
        """

    def down(self, conn: sqlite3.Connection) -> None:
        """
        Rollback the migration (optional).

        Args:
            conn: Database connection to execute rollback on

        Raises:
            MigrationError: If rollback fails
        """
        raise NotImplementedError(f"Migration {self.version}_{self.name} does not support rollback")

    @property
    def full_name(self) -> str:
        """Get the full migration identifier."""
        return f"{self.version}_{self.name}"

    def __str__(self) -> str:
        return f"Migration({self.full_name})"

    def __repr__(self) -> str:
        return f"Migration(version='{self.version}', name='{self.name}')"


class AddColumnMigration(BaseMigration):
    """
    Base class for simple "add column" migrations.

    Eliminates duplication across similar migration scripts that just
    add a single column to a table.

    Subclasses only need to call super().__init__() with the appropriate
    parameters instead of duplicating the entire up/down logic.

    Security: All identifiers and types are validated to prevent SQL injection.
    """

    # Allowed SQL types for SQLite (whitelist approach)
    ALLOWED_COLUMN_TYPES = {
        "TEXT",
        "INTEGER",
        "REAL",
        "BLOB",
        "NUMERIC",
        "INT",
        "SMALLINT",
        "BIGINT",
        "FLOAT",
        "DOUBLE",
        "VARCHAR",
        "CHAR",
        "BOOLEAN",
        "DATE",
        "DATETIME",
    }

    def __init__(
        self,
        version: str,
        name: str,
        description: str,
        table_name: str,
        column_name: str,
        column_type: str,
        column_default: str | None = None,
    ):
        """
        Initialize an add column migration with security validation.

        Args:
            version: Migration version (e.g., "001")
            name: Migration name (e.g., "add_notes_project_id")
            description: What this migration does
            table_name: Table to modify (e.g., "note_list")
            column_name: Column to add (e.g., "project_id")
            column_type: SQL type (e.g., "TEXT", "INTEGER")
            column_default: Optional default value clause (e.g., "DEFAULT 0")

        Raises:
            MigrationError: If any identifier or type fails validation
        """
        super().__init__(version, name, description)

        # Validate and store identifiers with SQL injection protection
        self.table_name = self._validate_identifier(table_name, "table_name")
        self.column_name = self._validate_identifier(column_name, "column_name")
        self.column_type = self._validate_column_type(column_type)
        self.column_default = self._validate_default(column_default) if column_default else None

    @staticmethod
    def _validate_identifier(identifier: str, field_name: str) -> str:
        """
        Validate that an identifier is safe for use in SQL.

        SQL identifiers must start with letter or underscore, followed by
        letters, digits, or underscores only.

        Args:
            identifier: The identifier to validate
            field_name: Name of the field for error messages

        Returns:
            The validated identifier

        Raises:
            MigrationError: If identifier contains invalid characters
        """
        import re

        # SQLite identifier rules: start with letter/underscore, then alphanumeric/underscore
        if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", identifier):
            raise MigrationError(
                f"Invalid {field_name}: '{identifier}'. "
                f"Must start with letter or underscore, followed by alphanumeric or underscore characters only."
            )

        return identifier

    @staticmethod
    def _validate_column_type(column_type: str) -> str:
        """
        Validate column type against whitelist.

        Args:
            column_type: SQL column type to validate

        Returns:
            Normalized column type (uppercase)

        Raises:
            MigrationError: If type is not in whitelist
        """
        normalized_type = column_type.strip().upper()

        if normalized_type not in AddColumnMigration.ALLOWED_COLUMN_TYPES:
            raise MigrationError(
                f"Invalid column_type: '{column_type}'. "
                f"Must be one of: {', '.join(sorted(AddColumnMigration.ALLOWED_COLUMN_TYPES))}"
            )

        return normalized_type

    @staticmethod
    def _validate_default(default_clause: str) -> str:
        """
        Validate default value clause.

        Args:
            default_clause: Default clause like "DEFAULT 0" or "DEFAULT 'text'"

        Returns:
            Validated default clause

        Raises:
            MigrationError: If default clause contains dangerous patterns
        """
        import re

        # Allow only safe default patterns:
        # - DEFAULT followed by: integer, string literal, NULL, or simple expressions
        safe_patterns = [
            r"^DEFAULT\s+\d+$",  # DEFAULT 123
            r"^DEFAULT\s+NULL$",  # DEFAULT NULL
            r"^DEFAULT\s+'[^']*'$",  # DEFAULT 'text'
            r"^DEFAULT\s+\d+\.\d+$",  # DEFAULT 1.5
            r"^DEFAULT\s+CURRENT_TIMESTAMP$",  # DEFAULT CURRENT_TIMESTAMP
            r"^DEFAULT\s+CURRENT_DATE$",  # DEFAULT CURRENT_DATE
            f"or 'DEFAULT 'text''. Complex expressions not supported for security.",
        ]

        normalized = default_clause.strip().upper()

        for pattern in safe_patterns:
            if re.match(pattern, normalized):
                return default_clause.strip()

        raise MigrationError(
            f"Invalid column_default: '{default_clause}'. "
            f"Must match safe patterns like 'DEFAULT 0', 'DEFAULT NULL', "
            f"or 'DEFAULT \"text\"'. Complex expressions not supported for security."
        )

    @staticmethod
    def _quote_identifier(identifier: str) -> str:
        """
        Safely quote an SQL identifier.

        Uses double quotes as per SQL standard. Escapes any embedded quotes.

        Args:
            identifier: Validated identifier to quote

        Returns:
            Quoted identifier safe for SQL interpolation
        """
        # Escape any double quotes by doubling them
        escaped = identifier.replace('"', '""')
        return f'"{escaped}"'

    def up(self, conn: sqlite3.Connection) -> None:
        """
        Apply the migration: add the specified column.

        Uses validated identifiers and safe SQL construction to prevent injection.
        """
        cursor = conn.cursor()

        try:
            # Check if table exists (using parameterized query)
            cursor.execute(
                """
                SELECT name FROM sqlite_master
                WHERE type='table' AND name=?
                """,
                (self.table_name,),
            )
            table_exists = cursor.fetchone() is not None

            if table_exists:
                # Check if column already exists
                # Note: PRAGMA doesn't support parameters, but table_name is validated
                quoted_table = self._quote_identifier(self.table_name)
                cursor.execute(f"PRAGMA table_info({quoted_table})")
                columns = [row[1] for row in cursor.fetchall()]

                if self.column_name not in columns:
                    # Build ALTER TABLE statement with quoted identifiers
                    # All identifiers have been validated in __init__
                    quoted_table = self._quote_identifier(self.table_name)
                    quoted_column = self._quote_identifier(self.column_name)

                    # column_type is validated against whitelist (no quoting needed)
                    # column_default is validated and safe (if provided)
                    default_clause = f" {self.column_default}" if self.column_default else ""

                    sql = f"ALTER TABLE {quoted_table} ADD COLUMN {quoted_column} {self.column_type}{default_clause}"
                    cursor.execute(sql)
                    conn.commit()
            # If table doesn't exist, skip (it will be created with the column)

        except sqlite3.Error as e:
            raise MigrationError(f"Failed to add {self.column_name} column: {str(e)}") from e

    def down(self, conn: sqlite3.Connection) -> None:
        """Rollback not supported for column additions in SQLite."""
        raise MigrationError(
            f"Rollback not supported: SQLite doesn't support dropping columns easily. "
            f"Manual intervention required to remove {self.column_name} column."
        )


class MigrationRecord:
    """Represents a migration record from the database."""

    def __init__(
        self,
        version: str,
        name: str,
        applied_at: datetime,
        description: str = "",
        checksum: str | None = None,
    ):
        self.version = version
        self.name = name
        self.applied_at = applied_at
        self.description = description
        self.checksum = checksum

    @property
    def full_name(self) -> str:
        """Get the full migration identifier."""
        return f"{self.version}_{self.name}"

    @classmethod
    def from_row(cls, row: tuple) -> MigrationRecord:
        """Create a MigrationRecord from a database row."""
        version, name, applied_at_str, description, checksum = row
        applied_at = datetime.fromisoformat(applied_at_str)
        return cls(version, name, applied_at, description, checksum)

    def __str__(self) -> str:
        return f"MigrationRecord({self.full_name}, applied_at={self.applied_at})"


def ensure_migrations_table(conn: sqlite3.Connection) -> None:
    """
    Ensure the migrations tracking table exists.

    Args:
        conn: Database connection
    """
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS schema_migrations (
            version TEXT NOT NULL,
            name TEXT NOT NULL,
            applied_at DATETIME NOT NULL,
            description TEXT DEFAULT '',
            checksum TEXT DEFAULT NULL,
            PRIMARY KEY (version, name)
        )
    """)

    # Create index for efficient lookups
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_migrations_version
        ON schema_migrations(version)
    """)

    conn.commit()


def record_migration(conn: sqlite3.Connection, migration: BaseMigration) -> None:
    """
    Record a migration as applied in the migrations table.

    Args:
        conn: Database connection
        migration: The migration that was applied
    """
    cursor = conn.cursor()
    applied_at = datetime.now().isoformat()

    cursor.execute(
        """
        INSERT OR REPLACE INTO schema_migrations
        (version, name, applied_at, description)
        VALUES (?, ?, ?, ?)
    """,
        (migration.version, migration.name, applied_at, migration.description),
    )

    conn.commit()


def get_applied_migrations(conn: sqlite3.Connection) -> list[MigrationRecord]:
    """
    Get all applied migrations from the database.

    Args:
        conn: Database connection

    Returns:
        List of applied migration records, sorted by version
    """
    ensure_migrations_table(conn)

    cursor = conn.cursor()
    cursor.execute("""
        SELECT version, name, applied_at, description, checksum
        FROM schema_migrations
        ORDER BY version, name
    """)

    return [MigrationRecord.from_row(row) for row in cursor.fetchall()]


def is_migration_applied(conn: sqlite3.Connection, migration: BaseMigration) -> bool:
    """
    Check if a migration has been applied.

    Args:
        conn: Database connection
        migration: Migration to check

    Returns:
        True if migration has been applied, False otherwise
    """
    ensure_migrations_table(conn)

    cursor = conn.cursor()
    cursor.execute(
        """
        SELECT 1 FROM schema_migrations
        WHERE version = ? AND name = ?
    """,
        (migration.version, migration.name),
    )

    return cursor.fetchone() is not None
