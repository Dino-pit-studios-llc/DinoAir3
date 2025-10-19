"""
NotesRepository - Pure database operations for notes management.
Handles all SQLite database interactions without business logic.
"""

import json
import sqlite3
from collections import Counter
from dataclasses import dataclass
from datetime import datetime
from typing import Any

from models.note import Note
from utils.logger import Logger

from .initialize_db import DatabaseManager

NOTE_TABLE = "note_list"
INVALID_TABLE_ERROR = "Invalid table name"

NOTE_SELECT_COLUMNS = "id, title, content, content_html, tags, created_at, updated_at, project_id"

UPDATE_NOTE_FIELD_QUERIES = {
    "title": "UPDATE note_list SET title = ?, updated_at = ? WHERE id = ? AND is_deleted = 0",
    "content": "UPDATE note_list SET content = ?, updated_at = ? WHERE id = ? AND is_deleted = 0",
    "tags": "UPDATE note_list SET tags = ?, updated_at = ? WHERE id = ? AND is_deleted = 0",
    "content_html": "UPDATE note_list SET content_html = ?, updated_at = ? WHERE id = ? AND is_deleted = 0",
    "project_id": "UPDATE note_list SET project_id = ?, updated_at = ? WHERE id = ? AND is_deleted = 0",
}


@dataclass
class QueryResult:
    """Standardized result for database operations"""

    success: bool
    data: Any = None
    error: str = ""
    affected_rows: int = 0


class NotesRepository:
    """
    Pure database repository for notes operations.
    No business logic, security, or validation - just database CRUD.
    """

    def __init__(self, user_name: str | None = None):
        self.logger = Logger()
        self.db_manager = DatabaseManager(user_name)
        self.table_name = NOTE_TABLE
        self._ensure_database_ready()

    def _ensure_database_ready(self) -> None:
        """Ensure database schema is up to date (migrations now handle column additions)"""
        # Database schema updates are now handled by the migration system
        # in DatabaseManager._run_notes_migrations()
        # This method is kept for backward compatibility but no longer performs schema changes
        self.logger.debug("Database schema managed by migration system")

    def _execute_query_safe(self, query: str, params: tuple[Any, ...] = ()) -> QueryResult:
        """Execute a query with proper connection management and return results"""
        try:
            with self.db_manager.get_notes_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(query, params)
                # Fetch results immediately before connection closes
                if query.strip().upper().startswith(("SELECT", "PRAGMA")):
                    if "COUNT(" in query.upper():
                        # For count queries, return single value
                        result = cursor.fetchone()
                        data = result[0] if result else 0
                    else:
                        # For other SELECT queries, return all rows
                        data = cursor.fetchall()
                else:
                    # For non-SELECT queries (shouldn't happen in query methods)
                    data = cursor.rowcount

                return QueryResult(success=True, data=data)
        except Exception as e:
            self.logger.error(f"Database query error: {str(e)}")
            return QueryResult(success=False, error=str(e))

    def _execute_write(self, query: str, params: tuple[Any, ...] = ()) -> QueryResult:
        """Execute a write operation with transaction handling"""
        try:
            with self.db_manager.get_notes_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(query, params)
                conn.commit()
                return QueryResult(success=True, affected_rows=cursor.rowcount)
        except Exception as e:
            self.logger.error(f"Database write error: {str(e)}")
            return QueryResult(success=False, error=str(e))

    @staticmethod
    def _row_to_note(row: sqlite3.Row) -> Note:
        """Convert database row to Note object"""
        note = Note(
            id=row[0],
            title=row[1],
            content=row[2],
            tags=json.loads(row[4]) if row[4] else [],
            project_id=row[7],
        )
        # Preserve original timestamps
        note.created_at = row[5]
        note.updated_at = row[6]
        # Add content_html as custom attribute
        note.content_html = row[3]
        return note

    @staticmethod
    def _normalize_tags(tags: list[str]) -> list[str]:
        """
        Normalize tags for consistent storage and searching.

        Args:
            tags: List of tag strings

        Returns:
            List of normalized tags (lowercase, deduplicated, stripped)
        """
        if not tags:
            return []

        normalized_tags = []
        seen = set()

        for tag in tags:
            if isinstance(tag, str):
                tag_normalized = tag.lower().strip()
                if tag_normalized and tag_normalized not in seen:
                    normalized_tags.append(tag_normalized)
                    seen.add(tag_normalized)

        return normalized_tags
    def _has_json1_support(self) -> bool:
        """Check if SQLite installation supports JSON1 extension"""
        try:
            with self.db_manager.get_notes_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT json_valid('[]')")
                return True
        except sqlite3.OperationalError:
            return False

    def create_note(self, note: Note, content_html: str | None = None) -> QueryResult:
        """Insert a new note into the database"""
        # Normalize tags before storage
        normalized_tags = NotesRepository._normalize_tags(note.tags) if note.tags else []
        tags_json = json.dumps(normalized_tags)

        query = """
            INSERT INTO note_list
            (id, title, content, content_html, tags, created_at, updated_at, is_deleted, project_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """

        params = (
            note.id,
            note.title,
            note.content,
            content_html,
            tags_json,
            note.created_at,
            note.updated_at,
            0,
            note.project_id,
        )

        result = self._execute_write(query, params)
        if result.success:
            self.logger.info(f"Created note with ID: {note.id}")
        return result

    def get_note_by_id(self, note_id: str) -> QueryResult:
        """Retrieve a single note by ID"""
        try:
            with self.db_manager.get_notes_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    """
                    SELECT id, title, content, content_html, tags, created_at, updated_at, project_id
                    FROM note_list
                    WHERE id = ? AND is_deleted = 0
                    """,
                    (note_id,),
                )

                row = cursor.fetchone()
                if row:
                    note = NotesRepository._row_to_note(row)
                    return QueryResult(success=True, data=note)
                return QueryResult(success=False, error="Note not found")

        except Exception as e:
            self.logger.error(f"Error retrieving note {note_id}: {str(e)}")
            return QueryResult(success=False, error=str(e))

    def get_all_notes(self) -> QueryResult:
        """Retrieve all non-deleted notes"""
        try:
            with self.db_manager.get_notes_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    """
                    SELECT id, title, content, content_html, tags, created_at, updated_at, project_id
                    FROM note_list
                    WHERE is_deleted = 0
                    ORDER BY updated_at DESC
                    """
                )

                notes = [NotesRepository._row_to_note(row) for row in cursor.fetchall()]
                self.logger.info(f"Retrieved {len(notes)} notes")
                return QueryResult(success=True, data=notes)

        except Exception as e:
            self.logger.error(f"Error retrieving all notes: {str(e)}")
            return QueryResult(success=False, error=str(e))

    def update_note(self, note_id: str, updates: dict[str, Any]) -> QueryResult:
        """Update a note with the provided field updates."""
        processed_updates = self._process_note_updates(updates)
        if not processed_updates:
            return QueryResult(success=False, error="No valid fields to update")

        affected_rows = self._apply_note_updates(note_id, processed_updates)

        if affected_rows > 0:
            self.logger.info(f"Updated note: {note_id}")  # nosec
            return QueryResult(success=True, affected_rows=affected_rows)

        return QueryResult(success=False, error="Note not found or no changes applied")

    @staticmethod
    def _process_note_updates(updates: dict[str, Any]) -> list[tuple[str, Any]]:
        """Process and validate note field updates.

        Args:
            updates: Dictionary of field names and values to update

        Returns:
            List of tuples containing (field_name, processed_value)
        """
        processed_updates: list[tuple[str, Any]] = []
        for field in UPDATE_NOTE_FIELD_QUERIES:
            if field in updates:
                value = updates[field]
                if field == "tags":
                    normalized_tags = NotesRepository._normalize_tags(value) if value else []
                    value = json.dumps(normalized_tags)
                processed_updates.append((field, value))
        return processed_updates

    def _apply_note_updates(self, note_id: str, processed_updates: list[tuple[str, Any]]) -> int:
        """Apply processed updates to a note in the database.

        Args:
            note_id: ID of the note to update
            processed_updates: List of (field_name, value) tuples

        Returns:
            Number of affected rows
        """
        timestamp = datetime.now().isoformat()
        affected_rows = 0

        try:
            with self.db_manager.get_notes_connection() as conn:
                cursor = conn.cursor()
                for field_name, field_value in processed_updates:
                    query = UPDATE_NOTE_FIELD_QUERIES[field_name]
                    cursor.execute(query, (field_value, timestamp, note_id))
                    if cursor.rowcount:
                        affected_rows += cursor.rowcount
                conn.commit()
        except Exception as exc:
            self.logger.error(f"Error updating note {note_id}: {exc}")
            return 0

        return affected_rows

    def soft_delete_note(self, note_id: str) -> QueryResult:
        """Soft delete a note"""
        query = """
            UPDATE note_list
            SET is_deleted = 1, updated_at = ?
            WHERE id = ? AND is_deleted = 0
        """
        params = (datetime.now().isoformat(), note_id)

        result = self._execute_write(query, params)
        if result.success and result.affected_rows > 0:
            self.logger.info(f"Soft deleted note: {note_id}")
        return result

    def hard_delete_note(self, note_id: str) -> QueryResult:
        """Permanently delete a note"""
        # Security: Use parameterized query with validated table name
        if self.table_name != NOTE_TABLE:  # Validate expected table name
            return QueryResult(False, None, INVALID_TABLE_ERROR)

        query = "DELETE FROM note_list WHERE id = ?"
        result = self._execute_write(query, (note_id,))
        if result.success:
            self.logger.info(f"Hard deleted note: {note_id}")
        return result

    def restore_note(self, note_id: str) -> QueryResult:
        """Restore a soft-deleted note"""
        query = """
            UPDATE note_list
            SET is_deleted = 0, updated_at = ?
            WHERE id = ? AND is_deleted = 1
        """
        params = (datetime.now().isoformat(), note_id)

        result = self._execute_write(query, params)
        if result.success and result.affected_rows > 0:
            self.logger.info(f"Restored note: {note_id}")
        return result

    def get_deleted_notes(self) -> QueryResult:
        """Get all soft-deleted notes"""
        try:
            with self.db_manager.get_notes_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    """
                    SELECT id, title, content, content_html, tags, created_at, updated_at, project_id
                    FROM note_list
                    WHERE is_deleted = 1
                    ORDER BY updated_at DESC
                    """
                )

                notes = [NotesRepository._row_to_note(row) for row in cursor.fetchall()]
                self.logger.info(f"Retrieved {len(notes)} deleted notes")
                return QueryResult(success=True, data=notes)

        except Exception as e:
            self.logger.error(f"Error retrieving deleted notes: {str(e)}")
            return QueryResult(success=False, error=str(e))

    def search_notes(self, query: str, filter_option: str = "All", project_id: str | None = None) -> QueryResult:
        """Search notes with various filter options"""
        try:
            q_like = f"%{query}%"
            search_sql, params = self._build_search_query(q_like, filter_option, project_id)

            with self.db_manager.get_notes_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(search_sql, params)
                notes = [NotesRepository._row_to_note(row) for row in cursor.fetchall()]

            self.logger.info(f"Search found {len(notes)} notes for query: '{query}'")
            return QueryResult(success=True, data=notes)

        except Exception as e:
            self.logger.error(f"Error searching notes: {str(e)}")
            return QueryResult(success=False, error=str(e))

    def _build_search_query(
        self, q_like: str, filter_option: str, project_id: str | None
    ) -> tuple[str, tuple[str, ...]]:
        """Build SQL search query based on filter options.

        Args:
            q_like: LIKE pattern for search
            filter_option: Which field(s) to search in
            project_id: Optional project ID filter

        Returns:
            Tuple of (SQL query string, parameters tuple)
        """
        base_select = """
            SELECT id, title, content, content_html, tags, created_at, updated_at, project_id
            FROM note_list
            WHERE is_deleted = 0
        """

        search_condition, params = self._get_search_condition(filter_option, q_like)
        search_condition, params = self._apply_project_filter(search_condition, params, project_id)

        search_sql = base_select + "\n" + search_condition + "\nORDER BY updated_at DESC"
        return search_sql, params

    @staticmethod
    def _get_search_condition(filter_option: str, q_like: str) -> tuple[str, tuple[str, ...]]:
        """Get search condition based on filter option.

        Args:
            filter_option: Which field(s) to search in
            q_like: LIKE pattern for search

        Returns:
            Tuple of (search condition string, parameters tuple)
        """
        if filter_option == "Title Only":
            return "AND title LIKE ? ESCAPE '\\'", (q_like,)
        if filter_option == "Content Only":
            return "AND content LIKE ? ESCAPE '\\'", (q_like,)
        if filter_option == "Tags Only":
            return "AND tags LIKE ? ESCAPE '\\'", (q_like,)
        # "All"
        return (
            "AND (title LIKE ? ESCAPE '\\' OR content LIKE ? ESCAPE '\\' OR tags LIKE ? ESCAPE '\\')",
            (q_like, q_like, q_like),
        )

    @staticmethod
    def _apply_project_filter(
        search_condition: str, params: tuple[str, ...], project_id: str | None
    ) -> tuple[str, tuple[str, ...]]:
        """Add project filter to search condition if needed.

        Args:
            search_condition: Current search condition
            params: Current parameters tuple
            project_id: Optional project ID filter

        Returns:
            Tuple of (updated search condition, updated parameters)
        """
        if project_id is not None:
            search_condition += "\nAND project_id = ?"
            params = params + (project_id,)
        return search_condition, params

    def get_notes_by_tag(self, tag: str) -> QueryResult:
        """Get all notes with a specific tag using efficient JSON1 queries"""
        try:
            # Normalize the search tag for consistent matching
            normalized_tag = tag.lower().strip()
            if not normalized_tag:
                return QueryResult(success=True, data=[])

            if self._has_json1_support():
                # Use efficient JSON1 query with EXISTS and json_each
                with self.db_manager.get_notes_connection() as conn:
                    cursor = conn.cursor()
                    cursor.execute(
                        """
                        SELECT id, title, content, content_html, tags, created_at, updated_at, project_id
                        FROM note_list
                        WHERE is_deleted = 0
                        AND EXISTS (
                            SELECT 1 FROM json_each(tags)
                            WHERE value = ?
                        )
                        ORDER BY updated_at DESC
                        """,
                        (normalized_tag,),
                    )

                    notes = [NotesRepository._row_to_note(row) for row in cursor.fetchall()]
            else:
                # Fallback to LIKE query with post-filtering for systems without JSON1
                tag_pattern = f'%"{normalized_tag}"%'
                with self.db_manager.get_notes_connection() as conn:
                    cursor = conn.cursor()
                    cursor.execute(
                        """
                        SELECT id, title, content, content_html, tags, created_at, updated_at, project_id
                        FROM note_list
                        WHERE is_deleted = 0 AND tags LIKE ? ESCAPE '\\'
                        ORDER BY updated_at DESC
                        """,
                        (tag_pattern,),
                    )

                    notes = []
                    for row in cursor.fetchall():
                        note = NotesRepository._row_to_note(row)
                        # Double-check that the normalized tag is actually in the list
                        if normalized_tag in (note.tags or []):
                            notes.append(note)

            self.logger.info(f"Found {len(notes)} notes with tag: '{tag}' (normalized: '{normalized_tag}')")
            return QueryResult(success=True, data=notes)

        except Exception as e:
            self.logger.error(f"Error getting notes by tag '{tag}': {str(e)}")
            return QueryResult(success=False, error=str(e))

    def get_all_tags(self) -> QueryResult:
        """Get all unique tags with their usage counts"""
        try:
            # Security: Use parameterized query with validated table name
            if self.table_name != NOTE_TABLE:  # Validate expected table name
                return QueryResult(False, None, INVALID_TABLE_ERROR)

            with self.db_manager.get_notes_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT tags FROM note_list WHERE is_deleted = 0")

                tag_counts: Counter[str] = Counter()
                original_case: dict[str, str] = {}
                for row in cursor.fetchall():
                    serialized_tags = row[0]
                    if not serialized_tags:
                        continue

                    tags = json.loads(serialized_tags)
                    if not isinstance(tags, list):
                        continue

                    for tag in tags:
                        if not isinstance(tag, str):
                            continue

                        normalized = tag.lower()
                        original_case.setdefault(normalized, tag)
                        tag_counts[normalized] += 1

            # Convert to simple dict preserving the first-seen casing
            result = {original_case[key]: tag_counts[key] for key in tag_counts}
            self.logger.info(f"Retrieved {len(result)} unique tags")
            return QueryResult(success=True, data=result)

        except Exception as e:
            self.logger.error(f"Error retrieving all tags: {str(e)}")
            return QueryResult(success=False, error=str(e))

    def update_tag_in_notes(self, old_tag: str, new_tag: str) -> QueryResult:
        """Rename a tag across all notes"""
        try:
            old_tag_normalized = old_tag.lower().strip()
            new_tag_normalized = new_tag.lower().strip()

            if not old_tag_normalized or not new_tag_normalized:
                return QueryResult(False, None, "Tag names cannot be empty")

            if self.table_name != NOTE_TABLE:
                return QueryResult(False, None, INVALID_TABLE_ERROR)

            affected_notes = self._process_tag_rename(old_tag_normalized, new_tag_normalized)

            self.logger.info(f"Renamed tag '{old_tag}' to '{new_tag}' in {affected_notes} notes")
            return QueryResult(success=True, data={"affected_notes": affected_notes})

        except Exception as e:
            self.logger.error(f"Error renaming tag: {str(e)}")
            return QueryResult(success=False, error=str(e))

    def _process_tag_rename(self, old_tag_normalized: str, new_tag_normalized: str) -> int:
        """Process tag renaming for all notes containing the old tag.

        Args:
            old_tag_normalized: Normalized old tag name
            new_tag_normalized: Normalized new tag name

        Returns:
            Number of notes affected
        """
        affected_notes = 0

        with self.db_manager.get_notes_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT id, tags FROM note_list WHERE is_deleted = 0")

            for row in cursor.fetchall():
                note_id = row[0]
                tags = json.loads(row[1]) if row[1] else []

                updated_tags, tag_found = self._replace_tag_in_list(tags, old_tag_normalized, new_tag_normalized)

                if tag_found and self._update_note_tags(note_id, updated_tags):
                    affected_notes += 1

        return affected_notes

    @staticmethod
    def _replace_tag_in_list(tags: list[str], old_tag: str, new_tag: str) -> tuple[list[str], bool]:
        """Replace occurrences of old tag with new tag in a tag list.

        Args:
            tags: List of tags to process
            old_tag: Normalized old tag to find
            new_tag: Normalized new tag to replace with

        Returns:
            Tuple of (updated tag list, whether tag was found)
        """
        updated_tags = []
        tag_found = False

        for tag in tags:
            if isinstance(tag, str) and tag.lower() == old_tag:
                updated_tags.append(new_tag)
                tag_found = True
            else:
                updated_tags.append(tag)

        # Deduplicate tags while preserving order
        seen = set()
        deduped_tags = []
        for tag in updated_tags:
            if tag not in seen:
                deduped_tags.append(tag)
                seen.add(tag)

        return deduped_tags, tag_found

    def _update_note_tags(self, note_id: str, tags: list[str]) -> bool:
        """Update tags for a specific note.

        Args:
            note_id: ID of the note to update
            tags: New list of tags

        Returns:
            True if update was successful
        """
        if self.table_name != NOTE_TABLE:
            return False

        update_result = self._execute_write(
            "UPDATE note_list SET tags = ?, updated_at = ? WHERE id = ?",
            (json.dumps(tags), datetime.now().isoformat(), note_id),
        )
        return update_result.success

    def remove_tag_from_notes(self, tag_to_remove: str) -> QueryResult:
        """Remove a tag from all notes"""
        try:
            # Normalize tag for consistent searching
            tag_normalized = tag_to_remove.lower().strip()
            if not tag_normalized:
                return QueryResult(False, None, "Tag name cannot be empty")

            # Security: Use validated table name
            if self.table_name != NOTE_TABLE:
                return QueryResult(False, None, INVALID_TABLE_ERROR)

            with self.db_manager.get_notes_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT id, tags FROM note_list WHERE is_deleted = 0")

                affected_notes = 0
                for row in cursor.fetchall():
                    note_id = row[0]
                    tags = json.loads(row[1]) if row[1] else []

                    # Remove normalized tag
                    original_count = len(tags)
                    updated_tags = [tag for tag in tags if isinstance(tag, str) and tag.lower() != tag_normalized]

                    if len(updated_tags) < original_count:
                        # Update the note
                        # Security: Use validated table name
                        if self.table_name != NOTE_TABLE:
                            continue

                        update_result = self._execute_write(
                            "UPDATE note_list SET tags = ?, updated_at = ? WHERE id = ?",
                            (
                                json.dumps(updated_tags),
                                datetime.now().isoformat(),
                                note_id,
                            ),
                        )
                        if update_result.success:
                            affected_notes += 1

            self.logger.info(
                f"Deleted tag '{tag_to_remove}' from {affected_notes} notes"  # nosec
            )
            return QueryResult(success=True, data={"affected_notes": affected_notes})

        except Exception as e:
            self.logger.error(f"Error deleting tag: {str(e)}")
            return QueryResult(success=False, error=str(e))

    def get_notes_by_project(self, project_id: str) -> QueryResult:
        """Get all notes for a specific project"""
        try:
            with self.db_manager.get_notes_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    """
                    SELECT id, title, content, content_html, tags, created_at, updated_at, project_id
                    FROM note_list
                    WHERE is_deleted = 0 AND project_id = ?
                    ORDER BY updated_at DESC
                    """,
                    (project_id,),
                )

                notes = [NotesRepository._row_to_note(row) for row in cursor.fetchall()]
                self.logger.info(f"Retrieved {len(notes)} notes for project: {project_id}")
                return QueryResult(success=True, data=notes)

        except Exception as e:
            self.logger.error(f"Error retrieving notes for project {project_id}: {str(e)}")
            return QueryResult(success=False, error=str(e))

    def get_notes_without_project(self) -> QueryResult:
        """Get all notes not associated with any project"""
        try:
            with self.db_manager.get_notes_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    """
                    SELECT id, title, content, content_html, tags, created_at, updated_at, project_id
                    FROM note_list
                    WHERE is_deleted = 0 AND (project_id IS NULL OR project_id = '')
                    ORDER BY updated_at DESC
                    """
                )

                notes = [NotesRepository._row_to_note(row) for row in cursor.fetchall()]
                self.logger.info(f"Retrieved {len(notes)} notes without project association")
                return QueryResult(success=True, data=notes)

        except Exception as e:
            self.logger.error(f"Error retrieving notes without project: {str(e)}")
            return QueryResult(success=False, error=str(e))

    def bulk_update_project(self, note_ids: list[str], project_id: str | None) -> QueryResult:
        """Assign multiple notes to a project or remove project association"""
        try:
            if not note_ids:
                return QueryResult(success=False, error="No note IDs provided")

            timestamp = datetime.now().isoformat()
            affected_rows = 0

            with self.db_manager.get_notes_connection() as conn:
                cursor = conn.cursor()
                for nid in note_ids:
                    cursor.execute(
                        """
                        UPDATE note_list
                        SET project_id = ?, updated_at = ?
                        WHERE id = ? AND is_deleted = 0
                        """,
                        (project_id, timestamp, nid),
                    )
                    if cursor.rowcount:
                        affected_rows += cursor.rowcount
                conn.commit()

            action = "assigned to" if project_id else "removed from"
            self.logger.info(f"{affected_rows} notes {action} project {project_id}")
            return QueryResult(success=True, affected_rows=affected_rows)

        except Exception as e:
            self.logger.error(f"Error bulk updating project: {str(e)}")
            return QueryResult(success=False, error=str(e))

    def get_project_notes_count(self, project_id: str) -> QueryResult:
        """Get the count of notes associated with a project"""
        try:
            # Security: Use validated table name
            if self.table_name != NOTE_TABLE:
                return QueryResult(False, None, INVALID_TABLE_ERROR)

            with self.db_manager.get_notes_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "SELECT COUNT(*) FROM note_list WHERE is_deleted = 0 AND project_id = ?",
                    (project_id,),
                )

                count = cursor.fetchone()[0]
                return QueryResult(success=True, data=count)

        except Exception as e:
            self.logger.error(f"Error counting notes for project {project_id}: {str(e)}")
            return QueryResult(success=False, error=str(e))
