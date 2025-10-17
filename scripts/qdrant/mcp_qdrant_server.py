#!/usr/bin/env python3
"""
Qdrant MCP Server for DinoAir3

This module provides a Model Context Protocol (MCP) server that integrates
Qdrant vector database with the DinoAir3 file search system.

The server allows AI models to:
- Search vectors in Qdrant collections
- Upload embeddings to Qdrant
- Manage collections and points
- Perform similarity searches
"""

import asyncio
import json
import logging
import os
import sys
from datetime import datetime
from typing import Any, Dict, List, Optional, Union

try:
    from qdrant_client import QdrantClient
    from qdrant_client.models import (
        Distance,
        FieldCondition,
        Filter,
        PointIdsList,
        PointStruct,
        Range,
        SearchParams,
        SearchRequest,
        UpdateStatus,
        VectorParams,
    )

    QDRANT_AVAILABLE = True
except ImportError:
    QDRANT_AVAILABLE = False
    print(
        "Warning: qdrant-client not installed. Install with: pip install qdrant-client"
    )

from mcp import McpServer
from mcp.models import ServerCapabilities
from mcp.types import (
    Resource,
    Tool,
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("qdrant-mcp")


class QdrantMCPServer:
    """MCP Server for Qdrant vector database integration."""

    def __init__(self, qdrant_url: str = None, api_key: str = None):
        """Initialize Qdrant MCP Server.

        Args:
            qdrant_url: Qdrant server URL (defaults to QDRANT_URL env var)
            api_key: Qdrant API key (defaults to QDRANT_API_KEY env var)
        """
        self.qdrant_url = qdrant_url or os.getenv("QDRANT_URL", "http://localhost:6333")
        self.api_key = api_key or os.getenv("QDRANT_API_KEY")

        if not QDRANT_AVAILABLE:
            raise ImportError("qdrant-client is required for Qdrant MCP server")

        # Initialize Qdrant client
        self.client = QdrantClient(
            url=self.qdrant_url, api_key=self.api_key, timeout=30
        )

        # Test connection
        try:
            self.client.health()
            logger.info("Connected to Qdrant at %s", self.qdrant_url)
        except Exception as e:
            logger.error("Failed to connect to Qdrant: %s", e)
            raise

        # MCP Server setup
        self.server = McpServer("qdrant-mcp-server")

    async def run(self):
        """Run the MCP server."""
        # Define tools
        _tools = [
            Tool(
                name="search_vectors",
                description="Search for similar vectors in a Qdrant collection",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "collection_name": {
                            "type": "string",
                            "description": "Name of the Qdrant collection to search in",
                        },
                        "query_vector": {
                            "type": "array",
                            "items": {"type": "number"},
                            "description": "Query vector for similarity search",
                        },
                        "limit": {
                            "type": "integer",
                            "default": 10,
                            "description": "Maximum number of results to return",
                        },
                        "score_threshold": {
                            "type": "number",
                            "default": 0.0,
                            "description": "Minimum similarity score threshold",
                        },
                        "filter": {
                            "type": "object",
                            "description": "Optional filter conditions",
                        },
                    },
                    "required": ["collection_name", "query_vector"],
                },
            ),
            Tool(
                name="upload_points",
                description="Upload points (vectors with metadata) to a Qdrant collection",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "collection_name": {
                            "type": "string",
                            "description": "Name of the Qdrant collection",
                        },
                        "points": {
                            "type": "array",
                            "items": {
                                "type": "object",
                                "properties": {
                                    "id": {"type": "string"},
                                    "vector": {
                                        "type": "array",
                                        "items": {"type": "number"},
                                    },
                                    "payload": {"type": "object"},
                                },
                            },
                            "description": "List of points to upload",
                        },
                    },
                    "required": ["collection_name", "points"],
                },
            ),
            Tool(
                name="create_collection",
                description="Create a new Qdrant collection",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "collection_name": {
                            "type": "string",
                            "description": "Name of the collection to create",
                        },
                        "vector_size": {
                            "type": "integer",
                            "description": "Dimensionality of vectors",
                        },
                        "distance": {
                            "type": "string",
                            "enum": ["Cosine", "Euclidean", "Dot"],
                            "default": "Cosine",
                            "description": "Distance metric for the collection",
                        },
                    },
                    "required": ["collection_name", "vector_size"],
                },
            ),
            Tool(
                name="list_collections",
                description="List all available Qdrant collections",
                inputSchema={"type": "object", "properties": {}},
            ),
            Tool(
                name="delete_collection",
                description="Delete a Qdrant collection",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "collection_name": {
                            "type": "string",
                            "description": "Name of the collection to delete",
                        }
                    },
                    "required": ["collection_name"],
                },
            ),
            Tool(
                name="get_collection_info",
                description="Get detailed information about a collection",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "collection_name": {
                            "type": "string",
                            "description": "Name of the collection",
                        }
                    },
                    "required": ["collection_name"],
                },
            ),
        ]

        # Define resources
        _resources = [
            Resource(
                uri="qdrant://health",
                name="Qdrant Health Status",
                description="Current health status of the Qdrant server",
                mimeType="application/json",
            ),
            Resource(
                uri="qdrant://collections",
                name="Qdrant Collections",
                description="List of all collections in the Qdrant database",
                mimeType="application/json",
            ),
        ]

        # Set up server capabilities
        self.server.set_request_handler("initialize", self._handle_initialize)
        self.server.set_request_handler("tools/list", self._handle_list_tools)
        self.server.set_request_handler("tools/call", self._handle_call_tool)
        self.server.set_request_handler("resources/list", self._handle_list_resources)
        self.server.set_request_handler("resources/read", self._handle_read_resource)

        # Run the server
        await self.server.run()

    @staticmethod
    async def _handle_initialize(params: Any) -> Any:
        """Handle server initialization."""
        return {
            "capabilities": ServerCapabilities(
                tools={"listChanged": False}, resources={"listChanged": False}
            ),
            "serverInfo": {"name": "Qdrant MCP Server", "version": "1.0.0"},
        }

    @staticmethod
    async def _handle_list_tools(params: Any) -> Any:
        """Handle tools list request."""
        # This would return the tools defined above
        return {"tools": []}  # Placeholder

    async def _handle_call_tool(self, params: Any) -> Any:
        """Handle tool execution."""
        tool_name = params.get("name")
        arguments = params.get("arguments", {})

        try:
            if tool_name == "search_vectors":
                return await self._search_vectors(arguments)
            elif tool_name == "upload_points":
                return await self._upload_points(arguments)
            elif tool_name == "create_collection":
                return await self._create_collection(arguments)
            elif tool_name == "list_collections":
                return await self._list_collections(arguments)
            elif tool_name == "delete_collection":
                return await self._delete_collection(arguments)
            elif tool_name == "get_collection_info":
                return await self._get_collection_info(arguments)
            else:
                raise ValueError(f"Unknown tool: {tool_name}")
        except Exception as e:
            logger.error("Error executing tool %s: %s", tool_name, e)
            return {
                "content": [{"type": "text", "text": f"Error: {str(e)}"}],
                "isError": True,
            }

    @staticmethod
    async def _handle_list_resources(params: Any) -> Any:
        """Handle resources list request."""
        return {"resources": []}  # Placeholder

    async def _handle_read_resource(self, params: Any) -> Any:
        """Handle resource read request."""
        uri = params.get("uri", "")

        if uri == "qdrant://health":
            return await self._get_health_resource()
        elif uri == "qdrant://collections":
            return await self._get_collections_resource()
        else:
            raise ValueError(f"Unknown resource: {uri}")

    async def _search_vectors(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Execute vector search."""
        collection_name = args["collection_name"]
        query_vector = args["query_vector"]
        limit = args.get("limit", 10)
        score_threshold = args.get("score_threshold", 0.0)

        try:
            # Perform search
            search_results = self.client.search(
                collection_name=collection_name,
                query_vector=query_vector,
                limit=limit,
                score_threshold=score_threshold,
            )

            # Format results
            results = []
            for result in search_results:
                results.append(
                    {
                        "id": result.id,
                        "score": result.score,
                        "payload": result.payload,
                        "vector": (
                            result.vector[:10] if result.vector else None
                        ),  # First 10 dimensions
                    }
                )

            return {
                "content": [
                    {
                        "type": "text",
                        "text": json.dumps(
                            {
                                "collection": collection_name,
                                "results": results,
                                "total": len(results),
                            },
                            indent=2,
                        ),
                    }
                ]
            }

        except Exception as e:
            return {
                "content": [{"type": "text", "text": f"Search error: {str(e)}"}],
                "isError": True,
            }

    async def _upload_points(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Upload points to collection."""
        collection_name = args["collection_name"]
        points = args["points"]

        try:
            # Convert points to PointStruct format
            point_structs = []
            for point in points:
                point_structs.append(
                    PointStruct(
                        id=point["id"],
                        vector=point["vector"],
                        payload=point.get("payload", {}),
                    )
                )

            # Upload points
            operation_info = self.client.upsert(
                collection_name=collection_name, points=point_structs
            )

            return {
                "content": [
                    {
                        "type": "text",
                        "text": json.dumps(
                            {
                                "collection": collection_name,
                                "operation_id": operation_info.operation_id,
                                "status": operation_info.status.name,
                                "points_uploaded": len(points),
                            },
                            indent=2,
                        ),
                    }
                ]
            }

        except Exception as e:
            return {
                "content": [{"type": "text", "text": f"Upload error: {str(e)}"}],
                "isError": True,
            }

    async def _create_collection(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new collection."""
        collection_name = args["collection_name"]
        vector_size = args["vector_size"]
        distance = args.get("distance", "Cosine")

        try:
            # Map distance string to enum
            distance_enum = {
                "Cosine": Distance.COSINE,
                "Euclidean": Distance.EUCLID,
                "Dot": Distance.DOT,
            }.get(distance, Distance.COSINE)

            # Create collection
            self.client.create_collection(
                collection_name=collection_name,
                vectors_config=VectorParams(size=vector_size, distance=distance_enum),
            )

            return {
                "content": [
                    {
                        "type": "text",
                        "text": json.dumps(
                            {
                                "collection": collection_name,
                                "vector_size": vector_size,
                                "distance": distance,
                                "status": "created",
                            },
                            indent=2,
                        ),
                    }
                ]
            }

        except Exception as e:
            return {
                "content": [
                    {"type": "text", "text": f"Create collection error: {str(e)}"}
                ],
                "isError": True,
            }

    async def _list_collections(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """List all collections."""
        try:
            collections = self.client.get_collections()

            collection_list = []
            for collection in collections.collections:
                collection_list.append(
                    {
                        "name": collection.name,
                        "status": "active",
                        "vectors_config": (
                            str(collection.config.params) if collection.config else None
                        ),
                    }
                )

            return {
                "content": [
                    {
                        "type": "text",
                        "text": json.dumps(
                            {
                                "collections": collection_list,
                                "total": len(collection_list),
                            },
                            indent=2,
                        ),
                    }
                ]
            }

        except Exception as e:
            return {
                "content": [
                    {"type": "text", "text": f"List collections error: {str(e)}"}
                ],
                "isError": True,
            }

    async def _delete_collection(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Delete a collection."""
        collection_name = args["collection_name"]

        try:
            self.client.delete_collection(collection_name)

            return {
                "content": [
                    {
                        "type": "text",
                        "text": json.dumps(
                            {"collection": collection_name, "status": "deleted"},
                            indent=2,
                        ),
                    }
                ]
            }

        except Exception as e:
            return {
                "content": [
                    {"type": "text", "text": f"Delete collection error: {str(e)}"}
                ],
                "isError": True,
            }

    async def _get_collection_info(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Get collection information."""
        collection_name = args["collection_name"]

        try:
            collection_info = self.client.get_collection(collection_name)

            info = {
                "name": collection_info.name,
                "vectors_count": collection_info.points_count,
                "segments_count": len(collection_info.segments),
                "status": collection_info.status.name,
                "vectors_config": (
                    {
                        "size": collection_info.config.params.size,
                        "distance": collection_info.config.params.distance.name,
                    }
                    if collection_info.config
                    else None
                ),
            }

            return {"content": [{"type": "text", "text": json.dumps(info, indent=2)}]}

        except Exception as e:
            return {
                "content": [
                    {"type": "text", "text": f"Get collection info error: {str(e)}"}
                ],
                "isError": True,
            }

    async def _get_health_resource(self) -> Dict[str, Any]:
        """Get Qdrant health status."""
        try:
            health = self.client.health()

            return {
                "contents": [
                    {
                        "type": "text",
                        "text": json.dumps(
                            {
                                "status": "healthy",
                                "timestamp": datetime.now().isoformat(),
                                "version": getattr(health, "version", "unknown"),
                                "title": getattr(health, "title", "Qdrant"),
                            },
                            indent=2,
                        ),
                    }
                ]
            }

        except Exception as e:
            return {
                "contents": [
                    {
                        "type": "text",
                        "text": json.dumps(
                            {
                                "status": "unhealthy",
                                "error": str(e),
                                "timestamp": datetime.now().isoformat(),
                            },
                            indent=2,
                        ),
                    }
                ]
            }

    async def _get_collections_resource(self) -> Dict[str, Any]:
        """Get collections list resource."""
        try:
            collections = self.client.get_collections()

            collection_list = []
            for collection in collections.collections:
                collection_list.append(
                    {
                        "name": collection.name,
                        "points_count": collection.points_count,
                        "status": collection.status.name,
                    }
                )

            return {
                "contents": [
                    {
                        "type": "text",
                        "text": json.dumps(
                            {
                                "collections": collection_list,
                                "total": len(collection_list),
                                "timestamp": datetime.now().isoformat(),
                            },
                            indent=2,
                        ),
                    }
                ]
            }

        except Exception as e:
            return {
                "contents": [
                    {
                        "type": "text",
                        "text": json.dumps(
                            {"error": str(e), "timestamp": datetime.now().isoformat()},
                            indent=2,
                        ),
                    }
                ]
            }


def create_qdrant_mcp_server(
    qdrant_url: str = None, api_key: str = None
) -> QdrantMCPServer:
    """Factory function to create Qdrant MCP server instance."""
    return QdrantMCPServer(qdrant_url=qdrant_url, api_key=api_key)


async def main():
    """Main entry point for running the Qdrant MCP server."""
    import argparse

    parser = argparse.ArgumentParser(description="Qdrant MCP Server")
    parser.add_argument("--qdrant-url", help="Qdrant server URL")
    parser.add_argument("--api-key", help="Qdrant API key")

    args = parser.parse_args()

    # Use provided API key or environment variable
    api_key = args.api_key or os.getenv("QDRANT_API_KEY")

    if not api_key:
        print(
            "Error: Qdrant API key required. Provide via --api-key or QDRANT_API_KEY environment variable"
        )
        return 1

    try:
        server = create_qdrant_mcp_server(qdrant_url=args.qdrant_url, api_key=api_key)

        print("Starting Qdrant MCP Server...")
        print(f"Qdrant URL: {server.qdrant_url}")
        print("API Key: Provided" if api_key else "No API key")

        await server.run()

    except Exception as e:
        print(f"Error starting server: {e}")
        return 1

    return 0


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
