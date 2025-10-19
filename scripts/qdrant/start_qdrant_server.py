#!/usr/bin/env python3
"""
Qdrant Server Startup Script for DinoAir3

This script helps start a Qdrant server instance for testing and development.
It can start Qdrant using Docker or connect to an existing instance.
"""

import argparse
import logging
import os
import shutil
import sys
import time
from pathlib import Path

import requests

from utils.process import safe_run

# Constants
QDRANT_DEFAULT_URL = "http://localhost:6333"

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def _docker_bin_and_allow() -> tuple[str, set[str]]:
    """
    Resolve docker binary path from DOCKER_PATH, PATH, or fallback, and build an allowlist.
    No shell usage; only static argument lists.
    """
    hint = os.getenv("DOCKER_PATH")
    path = hint or shutil.which("docker") or "/usr/bin/docker"
    name = Path(path).name
    return path, {name, "docker", "docker.exe"}


def check_docker_available():
    """Check if Docker is available."""
    try:
        docker_bin, allow = _docker_bin_and_allow()
        result = safe_run(
            [docker_bin, "--version"],
            allowed_binaries=allow,
            timeout=10,
            check=False,
            text=True,
        )
        if result.returncode == 0:
            print(f"Docker available: {result.stdout.strip()}")
            return True
    except OSError as e:
        logger.debug("Docker check failed: %s", e)
    print("Docker not available. Please install Docker or start Qdrant manually.")
    return False


def start_qdrant_docker(api_key: str):
    """Start Qdrant server using Docker."""
    print("Starting Qdrant server with Docker...")

    # Check if container already exists
    docker_bin, allow = _docker_bin_and_allow()
    result = safe_run(
        [
            docker_bin,
            "ps",
            "-a",
            "--filter",
            "name=qdrant-dinoair",
            "--format",
            "{{.Names}}",
        ],
        allowed_binaries=allow,
        timeout=15,
        check=False,
        text=True,
    )

    if result.returncode == 0 and "qdrant-dinoair" in (result.stdout or ""):
        print("Qdrant container already exists. Starting it...")
        safe_run(
            [docker_bin, "start", "qdrant-dinoair"],
            allowed_binaries=allow,
            timeout=30,
            check=True,
        )
    else:
        print("Creating new Qdrant container...")

        # Create Docker volume for persistence
        safe_run(
            [docker_bin, "volume", "create", "qdrant-dinoair-storage"],
            allowed_binaries=allow,
            timeout=30,
            check=True,
        )

        # Start Qdrant container
        cmd = [
            docker_bin,
            "run",
            "-d",
            "--name",
            "qdrant-dinoair",
            "-p",
            "6333:6333",
            "-p",
            "6334:6334",
            "-e",
            f"QDRANT__SERVICE__API_KEY={api_key}",
            "-v",
            "qdrant-dinoair-storage:/qdrant/storage",
            "qdrant/qdrant:latest",
        ]

        safe_run(cmd, allowed_binaries=allow, timeout=60, check=True)
        print("Qdrant container started successfully")

    # Wait for Qdrant to be ready
    print("Waiting for Qdrant to be ready...")
    for i in range(30):  # 30 seconds timeout
        try:
            response = requests.get(f"{QDRANT_DEFAULT_URL}/health", timeout=5)
            if response.status_code == 200:
                print("Qdrant is ready!")
                return True
        except requests.exceptions.RequestException:
            pass

        print(f"Waiting... ({i + 1}/30)")
        time.sleep(1)

    print("Timeout waiting for Qdrant to be ready")
    return False


def test_qdrant_connection(api_key: str):
    """Test connection to Qdrant server."""
    print("Testing Qdrant connection...")

    try:
        from qdrant_client import QdrantClient

        client = QdrantClient(url=QDRANT_DEFAULT_URL, api_key=api_key, timeout=10)

        # Test health check
        health = client.health()
        print(f"Connected to Qdrant: {health.title} v{health.version}")

        # Test collections
        collections = client.get_collections()
        print(f"Found {len(collections.collections)} existing collections")

        return True

    except Exception as e:
        print(f"Failed to connect to Qdrant: {e}")
        return False


def main():
    """Main function to start Qdrant server."""
    parser = argparse.ArgumentParser(description="Start Qdrant server for DinoAir3")
    parser.add_argument("--api-key", help="Qdrant API key")
    parser.add_argument(
        "--no-docker",
        action="store_true",
        help="Don't use Docker, assume Qdrant is already running",
    )

    args = parser.parse_args()

    # Get API key
    api_key = args.api_key or os.getenv("QDRANT_API_KEY")
    if not api_key:
        print("Error: Qdrant API key required!")
        print("Provide with --api-key or set QDRANT_API_KEY environment variable")
        return 1

    print("Starting Qdrant server for DinoAir3...")
    print("API Key provided.")

    if args.no_docker:
        print("Assuming Qdrant is already running...")
        if test_qdrant_connection(api_key):
            print("Qdrant connection successful!")
            return 0
        print("Failed to connect to Qdrant")
        return 1

    # Check Docker availability
    if not check_docker_available():
        print("Please start Qdrant manually or install Docker:")
        print("docker run -p 6333:6333 -p 6334:6334 -e QDRANT__SERVICE__API_KEY=<your_key> qdrant/qdrant")
        return 1

    # Start Qdrant with Docker
    if start_qdrant_docker(api_key):
        print("\nQdrant server is running!")
        print(f"Dashboard: {QDRANT_DEFAULT_URL}/dashboard")
        print(f"API: {QDRANT_DEFAULT_URL}")
        print("gRPC: localhost:6334")

        # Test connection
        if test_qdrant_connection(api_key):
            print("\nQdrant is ready for use with DinoAir3!")
            return 0
        print("\nQdrant started but connection test failed")
        return 1
    print("Failed to start Qdrant server")
    return 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
