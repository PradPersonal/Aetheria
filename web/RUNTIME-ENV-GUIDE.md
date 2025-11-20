# Runtime Environment Injection Guide

## Overview

The Aetheria web service supports **runtime environment injection**, allowing you to configure the application without rebuilding Docker images. This is essential for:

- **Multi-environment deployments** (dev, staging, production)
- **Container orchestration** (Kubernetes, Docker Swarm)
- **CI/CD pipelines** with environment-specific configurations

## How It Works

1. **Build Time**: React app builds with environment placeholders
2. **Runtime**: Docker entrypoint script injects actual values
3. **Browser**: JavaScript configuration loads the injected values

## Quick Start

### Development
```bash
# Copy environment template
cp web/.env.example web/.env.development

# Run with npm (uses .env.development)
cd web
npm start
```

### Docker Development
```bash
# Build the image
docker build -t aetheria-web ./web

# Run with development configuration
docker run -p 80:80 \
  -e REACT_APP_ENVIRONMENT=development \
  -e REACT_APP_ENABLE_DEBUG=true \
  aetheria-web
```

### Production
```bash
# Run with production configuration
docker run -p 80:80 \
  -e REACT_APP_API_URL=https://api.yourdomain.com/api \
  -e REACT_APP_STREAMING_URL=https://streaming.yourdomain.com/api \
  -e REACT_APP_ENVIRONMENT=production \
  -e REACT_APP_ENABLE_ANALYTICS=true \
  -e REACT_APP_ANALYTICS_ID=GA-XXXXXXXXX \
  aetheria-web
```

## Docker Compose

### Development
```yaml
services:
  web:
    build: ./web
    ports:
      - "3000:80"
    environment:
      - REACT_APP_API_URL=http://auth-service:3001/api
      - REACT_APP_STREAMING_URL=http://streaming-service:3002/api
      - REACT_APP_ENVIRONMENT=development
      - REACT_APP_ENABLE_DEBUG=true
```

### Production
```yaml
services:
  web:
    image: aetheria-web:latest
    ports:
      - "80:80"
    environment:
      - REACT_APP_API_URL=https://api.yourdomain.com/api
      - REACT_APP_STREAMING_URL=https://streaming.yourdomain.com/api
      - REACT_APP_ENVIRONMENT=production
      - REACT_APP_ENABLE_ANALYTICS=true
```

## Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aetheria-web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: aetheria-web
  template:
    metadata:
      labels:
        app: aetheria-web
    spec:
      containers:
      - name: web
        image: aetheria-web:latest
        ports:
        - containerPort: 80
        env:
        - name: REACT_APP_API_URL
          value: "https://api.yourdomain.com/api"
        - name: REACT_APP_ENVIRONMENT
          value: "production"
        - name: REACT_APP_VERSION
          valueFrom:
            fieldRef:
              fieldPath: metadata.labels['version']
```

## Available Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `REACT_APP_API_URL` | `http://localhost:3001/api` | Authentication service URL |
| `REACT_APP_STREAMING_URL` | `http://localhost:3002/api` | Streaming service URL |
| `REACT_APP_CHAT_URL` | `http://localhost:3003/api` | Chat service URL |
| `REACT_APP_CORE_API_URL` | `http://localhost:3004/api` | Core API service URL |
| `REACT_APP_WS_URL` | `ws://localhost:3003` | WebSocket URL for chat |
| `REACT_APP_ENVIRONMENT` | `production` | Runtime environment |
| `REACT_APP_ENABLE_CHAT` | `true` | Enable/disable chat feature |
| `REACT_APP_ENABLE_ANALYTICS` | `false` | Enable/disable analytics |
| `REACT_APP_ENABLE_DEBUG` | `false` | Enable/disable debug mode |

## Configuration Access

In your React components:

```javascript
import config from './config';

// Use configuration
const apiUrl = config.apiUrl;
const isDebugEnabled = config.isDebugEnabled;
const appName = config.appName;

// Feature flags
if (config.isChatEnabled) {
  // Render chat component
}
```

## Troubleshooting

### Check Configuration
```bash
# View current configuration in browser console
# The config utility logs all settings in debug mode

# Or check the generated env.js file
curl http://localhost/env.js
```

### Common Issues

1. **Environment variables not updating**: Restart the container
2. **Configuration not loading**: Check that `/env.js` is accessible
3. **Build-time vs Runtime**: Remember that React build-time env vars are fallbacks only

### Debug Mode

Enable debug mode to see configuration logging:
```bash
docker run -e REACT_APP_ENABLE_DEBUG=true aetheria-web
```

## Best Practices

1. **Use defaults**: Provide sensible defaults for all configuration
2. **Validate URLs**: Ensure API URLs are accessible from the browser
3. **Security**: Never expose secrets in frontend environment variables
4. **Documentation**: Keep environment variable documentation updated
5. **Testing**: Test configuration in all target environments