#!/usr/bin/env python3
"""
Simple Qdrant Demo for DinoAir3

This script demonstrates Qdrant functionality using in-memory storage
for testing and development without requiring Docker or external services.
"""

import time
from datetime import datetime
from typing import Dict, List

import numpy as np


class SimpleInMemoryQdrant:
    """Simple in-memory Qdrant-like vector database for demo purposes."""

    def __init__(self):
        """Initialize in-memory vector database."""
        self.collections = {}
        self.points = {}  # collection_name -> {point_id -> point_data}

    def create_collection(
        self, collection_name: str, vector_size: int = 384, distance: str = "Cosine"
    ):
        """Create a new collection."""
        if collection_name in self.collections:
            raise ValueError(f"Collection '{collection_name}' already exists")

        self.collections[collection_name] = {
            "name": collection_name,
            "vector_size": vector_size,
            "distance": distance,
            "points_count": 0,
            "created_at": datetime.now().isoformat(),
        }
        self.points[collection_name] = {}

        print(
            f"Created collection '{collection_name}' with vector_size={vector_size}, distance={distance}"
        )

    def upsert_points(self, collection_name: str, points: List[Dict]) -> Dict:
        """Upload points to a collection."""
        if collection_name not in self.collections:
            raise ValueError(f"Collection '{collection_name}' does not exist")

        collection_points = self.points[collection_name]

        for point in points:
            point_id = point["id"]
            collection_points[point_id] = {
                "id": point_id,
                "vector": point["vector"],
                "payload": point.get("payload", {}),
                "created_at": datetime.now().isoformat(),
            }

        # Update collection stats
        self.collections[collection_name]["points_count"] = len(collection_points)

        return {
            "operation_id": f"op_{int(time.time())}",
            "status": "completed",
            "points_uploaded": len(points),
        }

    def search(
        self,
        collection_name: str,
        query_vector: List[float],
        limit: int = 10,
        score_threshold: float = 0.0,
    ) -> List[Dict]:
        """Search for similar vectors."""
        if collection_name not in self.collections:
            raise ValueError(f"Collection '{collection_name}' does not exist")

        collection_points = self.points[collection_name]

        if not collection_points:
            return []

        # Calculate cosine similarity for all points
        results = []
        query_vector = np.array(query_vector)

        for point_id, point_data in collection_points.items():
            point_vector = np.array(point_data["vector"])

            # Cosine similarity
            dot_product = np.dot(query_vector, point_vector)
            query_norm = np.linalg.norm(query_vector)
            point_norm = np.linalg.norm(point_vector)

            if query_norm == 0 or point_norm == 0:
                similarity = 0.0
            else:
                similarity = dot_product / (query_norm * point_norm)

            if similarity >= score_threshold:
                results.append(
                    {
                        "id": point_id,
                        "score": float(similarity),
                        "payload": point_data["payload"],
                        "vector": point_data["vector"][:10],  # First 10 dimensions
                    }
                )

        # Sort by similarity score (descending) and limit results
        results.sort(key=lambda x: x["score"], reverse=True)
        return results[:limit]

    def get_collection_info(self, collection_name: str) -> Dict:
        """Get information about a collection."""
        if collection_name not in self.collections:
            raise ValueError(f"Collection '{collection_name}' does not exist")

        collection = self.collections[collection_name]

        return {
            "name": collection["name"],
            "status": "green",
            "vectors_count": collection["points_count"],
            "points_count": collection["points_count"],
            "config": {
                "params": {
                    "vectors": {
                        "size": collection["vector_size"],
                        "distance": collection["distance"],
                    }
                }
            },
        }

    def list_collections(self) -> Dict:
        """List all collections."""
        collections = []

        for name, info in self.collections.items():
            collections.append(
                {"name": name, "status": "green", "vectors_count": info["points_count"]}
            )

        return {"collections": collections, "total": len(collections)}


def generate_mock_embedding(text: str, dimensions: int = 384) -> List[float]:
    """Generate a mock embedding for text content."""
    # Create a deterministic embedding based on text hash
    import hashlib

    hash_obj = hashlib.sha256(text.encode("utf-8"))
    hash_bytes = hash_obj.digest()

    # Convert to float values in range [-1, 1]
    embedding = []
    for i in range(dimensions):
        # Use hash bytes to create pseudo-random values
        byte_value = hash_bytes[i % len(hash_bytes)]
        # Add some variation based on character positions
        char_factor = ord(text[i % len(text)]) / 255.0
        value = (byte_value / 255.0 + char_factor * 0.1) % 1.0
        signed_value = (value - 0.5) * 2  # Convert to [-1, 1]
        embedding.append(signed_value)

    return embedding


def create_sample_dinoair_data() -> List[Dict]:
    """Create sample DinoAir3 data for demonstration."""
    sample_files = [
        {
            "id": "dinoair_search_001",
            "file_path": "/src/dinoair/search_engine.py",
            "file_name": "search_engine.py",
            "file_type": "py",
            "content": """
class SearchEngine:
    def __init__(self):
        self.vector_store = None
        self.embedding_model = "all-MiniLM-L6-v2"

    def search(self, query: str) -> List[Dict]:
        \"\"\"Search for relevant documents using vector similarity.\"\"\"
        # Generate query embedding
        query_embedding = self.generate_embedding(query)

        # Search vector database
        results = self.vector_store.search(query_embedding)

        return results

    def generate_embedding(self, text: str) -> List[float]:
        \"\"\"Generate embedding vector for text.\"\"\"
        # Implementation would use sentence-transformers
        return [0.1] * 384
""",
            "metadata": {
                "project": "dinoair-core",
                "module": "search",
                "complexity": "high",
                "lines": 25,
                "tags": ["search", "vector", "python", "embeddings"],
            },
        },
        {
            "id": "dinoair_api_001",
            "file_path": "/src/dinoair/api.py",
            "file_name": "api.py",
            "file_type": "py",
            "content": """
from fastapi import FastAPI, HTTPException
from typing import List, Dict

app = FastAPI(title="DinoAir API")

@app.post("/api/v1/search")
async def search_files(query: str, limit: int = 10) -> Dict:
    \"\"\"Search for files using natural language queries.\"\"\"
    try:
        results = search_engine.search(query, limit)
        return {"results": results, "total": len(results)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/health")
async def health_check():
    \"\"\"Health check endpoint.\"\"\"
    return {"status": "healthy", "service": "dinoair-api"}
""",
            "metadata": {
                "project": "dinoair-core",
                "module": "api",
                "complexity": "medium",
                "lines": 20,
                "tags": ["api", "fastapi", "python", "rest"],
            },
        },
        {
            "id": "dinoair_ui_001",
            "file_path": "/ui/src/components/SearchBox.jsx",
            "file_name": "SearchBox.jsx",
            "file_type": "jsx",
            "content": """
import React, { useState } from 'react';
import { searchAPI } from '../services/api';

const SearchBox = () => {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);

  const handleSearch = async () => {
    if (!query.trim()) return;

    setLoading(true);
    try {
      const response = await searchAPI.search(query);
      setResults(response.results);
    } catch (error) {
      console.error('Search failed:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="search-box">
      <input
        type="text"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Search files..."
        onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
      />
      <button onClick={handleSearch} disabled={loading}>
        {loading ? 'Searching...' : 'Search'}
      </button>
    </div>
  );
};

export default SearchBox;
""",
            "metadata": {
                "project": "dinoair-ui",
                "framework": "react",
                "component": "SearchBox",
                "complexity": "medium",
                "lines": 35,
                "tags": ["react", "javascript", "ui", "search"],
            },
        },
        {
            "id": "dinoair_docs_001",
            "file_path": "/docs/architecture.md",
            "file_name": "architecture.md",
            "file_type": "md",
            "content": """
# DinoAir Architecture Overview

## System Components

### Backend (Python/FastAPI)
- **Search Engine**: Vector-based document search
- **API Layer**: RESTful endpoints for client communication
- **Database**: SQLite for metadata, Qdrant for vectors
- **Embedding Service**: Local sentence-transformers integration

### Frontend (React/TypeScript)
- **Search Interface**: Natural language query interface
- **Results Display**: Formatted file and content results
- **Settings Panel**: Configuration and customization options

### Vector Database (Qdrant)
- **Document Embeddings**: 384-dimensional vectors using all-MiniLM-L6-v2
- **Similarity Search**: Cosine similarity for semantic matching
- **Metadata Storage**: File information and search statistics

## Data Flow

1. User submits natural language query
2. Frontend sends query to backend API
3. Backend generates query embedding
4. Qdrant performs vector similarity search
5. Results are formatted and returned
6. Frontend displays results with highlighting

## Performance Considerations

- Embedding generation is cached
- Vector search uses approximate nearest neighbors
- Results are paginated for large datasets
- Database queries are optimized with proper indexing
""",
            "metadata": {
                "project": "dinoair-docs",
                "type": "architecture",
                "section": "overview",
                "complexity": "low",
                "lines": 45,
                "tags": ["documentation", "architecture", "markdown"],
            },
        },
    ]

    return sample_files


def main():
    """Main demo function."""
    print("Simple Qdrant Demo for DinoAir3")
    print("=" * 50)

    # Initialize in-memory Qdrant
    qdrant = SimpleInMemoryQdrant()

    # Create collections
    print("\n1. Creating collections...")
    collections_to_create = [
        ("dinoair_files", 384, "Cosine"),
        ("dinoair_projects", 384, "Cosine"),
        ("dinoair_notes", 384, "Cosine"),
    ]

    for name, vector_size, distance in collections_to_create:
        qdrant.create_collection(name, vector_size, distance)

    # Get sample data
    print("\n2. Preparing sample data...")
    sample_files = create_sample_dinoair_data()
    print(f"Created {len(sample_files)} sample files")

    # Upload to collections
    print("\n3. Uploading embeddings...")

    # Upload to dinoair_files collection
    files_collection = "dinoair_files"
    files_points = []

    for file_data in sample_files:
        # Generate embedding for file content
        embedding = generate_mock_embedding(file_data["content"])

        point = {
            "id": file_data["id"],
            "vector": embedding,
            "payload": {
                "file_path": file_data["file_path"],
                "file_name": file_data["file_name"],
                "file_type": file_data["file_type"],
                "content": file_data["content"][:500],  # Truncate for demo
                "metadata": file_data["metadata"],
            },
        }
        files_points.append(point)

    # Upload points
    upload_result = qdrant.upsert_points(files_collection, files_points)
    print(f"Uploaded {upload_result['points_uploaded']} points to {files_collection}")

    # Demonstrate search functionality
    print("\n4. Testing search functionality...")

    # Search queries
    test_queries = [
        "search functions and API",
        "React components and UI",
        "documentation and architecture",
        "Python code and classes",
    ]

    for query in test_queries:
        print(f"\n--- Searching for: '{query}' ---")

        # Generate query embedding
        query_embedding = generate_mock_embedding(query)

        # Search
        results = qdrant.search(
            collection_name=files_collection,
            query_vector=query_embedding,
            limit=3,
            score_threshold=0.1,
        )

        print(f"Found {len(results)} results:")
        for i, result in enumerate(results, 1):
            file_name = result["payload"]["file_name"]
            score = result["score"]
            file_type = result["payload"]["file_type"]
            print(f"  {i}. {file_name} ({file_type}) - Score: {score:.3f}")

    # Show collection info
    print("\n5. Collection Information...")
    for collection_name in qdrant.collections:
        info = qdrant.get_collection_info(collection_name)
        print(f"  {collection_name}: {info['points_count']} points")

    # List all collections
    print("\n6. All Collections...")
    collections_info = qdrant.list_collections()
    for collection in collections_info["collections"]:
        print(f"  - {collection['name']}: {collection['vectors_count']} vectors")

    print("\n" + "=" * 50)
    print("DEMO COMPLETE!")
    print("=" * 50)
    print("This demo shows how Qdrant would work with DinoAir3 data.")
    print("In a real deployment, you would:")
    print("1. Use actual sentence-transformers for embeddings")
    print("2. Connect to a real Qdrant server")
    print("3. Load real file content from your codebase")
    print("4. Set up the MCP server for AI integration")

    print("\nTo use with real Qdrant:")
    print("1. Start Qdrant server (Docker or local installation)")
    print("2. Run: python mcp_qdrant_server.py")
    print("3. Run: python populate_qdrant_collections.py")
    print("4. Test with: python demo_qdrant_mcp.py")


if __name__ == "__main__":
    main()
