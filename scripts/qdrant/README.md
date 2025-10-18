# Qdrant MCP Server Setup for DinoAir3

This guide explains how to set up and use the Qdrant MCP (Model Context Protocol) server integration with your DinoAir3 file search system.

## Overview

The Qdrant MCP Server provides a standardized interface for AI models to interact with Qdrant vector database. It enables:

- **Vector Search**: Semantic similarity search across your indexed files
- **Collection Management**: Create, manage, and delete Qdrant collections
- **Embedding Storage**: Upload and manage vector embeddings
- **Real-time Integration**: Live synchronization with DinoAir3 data

## Prerequisites

- Python 3.8+
- Qdrant server running (Docker or standalone)
- Qdrant API key (see Security Note below)
- DinoAir3 project with existing vector search functionality

## Security Note

**⚠️ IMPORTANT: API Key Security**

- Never commit your actual API key to version control
- Store API keys in environment variables or secure credential management systems
- Replace `YOUR_QDRANT_API_KEY_HERE` placeholder with your actual API key when running commands
- Keep your API keys confidential and rotate them regularly
- Use different API keys for development, staging, and production environments

## Quick Start

### 1. One-Command Setup (Recommended)

```bash
# Complete setup with sample data
# Replace YOUR_QDRANT_API_KEY_HERE with your actual API key
python setup_and_populate_qdrant.py --api-key "YOUR_QDRANT_API_KEY_HERE"
```

### 2. Manual Setup (Step by Step)

```bash
# Set your API key (replace YOUR_QDRANT_API_KEY_HERE with your actual API key)
export QDRANT_API_KEY="YOUR_QDRANT_API_KEY_HERE"

# Install dependencies
pip install -r mcp_qdrant_requirements.txt

# Start Qdrant server
python start_qdrant_server.py --api-key "$QDRANT_API_KEY"

# In another terminal, start MCP server
python mcp_qdrant_server.py

# Populate with sample data
python populate_qdrant_collections.py
```

### 2. Start Qdrant Server

If Qdrant isn't running yet:

```bash
# Using Docker
docker run -d -p 6333:6333 -p 6334:6334 \
  --name qdrant \
  -e QDRANT__SERVICE__API_KEY="$QDRANT_API_KEY" \
  qdrant/qdrant

# Or using Docker Compose
docker-compose up -d qdrant
```

### 3. Start the MCP Server

```bash
# Start the server
python mcp_qdrant_server.py

# Or use the startup script
./start_qdrant_mcp.sh
```

The server will be available at `http://localhost:8080`

## Configuration

### Environment Variables

Create a `.env.qdrant` file (replace YOUR_QDRANT_API_KEY_HERE with your actual API key):

```bash
QDRANT_API_KEY=YOUR_QDRANT_API_KEY_HERE
QDRANT_URL=http://localhost:6333
MCP_SERVER_HOST=localhost
MCP_SERVER_PORT=8080
```

### Configuration File

Edit `qdrant_mcp_config.yaml` to customize:

```yaml
qdrant:
  url: "http://localhost:6333"
  api_key: "${QDRANT_API_KEY}"
  timeout: 30

collections:
  dinoair_files:
    name: "dinoair_files"
    vector_size: 384
    distance: "Cosine"

search:
  default_limit: 10
  max_limit: 50
  default_threshold: 0.7
```

## Available Tools

### Vector Search

Search for similar vectors in a collection:

```bash
curl -X POST "http://localhost:8080/tools/call" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "search_vectors",
    "arguments": {
      "collection_name": "dinoair_files",
      "query_vector": [0.1, 0.2, 0.3, 0.4],
      "limit": 5,
      "score_threshold": 0.7
    }
  }'
```

### Upload Points

Upload embeddings to a collection:

```bash
curl -X POST "http://localhost:8080/tools/call" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "upload_points",
    "arguments": {
      "collection_name": "dinoair_files",
      "points": [
        {
          "id": "file_001",
          "vector": [0.1, 0.2, 0.3, 0.4],
          "payload": {
            "file_path": "/docs/example.txt",
            "file_type": "txt",
            "content": "Sample content"
          }
        }
      ]
    }
  }'
```

### Collection Management

```bash
# Create collection
curl -X POST "http://localhost:8080/tools/call" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "create_collection",
    "arguments": {
      "collection_name": "my_collection",
      "vector_size": 384,
      "distance": "Cosine"
    }
  }'

# List collections
curl -X POST "http://localhost:8080/tools/call" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "list_collections",
    "arguments": {}
  }'

# Get collection info
curl -X POST "http://localhost:8080/tools/call" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "get_collection_info",
    "arguments": {
      "collection_name": "dinoair_files"
    }
  }'
```

## Integration with DinoAir3

### Automatic Setup and Population

Use the automated setup script for complete integration:

```bash
# One-command setup with sample data
# Replace YOUR_QDRANT_API_KEY_HERE with your actual API key
python setup_and_populate_qdrant.py --api-key "YOUR_QDRANT_API_KEY_HERE"

# Or run individual steps
python start_qdrant_server.py --api-key "YOUR_QDRANT_API_KEY_HERE"
python mcp_qdrant_server.py
python populate_qdrant_collections.py
```

### Data Synchronization

The system can automatically sync data from DinoAir3's local vector database:

1. **Enable Auto-sync** in `qdrant_mcp_config.yaml`:

   ```yaml
   integration:
     sync_existing_data: true
     auto_sync: true
     sync_interval_minutes: 30
   ```

2. **Run Data Migration**:

   ```python
   from mcp_qdrant_server import create_qdrant_mcp_server

   server = create_qdrant_mcp_server()
   # Migration logic would go here
   ```

### Embedding Integration

Integrate with DinoAir3's existing embedding system:

```python
from rag.embedding_generator import get_embedding_generator
from mcp_qdrant_server import QdrantMCPServer

# Generate embeddings using DinoAir3's system
embedding_gen = get_embedding_generator()
embeddings = embedding_gen.generate_embeddings_batch(texts)

# Upload to Qdrant via MCP
server = QdrantMCPServer()
# Upload logic here
```

### Docker Integration

Use Docker Compose for easy deployment:

```bash
# Start all services
docker-compose up -d

# Or build and run MCP server
docker build -f Dockerfile.mcp -t qdrant-mcp-server .
docker run -p 8080:8080 --env-file .env.qdrant qdrant-mcp-server
```

## API Reference

### Endpoints

- `POST /tools/call` - Execute MCP tools
- `GET /resources/list` - List available resources
- `GET /resources/read` - Read resource content

### Error Handling

The server returns standardized error responses:

```json
{
  "content": [
    {
      "type": "text",
      "text": "Error: Collection not found"
    }
  ],
  "isError": true
}
```

## Troubleshooting

### Common Issues

1. **Connection Failed**
   - Ensure Qdrant server is running on the correct URL
   - Check API key validity
   - Verify network connectivity

2. **Import Errors**
   - Run `pip install -r mcp_qdrant_requirements.txt`
   - Check Python version (3.8+ required)

3. **Permission Errors**
   - Ensure API key has proper permissions
   - Check Qdrant server configuration

### Debug Mode

Enable debug logging:

```bash
export DEBUG=true
python mcp_qdrant_server.py
```

### Health Check

```bash
curl http://localhost:8080/health
```

## Security Considerations

**⚠️ CRITICAL: Protect Your API Keys**

- **API Key Protection**: 
  - Never commit API keys to version control (use `.gitignore` for `.env.*` files)
  - Store API keys in environment variables or secure credential management systems
  - Use different API keys for development, staging, and production environments
  - Rotate API keys regularly
- **Network Security**: Use HTTPS in production environments to encrypt data in transit
- **Access Control**: Configure Qdrant with appropriate authentication and authorization
- **Data Privacy**: Be aware of sensitive data stored in vector collections and implement appropriate access controls

## Performance Tuning

### Collection Optimization

```yaml
collections:
  dinoair_files:
    name: "dinoair_files"
    vector_size: 384
    distance: "Cosine"
    # Add optimization settings
    optimization:
      memmap_threshold: 20000
      indexing_threshold: 20000
```

### Search Optimization

```yaml
search:
  default_limit: 10
  max_limit: 50
  # Enable search caching
  cache:
    enabled: true
    ttl_seconds: 300
```

## Monitoring

### Logs

Logs are written to `logs/qdrant_mcp.log`:

```bash
tail -f logs/qdrant_mcp.log
```

### Metrics

The server exposes basic metrics:

- Request count
- Response times
- Error rates
- Collection statistics

## Support

For issues and questions:

1. Check the troubleshooting section
2. Review Qdrant documentation: https://qdrant.tech/documentation/
3. Check MCP documentation: https://modelcontextprotocol.io/
4. Review DinoAir3 vector search implementation in `rag/` directory

## License

This Qdrant MCP integration is part of the DinoAir3 project and follows the same license terms.
