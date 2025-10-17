"""
Tests for database file search operations.

Tests the FileSearchDB class for core file search functionality including
keyword search, index management, and statistics retrieval.
"""

import os
import sqlite3
import tempfile

import pytest

from database.file_search_db import FileSearchDB
from database.initialize_db import DatabaseManager


class TestFileSearchDB:
    """Test suite for FileSearchDB class."""

    @pytest.fixture
    def temp_db_path(self):
        """Create a temporary database file."""
        with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
            db_path = f.name

        yield db_path

        # Cleanup
        if os.path.exists(db_path):
            os.unlink(db_path)

    @pytest.fixture
    def db_manager(self, temp_db_path):
        """Database manager with temporary database."""
        return DatabaseManager(db_path=temp_db_path)

    @pytest.fixture
    def file_search_db(self, db_manager):
        """FileSearchDB instance with initialized database."""
        db = FileSearchDB(db_manager)
        db.create_tables()  # Initialize tables
        return db

    @staticmethod
    def test_initialization(file_search_db):
        """Test FileSearchDB initialization."""
        assert file_search_db is not None
        assert file_search_db._db_manager is not None

    @staticmethod
    def test_create_tables(file_search_db):
        """Test table creation."""
        # Tables should be created during initialization
        conn = file_search_db._get_connection()
        cursor = conn.cursor()

        # Check if key tables exist
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='indexed_files'")
        assert cursor.fetchone() is not None

        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='file_chunks'")
        assert cursor.fetchone() is not None

        cursor.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='file_embeddings'"
        )
        assert cursor.fetchone() is not None

    @staticmethod
    def test_search_by_keywords_empty_results(file_search_db):
        """Test keyword search with no indexed files."""
        results = file_search_db.search_by_keywords(keywords=["test"], limit=10)

        assert results == []

    @staticmethod
    def test_add_indexed_file(file_search_db):
        """Test adding a file to the index."""
        file_path = "/test/file.txt"
        file_hash = "test_hash_123"
        file_size = 1024
        file_type = "txt"
        content_hash = "content_hash_456"

        result = file_search_db.add_indexed_file(
            file_path=file_path,
            file_hash=file_hash,
            file_size=file_size,
            file_type=file_type,
            content_hash=content_hash,
        )

        assert result["success"] is True
        assert "file_id" in result

    @staticmethod
    def test_get_file_by_path(file_search_db):
        """Test retrieving file information by path."""
        # First add a file
        file_path = "/test/retrieve_file.txt"
        file_search_db.add_indexed_file(
            file_path=file_path,
            file_hash="hash_789",
            file_size=2048,
            file_type="txt",
            content_hash="content_789",
        )

        # Then retrieve it
        file_info = file_search_db.get_file_by_path(file_path)

        assert file_info is not None
        assert file_info["file_path"] == file_path
        assert file_info["file_size"] == 2048
        assert file_info["file_type"] == "txt"

    @staticmethod
    def test_get_file_by_path_not_found(file_search_db):
        """Test retrieving non-existent file."""
        file_info = file_search_db.get_file_by_path("/nonexistent/file.txt")

        assert file_info is None

    @staticmethod
    def test_remove_file_from_index(file_search_db):
        """Test removing a file from the index."""
        # First add a file
        file_path = "/test/remove_file.txt"
        file_search_db.add_indexed_file(
            file_path=file_path,
            file_hash="hash_remove",
            file_size=512,
            file_type="md",
            content_hash="content_remove",
        )

        # Verify it exists
        file_info = file_search_db.get_file_by_path(file_path)
        assert file_info is not None

        # Remove it
        remove_result = file_search_db.remove_file_from_index(file_path)

        assert remove_result["success"] is True

        # Verify it's gone
        file_info = file_search_db.get_file_by_path(file_path)
        assert file_info is None

    @staticmethod
    def test_get_indexed_files_stats_empty(file_search_db):
        """Test getting statistics for empty index."""
        stats = file_search_db.get_indexed_files_stats()

        assert stats is not None
        assert stats["total_files"] == 0
        assert stats["total_size_bytes"] == 0
        assert stats["total_chunks"] == 0
        assert stats["total_embeddings"] == 0

    @staticmethod
    def test_get_indexed_files_stats_with_data(file_search_db):
        """Test getting statistics with indexed files."""
        # Add some test files
        test_files = [
            ("/test/file1.txt", "hash1", 1000, "txt", "content1"),
            ("/test/file2.md", "hash2", 2000, "md", "content2"),
            ("/test/file3.py", "hash3", 1500, "py", "content3"),
        ]

        for file_path, file_hash, file_size, file_type, content_hash in test_files:
            file_search_db.add_indexed_file(
                file_path=file_path,
                file_hash=file_hash,
                file_size=file_size,
                file_type=file_type,
                content_hash=content_hash,
            )

        # Get statistics
        stats = file_search_db.get_indexed_files_stats()

        assert stats is not None
        assert stats["total_files"] == 3
        assert stats["total_size_bytes"] == 4500  # Sum of all file sizes
        assert "files_by_type" in stats
        assert stats["files_by_type"]["txt"] == 1
        assert stats["files_by_type"]["md"] == 1
        assert stats["files_by_type"]["py"] == 1

    @staticmethod
    def test_search_settings_management(file_search_db):
        """Test search settings management."""
        # Test getting initial settings (should be empty)
        settings = file_search_db.get_search_settings()
        assert settings["success"] is True

        # Test updating settings
        update_result = file_search_db.update_search_settings("test_setting", {"key": "value"})
        assert update_result["success"] is True

        # Test retrieving updated settings
        settings = file_search_db.get_search_settings("test_setting")
        assert settings["success"] is True
        assert settings["setting_value"] == {"key": "value"}

    @staticmethod
    def test_directory_settings_management(file_search_db):
        """Test directory settings management."""
        # Test initial directory settings
        settings = file_search_db.get_directory_settings()
        assert settings["success"] is True

        # Test adding allowed directory
        add_result = file_search_db.add_allowed_directory("/test/allowed")
        assert add_result["success"] is True

        # Test adding excluded directory
        exclude_result = file_search_db.add_excluded_directory("/test/excluded")
        assert exclude_result["success"] is True

        # Test retrieving directory settings
        settings = file_search_db.get_directory_settings()
        assert settings["success"] is True
        assert "/test/allowed" in settings.get("allowed_directories", [])
        assert "/test/excluded" in settings.get("excluded_directories", [])

        # Test removing directories
        remove_allowed = file_search_db.remove_allowed_directory("/test/allowed")
        assert remove_allowed["success"] is True

        remove_excluded = file_search_db.remove_excluded_directory("/test/excluded")
        assert remove_excluded["success"] is True

    @staticmethod
    def test_optimize_database(file_search_db):
        """Test database optimization."""
        # Add some data first
        file_search_db.add_indexed_file(
            file_path="/test/optimize.txt",
            file_hash="hash_opt",
            file_size=100,
            file_type="txt",
            content_hash="content_opt",
        )

        # Test optimization
        optimize_result = file_search_db.optimize_database()

        assert optimize_result["success"] is True

    @staticmethod
    def test_error_handling_invalid_file_path(file_search_db):
        """Test error handling for invalid operations."""
        # Test adding file with invalid path
        result = file_search_db.add_indexed_file(
            file_path="",
            file_hash="invalid",
            file_size=100,
            file_type="txt",
            content_hash="invalid",
        )

        # Should handle gracefully (exact behavior depends on implementation)
        assert isinstance(result, dict)
        assert "success" in result or "error" in result

    @staticmethod
    def test_concurrent_access_safety(file_search_db):
        """Test that database handles concurrent access safely."""
        import threading
        import time

        errors = []

        def add_files(start_id):
            try:
                for i in range(5):
                    file_search_db.add_indexed_file(
                        file_path=f"/test/thread_{start_id}_file_{i}.txt",
                        file_hash=f"hash_{start_id}_{i}",
                        file_size=100,
                        file_type="txt",
                        content_hash=f"content_{start_id}_{i}",
                    )
                    time.sleep(0.01)  # Small delay to encourage race conditions
            except Exception as e:
                errors.append(e)

        # Start multiple threads
        threads = []
        for thread_id in range(3):
            thread = threading.Thread(target=add_files, args=(thread_id,))
            threads.append(thread)
            thread.start()

        # Wait for all threads to complete
        for thread in threads:
            thread.join()

        # Check results
        assert len(errors) == 0, f"Errors occurred during concurrent access: {errors}"

        # Verify all files were added
        stats = file_search_db.get_indexed_files_stats()
        assert stats["total_files"] == 15  # 3 threads * 5 files each


class TestDatabaseManager:
    """Test suite for DatabaseManager integration."""

    @pytest.fixture
    def temp_dir(self):
        """Create a temporary directory for databases."""
        with tempfile.TemporaryDirectory() as temp_dir:
            yield temp_dir

    @staticmethod
    def test_database_manager_initialization(temp_dir):
        """Test DatabaseManager initialization."""
        db_manager = DatabaseManager(db_path=os.path.join(temp_dir, "test.db"))

        assert db_manager is not None
        assert db_manager.db_path == os.path.join(temp_dir, "test.db")

    @staticmethod
    def test_file_search_connection(temp_dir):
        """Test getting file search database connection."""
        db_manager = DatabaseManager(db_path=os.path.join(temp_dir, "test.db"))

        # Should be able to get connection without errors
        conn = db_manager.get_file_search_connection()
        assert conn is not None
        assert isinstance(conn, sqlite3.Connection)

        conn.close()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
