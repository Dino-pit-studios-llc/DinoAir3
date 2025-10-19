#!/usr/bin/env python3
"""
Setup script for Qdrant MCP integration with DinoAir3

This script helps set up and configure Qdrant MCP server integration:
1. Installs required dependencies
2. Sets up environment variables
3. Creates necessary directories
4. Tests Qdrant connection
5. Provides usage instructions
"""

# ... existing code ...
import argparse
import os

# removed: import subprocess
import sys
from pathlib import Path

import yaml

# Add safe subprocess wrapper
from utils.process import PYTHON_EXE, SafeProcessError, safe_run

# Constants
QDRANT_DEFAULT_URL = "http://localhost:6333"


def _secure_write_text(path: str, content: str) -> None:
    # Restrict file permissions to 0o600 (owner read/write only). Works on Unix; on Windows chmod is best-effort.

    flags = os.O_WRONLY | os.O_CREAT | os.O_TRUNC
    mode = 0o600
    fd = os.open(path, flags, mode)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as f:
            f.write(content)
        try:
            os.chmod(path, mode)
        except Exception:
            # Best-effort on non-POSIX
            pass
    except Exception:
        try:
            os.close(fd)
        except Exception:
            pass
        raise


class QdrantMCPSetup:
    """Setup class for Qdrant MCP integration."""

    def __init__(self, api_key: str = None):
        """Initialize setup with API key."""
        self.api_key = api_key or os.getenv("QDRANT_API_KEY")
        self.project_root = Path(__file__).parent
        self.config_file = self.project_root / "qdrant_mcp_config.yaml"
        self.env_file = self.project_root / ".env.qdrant"

    @staticmethod
    def check_prerequisites() -> bool:
        """Check if all prerequisites are met."""
        print("Checking prerequisites...")

        # Check Python version
        python_version = sys.version_info
        if python_version < (3, 8):
            print(
                f"ERROR: Python {python_version.major}.{python_version.minor} detected. Python 3.8+ required."
            )
            return False

        print(f"OK: Python {python_version.major}.{python_version.minor}.{python_version.micro}")

        # Check if pip is available
        try:
            # replaced subprocess.run with safe_run using allowlist and timeout
            safe_run(
                [sys.executable, "-m", "pip", "--version"],
                allowed_binaries={Path(sys.executable).name, "python", PYTHON_EXE},
                timeout=60,
                check=True,
                text=True,
            )
            print("OK: pip is available")
        except (SafeProcessError, FileNotFoundError):
            print("ERROR: pip is not available")
            return False

        return True

    def install_dependencies(self) -> bool:
        """Install required dependencies."""
        print("\nInstalling dependencies...")

        requirements_file = self.project_root / "mcp_qdrant_requirements.txt"
        if not requirements_file.exists():
            print(f"ERROR: Requirements file not found: {requirements_file}")
            return False

        try:
            # Upgrade pip first
            safe_run(
                [sys.executable, "-m", "pip", "install", "--upgrade", "pip"],
                allowed_binaries={Path(sys.executable).name, "python", PYTHON_EXE},
                timeout=300,
                check=True,
            )

            # Install requirements
            safe_run(
                [sys.executable, "-m", "pip", "install", "-r", str(requirements_file)],
                allowed_binaries={Path(sys.executable).name, "python", PYTHON_EXE},
                timeout=600,
                check=True,
            )

            print("OK: Dependencies installed successfully")
            return True

        except SafeProcessError as e:
            print(f"ERROR: Failed to install dependencies: {e}")
            return False

    def setup_environment(self) -> bool:
        """Set up environment variables and configuration."""
        print("\nSetting up environment...")

        if not self.api_key:
            print("ERROR: Qdrant API key is required")
            print("Please provide it as an argument: --api-key YOUR_API_KEY")
            print("Or set environment variable: QDRANT_API_KEY")
            return False

        # Create .env file
        env_content = f"""# Qdrant MCP Server Environment Variables
QDRANT_API_KEY={self.api_key}
QDRANT_URL=http://localhost:6333

# MCP Server Settings
MCP_SERVER_HOST=localhost
MCP_SERVER_PORT=8080
MCP_LOG_LEVEL=INFO

# Development settings
DEBUG=false
"""

        try:
            _secure_write_text(
                str(self.env_file), env_content
            )  # restrict file permissions to 0o600

            print(f"OK: Environment file created: {self.env_file}")

            # Load and update config file
            if self.config_file.exists():
                with open(self.config_file) as f:
                    config = yaml.safe_load(f)

                # Update with API key
                config["qdrant"]["api_key"] = self.api_key

                # Write YAML with restricted permissions
                yaml_text = yaml.dump(config, default_flow_style=False)
                _secure_write_text(
                    str(self.config_file), yaml_text
                )  # restrict file permissions to 0o600

                print(f"OK: Configuration updated: {self.config_file}")

            return True

        except Exception as e:
            print(f"ERROR: Failed to setup environment: {e}")
            return False

    def test_qdrant_connection(self) -> bool:
        """Test connection to Qdrant server."""
        print("\nTesting Qdrant connection...")

        try:
            from qdrant_client import QdrantClient

            client = QdrantClient(url=QDRANT_DEFAULT_URL, api_key=self.api_key, timeout=10)

            # Test health check
            health = client.health()
            print(f"OK: Qdrant connection successful: {health.title} v{health.version}")

            # Test collections
            collections = client.get_collections()
            print(f"OK: Found {len(collections.collections)} collections")

            return True

        except ImportError:
            print("ERROR: qdrant-client not installed. Run setup first.")
            return False
        except Exception as e:
            print(f"ERROR: Qdrant connection failed: {e}")
            print("Make sure Qdrant server is running on http://localhost:6333")
            return False

    def create_dinoair_collections(self) -> bool:
        """Create DinoAir3-specific collections in Qdrant."""
        print("\nCreating DinoAir3 collections...")

        try:
            from qdrant_client import QdrantClient
            from qdrant_client.models import Distance, VectorParams

            client = QdrantClient(url=QDRANT_DEFAULT_URL, api_key=self.api_key)

            collections_to_create = [
                {
                    "name": "dinoair_files",
                    "description": "File embeddings for DinoAir3 search",
                    "vector_size": 384,
                    "distance": Distance.COSINE,
                },
                {
                    "name": "dinoair_notes",
                    "description": "Note embeddings for semantic search",
                    "vector_size": 384,
                    "distance": Distance.COSINE,
                },
                {
                    "name": "dinoair_projects",
                    "description": "Project embeddings for discovery",
                    "vector_size": 384,
                    "distance": Distance.COSINE,
                },
            ]

            for collection_info in collections_to_create:
                try:
                    # Check if collection exists
                    existing = client.get_collection(collection_info["name"])

                    # Update vector config if needed
                    if (
                        existing.config.params.size != collection_info["vector_size"]
                        or existing.config.params.distance != collection_info["distance"]
                    ):
                        print(
                            f"Warning: Collection '{collection_info['name']}' exists but has different config"
                        )
                        print("   Consider recreating or updating the collection")
                    else:
                        print(f"OK: Collection '{collection_info['name']}' already exists")

                except Exception:
                    # Collection doesn't exist, create it
                    client.create_collection(
                        collection_name=collection_info["name"],
                        vectors_config=VectorParams(
                            size=collection_info["vector_size"],
                            distance=collection_info["distance"],
                        ),
                    )
                    print(f"OK: Created collection '{collection_info['name']}'")

            return True

        except Exception as e:
            print(f"ERROR: Failed to create collections: {e}")
            return False

    def create_startup_script(self) -> bool:
        """Create startup script for easy server management."""
        print("\nCreating startup script...")

        script_content = """#!/bin/bash
# Qdrant MCP Server Startup Script for DinoAir3

# Load environment variables
if [ -f ".env.qdrant" ]; then
    source .env.qdrant
fi

# Check if API key is set
if [ -z "$QDRANT_API_KEY" ]; then
    echo "Error: QDRANT_API_KEY not set"
    echo "Please set it in .env.qdrant file or environment variable"
    exit 1
fi

echo "Starting Qdrant MCP Server..."
echo "Qdrant URL: $QDRANT_URL"
echo "MCP Server: https://$MCP_SERVER_HOST:$MCP_SERVER_PORT"

# Start the server
python mcp_qdrant_server.py --qdrant-url "$QDRANT_URL" --api-key "$QDRANT_API_KEY"
"""

        script_file = self.project_root / "start_qdrant_mcp.sh"
        try:
            _secure_write_text(
                str(script_file), script_content
            )  # restrict file permissions to 0o600

            # Make executable
            os.chmod(script_file, 0o700)

            print(f"OK: Startup script created: {script_file}")
            print("   Run with: ./start_qdrant_mcp.sh")
            return True

        except Exception as e:
            print(f"ERROR: Failed to create startup script: {e}")
            return False

    def show_usage_instructions(self):
        """Show usage instructions."""
        print("\n" + "=" * 60)
        print("Qdrant MCP Server Setup Complete!")
        print("=" * 60)

        print("\nUsage Instructions:")
        print("1. Start Qdrant server (if not already running):")
        print("   docker run -p 6333:6333 -p 6334:6334 qdrant/qdrant")

        print("\n2. Start MCP server:")
        print("   python mcp_qdrant_server.py")
        print("   OR")
        print("   ./start_qdrant_mcp.sh")

        print("\n3. Test the server:")
        print("   curl http://localhost:8080/health")

        print("\nAvailable Tools:")
        print("- search_vectors: Search for similar vectors")
        print("- upload_points: Upload embeddings to collections")
        print("- create_collection: Create new collections")
        print("- list_collections: List all collections")
        print("- delete_collection: Delete collections")
        print("- get_collection_info: Get collection details")

        print("\nExample Usage:")
        print("# Search vectors")
        print('curl -X POST "http://localhost:8080/tools/call" \\')
        print('  -H "Content-Type: application/json" \\')
        print(
            '  -d \'{"name": "search_vectors", "arguments": {"collection_name": "dinoair_files", "query_vector": [0.1, 0.2, 0.3], "limit": 5}}\''
        )

        print("\nConfiguration:")
        print(f"- Config file: {self.config_file}")
        print(f"- Environment file: {self.env_file}")
        print("- Edit these files to customize settings")

        print("\nSecurity:")
        print("- API key is stored in .env.qdrant file")
        print("- Keep this file secure and don't commit to version control")
        print("\nNext Steps:")
        print("1. Integrate with your DinoAir3 application")
        print("2. Set up automatic data synchronization")
        print("3. Configure monitoring and logging")
        print("4. Set up backup strategies for vector data")

    def run_setup(self) -> bool:
        """Run complete setup process."""
        print("Setting up Qdrant MCP Server for DinoAir3")
        print("=" * 50)

        # Check prerequisites
        if not self.check_prerequisites():
            return False

        # Install dependencies
        if not self.install_dependencies():
            return False

        # Setup environment
        if not self.setup_environment():
            return False

        # Test Qdrant connection
        if not self.test_qdrant_connection():
            print("\nWarning: Qdrant connection failed, but continuing setup...")
            print("Make sure Qdrant server is running before starting MCP server")

        # Create collections
        if not self.create_dinoair_collections():
            print("\nWarning: Failed to create collections, but continuing...")

        # Create startup script
        if not self.create_startup_script():
            return False

        # Show instructions
        self.show_usage_instructions()

        return True


def main():
    """Main setup function."""
    parser = argparse.ArgumentParser(description="Setup Qdrant MCP Server for DinoAir3")
    parser.add_argument("--api-key", help="Qdrant API key")
    parser.add_argument("--qdrant-url", default=QDRANT_DEFAULT_URL, help="Qdrant server URL")
    parser.add_argument("--skip-deps", action="store_true", help="Skip dependency installation")

    args = parser.parse_args()

    # Get API key from argument or environment
    api_key = args.api_key or os.getenv("QDRANT_API_KEY")

    if not api_key:
        print("Error: Qdrant API key is required!")
        print("Provide it with: --api-key YOUR_API_KEY")
        print("Or set environment variable: QDRANT_API_KEY")
        return 1

    # Validate API key format (JWT-like)
    if not api_key.startswith(("eyJ", "eyA")) or len(api_key) < 50:
        print("Warning: API key format looks suspicious")
        print("Make sure you're using the correct Qdrant API key")

    setup = QdrantMCPSetup(api_key=api_key)

    success = setup.run_setup()

    if success:
        print("\nSetup completed successfully!")
        return 0
    print("\nSetup failed!")
    return 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
