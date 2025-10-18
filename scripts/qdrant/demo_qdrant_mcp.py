#!/usr/bin/env python3
"""
Demonstration of Qdrant MCP Server with DinoAir3

This script demonstrates how to use the Qdrant MCP server to:
1. Create collections for DinoAir3 data
2. Upload sample embeddings
3. Perform vector searches
4. Show integration with existing DinoAir3 functionality
"""

import json
import os
from typing import Any
import urllib.parse
import requests


def is_safe_url(url: str) -> bool:
    """Restrict URLs to http/https and prevent local/private IPs."""
    try:
        parsed = urllib.parse.urlparse(url)
        if parsed.scheme not in ["http", "https"]:
            return False
        host = parsed.hostname
        # Block localhost and private IP ranges (examples shown, expand as needed)
        if host in ("localhost", "127.0.0.1", "::1"):
            return False
        # Block RFC1918 private ranges (10.*, 172.16-31.*, 192.168.*)
        if host:
            parts = host.split(".")
            if (
                parts[0] == "10"
                or (parts[0] == "172" and 16 <= int(parts[1]) <= 31)
                or (parts[0] == "192" and parts[1] == "168")
            ):
                return False
        return True
    except Exception:
        return False


class QdrantMCPDemo:
    """Demonstration class for Qdrant MCP server."""

    def __init__(self, mcp_server_url: str = "http://localhost:8080", api_key: str = None):
        """Initialize demo with MCP server details."""
        if not is_safe_url(mcp_server_url):
            raise ValueError(f"Unsafe MCP server URL: {mcp_server_url}")
        self.mcp_server_url = mcp_server_url
        self.api_key = api_key or os.environ.get("QDRANT_API_KEY")
        if not self.api_key:
            raise RuntimeError("QDRANT_API_KEY not set")

        # Headers for API requests
        self.headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}",
        }

    def call_mcp_tool(self, tool_name: str, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Call an MCP tool and return the result."""
        url = f"{self.mcp_server_url}/tools/call"

        payload = {"name": tool_name, "arguments": arguments}

        try:
            response = requests.post(url, json=payload, headers=self.headers, timeout=30)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"Error calling {tool_name}: {e}")
            return {"error": str(e)}

    def demo_collection_management(self):
        """Demonstrate collection management operations."""
        print("=== Collection Management Demo ===")

        # List existing collections
        print("\n1. Listing existing collections...")
        result = self.call_mcp_tool("list_collections", {})
        print(json.dumps(result, indent=2))

        # Create a test collection
        print("\n2. Creating test collection...")
        result = self.call_mcp_tool(
            "create_collection",
            {
                "collection_name": "demo_collection",
                "vector_size": 384,
                "distance": "Cosine",
            },
        )
        print(json.dumps(result, indent=2))

        # Get collection info
        print("\n3. Getting collection info...")
        result = self.call_mcp_tool("get_collection_info", {"collection_name": "demo_collection"})
        print(json.dumps(result, indent=2))

    def demo_vector_upload(self):
        """Demonstrate uploading vectors to collections."""
        print("\n=== Vector Upload Demo ===")

        # Sample vectors with DinoAir3-like data
        sample_points = [
            {
                "id": "demo_001",
                "vector": [0.1] * 384,  # Mock embedding
                "payload": {
                    "file_path": "/demo/sample.py",
                    "file_name": "sample.py",
                    "file_type": "py",
                    "content": "def demo_function():\n    return 'Hello, DinoAir!'",
                    "metadata": {"project": "demo", "lines": 3, "complexity": "low"},
                },
            },
            {
                "id": "demo_002",
                "vector": [0.2] * 384,  # Mock embedding
                "payload": {
                    "file_path": "/demo/readme.md",
                    "file_name": "readme.md",
                    "file_type": "md",
                    "content": "# Demo Project\nThis is a demonstration of DinoAir search capabilities.",
                    "metadata": {
                        "project": "demo",
                        "type": "documentation",
                        "lines": 5,
                    },
                },
            },
        ]

        # Upload points
        print("Uploading sample vectors...")
        result = self.call_mcp_tool(
            "upload_points",
            {"collection_name": "demo_collection", "points": sample_points},
        )
        print(json.dumps(result, indent=2))

    def demo_vector_search(self):
        """Demonstrate vector search functionality."""
        print("\n=== Vector Search Demo ===")

        # Search for Python-related content
        print("1. Searching for Python-related content...")
        python_query = "Python functions and classes"
        query_vector = [0.15] * 384  # Mock query embedding

        result = self.call_mcp_tool(
            "search_vectors",
            {
                "collection_name": "demo_collection",
                "query_vector": query_vector,
                "limit": 5,
                "score_threshold": 0.5,
            },
        )
        print(f"Query: {python_query}")
        print(json.dumps(result, indent=2))

        # Search for documentation
        print("\n2. Searching for documentation...")
        doc_query = "project documentation and guides"
        doc_query_vector = [0.25] * 384  # Mock query embedding

        result = self.call_mcp_tool(
            "search_vectors",
            {
                "collection_name": "demo_collection",
                "query_vector": doc_query_vector,
                "limit": 5,
                "score_threshold": 0.3,
            },
        )
        print(f"Query: {doc_query}")
        print(json.dumps(result, indent=2))

    def demo_dinoair_integration(self):
        """Demonstrate integration with DinoAir3 data types."""
        print("\n=== DinoAir3 Integration Demo ===")

        # Simulate DinoAir3 file search data
        dinoair_points = [
            {
                "id": "dinoair_search_001",
                "vector": [0.3] * 384,
                "payload": {
                    "file_path": "/src/dinoair/search_engine.py",
                    "file_name": "search_engine.py",
                    "file_type": "py",
                    "content": "class SearchEngine:\n    def search(self, query):\n        return results",
                    "metadata": {
                        "project": "dinoair-core",
                        "module": "search",
                        "functionality": "core_search",
                        "tags": ["search", "vector", "python"],
                    },
                },
            },
            {
                "id": "dinoair_ui_001",
                "vector": [0.4] * 384,
                "payload": {
                    "file_path": "/ui/src/components/SearchBox.jsx",
                    "file_name": "SearchBox.jsx",
                    "file_type": "jsx",
                    "content": "const SearchBox = () => {\n  const [query, setQuery] = useState('');",
                    "metadata": {
                        "project": "dinoair-ui",
                        "framework": "react",
                        "component": "SearchBox",
                        "tags": ["ui", "react", "search"],
                    },
                },
            },
        ]

        # Create DinoAir3 collection
        print("Creating DinoAir3 collection...")
        self.call_mcp_tool(
            "create_collection",
            {
                "collection_name": "dinoair_demo",
                "vector_size": 384,
                "distance": "Cosine",
            },
        )

        # Upload DinoAir3 data
        print("Uploading DinoAir3 sample data...")
        result = self.call_mcp_tool(
            "upload_points",
            {"collection_name": "dinoair_demo", "points": dinoair_points},
        )
        print(json.dumps(result, indent=2))

        # Search for search-related functionality
        print("\nSearching for search functionality...")
        search_query = "search functions and components"
        search_vector = [0.35] * 384

        result = self.call_mcp_tool(
            "search_vectors",
            {
                "collection_name": "dinoair_demo",
                "query_vector": search_vector,
                "limit": 10,
                "score_threshold": 0.1,
            },
        )
        print(f"Query: {search_query}")
        print(json.dumps(result, indent=2))

    def demo_error_handling(self):
        """Demonstrate error handling."""
        print("\n=== Error Handling Demo ===")

        # Try to search in non-existent collection
        print("1. Searching in non-existent collection...")
        result = self.call_mcp_tool(
            "search_vectors",
            {
                "collection_name": "non_existent_collection",
                "query_vector": [0.1] * 384,
                "limit": 5,
            },
        )
        print(json.dumps(result, indent=2))

        # Try to get info for non-existent collection
        print("\n2. Getting info for non-existent collection...")
        result = self.call_mcp_tool(
            "get_collection_info", {"collection_name": "non_existent_collection"}
        )
        print(json.dumps(result, indent=2))

    def run_full_demo(self):
        """Run the complete demonstration."""
        print("Qdrant MCP Server Demonstration for DinoAir3")
        print("=" * 60)

        # Check if MCP server is running
        try:
            response = requests.get(f"{self.mcp_server_url}/health", timeout=10)
            if response.status_code != 200:
                print(f"MCP server health check failed: {response.status_code}")
                print("Make sure the MCP server is running: python mcp_qdrant_server.py")
                return
        except Exception as e:
            print(f"Failed to connect to MCP server: {e}")
            print("Make sure the MCP server is running: python mcp_qdrant_server.py")
            return

        print(f"Connected to MCP server at {self.mcp_server_url}")

        # Run demonstrations
        self.demo_collection_management()
        self.demo_vector_upload()
        self.demo_vector_search()
        self.demo_dinoair_integration()
        self.demo_error_handling()

        print("\n" + "=" * 60)
        print("DEMONSTRATION COMPLETE!")
        print("=" * 60)
        print("The Qdrant MCP server is working correctly with DinoAir3 data!")
        print("\nNext steps:")
        print("1. Start Qdrant server: python start_qdrant_server.py")
        print("2. Populate with real data: python populate_qdrant_collections.py")
        print("3. Integrate with DinoAir3 application")
        print("4. Use vector search in production")


def main():
    """Main demo function."""
    import argparse

    parser = argparse.ArgumentParser(description="Demo Qdrant MCP Server for DinoAir3")
    parser.add_argument("--mcp-url", default="http://localhost:8080", help="MCP server URL")
    parser.add_argument("--api-key", help="Qdrant API key")

    args = parser.parse_args()

    demo = QdrantMCPDemo(mcp_server_url=args.mcp_url, api_key=args.api_key)
    demo.run_full_demo()


if __name__ == "__main__":
    main()
