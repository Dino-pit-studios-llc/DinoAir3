#!/usr/bin/env python3
"""
Alternative Qdrant Setup Methods for DinoAir3

This script provides multiple ways to set up Qdrant:
1. Using Docker (if available)
2. Using Qdrant Cloud (recommended)
3. Using local Qdrant installation
4. Using in-memory Qdrant for testing
"""

import os
import sys
from pathlib import Path

from utils.process import safe_run

# Constants
QDRANT_DEFAULT_URL = "http://localhost:6333"


class QdrantSetupAlternatives:
    """Alternative setup methods for Qdrant."""

    def __init__(self, api_key: str):
        """Initialize with API key."""
        self.api_key = api_key
        self.project_root = Path(__file__).parent

    def check_docker_alternative(self) -> bool:
        """Try Docker setup, fallback to alternatives."""
        print("Attempting Docker setup...")

        try:
            # Check Docker
            safe_run(
                ["/usr/bin/docker", "--version"],
                allowed_binaries={"docker", "docker.exe"},
                timeout=60,
                check=True,
            )
            print("Docker is available")

            # Try to start Qdrant
            result = self.start_qdrant_docker()
            if not result:
                # Docker started but failed to connect, try alternatives
                print("Docker setup failed, trying alternatives...")
                return self.setup_alternatives()
            return result
        except Exception:
            print("Docker not available, trying alternatives...")
            return self.setup_alternatives()

    def start_qdrant_docker(self) -> bool:
        """Start Qdrant using Docker."""
        print("Starting Qdrant with Docker...")

        try:
            # Check if container exists
            result = safe_run(
                [
                    "/usr/bin/docker",
                    "ps",
                    "-a",
                    "--filter",
                    "name=qdrant-dinoair",
                    "--format",
                    "{{.Names}}",
                ],
                allowed_binaries={"docker", "docker.exe"},
                timeout=60,
                check=True,
            )

            if "qdrant-dinoair" in result.stdout:
                safe_run(
                    ["/usr/bin/docker", "start", "qdrant-dinoair"],
                    allowed_binaries={"docker", "docker.exe"},
                    timeout=120,
                    check=True,
                )
            else:
                safe_run(
                    [
                        "/usr/bin/docker",
                        "run",
                        "-d",
                        "--name",
                        "qdrant-dinoair",
                        "-p",
                        "6333:6333",
                        "-p",
                        "6334:6334",
                        "-e",
                        f"QDRANT__SERVICE__API_KEY={self.api_key}",
                        "qdrant/qdrant:latest",
                    ],
                    allowed_binaries={"docker", "docker.exe"},
                    timeout=300,
                    check=True,
                    env={"QDRANT__SERVICE__API_KEY": self.api_key},
                )

            # Test connection
            return self.test_qdrant_connection(QDRANT_DEFAULT_URL)

        except Exception as e:
            print(f"Docker setup failed: {e}")
            return False

    def setup_qdrant_cloud(self) -> bool:
        """Set up Qdrant Cloud connection."""
        print("\nSetting up Qdrant Cloud connection...")

        # For demo, we'll use a mock cloud URL
        # In real usage, user would provide their Qdrant Cloud URL
        cloud_url = input(
            "Enter your Qdrant Cloud URL (e.g., https://your-project.cloud.qdrant.io): "
        ).strip()

        if not cloud_url:
            print("No cloud URL provided, using localhost for demo")
            cloud_url = QDRANT_DEFAULT_URL

        return self.test_qdrant_connection(cloud_url)

    def setup_local_qdrant(self) -> bool:
        """Set up local Qdrant installation."""
        print("\nSetting up local Qdrant installation...")

        print("To install Qdrant locally:")
        print("1. Download from: https://qdrant.tech/download/")
        print("2. Or install with Homebrew (macOS): brew install qdrant")
        print("3. Or use the binary installer")

        # For demo, try to connect to localhost
        return self.test_qdrant_connection(QDRANT_DEFAULT_URL)

    def setup_memory_qdrant(self) -> bool:
        """Set up in-memory Qdrant for testing."""
        print("\nSetting up in-memory Qdrant for testing...")

        try:
            from qdrant_client import QdrantClient

            # Create in-memory client
            client = QdrantClient(location=":memory:", api_key=self.api_key)

            # Test basic functionality
            health = client.health()
            print(f"In-memory Qdrant ready: {health.title}")

            # Store client for later use
            self.memory_client = client
            return True

        except ImportError:
            print("qdrant-client not installed")
            return False
        except Exception as e:
            print(f"In-memory Qdrant setup failed: {e}")
            return False

    def setup_alternatives(self) -> bool:
        """Try alternative setup methods."""
        print("\nTrying alternative setup methods...")

        methods = [
            ("Qdrant Cloud", self.setup_qdrant_cloud),
            ("Local Installation", self.setup_local_qdrant),
            ("In-Memory (Testing)", self.setup_memory_qdrant),
        ]

        for method_name, method_func in methods:
            print(f"\nTrying {method_name}...")
            if method_func():
                print(f"Successfully set up Qdrant with {method_name}")
                return True

        return False

    def test_qdrant_connection(self, url: str) -> bool:
        """Test connection to Qdrant server."""
        print(f"Testing connection to {url}...")

        try:
            from qdrant_client import QdrantClient

            client = QdrantClient(url=url, api_key=self.api_key, timeout=10)

            # Test health
            health = client.health()
            print(f"Connected to Qdrant: {health.title} v{health.version}")

            # Test collections
            collections = client.get_collections()
            print(f"Found {len(collections.collections)} collections")

            self.qdrant_url = url
            self.client = client
            return True

        except Exception as e:
            print(f"Connection failed: {e}")
            return False

    def create_demo_collections(self) -> bool:
        """Create demo collections for DinoAir3."""
        print("\nCreating demo collections...")

        if hasattr(self, "memory_client"):
            client = self.memory_client
        elif hasattr(self, "client"):
            client = self.client
        else:
            print("No Qdrant client available")
            return False

        try:
            from qdrant_client.models import Distance, VectorParams

            collections = [
                {
                    "name": "dinoair_files_demo",
                    "vector_size": 384,
                    "distance": Distance.COSINE,
                },
                {
                    "name": "dinoair_projects_demo",
                    "vector_size": 384,
                    "distance": Distance.COSINE,
                },
            ]

            for collection in collections:
                try:
                    client.get_collection(collection["name"])
                    print(f"Collection '{collection['name']}' already exists")
                except Exception:
                    client.create_collection(
                        collection_name=collection["name"],
                        vectors_config=VectorParams(
                            size=collection["vector_size"],
                            distance=collection["distance"],
                        ),
                    )
                    print(f"Created collection '{collection['name']}'")

            return True

        except Exception as e:
            print(f"Failed to create collections: {e}")
            return False

    def populate_demo_data(self) -> bool:
        """Populate collections with demo data."""
        print("\nPopulating with demo data...")

        if hasattr(self, "memory_client"):
            client = self.memory_client
        elif hasattr(self, "client"):
            client = self.client
        else:
            print("No Qdrant client available")
            return False

        try:
            # Demo embeddings (384 dimensions)
            import random

            from qdrant_client.models import PointStruct

            random.seed(42)  # For reproducible results

            demo_points = [
                PointStruct(
                    id="demo_001",
                    vector=[random.random() for _ in range(384)],
                    payload={
                        "file_path": "/demo/search_engine.py",
                        "file_name": "search_engine.py",
                        "file_type": "py",
                        "content": "class SearchEngine:\n    def search(self, query):",
                        "metadata": {"project": "demo", "type": "code"},
                    },
                ),
                PointStruct(
                    id="demo_002",
                    vector=[random.random() for _ in range(384)],
                    payload={
                        "file_path": "/demo/readme.md",
                        "file_name": "readme.md",
                        "file_type": "md",
                        "content": "# Demo Project\nThis is a demo file.",
                        "metadata": {"project": "demo", "type": "documentation"},
                    },
                ),
            ]

            # Upload to first collection
            collection_name = "dinoair_files_demo"
            try:
                from qdrant_client.http.exceptions import UnexpectedResponse

                client.get_collection(collection_name)
            except UnexpectedResponse:
                print(f"Collection '{collection_name}' not found, creating...")
                from qdrant_client.models import Distance, VectorParams

                client.create_collection(
                    collection_name=collection_name,
                    vectors_config=VectorParams(size=384, distance=Distance.COSINE),
                )

            operation_info = client.upsert(collection_name=collection_name, points=demo_points)

            print(f"Uploaded {len(demo_points)} demo points")
            print(f"Operation ID: {operation_info.operation_id}")
            return True

        except Exception as e:
            print(f"Failed to populate demo data: {e}")
            return False

    def test_search_functionality(self) -> bool:
        """Test search functionality."""
        print("\nTesting search functionality...")

        if hasattr(self, "memory_client"):
            client = self.memory_client
            collection_name = "dinoair_files_demo"
        elif hasattr(self, "client"):
            client = self.client
            collection_name = "dinoair_files_demo"
        else:
            print("No Qdrant client available")
            return False

        try:
            # Search with a query vector
            import random

            random.seed(123)
            query_vector = [random.random() for _ in range(384)]

            results = client.search(
                collection_name=collection_name, query_vector=query_vector, limit=3
            )

            print(f"Search returned {len(results)} results:")
            for i, result in enumerate(results):
                print(
                    f"  {i + 1}. {result.payload.get('file_name', 'Unknown')} (score: {result.score:.3f})"
                )

            return True

        except Exception as e:
            print(f"Search test failed: {e}")
            return False

    def show_setup_summary(self):
        """Show setup summary and next steps."""
        print("\n" + "=" * 60)
        print("QDRANT SETUP SUMMARY")
        print("=" * 60)

        if hasattr(self, "qdrant_url"):
            print(f"Qdrant URL: {self.qdrant_url}")
        else:
            print("Qdrant URL: In-memory instance")

        if hasattr(self, "client") or hasattr(self, "memory_client"):
            print("Status: Connected and ready")
        else:
            print("Status: Not connected")

        print("\nCollections:")
        print("  dinoair_files_demo    - Demo file embeddings")
        print("  dinoair_projects_demo - Demo project data")

        print("\nNext Steps:")
        print("1. Start MCP server: python mcp_qdrant_server.py")
        print("2. Test search: python demo_qdrant_mcp.py")
        print("3. Add real data: python populate_qdrant_collections.py")
        print("4. Integrate with DinoAir3 application")

        print("\nAlternative Setup Methods:")
        print("1. Docker (if available): python start_qdrant_server.py")
        print("2. Qdrant Cloud: Use your cloud instance URL")
        print("3. Local install: Download from qdrant.tech")
        print("4. In-memory: For testing and development")

    def run_setup(self) -> bool:
        """Run the setup process."""
        print("Setting up Qdrant for DinoAir3 (Alternative Methods)")
        print("=" * 60)

        # Try different setup methods
        if not self.check_docker_alternative():
            print("All setup methods failed")
            return False

        # If we have a client, set up demo collections
        if hasattr(self, "client") or hasattr(self, "memory_client"):
            if not self.create_demo_collections():
                print("Failed to create demo collections")
                return False

            if not self.populate_demo_data():
                print("Failed to populate demo data")
                return False

            if not self.test_search_functionality():
                print("Search functionality test failed")
                return False

        self.show_setup_summary()
        return True


def main():
    """Main setup function."""
    import argparse
    import re

    parser = argparse.ArgumentParser(description="Setup Qdrant for DinoAir3 (Alternative Methods)")
    parser.add_argument("--api-key", help="Qdrant API key")
    parser.add_argument("--qdrant-url", help="Qdrant server URL")

    args = parser.parse_args()

    # Get API key
    api_key = args.api_key or os.getenv("QDRANT_API_KEY")
    if not api_key:
        print("Error: Qdrant API key required!")
        print("Provide with --api-key or set QDRANT_API_KEY environment variable")
        return 1

    # Sanitize API key: must be alphanumeric and dash/underscore only
    if not re.fullmatch(r'[A-Za-z0-9_\-]+', api_key):
        print("Error: API key contains invalid characters. Allowed: letters, numbers, - and _")
        return 1

    print("Setting up Qdrant...")

    setup = QdrantSetupAlternatives(api_key)

    if args.qdrant_url:
        setup.qdrant_url = args.qdrant_url
        if setup.test_qdrant_connection(args.qdrant_url):
            setup.create_demo_collections()
            setup.populate_demo_data()
            setup.test_search_functionality()
            setup.show_setup_summary()
            return 0

    success = setup.run_setup()
    return 0 if success else 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
