"""
Migration: Add is_deleted column to notes table

This migration adds the is_deleted column to the note_list table
to support soft delete functionality.

Version: 002
Created: 2024-09-16
"""

# Import will be resolved at runtime when loaded by migration runner
try:
    from database.migrations.base import AddColumnMigration
except ImportError:
    # Fallback for direct execution or different import paths
    import sys
    from pathlib import Path

    sys.path.append(str(Path(__file__).parent.parent))
    from base import AddColumnMigration


class AddNotesIsDeletedMigration(AddColumnMigration):
    """Add is_deleted column to notes table."""

    def __init__(self):
        super().__init__(
            version="002",
            name="add_notes_is_deleted",
            description="Add is_deleted column to notes table for soft delete functionality",
            table_name="note_list",
            column_name="is_deleted",
            column_type="INTEGER",
            column_default="DEFAULT 0",
        )
