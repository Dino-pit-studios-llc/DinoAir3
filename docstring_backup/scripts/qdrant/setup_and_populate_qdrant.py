#!/usr/bin/env python3
"""
Complete Qdrant Setup and Population Script for DinoAir3

This script provides a one-command solution to:
1. Set up Qdrant MCP server
2. Start Qdrant database
3. Create DinoAir3 collections
4. Populate with relevant embeddings
5. Test the integration

Usage:
    python setup_and_populate_qdrant.py --api-key YOUR_API_KEY
"""

import os
import sys
import time
from pathlib import Path

import requests

from utils.process import PYTHON_EXE, safe_popen, safe_run

# Constants
QDRANT_DEFAULT_URL = "http://localhost:6333"


class QdrantSetupManager:
    """Complete setup manager for Qdrant MCP integration."""

    def __init__(self, api_key: str):
        """Initialize setup manager."""
        self.api_key = api_key
        self.project_root = Path(__file__).parent

        # Set environment
        os.environ["QDRANT_API_KEY"] = api_key
        os.environ["QDRANT_URL"] = QDRANT_DEFAULT_URL

    def install_dependencies(self) -> bool:
        """Install all required dependencies."""
        print("Installing dependencies...")

        try:
            safe_run(
                [
                    sys.executable,
                    "-m",
                    "pip",
                    "install",
                    "-r",
                    str(self.project_root / "mcp_qdrant_requirements.txt"),
                ],
                allowed_binaries={Path(sys.executable).name, "python", PYTHON_EXE},
                timeout=300,
                check=True,
            )
            print("Dependencies installed successfully")
            return True
        except Exception as e:
            print(f"Failed to install dependencies: {e}")
            return False

    def start_qdrant_server(self) -> bool:
        """Start Qdrant server with Docker."""
        print("Starting Qdrant server...")

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
                # Pass API key via environment to avoid logging secrets in argv
                _env = os.environ.copy()
                _env["QDRANT__SERVICE__API_KEY"] = self.api_key
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
                        "QDRANT__SERVICE__API_KEY",
                        "qdrant/qdrant:latest",
                    ],
                    allowed_binaries={"docker", "docker.exe"},
                    timeout=300,
                    check=True,
                    env=_env,
                )

            # Wait for ready
            for _ in range(30):
                try:
                    response = requests.get("http://localhost:6333/health", timeout=5)
                    if response.status_code == 200:
                        print("Qdrant server is ready!")
                        return True
                except requests.exceptions.RequestException:
                    pass
                time.sleep(1)

            return False

        except Exception as e:
            print(f"Failed to start Qdrant server: {e}")
            return False

    def start_mcp_server(self) -> bool:
        """Start MCP server."""
        print("Starting MCP server...")

        try:
            process = safe_popen(
                [sys.executable, str(self.project_root / "mcp_qdrant_server.py")],
                allowed_binaries={Path(sys.executable).name, "python", PYTHON_EXE},
                cwd=self.project_root,
            )

            # Wait for server to be ready
            for _ in range(30):
                try:
                    response = requests.get("http://localhost:8080/health", timeout=5)
                    if response.status_code == 200:
                        print("MCP server is ready!")
                        return True
                except requests.exceptions.RequestException:
                    pass
                time.sleep(1)

            process.terminate()
            return False

        except Exception as e:
            print(f"Failed to start MCP server: {e}")
            return False

    def create_dinoair_collections(self) -> bool:
        """Create collections for DinoAir3 data types."""
        print("Creating DinoAir3 collections...")

        try:
            from qdrant_client import QdrantClient
            from qdrant_client.models import Distance, VectorParams

            client = QdrantClient(url=QDRANT_DEFAULT_URL, api_key=self.api_key)

            collections = [
                {
                    "name": "dinoair_files",
                    "description": "File embeddings for DinoAir3 search",
                    "vector_size": 384,
                    "distance": Distance.COSINE,
                },
                {
                    "name": "dinoair_projects",
                    "description": "Project embeddings for discovery",
                    "vector_size": 384,
                    "distance": Distance.COSINE,
                },
                {
                    "name": "dinoair_notes",
                    "description": "Note embeddings for semantic search",
                    "vector_size": 384,
                    "distance": Distance.COSINE,
                },
            ]

            for collection in collections:
                try:
                    client.get_collection(collection["name"])
                    print(f"Collection '{collection['name']}' already exists")
                except requests.exceptions.HTTPError:
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

    def populate_with_sample_data(self) -> bool:
        """Populate collections with relevant DinoAir3 sample data."""
        print("Populating collections with sample data...")

        try:
            # Run the populate script
            result = safe_run(
                [
                    sys.executable,
                    str(self.project_root / "populate_qdrant_collections.py"),
                ],
                cwd=self.project_root,
                allowed_binaries={Path(sys.executable).name, "python", PYTHON_EXE},
                timeout=180,
                check=True,
            )

            if result.returncode == 0:
                print("Sample data populated successfully")
                return True
            print("Failed to populate sample data:")
            print(result.stderr)
            return False

        except Exception as e:
            print(f"Error running populate script: {e}")
            return False

    def test_integration(self) -> bool:
        """Test the complete integration."""
        print("Testing integration...")

        try:
            # Test MCP server health
            response = requests.get("http://localhost:8080/health", timeout=10)
            if response.status_code != 200:
                print("MCP server health check failed")
                return False

            # Test Qdrant connection
            from qdrant_client import QdrantClient

            client = QdrantClient(url=QDRANT_DEFAULT_URL, api_key=self.api_key)
            health = client.health()

            print(f"Integration test successful: {health.title} v{health.version}")
            return True

        except Exception as e:
            print(f"Integration test failed: {e}")
            return False

    def run_setup(self) -> bool:
        """Run complete setup process."""
        print("Setting up Qdrant MCP Server for DinoAir3")
        print("=" * 50)

        # Install dependencies
        if not self.install_dependencies():
            return False

        # Start Qdrant server
        if not self.start_qdrant_server():
            print("Failed to start Qdrant server")
            print(
                "Please start it manually: docker run -p 6333:6333 -p 6334:6334 -e QDRANT__SERVICE__API_KEY=<key> qdrant/qdrant"
            )
            return False

        # Start MCP server
        if not self.start_mcp_server():
            print("Failed to start MCP server")
            return False

        # Create collections
        if not self.create_dinoair_collections():
            print("Failed to create collections")
            return False

        # Populate with sample data
        if not self.populate_with_sample_data():
            print("Failed to populate sample data")
            return False

        # Test integration
        if not self.test_integration():
            print("Integration test failed")
            return False

        return True

    @staticmethod
    def show_success_message():
        """Show success message with usage instructions."""
        print("\n" + "=" * 60)
        print("QDRANT MCP SERVER SETUP COMPLETE!")
        print("=" * 60)

        print("\nServices Running:")
        print("  Qdrant Database: http://localhost:6333")
        print("  MCP Server:      http://localhost:8080")
        print("  Dashboard:       http://localhost:6333/dashboard")

        print("\nCollections Created:")
        print("  dinoair_files     - File embeddings and code")
        print("  dinoair_projects  - Project documentation")
        print("  dinoair_notes     - Notes and planning documents")

        print("\nSample Data Added:")
        print("  Python files with search functionality")
        print("  React components for UI")
        print("  Documentation and configuration files")
        print("  Project planning and architecture notes")

        print("\nQuick Test:")
        print("  # Test MCP server health")
        print("  curl http://localhost:8080/health")
        print("")
        print("  # Search for Python code")
        print("  curl -X POST 'http://localhost:8080/tools/call' \\")
        print("    -H 'Content-Type: application/json' \\")
        print(
            '    -d \'{"name": "search_vectors", "arguments": {"collection_name": "dinoair_files", "query_vector": [0.1,0.2,0.3], "limit": 3}}\''
        )

        print("\nNext Steps:")
        print("  1. Integrate with DinoAir3 frontend")
        print("  2. Add real file embeddings from your codebase")
        print("  3. Customize search parameters")
        print("  4. Set up monitoring and backups")
        print("  5. Deploy to production environment")

        print("\nDocumentation:")
        print("  - QDRANT_MCP_README.md - Complete setup guide")
        print("  - demo_qdrant_mcp.py - Interactive demonstrations")
        print("  - populate_qdrant_collections.py - Data population scripts")


def main():
    """Main setup function."""
    import argparse

    parser = argparse.ArgumentParser(description="Complete Qdrant MCP setup for DinoAir3")
    parser.add_argument("--api-key", required=True, help="Qdrant API key")
    parser.add_argument("--skip-deps", action="store_true", help="Skip dependency installation")

    args = parser.parse_args()

    print("Setting up Qdrant MCP with API key: [REDACTED]...")

    setup = QdrantSetupManager(args.api_key)

    if not args.skip_deps and not setup.install_dependencies():
        print("Failed to install dependencies")
        return 1

    if setup.run_setup():
        setup.show_success_message()
        print("\nSetup completed successfully! Ready to use Qdrant with DinoAir3!")
        return 0

    print("\nSetup failed!")
    return 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
