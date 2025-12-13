# Environment Configuration Guide

This document describes the environment configuration for all Aetheria services.

## Quick Start

1. Copy the `.env.example` files to `.env` in each service directory:
   ```bash
   cp api/authService/.env.example api/authService/.env
   cp api/streamingService/.env.example api/streamingService/.env
   cp api/chatService/.env.example api/chatService/.env
   cp api/coreAPIService/.env.example api/coreAPIService/.env
   ```

2. Update the `.env` files with your actual configuration values.

## Service Configurations

### Authentication Service (Port 3001)
- **Database**: MongoDB connection for user management
- **JWT**: Token-based authentication configuration
- **Email**: SMTP configuration for password reset emails
- **Security**: BCrypt rounds for password hashing

### Streaming Service (Port 3002)
- **Database**: MongoDB connection for video metadata
- **AWS S3**: File storage for video content
- **Video Processing**: File size limits and format restrictions

### Chat Service (Port 3003)
- **WebSocket**: Real-time messaging configuration
- **Redis**: Session management and message caching
- **Rate Limiting**: Message rate limiting configuration

### Core API Service (Port 3004)
- **Database**: PostgreSQL or other database connections
- **External APIs**: Third-party service integrations
- **Caching**: Performance optimization settings

### Web Service (Port 80)
- **Runtime Environment Injection**: Environment variables are injected at container startup
- **API Endpoints**: Configurable backend service URLs
- **Feature Flags**: Enable/disable features without rebuilding
- **External Services**: Analytics, monitoring, and error tracking

## Health Endpoints

All services expose comprehensive health check endpoints at `/health`:

```bash
# Check service health
curl http://localhost:3001/health  # Auth Service
curl http://localhost:3002/health  # Streaming Service
curl http://localhost:3003/health  # Chat Service
curl http://localhost:3004/health  # Core API Service
curl http://localhost/health       # Web Service
```

### Health Response Format

```json
{
  "status": "OK",
  "timestamp": "2025-11-20T10:30:00.000Z",
  "service": "Service Name",
  "version": "1.0.0",
  "environment": "production",
  "uptime": 86400,
  "memory": {
    "rss": 50331648,
    "heapTotal": 35651584,
    "heapUsed": 20971520,
    "external": 1638400
  },
  "database": {
    "status": "connected",
    "name": "streamingapp"
  }
}
```

## Runtime Environment Injection (Web Service)

The web service supports **runtime environment injection**, allowing you to configure API endpoints and feature flags without rebuilding the Docker image:

```bash
# Development
docker run -e REACT_APP_API_URL=http://localhost:3001/api aetheria-web

# Production
docker run -e REACT_APP_API_URL=https://api.yourdomain.com/api aetheria-web
```

### How it works:
1. **Build time**: React app is built with placeholders
2. **Runtime**: Docker entrypoint script replaces placeholders with actual environment values
3. **Browser**: JavaScript loads the injected configuration

## Docker Configuration

Each service includes:
- **Multi-stage builds** for optimized production images
- **Non-root user** for enhanced security (API services)
- **Health checks** for container orchestration
- **Environment-driven configuration**
- **Runtime injection** (Web service only)

## Security Best Practices

1. **Never commit `.env` files** - Use `.env.example` as templates
2. **Use strong secrets** - Generate random JWT secrets and API keys
3. **Limit CORS origins** - Restrict to your domain in production
4. **Use HTTPS** - Always use SSL/TLS in production
5. **Regular updates** - Keep dependencies updated

## Development vs Production

### Development
```bash
NODE_ENV=development
CORS_ORIGIN=http://localhost:3000
```

### Production
```bash
NODE_ENV=production
CORS_ORIGIN=https://yourdomain.com
```

## Monitoring

Health endpoints are designed for:
- **Docker health checks**
- **Load balancer health checks**
- **Monitoring systems** (Prometheus, etc.)
- **Service discovery** systems

## Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NODE_ENV` | No | development | Runtime environment |
| `PORT` | No | Service-specific | Server port |
| `CORS_ORIGIN` | No | http://localhost:3000 | Allowed CORS origin |
| `SERVICE_NAME` | No | Auto-generated | Service identifier |
| `SERVICE_VERSION` | No | 1.0.0 | Service version |

Service-specific variables are documented in each `.env.example` file.