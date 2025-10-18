"""
Comprehensive tests for API search service functionality.

Tests the SearchService class and related API endpoints for file search operations
including keyword search, vector search, hybrid search, and index statistics.
"""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from unittest.mock import Mock, patch

import pytest
from fastapi import HTTPException
from starlette import status

from API.services.search import (
    DirectorySettingsResponse,
    FileIndexStatsResponse,
    HybridSearchRequest,
    HybridSearchResponse,
    KeywordSearchRequest,
    KeywordSearchResponse,
    SearchService,
    VectorSearchRequest,
    VectorSearchResponse,
    _sanitize_file_types,
    _to_hit,
    _truncate_snippet,
    directory_settings,
    hybrid,
    index_stats,
    keyword,
    router_search,
    vector,
)


class TestSearchService:
    """Test suite for SearchService class."""

    @pytest.fixture
    def mock_db(self):
        """Mock FileSearchDB instance."""
        mock_db = Mock()
        mock_db.search_by_keywords.return_value = [
            {
                "file_path": "/test/file1.txt",
                "content": "test content for search",
                "relevance_score": 0.95,
                "chunk_index": 0,
                "start_pos": 0,
                "end_pos": 25,
                "file_type": "txt",
                "chunk_metadata": {"lines": [1, 2]},
            }
        ]
        mock_db.get_indexed_files_stats.return_value = {
            "total_files": 100,
            "files_by_type": {"txt": 50, "md": 30, "py": 20},
            "total_size_bytes": 1048576,
            "total_size_mb": 1.0,
            "total_chunks": 500,
            "total_embeddings": 500,
            "last_indexed_date": "2024-01-01T00:00:00Z",
        }
        mock_db.get_directory_settings.return_value = {
            "success": True,
            "allowed_directories": ["/docs", "/src"],
            "excluded_directories": ["/temp", "/cache"],
        }
        return mock_db

    @pytest.fixture
    def search_service(self, mock_db):
        """SearchService instance with mocked database."""
        with patch("API.services.search.FileSearchDB", return_value=mock_db):
            service = SearchService()
            service._db = mock_db
            return service

    @staticmethod
    def test_search_keyword_success(search_service, mock_db):
        """Test successful keyword search."""
        # Arrange
        request = KeywordSearchRequest(query="test query", top_k=10, file_types=["txt", "md"])

        # Act
        response = search_service.search_keyword(request)

        # Assert
        assert len(response.hits) == 1
        hit = response.hits[0]
        assert hit.file_path == "/test/file1.txt"
        assert hit.content == "test content for search"
        assert hit.score == 0.95
        assert hit.file_type == "txt"

        # Verify database call
        mock_db.search_by_keywords.assert_called_once_with(
            keywords=["test query"], limit=10, file_types=["txt", "md"]
        )

    @staticmethod
    def test_search_keyword_empty_results(search_service, mock_db):
        """Test keyword search with no results."""
        # Arrange
        mock_db.search_by_keywords.return_value = []
        request = KeywordSearchRequest(query="nonexistent")

        # Act
        response = search_service.search_keyword(request)

        # Assert
        assert len(response.hits) == 0
        mock_db.search_by_keywords.assert_called_once()

    @staticmethod
    def test_search_keyword_validation_error(search_service, mock_db):
        """Test keyword search with validation error."""
        # Arrange - mock ValidationError
        with patch("API.services.search.ValidationError") as mock_validation_error:
            mock_db.search_by_keywords.side_effect = mock_validation_error(
                [{"type": "value_error", "loc": ("query",), "msg": "Invalid query"}]
            )

            request = KeywordSearchRequest(query="test")

            # Act
            response = search_service.search_keyword(request)

            # Assert
            assert len(response.hits) == 0  # Should return empty on validation error

    @staticmethod
    def test_search_vector_unavailable_index(search_service, mock_db):
        """Test vector search when index is not available."""
        # Arrange
        mock_db.get_indexed_files_stats.return_value = {"total_embeddings": 0}
        request = VectorSearchRequest(query="test query")

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            search_service.search_vector(request)

        assert exc_info.value.status_code == status.HTTP_501_NOT_IMPLEMENTED
        assert "Vector index not available" in exc_info.value.detail

    @staticmethod
    def test_search_vector_success(search_service, mock_db):
        """Test successful vector search."""
        # Arrange
        mock_db.get_indexed_files_stats.return_value = {"total_embeddings": 100}

        # Mock the vector search engine
        mock_engine = Mock()
        mock_engine.search.return_value = [
            Mock(
                file_path="/test/vector_file.txt",
                content="vector search content",
                score=0.85,
                chunk_index=0,
                start_pos=0,
                end_pos=20,
                file_type="txt",
                metadata={"test": "metadata"},
            )
        ]

        with patch("API.services.search._require_engine", return_value=mock_engine):
            request = VectorSearchRequest(
                query="test query",
                top_k=5,
                similarity_threshold=0.7,
                file_types=["txt"],
            )

            # Act
            response = search_service.search_vector(request)

            # Assert
            assert len(response.hits) == 1
            hit = response.hits[0]
            assert hit.file_path == "/test/vector_file.txt"
            assert hit.score == 0.85

            # Verify engine call
            mock_engine.search.assert_called_once_with(
                query="test query",
                top_k=5,
                similarity_threshold=0.7,
                file_types=["txt"],
                distance_metric="cosine",
            )

    @staticmethod
    def test_search_hybrid_success(search_service, mock_db):
        """Test successful hybrid search."""
        # Arrange
        mock_db.get_indexed_files_stats.return_value = {"total_embeddings": 100}

        mock_engine = Mock()
        mock_engine.hybrid_search.return_value = [
            Mock(
                file_path="/test/hybrid_file.txt",
                content="hybrid search content",
                score=0.90,
                chunk_index=0,
                start_pos=0,
                end_pos=20,
                file_type="txt",
                metadata={"hybrid": "result"},
            )
        ]

        with patch("API.services.search._require_engine", return_value=mock_engine):
            request = HybridSearchRequest(
                query="test query",
                top_k=5,
                vector_weight=0.7,
                keyword_weight=0.3,
                rerank=True,
            )

            # Act
            response = search_service.search_hybrid(request)

            # Assert
            assert len(response.hits) == 1
            hit = response.hits[0]
            assert hit.file_path == "/test/hybrid_file.txt"
            assert hit.score == 0.90

            # Verify engine call
            mock_engine.hybrid_search.assert_called_once_with(
                query="test query",
                top_k=5,
                vector_weight=0.7,
                keyword_weight=0.3,
                similarity_threshold=0.5,
                file_types=None,
                rerank=True,
            )

    @staticmethod
    def test_search_hybrid_zero_weights(search_service, mock_db):
        """Test hybrid search with zero weights defaults to balanced weights."""
        # Arrange
        mock_db.get_indexed_files_stats.return_value = {"total_embeddings": 100}

        mock_engine = Mock()
        mock_engine.hybrid_search.return_value = []

        with patch("API.services.search._require_engine", return_value=mock_engine):
            request = HybridSearchRequest(query="test query", vector_weight=0.0, keyword_weight=0.0)

            # Act
            response = search_service.search_hybrid(request)

            # Assert
            assert len(response.hits) == 0

            # Verify engine called with default balanced weights
            mock_engine.hybrid_search.assert_called_once()
            call_kwargs = mock_engine.hybrid_search.call_args[1]
            assert call_kwargs["vector_weight"] == 0.7
            assert call_kwargs["keyword_weight"] == 0.3

    @staticmethod
    def test_get_index_stats_success(search_service, mock_db):
        """Test successful index statistics retrieval."""
        # Act
        response = search_service.get_index_stats()

        # Assert
        assert response.total_files == 100
        assert response.files_by_type == {"txt": 50, "md": 30, "py": 20}
        assert response.total_size_bytes == 1048576
        assert response.total_size_mb == 1.0
        assert response.total_chunks == 500
        assert response.total_embeddings == 500
        assert response.last_indexed_date == "2024-01-01T00:00:00Z"

        mock_db.get_indexed_files_stats.assert_called_once()

    @staticmethod
    def test_get_index_stats_validation_error(search_service, mock_db):
        """Test index stats with validation error returns defaults."""
        # Arrange - mock ValidationError
        with patch("API.services.search.ValidationError") as mock_validation_error:
            mock_db.get_indexed_files_stats.return_value = {"invalid": "data"}
            # Force validation error by making response creation fail
            with patch.object(
                FileIndexStatsResponse,
                "__init__",
                side_effect=mock_validation_error([]),
            ):
                # Act
                response = search_service.get_index_stats()

                # Assert
                assert response.total_files == 0  # Should return defaults on error
                assert response.files_by_type == {}

    @staticmethod
    def test_get_directory_settings_success(search_service, mock_db):
        """Test successful directory settings retrieval."""
        # Act
        response = search_service.get_directory_settings()

        # Assert
        assert response.allowed_directories == ["/docs", "/src"]
        assert response.excluded_directories == ["/temp", "/cache"]
        assert response.total_allowed == 2
        assert response.total_excluded == 2

        mock_db.get_directory_settings.assert_called_once()

    @staticmethod
    def test_get_directory_settings_backend_error(search_service, mock_db):
        """Test directory settings with backend error."""
        # Arrange
        mock_db.get_directory_settings.return_value = {
            "success": False,
            "error": "Database connection failed",
        }

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            search_service.get_directory_settings()

        assert exc_info.value.status_code == status.HTTP_501_NOT_IMPLEMENTED
        assert "Database connection failed" in exc_info.value.detail


class TestSearchUtilityFunctions:
    """Test suite for search utility functions."""

    @staticmethod
    def test_sanitize_file_types_valid():
        """Test file type sanitization with valid inputs."""
        file_types = ["txt", "  md  ", "PY", "", None, "js"]
        result = _sanitize_file_types(file_types)

        assert result == ["txt", "md", "py"]  # Should filter and lowercase valid types

    @staticmethod
    def test_sanitize_file_types_empty():
        """Test file type sanitization with empty/None input."""
        assert _sanitize_file_types([]) is None
        assert _sanitize_file_types(None) is None

    @staticmethod
    def test_sanitize_file_types_too_long():
        """Test file type sanitization filters out overly long types."""
        file_types = ["txt", "a" * 25]  # 25 chars is too long
        result = _sanitize_file_types(file_types)

        assert result == ["txt"]  # Should filter out the too-long type

    @staticmethod
    def test_sanitize_file_types_max_count():
        """Test file type sanitization respects maximum count."""
        file_types = ["txt"] * 25  # More than 20
        result = _sanitize_file_types(file_types)

        assert len(result) == 20  # Should be capped at 20

    @staticmethod
    def test_truncate_snippet_short():
        """Test snippet truncation with short text."""
        text = "Short text"
        result = _truncate_snippet(text, 50)

        assert result == "Short text"  # No truncation needed

    @staticmethod
    def test_truncate_snippet_long():
        """Test snippet truncation with long text."""
        text = "a" * 100
        result = _truncate_snippet(text, 50)

        assert len(result) == 50
        assert result.endswith("…")

    @staticmethod
    def test_to_hit_with_search_result():
        """Test conversion of search result to hit."""
        result = Mock()
        result.file_path = "/test/file.txt"
        result.content = "test content"
        result.score = 0.85
        result.chunk_index = 1
        result.start_pos = 10
        result.end_pos = 25
        result.file_type = "txt"
        result.metadata = {"test": "data"}

        hit = _to_hit(result)

        assert hit.file_path == "/test/file.txt"
        assert hit.content == "test content"
        assert hit.score == 0.85
        assert hit.chunk_index == 1
        assert hit.start_pos == 10
        assert hit.end_pos == 25
        assert hit.file_type == "txt"
        assert hit.metadata == {"test": "data"}

    @staticmethod
    def test_to_hit_with_dict_result():
        """Test conversion of dict result to hit."""
        result = {
            "file_path": "/test/dict_file.txt",
            "content": "dict content",
            "relevance_score": 0.75,  # Alternative score key
            "chunk_index": 2,
            "start_pos": 5,
            "end_pos": 20,
            "file_type": "md",
            "chunk_metadata": {"dict": "metadata"},
        }

        hit = _to_hit(result)

        assert hit.file_path == "/test/dict_file.txt"
        assert hit.content == "dict content"
        assert hit.score == 0.75
        assert hit.file_type == "md"
        assert hit.metadata == {"dict": "metadata"}

    @staticmethod
    def test_to_hit_truncated_content():
        """Test that long content gets truncated in hit conversion."""
        result = Mock()
        result.file_path = "/test/file.txt"
        result.content = "a" * 600  # Long content
        result.score = 0.8
        result.chunk_index = 0
        result.start_pos = 0
        result.end_pos = 600
        result.file_type = "txt"
        result.metadata = None

        hit = _to_hit(result)

        assert len(hit.content) == 500  # Should be truncated to SNIPPET_MAX_CHARS
        assert hit.content.endswith("…")


class TestSearchFacadeFunctions:
    """Test suite for module-level facade functions."""

    @patch("API.services.search.get_search_service")
    def test_keyword_facade(self, mock_get_service):
        """Test keyword search facade function."""
        # Arrange
        mock_service = Mock()
        mock_service.search_keyword.return_value = KeywordSearchResponse(hits=[])
        mock_get_service.return_value = mock_service

        request = KeywordSearchRequest(query="test")

        # Act
        response = keyword(request)

        # Assert
        assert isinstance(response, KeywordSearchResponse)
        mock_service.search_keyword.assert_called_once_with(request)

    @patch("API.services.search.get_search_service")
    def test_vector_facade(self, mock_get_service):
        """Test vector search facade function."""
        # Arrange
        mock_service = Mock()
        mock_service.search_vector.return_value = VectorSearchResponse(hits=[])
        mock_get_service.return_value = mock_service

        request = VectorSearchRequest(query="test")

        # Act
        response = vector(request)

        # Assert
        assert isinstance(response, VectorSearchResponse)
        mock_service.search_vector.assert_called_once_with(request)

    @patch("API.services.search.get_search_service")
    def test_hybrid_facade(self, mock_get_service):
        """Test hybrid search facade function."""
        # Arrange
        mock_service = Mock()
        mock_service.search_hybrid.return_value = HybridSearchResponse(hits=[])
        mock_get_service.return_value = mock_service

        request = HybridSearchRequest(query="test")

        # Act
        response = hybrid(request)

        # Assert
        assert isinstance(response, HybridSearchResponse)
        mock_service.search_hybrid.assert_called_once_with(request)

    @patch("API.services.search.get_search_service")
    def test_index_stats_facade(self, mock_get_service):
        """Test index stats facade function."""
        # Arrange
        mock_service = Mock()
        mock_service.get_index_stats.return_value = FileIndexStatsResponse(
            total_files=100,
            files_by_type={},
            total_size_bytes=0,
            total_size_mb=0.0,
            total_chunks=0,
            total_embeddings=0,
            last_indexed_date=None,
        )
        mock_get_service.return_value = mock_service

        # Act
        response = index_stats()

        # Assert
        assert isinstance(response, FileIndexStatsResponse)
        assert response.total_files == 100
        mock_service.get_index_stats.assert_called_once()

    @patch("API.services.search.get_search_service")
    def test_directory_settings_facade(self, mock_get_service):
        """Test directory settings facade function."""
        # Arrange
        mock_service = Mock()
        mock_service.get_directory_settings.return_value = DirectorySettingsResponse(
            allowed_directories=[],
            excluded_directories=[],
            total_allowed=0,
            total_excluded=0,
        )
        mock_get_service.return_value = mock_service

        # Act
        response = directory_settings()

        # Assert
        assert isinstance(response, DirectorySettingsResponse)
        mock_service.get_directory_settings.assert_called_once()


class TestSearchRouterAdapter:
    """Test suite for router adapter functions."""

    @staticmethod
    def test_router_search_keyword_inferred():
        """Test router search with keyword operation inferred."""
        payload = {"query": "test query", "top_k": 5, "file_types": ["txt"]}

        with patch("API.services.search._handle_keyword") as mock_handle:
            mock_handle.return_value = {"hits": []}

            result = router_search(payload)

            assert result == {"hits": []}
            mock_handle.assert_called_once_with(payload)

    @staticmethod
    def test_router_search_vector_inferred():
        """Test router search with vector operation inferred."""
        payload = {
            "query": "test query",
            "similarity_threshold": 0.7,
            "distance_metric": "cosine",
        }

        with patch("API.services.search._handle_vector") as mock_handle:
            mock_handle.return_value = {"hits": []}

            result = router_search(payload)

            assert result == {"hits": []}
            mock_handle.assert_called_once_with(payload)

    @staticmethod
    def test_router_search_hybrid_inferred():
        """Test router search with hybrid operation inferred."""
        payload = {
            "query": "test query",
            "vector_weight": 0.6,
            "keyword_weight": 0.4,
            "rerank": True,
        }

        with patch("API.services.search._handle_hybrid") as mock_handle:
            mock_handle.return_value = {"hits": []}

            result = router_search(payload)

            assert result == {"hits": []}
            mock_handle.assert_called_once_with(payload)

    @staticmethod
    def test_router_search_explicit_op():
        """Test router search with explicit operation."""
        payload = {"op": "vector", "query": "test query"}

        with patch("API.services.search._handle_vector") as mock_handle:
            mock_handle.return_value = {"hits": []}

            result = router_search(payload)

            assert result == {"hits": []}
            mock_handle.assert_called_once_with(payload)

    @staticmethod
    def test_router_search_error_handling():
        """Test router search error handling."""
        payload = {"query": "test"}

        with patch("API.services.search._handle_keyword") as mock_handle:
            mock_handle.side_effect = Exception("Test error")

            result = router_search(payload)

            # Should return minimal valid response on error
            assert result == {"hits": []}

    @staticmethod
    def test_infer_search_op_keyword():
        """Test operation inference for keyword search."""
        from API.services.search import _infer_search_op

        payload = {"query": "test", "top_k": 5}
        assert _infer_search_op(payload) == "keyword"

    @staticmethod
    def test_infer_search_op_vector():
        """Test operation inference for vector search."""
        from API.services.search import _infer_search_op

        payload = {"query": "test", "similarity_threshold": 0.7}
        assert _infer_search_op(payload) == "vector"

    @staticmethod
    def test_infer_search_op_hybrid():
        """Test operation inference for hybrid search."""
        from API.services.search import _infer_search_op

        payload = {"query": "test", "vector_weight": 0.5, "keyword_weight": 0.5}
        assert _infer_search_op(payload) == "hybrid"

    @staticmethod
    def test_infer_search_op_explicit():
        """Test operation inference with explicit op field."""
        from API.services.search import _infer_search_op

        payload = {"op": "vector", "query": "test"}
        assert _infer_search_op(payload) == "vector"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
