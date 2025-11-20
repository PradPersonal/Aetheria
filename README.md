# Aetheria

A modern streaming platform with microservices architecture.

## 🚀 Quick Start (Local Development)

### One-Command Setup

**Windows (PowerShell):**
```powershell
.\setup.ps1
```

**Linux/macOS (Bash):**
```bash
chmod +x setup.sh && ./setup.sh
```

### Manual Setup

1. **Prerequisites**: Docker, Docker Compose
2. **Start services**: `docker-compose up -d`
3. **Verify setup**: `.\scripts\verify-local-setup.ps1` (Windows) or `./scripts/verify-local-setup.sh` (Linux/macOS)
4. **Access app**: http://localhost

### Test Accounts
- **Admin**: admin@aetheria.com / admin123
- **User**: user@aetheria.com / admin123

## 📖 Documentation

- [Local Setup Guide](LOCAL-SETUP.md) - Detailed local development setup
- [Environment Configuration](ENVIRONMENT.md) - Environment variables and configuration
- [Runtime Environment Guide](web/RUNTIME-ENV-GUIDE.md) - Web service runtime configuration

## 🏗️ Architecture

### Services
- **Web Frontend** (Port 80) - React application with runtime environment injection
- **Auth Service** (Port 3001) - User authentication and authorization
- **Streaming Service** (Port 3002) - Video management and streaming
- **Chat Service** (Port 3003) - Real-time messaging
- **Core API Service** (Port 3004) - Core business logic

### Infrastructure
- **MongoDB** - Primary database
- **Redis** - Caching and session management  
- **MinIO** - S3-compatible object storage (local development)

## 🛠️ Development Commands

Using the included Makefile:
```bash
make help          # Show available commands
make setup         # Build and start all services
make verify        # Verify all services are running
make logs          # View logs from all services
make clean         # Clean up Docker resources
make reset         # Complete reset and fresh start
```

Or using Docker Compose directly:
```bash
docker-compose up -d        # Start services
docker-compose logs -f      # View logs
docker-compose down         # Stop services
docker-compose ps           # Check status
```

## 🔍 Verification

After setup, verify everything is working:

1. **Web App**: http://localhost
2. **API Health Checks**:
   - Auth: http://localhost:3001/health
   - Streaming: http://localhost:3002/health  
   - Chat: http://localhost:3003/health
   - Core API: http://localhost:3004/health
3. **MinIO Console**: http://localhost:9001 (minioadmin/minioadmin123)

## 🧪 Sample Data

The setup includes:
- Pre-created test users (admin and regular user)
- Sample video metadata with various genres
- Optimized database indexes
- S3 bucket configuration

## 🐳 Container Health

All services include comprehensive health checks:
- Database connectivity monitoring
- Service-specific health endpoints
- Container orchestration ready
- Automated startup verification

## 📊 Monitoring

- Health endpoints for all services
- Docker health checks
- Resource usage monitoring
- Comprehensive logging

## 🔒 Security

- Non-root users in containers
- Environment-driven configuration
- Secure defaults for local development
- JWT-based authentication

## 🎯 Features

- **Runtime Environment Injection** - Configure without rebuilding
- **Microservices Architecture** - Scalable and maintainable
- **Health Monitoring** - Built-in health checks
- **Sample Data** - Ready-to-use test data
- **Docker Compose** - One-command deployment
- **Cross-Platform** - Windows, Linux, macOS support