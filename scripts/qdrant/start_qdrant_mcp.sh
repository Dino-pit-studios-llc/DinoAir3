#!/bin/bash
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
echo "MCP Server: http://$MCP_SERVER_HOST:$MCP_SERVER_PORT"

# Start the server
python mcp_qdrant_server.py --qdrant-url "$QDRANT_URL" --api-key "$QDRANT_API_KEY"
