#!/usr/bin/env python3
"""
Complete Qdrant MCP Demo for DinoAir3

This script demonstrates the complete workflow:
1. Setting up Qdrant server
2. Starting MCP server
3. Creating collections
4. Populating with sample data
5. Demonstrating search functionality
6. Integration with DinoAir3
"""

import os
import sys
import time
from pathlib import Path
from subprocess import TimeoutExpired

# Remove the import of TimeoutExpired if not used
from typing import Any

import requests
from qdrant_client.http.exceptions import UnexpectedStatus
from utils.process import safe_popen, safe_run


class QdrantMCPDemoRunner:
    """Complete demo runner for Qdrant MCP integration."""

    def __init__(self, api_key: str):
        """Initialize demo runner."""
        self.api_key = api_key
        self.project_root = Path(__file__).parent

        # Set environment variables
        os.environ["QDRANT_API_KEY"] = api_key
        os.environ["QDRANT_URL"] = "http://localhost:6333"

        # Service URLs
        self.qdrant_url = "http://localhost:6333"
        self.mcp_server_url = "http://localhost:8080"

    def check_requirements(self) -> bool:
        """Check if all requirements are installed."""
        print("Checking requirements...")

        try:
            import fastapi
            import mcp
            import qdrant_client
            import uvicorn

            print("All Python requirements are installed")
            return True
        except ImportError as import_error:
            print(f"Missing requirements: {import_error}")
            print("Installing requirements...")
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
                    allowed_binaries={
                        Path(sys.executable).name,
                        "python",
                        "python.exe",
                    },
                    timeout=300,
                    check=True,
                )
                print("Requirements installed successfully")
                return True
            except Exception as install_error:
                print(f"Failed to install requirements: {install_error}")
                return False

    def start_qdrant_server(self) -> bool:
        """Start Qdrant server using Docker."""
        print("\nStarting Qdrant server...")

        # Check if Docker is available
        try:
            safe_run(
                ["/usr/bin/docker", "--version"],
                allowed_binaries={"docker", "docker.exe"},
                timeout=60,
                check=True,
            )
        except Exception:
            print("Docker not available. Please start Qdrant manually:")
            print(
                "/usr/bin/docker run -p 6333:6333 -p 6334:6334 -e QDRANT__SERVICE__API_KEY=<your_key> qdrant/qdrant"
            )
            return False

        # Check if container already exists
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
            print("Starting existing Qdrant container...")
            safe_run(
                ["/usr/bin/docker", "start", "qdrant-dinoair"],
                allowed_binaries={"docker", "docker.exe"},
                timeout=120,
                check=True,
            )
        else:
            print("Creating new Qdrant container...")
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
                    "-v",
                    "qdrant-dinoair-storage:/qdrant/storage",
                    "qdrant/qdrant:latest",
                ],
                allowed_binaries={"docker", "docker.exe"},
                timeout=300,
                check=True,
                env=_env,
            )

        # Wait for Qdrant to be ready
        print("Waiting for Qdrant to be ready...")
        for i in range(30):
            try:
                response = requests.get(f"{self.qdrant_url}/health", timeout=5)
                if response.status_code == 200:
                    print("Qdrant is ready!")
                    return True
            except requests.exceptions.RequestException:
                pass
            print(f"Waiting... ({i + 1}/30)")
            time.sleep(1)

        print("Timeout waiting for Qdrant")
        return False

    def start_mcp_server(self) -> Any | None:
        """Start MCP server in background."""
        print("\nStarting MCP server...")

        try:
            # Start MCP server
            process = safe_popen(
                [sys.executable, str(self.project_root / "mcp_qdrant_server.py")],
                allowed_binaries={Path(sys.executable).name, "python", "python.exe"},
                cwd=self.project_root,
            )

            # Wait for server to be ready
            print("Waiting for MCP server to be ready...")
            for i in range(30):
                try:
                    response = requests.get(f"{self.mcp_server_url}/health", timeout=5)
                    if response.status_code == 200:
                        print("MCP server is ready!")
                        return process
                except requests.exceptions.RequestException:
                    pass
                print(f"Waiting... ({i + 1}/30)")
                time.sleep(1)

            print("Timeout waiting for MCP server")
            process.terminate()
            return None

        except Exception as e:
            print(f"Failed to start MCP server: {e}")
            return None

    def create_collections(self) -> bool:
        """Create Qdrant collections for DinoAir3."""
        print("\nCreating DinoAir3 collections...")

        try:
            from qdrant_client import QdrantClient
            from qdrant_client.models import Distance, VectorParams

            client = QdrantClient(url=self.qdrant_url, api_key=self.api_key)

            collections = [
                ("dinoair_files", "File embeddings for DinoAir3 search"),
                ("dinoair_projects", "Project embeddings for discovery"),
                ("dinoair_notes", "Note embeddings for semantic search"),
            ]

            for name, _ in collections:
                try:
                    client.get_collection(name)
                    print(f"Collection '{name}' already exists")
                except UnexpectedStatus:
                    client.create_collection(
                        collection_name=name,
                        vectors_config=VectorParams(size=384, distance=Distance.COSINE),
                    )
                    print(f"Created collection '{name}'")

            return True

        except Exception as e:
            print(f"Failed to create collections: {e}")
            return False

    def populate_sample_data(self) -> bool:
        """Populate collections with sample DinoAir3 data."""
        print("\nPopulating collections with sample data...")

        try:
            # Run the populate script
            result = safe_run(
                [
                    sys.executable,
                    str(self.project_root / "populate_qdrant_collections.py"),
                ],
                cwd=self.project_root,
                allowed_binaries={Path(sys.executable).name, "python", "python.exe"},
                timeout=180,
                check=True,
            )

            if result.returncode == 0:
                print("Sample data populated successfully")
                print(result.stdout)
                return True
            else:
                print("Failed to populate sample data:")
                print(result.stderr)
                return False

        except Exception as e:
            print(f"Error running populate script: {e}")
            return False

    def run_demo(self) -> bool:
        """Run the interactive demo."""
        print("\nRunning interactive demo...")

        try:
            # Run the demo script
            result = safe_run(
                [sys.executable, str(self.project_root / "demo_qdrant_mcp.py")],
                cwd=self.project_root,
                allowed_binaries={Path(sys.executable).name, "python", "python.exe"},
                timeout=300,
                check=True,
            )

            return result.returncode == 0

        except Exception as e:
            print(f"Error running demo: {e}")
            return False

    @staticmethod
    def cleanup(mcp_process: Any | None):
        """Clean up running processes."""
        print("\nCleaning up...")

        if mcp_process:
            print("Stopping MCP server...")
            mcp_process.terminate()
            try:
                mcp_process.wait(timeout=10)
            except TimeoutExpired:
                mcp_process.kill()

        # Optionally stop Qdrant container
        print("Keeping Qdrant container running for further testing")
        print("To stop it manually: docker stop qdrant-dinoair")

    def run_complete_demo(self) -> bool:
        """Run the complete demonstration workflow."""
        print("Qdrant MCP Server Complete Demo for DinoAir3")
        print("=" * 60)

        # Check requirements
        if not self.check_requirements():
            return False

        # Start Qdrant server
        if not self.start_qdrant_server():
            print("Failed to start Qdrant server")
            print("Please start it manually and run the demo again")
            return False

        # Start MCP server
        mcp_process = self.start_mcp_server()
        if not mcp_process:
            print("Failed to start MCP server")
            return False

        try:
            # Create collections
            if not self.create_collections():
                print("Failed to create collections")
                return False

            # Populate sample data
            if not self.populate_sample_data():
                print("Failed to populate sample data")
                return False

            # Run interactive demo
            if not self.run_demo():
                print("Demo completed with some issues")
                return False

            print("\n" + "=" * 60)
            print("COMPLETE DEMO SUCCESSFUL!")
            print("=" * 60)
            print("Qdrant MCP server is now set up and ready for use with DinoAir3!")
            print("\nWhat you can do next:")
            print("1. Use the MCP tools to search vectors")
            print("2. Integrate with DinoAir3 frontend")
            print("3. Add real file embeddings")
            print("4. Customize search parameters")
            print("5. Set up monitoring and logging")

            return True

        finally:
            # Cleanup
            self.cleanup(mcp_process)


def main():
    """Main demo function."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Run complete Qdrant MCP demo for DinoAir3"
    )
    parser.add_argument("--api-key", help="Qdrant API key")
    parser.add_argument(
        "--skip-qdrant", action="store_true", help="Skip starting Qdrant server"
    )

    args = parser.parse_args()

    # Get API key
    api_key = args.api_key or os.getenv("QDRANT_API_KEY")
    if not api_key:
        print("Error: Qdrant API key required!")
        print("Provide with --api-key or set QDRANT_API_KEY environment variable")
        return 1

    # Validate API key
    if not api_key.startswith(("eyJ", "eyA")) or len(api_key) < 50:
        print("Warning: API key format looks suspicious")
        print("Make sure you're using the correct Qdrant API key")

    print("Starting complete demo with Qdrant API key provided...")

    demo = QdrantMCPDemoRunner(api_key)

    try:
        success = demo.run_complete_demo()
        return 0 if success else 1
    except KeyboardInterrupt:
        print("\nDemo interrupted by user")
        return 1
    except Exception as e:
        print(f"Demo failed with error: {e}")
        return 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
