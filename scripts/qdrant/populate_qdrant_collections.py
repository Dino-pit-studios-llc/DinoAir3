#!/usr/bin/env python3
"""
Populate Qdrant Collections with DinoAir3 Sample Data

This script creates sample embeddings and data that represent typical DinoAir3
file search content, including code files, documentation, notes, and projects.
"""

import json
import os
import sys
from typing import Dict, List

# Sample data representing DinoAir3 file search content
SAMPLE_FILES_DATA = [
    # Python files
    {
        "id": "file_001",
        "file_path": "/src/dinoair_api.py",
        "file_name": "dinoair_api.py",
        "file_type": "py",
        "content": """
class DinoAirAPI:
    def __init__(self):
        self.search_engine = None
        self.vector_store = None

    def search_files(self, query: str) -> List[Dict]:
        \"\"\"Search files using vector similarity and keyword matching.\"\"\"
        # Implementation for file search functionality
        pass

    def index_documents(self, documents: List[str]) -> bool:
        \"\"\"Index documents for search capabilities.\"\"\"
        return True
""",
        "metadata": {
            "project": "dinoair-core",
            "module": "api",
            "lines": 15,
            "complexity": "medium",
            "tags": ["api", "search", "python"],
        },
    },
    {
        "id": "file_002",
        "file_path": "/src/vector_search.py",
        "file_name": "vector_search.py",
        "file_type": "py",
        "content": """
import numpy as np
from typing import List, Dict, Tuple

class VectorSearchEngine:
    \"\"\"High-performance vector search for document retrieval.\"\"\"

    def __init__(self, embedding_model: str = "all-MiniLM-L6-v2"):
        self.model_name = embedding_model
        self.dimensions = 384

    def search_similar(self, query_vector: np.ndarray, top_k: int = 10) -> List[Dict]:
        \"\"\"Find similar documents using cosine similarity.\"\"\"
        # Vector search implementation
        results = []
        for i in range(top_k):
            results.append({
                "id": f"doc_{i}",
                "score": 0.95 - i * 0.05,
                "content": f"Document {i} content..."
            })
        return results
""",
        "metadata": {
            "project": "dinoair-core",
            "module": "search",
            "lines": 25,
            "complexity": "high",
            "tags": ["vector", "search", "embeddings", "numpy"],
        },
    },
    # JavaScript/React files
    {
        "id": "file_003",
        "file_path": "/ui/src/components/SearchResults.jsx",
        "file_name": "SearchResults.jsx",
        "file_type": "jsx",
        "content": """
import React, { useState, useEffect } from 'react';
import { useQuery } from 'react-query';

const SearchResults = ({ query, filters }) => {
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);

  const { data, isLoading } = useQuery(
    ['search', query, filters],
    () => searchAPI.searchFiles(query, filters),
    { enabled: !!query }
  );

  useEffect(() => {
    if (data) {
      setResults(data.results);
      setLoading(isLoading);
    }
  }, [data, isLoading]);

  return (
    <div className="search-results">
      {loading ? (
        <div>Loading...</div>
      ) : (
        results.map(result => (
          <SearchResultCard key={result.id} result={result} />
        ))
      )}
    </div>
  );
};

export default SearchResults;
""",
        "metadata": {
            "project": "dinoair-ui",
            "framework": "react",
            "component": "SearchResults",
            "lines": 35,
            "complexity": "medium",
            "tags": ["react", "javascript", "search", "ui"],
        },
    },
    # Documentation files
    {
        "id": "file_004",
        "file_path": "/docs/api-documentation.md",
        "file_name": "api-documentation.md",
        "file_type": "md",
        "content": """
# DinoAir API Documentation

## File Search API

The DinoAir File Search API provides powerful search capabilities for code and documentation.

### Endpoints

#### POST /api/v1/search
Search for files using natural language queries.

**Request Body:**
```json
{
  "query": "find authentication functions",
  "file_types": ["py", "js"],
  "max_results": 10
}
```

**Response:**
```json
{
  "results": [
    {
      "file_path": "/src/auth.py",
      "content": "def authenticate_user(username, password):",
      "score": 0.95,
      "metadata": {
        "file_type": "py",
        "lines": 25
      }
    }
  ]
}
```

## Vector Search

Uses embeddings for semantic search across all indexed content.
""",
        "metadata": {
            "project": "dinoair-docs",
            "type": "documentation",
            "section": "api",
            "lines": 45,
            "complexity": "low",
            "tags": ["documentation", "api", "markdown"],
        },
    },
    # Configuration files
    {
        "id": "file_005",
        "file_path": "/config/search_config.json",
        "file_name": "search_config.json",
        "file_type": "json",
        "content": """
{
  "search": {
    "enabled": true,
    "vector_search": {
      "model": "all-MiniLM-L6-v2",
      "dimensions": 384,
      "threshold": 0.7
    },
    "keyword_search": {
      "case_sensitive": false,
      "fuzzy_matching": true
    },
    "hybrid_search": {
      "vector_weight": 0.7,
      "keyword_weight": 0.3
    }
  },
  "indexing": {
    "batch_size": 100,
    "auto_index": true,
    "excluded_paths": [
      "/tmp",
      "/cache",
      "/node_modules"
    ]
  },
  "performance": {
    "cache_size": 1000,
    "max_results": 50,
    "timeout": 30
  }
}
""",
        "metadata": {
            "project": "dinoair-config",
            "type": "configuration",
            "category": "search",
            "lines": 35,
            "complexity": "low",
            "tags": ["configuration", "json", "search"],
        },
    },
    # Note files
    {
        "id": "file_006",
        "file_path": "/notes/project-planning.txt",
        "file_name": "project-planning.txt",
        "file_type": "txt",
        "content": """
DinoAir Project Planning Notes

Phase 1: Core Infrastructure
- Set up vector database (Qdrant)
- Implement embedding generation
- Create basic search API
- Add user authentication

Phase 2: Advanced Features
- Implement hybrid search
- Add real-time indexing
- Create web interface
- Add analytics and monitoring

Phase 3: Scaling and Optimization
- Performance optimization
- Horizontal scaling
- Advanced caching strategies
- API rate limiting

Current Status:
- Vector search: 80% complete
- Web UI: 60% complete
- Documentation: 90% complete
- Testing: 70% complete

Next Steps:
1. Complete vector search testing
2. Implement user authentication
3. Add real-time file monitoring
4. Set up production deployment
""",
        "metadata": {
            "project": "dinoair-planning",
            "type": "notes",
            "category": "planning",
            "lines": 30,
            "complexity": "low",
            "tags": ["planning", "notes", "project-management"],
        },
    },
]

SAMPLE_PROJECTS_DATA = [
    {
        "id": "project_001",
        "file_path": "/projects/dinoair-core/README.md",
        "file_name": "README.md",
        "file_type": "md",
        "content": """
# DinoAir Core

A powerful file search system with vector embeddings and AI-powered search capabilities.

## Features

- **Vector Search**: Semantic search using embeddings
- **Hybrid Search**: Combine vector and keyword search
- **Real-time Indexing**: Automatic file monitoring and indexing
- **REST API**: Full API for integration with other systems
- **Web Interface**: Modern React-based UI

## Architecture

- Backend: Python/FastAPI
- Vector DB: Qdrant
- Frontend: React/TypeScript
- Embeddings: sentence-transformers

## Quick Start

1. Install dependencies: pip install -r requirements.txt
2. Start Qdrant: docker run -p 6333:6333 qdrant/qdrant
3. Run server: python -m uvicorn main:app --reload
4. Open http://localhost:8000

## API Usage

Search files:
```bash
curl -X POST "http://localhost:8000/api/v1/search" \\
  -H "Content-Type: application/json" \\
  -d '{"query": "authentication functions", "limit": 10}'
```
""",
        "metadata": {
            "project": "dinoair-core",
            "type": "readme",
            "version": "1.0.0",
            "lines": 40,
            "complexity": "low",
            "tags": ["readme", "documentation", "project-overview"],
        },
    }
]

SAMPLE_NOTES_DATA = [
    {
        "id": "note_001",
        "file_path": "/notes/architecture-decisions.md",
        "file_name": "architecture-decisions.md",
        "file_type": "md",
        "content": """
# Architecture Decision Records

## ADR 001: Vector Database Selection

**Date**: 2024-01-15

**Context**:
Need to choose a vector database for storing and searching embeddings.

**Options Considered**:
1. Qdrant - Dedicated vector database
2. Pinecone - Managed vector service
3. Weaviate - Open source vector search
4. Elasticsearch - Extended with vector plugins

**Decision**:
Choose Qdrant as primary vector database.

**Rationale**:
- Open source and self-hostable
- Excellent performance for similarity search
- Rich Python client library
- Good documentation and community support
- Cost-effective for our scale

**Consequences**:
- Need to manage Qdrant deployment
- Additional operational overhead
- Need to implement backup strategies

## ADR 002: Embedding Model Selection

**Date**: 2024-01-16

**Decision**:
Use sentence-transformers all-MiniLM-L6-v2 for embeddings.

**Rationale**:
- Good balance of performance and size (384 dimensions)
- Works well for code and documentation
- Local execution (no API calls required)
- Good multilingual support
""",
        "metadata": {
            "type": "architecture",
            "category": "decisions",
            "adr_numbers": ["001", "002"],
            "lines": 50,
            "complexity": "medium",
            "tags": ["architecture", "decisions", "vector-db", "embeddings"],
        },
    }
]


def generate_mock_embeddings(text: str, dimensions: int = 384) -> List[float]:
    """Generate mock embeddings for text content."""
    import hashlib
    import struct

    # Create a simple hash-based embedding for demo purposes
    # In real implementation, this would use sentence-transformers
    hash_obj = hashlib.sha256(text.encode("utf-8"))
    hash_bytes = hash_obj.digest()

    # Convert hash to float values in range [-1, 1]
    embeddings = []
    for i in range(0, min(dimensions, len(hash_bytes) * 2), 2):
        # Convert 2 bytes to a float in range [-1, 1]
        if i + 1 < len(hash_bytes):
            value = struct.unpack("H", hash_bytes[i : i + 2])[0] / 65535.0  # Normalize to [0, 1]
            signed_value = (value - 0.5) * 2  # Convert to [-1, 1]
            embeddings.append(signed_value)

    # Pad or truncate to desired dimensions
    while len(embeddings) < dimensions:
        # Add some variation based on text length
        variation = (len(text) * i * 0.01) % 1.0
        embeddings.append((variation - 0.5) * 2)

    return embeddings[:dimensions]


def create_collection_with_mcp(
    mcp_server_url: str, collection_name: str, vector_size: int, api_key: str
):
    """Create a collection using MCP server."""
    import requests

    url = f"{mcp_server_url}/tools/call"
    headers = {"Content-Type": "application/json", "Authorization": f"Bearer {api_key}"}

    payload = {
        "name": "create_collection",
        "arguments": {
            "collection_name": collection_name,
            "vector_size": vector_size,
            "distance": "Cosine",
        },
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        response.raise_for_status()
        result = response.json()

        print(f"Created collection '{collection_name}': {result}")
        return True

    except Exception as e:
        print(f"Failed to create collection '{collection_name}': {e}")
        return False


def upload_points_with_mcp(
    mcp_server_url: str, collection_name: str, points: List[Dict], api_key: str
):
    """Upload points using MCP server."""
    import requests

    url = f"{mcp_server_url}/tools/call"
    headers = {"Content-Type": "application/json", "Authorization": f"Bearer {api_key}"}

    # Convert our data format to MCP format
    mcp_points = []
    for point in points:
        # Generate mock embedding
        embedding = generate_mock_embeddings(point["content"])

        mcp_point = {
            "id": point["id"],
            "vector": embedding,
            "payload": {
                "file_path": point["file_path"],
                "file_name": point["file_name"],
                "file_type": point["file_type"],
                "content": point["content"][:500],  # Truncate content
                "metadata": point["metadata"],
            },
        }
        mcp_points.append(mcp_point)

    payload = {
        "name": "upload_points",
        "arguments": {"collection_name": collection_name, "points": mcp_points},
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=60)
        response.raise_for_status()
        result = response.json()

        print(f"Uploaded {len(mcp_points)} points to '{collection_name}': {result}")
        return True

    except Exception as e:
        print(f"Failed to upload points to '{collection_name}': {e}")
        return False


def search_vectors_with_mcp(
    mcp_server_url: str,
    collection_name: str,
    query_text: str,
    api_key: str,
    limit: int = 5,
):
    """Search vectors using MCP server."""
    import requests

    # Generate embedding for query
    query_embedding = generate_mock_embeddings(query_text)

    url = f"{mcp_server_url}/tools/call"
    headers = {"Content-Type": "application/json", "Authorization": f"Bearer {api_key}"}

    payload = {
        "name": "search_vectors",
        "arguments": {
            "collection_name": collection_name,
            "query_vector": query_embedding,
            "limit": limit,
            "score_threshold": 0.5,
        },
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        response.raise_for_status()
        result = response.json()

        print(f"Search results for '{query_text}' in '{collection_name}':")
        print(json.dumps(result, indent=2))
        return result

    except Exception as e:
        print(f"Failed to search vectors in '{collection_name}': {e}")
        return None


def main():
    """Main function to populate Qdrant collections."""
    print("Populating Qdrant Collections with DinoAir3 Sample Data")
    print("=" * 60)

    # Configuration
    mcp_server_url = "http://localhost:8080"
    api_key = os.environ.get("QDRANT_API_KEY")

    if not api_key:
        print("Error: QDRANT_API_KEY environment variable not set")
        return 1

    print(f"MCP Server URL: {mcp_server_url}")
    print("API Key: <hidden>")

    # Test MCP server connection
    try:
        import requests

        response = requests.get(f"{mcp_server_url}/health", timeout=10)
        if response.status_code != 200:
            print(f"MCP server health check failed: {response.status_code}")
            print("Make sure the MCP server is running: python mcp_qdrant_server.py")
            return 1
    except Exception as e:
        print(f"Failed to connect to MCP server: {e}")
        print("Make sure the MCP server is running: python mcp_qdrant_server.py")
        return 1

    print("MCP server is running. Starting data population...")

    # Create collections and upload data
    collections_data = [
        ("dinoair_files", SAMPLE_FILES_DATA),
        ("dinoair_projects", SAMPLE_PROJECTS_DATA),
        ("dinoair_notes", SAMPLE_NOTES_DATA),
    ]

    for collection_name, data in collections_data:
        print(f"\n--- Processing {collection_name} ---")

        # Create collection
        if not create_collection_with_mcp(mcp_server_url, collection_name, 384, api_key):
            print(f"Skipping {collection_name} due to creation failure")
            continue

        # Upload points
        if not upload_points_with_mcp(mcp_server_url, collection_name, data, api_key):
            print(f"Failed to upload data to {collection_name}")
            continue

        print(f"Successfully populated {collection_name} with {len(data)} documents")

    # Demonstrate search functionality
    print("\n" + "=" * 60)
    print("DEMONSTRATING SEARCH FUNCTIONALITY")
    print("=" * 60)

    test_queries = [
        ("dinoair_files", "search functions"),
        ("dinoair_files", "authentication code"),
        ("dinoair_projects", "vector database"),
        ("dinoair_notes", "architecture decisions"),
    ]

    for collection_name, query in test_queries:
        print(f"\n--- Searching '{query}' in {collection_name} ---")
        search_vectors_with_mcp(mcp_server_url, collection_name, query, api_key, limit=3)

    print("\n" + "=" * 60)
    print("POPULATION COMPLETE!")
    print("=" * 60)
    print("Collections populated with sample DinoAir3 data:")
    print("- dinoair_files: Code files and scripts")
    print("- dinoair_projects: Project documentation")
    print("- dinoair_notes: Architecture and planning notes")
    print("\nYou can now use these collections for testing vector search!")
    print("Try different search queries to see semantic similarity in action.")

    return 0


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
