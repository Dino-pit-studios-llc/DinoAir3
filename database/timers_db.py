"""TimersDatabase - centralized timer logging via DatabaseManager/ResilientDB."""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

from .base_db import BaseDatabase
from .initialize_db import DatabaseManager

if TYPE_CHECKING:
    from datetime import datetime


class TimersDatabase(BaseDatabase):
    """Handles timer log persistence using DatabaseManager.

    Schema is created by DatabaseManager._setup_timers_schema.
    """

    def __init__(self, db_manager: DatabaseManager | None = None):
        super().__init__()
        self.db_manager = db_manager or DatabaseManager()

    def create_log(
        self,
        task_name: str,
        start_time: datetime,
        end_time: datetime,
        elapsed_seconds: float,
    ) -> dict[str, Any]:
        """Create timer log entry.

        Args:
            task_name: Name/description of the timed task
            start_time: When the task started
            end_time: When the task ended
            elapsed_seconds: Duration of the task in seconds

        Returns:
            Standard response dict with success status
        """
        def _create() -> None:
            with self.db_manager.get_timers_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    """
                    INSERT INTO timer_logs (task_name, start_time, end_time, elapsed_seconds)
                    VALUES (?, ?, ?, ?)
                    """,
                    (task_name, start_time, end_time, elapsed_seconds),
                )
                conn.commit()
        
        return self.safe_execute(_create, error_context="create_timer_log")
