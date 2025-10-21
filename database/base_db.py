"""
Base Database Class

Provides common database operation patterns, error handling, and logging
to eliminate duplication across database modules.
"""

from __future__ import annotations

import sqlite3
from typing import TYPE_CHECKING, Any, Callable, TypeVar

from utils.logger import Logger
from utils.responses import error_response, success_response

if TYPE_CHECKING:
    from collections.abc import Generator
    from contextlib import AbstractContextManager

T = TypeVar("T")


class BaseDatabase:
    """
    Base class for database operations with standardized patterns.

    Provides:
    - Consistent logger initialization
    - Standard error handling for SQLite operations
    - Response formatting helpers
    - Context manager support for connections

    Subclasses should implement their specific database operations
    using the provided helper methods.

    Example:
        class MyDatabase(BaseDatabase):
            def __init__(self, db_manager):
                super().__init__()
                self.db_manager = db_manager

            def create_item(self, name: str) -> dict[str, Any]:
                return self.safe_execute(
                    lambda: self._do_create(name),
                    error_context="create_item"
                )
    """

    def __init__(self):
        """Initialize with logger."""
        self.logger = Logger()

    def safe_execute(
        self,
        operation: Callable[[], T],
        error_context: str = "Database operation",
        return_data: bool = False,
    ) -> dict[str, Any]:
        """
        Execute database operation with standard error handling.

        This method wraps database operations to provide consistent:
        - Error handling for SQLite and general exceptions
        - Logging of errors with context
        - Standard response format

        Args:
            operation: Callable that performs the database operation
            error_context: Description of the operation for error messages
            return_data: If True, includes operation result in response data field

        Returns:
            Standard response dict with success/error/data fields

        Example:
            def create_note(self, title: str) -> dict[str, Any]:
                def _create():
                    with self.get_connection() as conn:
                        cursor = conn.cursor()
                        cursor.execute("INSERT INTO notes (title) VALUES (?)", (title,))
                        conn.commit()
                        return cursor.lastrowid

                return self.safe_execute(_create, "create_note", return_data=True)
        """
        try:
            result = operation()
            if return_data:
                return success_response(data=result)
            return success_response()

        except sqlite3.Error as e:
            self.logger.error(f"{error_context} - SQLite error: {e}")
            return error_response(e, context=f"{error_context} (database)")

        except Exception as e:
            self.logger.error(f"{error_context} - Unexpected error: {e}")
            return error_response(e, context=error_context)

    def safe_query(
        self,
        query_operation: Callable[[], T],
        error_context: str = "Database query",
        default_value: T | None = None,
    ) -> T | None:
        """
        Execute a query operation with error handling, returning result or default.

        Unlike safe_execute, this returns the actual result (or None/default),
        not a response dict. Useful for read operations where you want the
        data directly.

        Args:
            query_operation: Callable that performs the query
            error_context: Description for error logging
            default_value: Value to return on error (defaults to None)

        Returns:
            Query result on success, default_value on error

        Example:
            def get_note(self, note_id: str) -> dict | None:
                def _query():
                    with self.get_connection() as conn:
                        cursor = conn.cursor()
                        cursor.execute("SELECT * FROM notes WHERE id=?", (note_id,))
                        row = cursor.fetchone()
                        return dict(row) if row else None

                return self.safe_query(_query, "get_note")
        """
        try:
            return query_operation()

        except sqlite3.Error as e:
            self.logger.error(f"{error_context} - SQLite error: {e}")
            return default_value

        except Exception as e:
            self.logger.error(f"{error_context} - Unexpected error: {e}")
            return default_value

    @staticmethod
    def get_connection_context(
        get_connection: Callable[[], sqlite3.Connection],
    ) -> AbstractContextManager[sqlite3.Connection]:
        """
        Wrap a connection getter as a context manager.

        This is a helper for database classes that need to use connections
        as context managers but don't have built-in context manager support.

        Args:
            get_connection: Function that returns a database connection

        Returns:
            Context manager that yields the connection

        Example:
            def _do_operation(self):
                with self.get_connection_context(self.db_manager.get_notes_connection) as conn:
                    cursor = conn.cursor()
                    cursor.execute("SELECT 1")
        """
        from contextlib import contextmanager

        @contextmanager
        def _context() -> Generator[sqlite3.Connection, None, None]:
            conn = get_connection()
            try:
                yield conn
            finally:
                # Connection cleanup handled by caller or connection pool
                pass

        return _context()
