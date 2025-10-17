# DinoAir3 Control Center

> **A comprehensive productivity and development platform with AI-powered tools**

DinoAir3 is a modern full-stack application that combines productivity tools, AI-powered features, and development utilities into a unified control center. Built with Python/FastAPI backend and Flutter/React frontends.

## ✨ Features

### 🎯 Core Productivity Tools
- **📝 Notes Management** - Rich text notes with tagging and search
- **📋 Project Management** - Hierarchical project organization with status tracking
- **🔍 Smart File Search** - Vector-powered semantic search across your codebase
- **📅 Calendar Integration** - Event management and scheduling

### 🤖 AI-Powered Tools
- **💬 AI Chat Assistant** - Intelligent conversational AI with context awareness
- **🔄 Pseudocode Translator** - Convert pseudocode to multiple programming languages
- **🧠 RAG (Retrieval Augmented Generation)** - Enhanced AI responses with document context

### 🛠️ Developer Tools
- **📊 Health Monitoring** - System health and performance metrics
- **🔒 Security Scanner** - Automated vulnerability scanning
- **📈 Performance Metrics** - Real-time application monitoring with Datadog integration
- **🐳 Docker Support** - Containerized deployment

### 💰 Additional Features
- **📊 Crypto Dashboard** - Market tracking and portfolio management
- **🌐 Multi-Platform** - Web interface and mobile Flutter app

## 🏗️ Architecture

### Backend Stack
- **FastAPI** - Modern Python web framework
- **SQLite/PostgreSQL** - Database layer with migrations
- **Qdrant** - Vector database for semantic search
- **Pydantic** - Data validation and serialization

### Frontend Options
- **Flutter** - Cross-platform mobile application
- **React** - Web interface (in development)

### Infrastructure
- **Docker** - Containerization
- **Prometheus + Grafana** - Monitoring stack
- **GitLab CI/CD** - Automated testing and deployment

## 🚀 Quick Start

### Prerequisites
- Python 3.11+
- Node.js 18+ (for frontend development)
- Docker (optional)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/DinoAir3.git
   cd DinoAir3
   ```

2. **Set up the development environment**
   ```bash
   # Run the bootstrap script to create virtual environment and install dependencies
   ./scripts/dev/bootstrap.sh
   ```

3. **Activate virtual environment**
   ```bash
   source .venv/bin/activate
   ```

4. **Start the API server**
   ```bash
   uvicorn API.app:app --reload --host 127.0.0.1 --port 24801
   ```

5. **Access the application**
   - API Documentation: http://127.0.0.1:24801/docs
   - Health Check: http://127.0.0.1:24801/health

### VS Code Development

Use the included VS Code tasks for common operations:
- **Setup venv**: Initial environment setup
- **Run API (uvicorn)**: Start the development server
- **Test (pytest)**: Run the test suite
- **Lint (ruff)**: Check code quality
- **Format (ruff)**: Auto-format code
- **Pre-commit**: Run all checks before committing

## 📋 Development Workflow

### Testing
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov

# Run specific test file
pytest tests/test_notes.py
```

### Code Quality
```bash
# Lint code
ruff check .

# Format code
ruff format .

# Run pre-commit hooks
pre-commit run --all-files
```

### Database Operations
```bash
# Initialize database
python -m database.initialize_db

# Run migrations (when implemented)
# python -m alembic upgrade head
```

## 🌐 API Endpoints

### Core APIs
- `GET /health` - Application health check
- `GET /api/v1/health` - Extended health information

### Notes API
- `POST /api/v1/notes` - Create note
- `GET /api/v1/notes` - List notes
- `GET /api/v1/notes/{id}` - Get note
- `PUT /api/v1/notes/{id}` - Update note
- `DELETE /api/v1/notes/{id}` - Delete note

### Projects API
- `POST /api/v1/projects` - Create project
- `GET /api/v1/projects` - List projects
- `GET /api/v1/projects/{id}` - Get project
- `PUT /api/v1/projects/{id}` - Update project
- `DELETE /api/v1/projects/{id}` - Delete project

### File Search API
- `POST /api/v1/file_search/search` - Semantic file search
- `GET /api/v1/file_search/stats` - Search statistics

## 🔧 Configuration

### Environment Variables
Create `.env` file in the root directory:
```bash
# API Configuration
DINOAIR_PORT=24801
DINOAIR_HOST=127.0.0.1
DINOAIR_ENVIRONMENT=development

# Database
DINOAIR_DATABASE_URL=sqlite:///./dinoair.db

# Security
DINOAIR_SECRET_KEY=your-secret-key-here
DINOAIR_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# Optional: External Services
DINOAIR_QDRANT_URL=http://localhost:6333
DINOAIR_DATADOG_API_KEY=your-datadog-key
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow PEP 8 style guidelines
- Write tests for new features
- Update documentation as needed
- Run pre-commit hooks before submitting

## 📖 Documentation

- [API Documentation](docs/) - Detailed API reference
- [Flutter Integration Plan](docs/flutter-integration-plan.md) - Mobile app development
- [Project Implementation](docs/projects-feature-implementation.md) - Feature development guide
- [Security Setup](tools/security/) - Security configuration

## 🔒 Security

- Built-in request validation and sanitization
- CORS protection
- Rate limiting capabilities
- Automated security scanning tools
- Input validation with Pydantic

## 📊 Monitoring

- Health check endpoints
- Performance metrics collection
- Error tracking and logging
- Optional Datadog integration

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏢 Authors

**Dino Pit Studios LLC**
- Development team focused on productivity and AI-powered tools

## 🚧 Project Status

**Active Development** - DinoAir3 is under active development with regular updates and new features being added.

### Current Phase
- ✅ Backend API (FastAPI) - Complete
- ✅ Core features (Notes, Projects, File Search) - Complete
- 🚧 Flutter mobile app - In Progress
- 🚧 React web interface - Planned
- 🚧 Advanced AI features - In Progress

### Roadmap
- [ ] Complete Flutter mobile application
- [ ] Enhanced AI chat capabilities
- [ ] Real-time collaboration features
- [ ] Advanced analytics dashboard
- [ ] Plugin system for extensibility
