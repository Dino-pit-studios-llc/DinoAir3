"""
Migration: Add content_html column to notes table

This migration adds the content_html column to the note_list table
to support HTML rendering of note content.

Version: 003
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


class AddNotesContentHtmlMigration(AddColumnMigration):
    """Add content_html column to notes table."""

    def __init__(self):
        super().__init__(
            version="003",
            name="add_notes_content_html",
            description="Add content_html column to notes table for HTML content rendering",
            table_name="note_list",
            column_name="content_html",
            column_type="TEXT",
        )
