"""
Migration: Add project_id column to notes table

This migration adds the project_id column to the note_list table
to support project association functionality.

Version: 001
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


class AddNotesProjectIdMigration(AddColumnMigration):
    """Add project_id column to notes table."""

    def __init__(self):
        super().__init__(
            version="001",
            name="add_notes_project_id",
            description="Add project_id column to notes table for project association",
            table_name="note_list",
            column_name="project_id",
            column_type="TEXT",
        )
