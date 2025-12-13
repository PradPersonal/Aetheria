# Aetheria Local Development Setup

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Git
- PowerShell (Windows) or Bash (Linux/macOS)

### 1. Start All Services
```bash
# Clone and navigate to the project
git clone <repository-url>
cd Aetheria-main

# Start all services (this will build images and start containers)
docker-compose up -d

# Wait for services to be ready (2-3 minutes)
docker-compose logs -f
```

### 2. Verify Setup
```bash
# Run verification script
# On Windows:
.\scripts\verify-local-setup.ps1

# On Linux/macOS:
chmod +x scripts/verify-local-setup.sh
./scripts/verify-local-setup.sh
```

### 3. Access the Application
- **Web Application**: http://localhost
- **MinIO Console**: http://localhost:9001 (minioadmin/minioadmin123)

### 4. Test Login
- **Admin**: admin@aetheria.com / admin123
- **User**: user@aetheria.com / admin123

## Services Overview

| Service | Port | Health Check | Purpose |
|---------|------|--------------|---------|
| Web Frontend | 80 | http://localhost/health | React application |
| Auth Service | 3001 | http://localhost:3001/health | User authentication |
| Streaming Service | 3002 | http://localhost:3002/health | Video management |
| Chat Service | 3003 | http://localhost:3003/health | Real-time messaging |
| Core API Service | 3004 | http://localhost:3004/health | Core business logic |
| MongoDB | 27017 | - | Primary database |
| Redis | 6379 | - | Caching and sessions |
| MinIO | 9000/9001 | http://localhost:9000/minio/health/live | S3-compatible storage |

## Sample Data

The setup includes:
- **Test Users**: Admin and regular user accounts
- **Sample Videos**: Pre-populated video metadata
- **Database Indexes**: Optimized for performance

### Sample Videos
- The Last Action Hero (Action, Featured)
- Urban Warriors (Action)
- Life's Moments (Drama)
- The Last Letter (Drama)
- Space Odyssey (Sci-Fi)
- Comedy Central (Comedy)
- And more...

## Docker Compose Commands

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f [service-name]

# Restart specific service
docker-compose restart [service-name]

# Stop all services
docker-compose down

# Stop and remove volumes (fresh start)
docker-compose down -v

# Rebuild and start
docker-compose up -d --build

# Check service status
docker-compose ps
```

## Troubleshooting

### Service Won't Start
1. Check if ports are available:
   ```bash
   # Windows
   netstat -an | findstr "80\|3001\|3002\|3003\|3004\|27017\|6379\|9000"
   
   # Linux/macOS  
   netstat -tulpn | grep -E "80|3001|3002|3003|3004|27017|6379|9000"
   ```

2. Check Docker resources:
   ```bash
   docker system df
   docker system prune # Clean up if needed
   ```

### Database Issues
```bash
# Reset database
docker-compose down -v
docker-compose up -d mongodb redis
# Wait for DB to be ready, then start other services
docker-compose up -d
```

### Frontend Not Loading
1. Check if environment injection worked:
   ```bash
   curl http://localhost/env.js
   ```

2. Check nginx logs:
   ```bash
   docker-compose logs web
   ```

### API Services Failing
1. Check environment variables:
   ```bash
   docker-compose exec auth-service env | grep MONGO_URI
   ```

2. Test database connection:
   ```bash
   docker-compose exec mongodb mongosh -u admin -p password123
   ```

## Development Workflow

### 1. Code Changes
```bash
# After making changes to a service
docker-compose up -d --build [service-name]
```

### 2. Database Changes
```bash
# Access MongoDB
docker-compose exec mongodb mongosh -u admin -p password123 streamingapp

# Access Redis
docker-compose exec redis redis-cli
```

### 3. View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f auth-service

# Last 50 lines
docker-compose logs --tail=50 streaming-service
```

## Production Considerations

This setup is for **local development only**. For production:

1. **Use secure passwords** (not the defaults)
2. **Use external databases** (not containers)
3. **Use proper SSL certificates**
4. **Use production-grade storage** (not MinIO)
5. **Configure monitoring and logging**
6. **Use container orchestration** (Kubernetes)

## API Testing

### Authentication
```bash
# Register a new user
curl -X POST http://localhost:3001/api/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","firstName":"Test","lastName":"User"}'

# Login
curl -X POST http://localhost:3001/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@aetheria.com","password":"admin123"}'
```

### Streaming
```bash
# Get videos (may require authentication)
curl http://localhost:3002/api/streaming
```

### Health Checks
```bash
# Check all service health
for port in 3001 3002 3003 3004; do
  echo "Service on port $port:"
  curl -s http://localhost:$port/health | jq .
done
```

## Environment Variables

All services support environment-driven configuration. See individual `.env.example` files for available options.

### Web Frontend Runtime Configuration
The web service supports runtime environment injection:
```bash
docker run -p 80:80 \
  -e REACT_APP_API_URL=http://localhost:3001/api \
  -e REACT_APP_ENVIRONMENT=development \
  aetheria-web
```

## Monitoring

### Container Health
```bash
# Check container health status
docker-compose ps

# Get detailed health info  
docker inspect --format='{{.State.Health.Status}}' aetheria-auth-service
```

### Resource Usage
```bash
# Monitor resource usage
docker stats

# Check logs for errors
docker-compose logs | grep -i error
```