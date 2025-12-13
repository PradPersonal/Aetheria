# API Endpoint Verification Guide

This guide provides multiple methods to verify that your API endpoints are ready to accept HTTP requests from the UI project.

## 1. Health Check Endpoints

### Verify Individual Service Health
Each microservice should have a `/health` endpoint that you can test directly.

```bash
# Check Auth Service
curl -v http://localhost:3001/health

# Check Streaming Service  
curl -v http://localhost:3002/health

# Check Core API Service
curl -v http://localhost:3003/health

# Check Chat Service
curl -v http://localhost:3004/health
```

**Expected Response:**
```json
{
  "status": "OK",
  "service": "auth-service",
  "timestamp": "2025-11-20T10:30:00Z",
  "version": "1.0.0",
  "database": "connected",
  "dependencies": {
    "mongodb": "connected",
    "redis": "connected"
  }
}
```

## 2. Docker Compose Health Verification

### Check Container Status
```bash
# Verify all containers are running and healthy
docker-compose ps

# Check logs for any errors
docker-compose logs auth-service
docker-compose logs streaming-service
docker-compose logs core-api-service
docker-compose logs chat-service

# Follow logs in real-time
docker-compose logs -f --tail=50
```

### Expected Container Status:
```
NAME                    IMAGE               STATUS              PORTS
aetheria-auth           aetheria-auth       Up (healthy)        0.0.0.0:3001->3000/tcp
aetheria-streaming      aetheria-streaming  Up (healthy)        0.0.0.0:3002->3000/tcp
aetheria-core-api       aetheria-core-api   Up (healthy)        0.0.0.0:3003->3000/tcp
aetheria-chat           aetheria-chat       Up (healthy)        0.0.0.0:3004->3000/tcp
aetheria-web            aetheria-web        Up (healthy)        0.0.0.0:3000->3000/tcp
```

## 3. API Gateway/ALB Health Checks

### Local Development (nginx proxy)
```bash
# Test through nginx proxy (if configured)
curl -v http://localhost/api/health
curl -v http://localhost/api/auth/health
curl -v http://localhost/api/streaming/health
```

### Production ALB Health Checks
```bash
# Check ALB target group health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output api_target_group_arn) \
  --region ca-central-1

# Expected output shows "healthy" targets
```

## 4. End-to-End API Testing

### Authentication Flow Test
```bash
# 1. Register a test user
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com", 
    "password": "TestPass123!"
  }'

# 2. Login to get JWT token
TOKEN=$(curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123!"
  }' | jq -r '.token')

# 3. Test protected endpoint
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3001/api/auth/profile
```

### Streaming Service Test
```bash
# Test video listing (may require auth)
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3002/api/videos

# Test video upload endpoint (should return method info)
curl -v -X OPTIONS http://localhost:3002/api/videos/upload
```

## 5. CORS Verification

### Test CORS Headers
```bash
# Test preflight request
curl -X OPTIONS http://localhost:3001/api/auth/login \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type,Authorization" \
  -v

# Check for CORS headers in response:
# Access-Control-Allow-Origin: http://localhost:3000
# Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
# Access-Control-Allow-Headers: Content-Type, Authorization
```

### UI to API Connection Test
```javascript
// Test from browser console (F12) while on UI (localhost:3000)
fetch('http://localhost:3001/api/health', {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json'
  }
})
.then(response => response.json())
.then(data => console.log('API Response:', data))
.catch(error => console.error('API Error:', error));
```

## 6. Network Connectivity Tests

### Port Accessibility
```bash
# Check if API ports are accessible
telnet localhost 3001  # Auth Service
telnet localhost 3002  # Streaming Service  
telnet localhost 3003  # Core API Service
telnet localhost 3004  # Chat Service

# Or use PowerShell on Windows:
Test-NetConnection -ComputerName localhost -Port 3001
Test-NetConnection -ComputerName localhost -Port 3002
Test-NetConnection -ComputerName localhost -Port 3003
Test-NetConnection -ComputerName localhost -Port 3004
```

### DNS Resolution (for production)
```bash
# Test domain resolution
nslookup api.aetheria.example.com
nslookup aetheria.example.com

# Test SSL certificate
curl -I https://api.aetheria.example.com/health
```

## 7. Database Connection Verification

### MongoDB Health
```bash
# Connect to MongoDB container
docker exec -it aetheria-mongodb mongosh

# In MongoDB shell:
use aetheria_dev
db.runCommand({ ping: 1 })
show collections
```

### Redis Health  
```bash
# Connect to Redis container
docker exec -it aetheria-redis redis-cli

# In Redis CLI:
PING
INFO server
```

## 8. Load Testing (Optional)

### Simple Load Test with curl
```bash
# Test API under load
for i in {1..10}; do
  curl -s http://localhost:3001/health &
done
wait
```

### Using Apache Bench (if installed)
```bash
# 100 requests, 10 concurrent
ab -n 100 -c 10 http://localhost:3001/health
```

## 9. Automated Verification Script

Create a verification script to check all endpoints:

### PowerShell Script (verify-api.ps1)
```powershell
# API Endpoint Verification Script
$services = @(
    @{ name="Auth Service"; url="http://localhost:3001/health" },
    @{ name="Streaming Service"; url="http://localhost:3002/health" },
    @{ name="Core API Service"; url="http://localhost:3003/health" },
    @{ name="Chat Service"; url="http://localhost:3004/health" }
)

Write-Host "🚀 Starting API Endpoint Verification..." -ForegroundColor Green

foreach ($service in $services) {
    try {
        $response = Invoke-RestMethod -Uri $service.url -TimeoutSec 10
        if ($response.status -eq "OK") {
            Write-Host "✅ $($service.name): HEALTHY" -ForegroundColor Green
        } else {
            Write-Host "⚠️  $($service.name): UNHEALTHY - Status: $($response.status)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ $($service.name): UNREACHABLE - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test CORS
Write-Host "`n🌐 Testing CORS..." -ForegroundColor Blue
try {
    $headers = @{
        "Origin" = "http://localhost:3000"
        "Access-Control-Request-Method" = "POST"
        "Access-Control-Request-Headers" = "Content-Type,Authorization"
    }
    $corsResponse = Invoke-WebRequest -Uri "http://localhost:3001/api/auth/login" -Method OPTIONS -Headers $headers
    if ($corsResponse.Headers["Access-Control-Allow-Origin"]) {
        Write-Host "✅ CORS: Configured correctly" -ForegroundColor Green
    } else {
        Write-Host "⚠️  CORS: May have issues" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "❌ CORS: Test failed - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎯 Verification Complete!" -ForegroundColor Green
```

### Bash Script (verify-api.sh)
```bash
#!/bin/bash
# API Endpoint Verification Script

echo "🚀 Starting API Endpoint Verification..."

services=(
    "Auth Service:http://localhost:3001/health"
    "Streaming Service:http://localhost:3002/health"
    "Core API Service:http://localhost:3003/health"
    "Chat Service:http://localhost:3004/health"
)

for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    url=$(echo $service | cut -d: -f2-)
    
    if response=$(curl -s --max-time 10 "$url" 2>/dev/null); then
        if echo "$response" | grep -q '"status":"OK"'; then
            echo "✅ $name: HEALTHY"
        else
            echo "⚠️  $name: UNHEALTHY"
        fi
    else
        echo "❌ $name: UNREACHABLE"
    fi
done

echo ""
echo "🌐 Testing CORS..."
cors_response=$(curl -s -I -X OPTIONS \
    -H "Origin: http://localhost:3000" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type,Authorization" \
    "http://localhost:3001/api/auth/login" 2>/dev/null)

if echo "$cors_response" | grep -q "Access-Control-Allow-Origin"; then
    echo "✅ CORS: Configured correctly"
else
    echo "⚠️  CORS: May have issues"
fi

echo ""
echo "🎯 Verification Complete!"
```

## 10. Production Readiness Checklist

### Before UI Integration:
- [ ] All health endpoints return 200 OK
- [ ] Database connections are established  
- [ ] CORS headers are configured for UI domain
- [ ] SSL certificates are valid (production)
- [ ] Load balancer health checks pass
- [ ] Rate limiting is configured appropriately
- [ ] Authentication endpoints work correctly
- [ ] API documentation is accessible

### Environment-Specific Tests:
- [ ] **Development**: All services accessible on localhost
- [ ] **Staging**: Services accessible via staging domains
- [ ] **Production**: Services accessible via production domains with SSL

## 11. Troubleshooting Common Issues

### Service Not Responding
```bash
# Check if service is running
docker-compose ps service-name

# Check service logs
docker-compose logs service-name

# Restart specific service
docker-compose restart service-name
```

### CORS Issues
```bash
# Verify CORS configuration in each service
# Check that UI domain is in ALLOWED_ORIGINS environment variable
docker-compose exec auth-service env | grep ALLOWED_ORIGINS
```

### Database Connection Issues
```bash
# Check database connectivity
docker-compose exec auth-service npm run db:ping
docker-compose exec streaming-service npm run db:ping
```

### Port Conflicts
```bash
# Check what's using the ports
netstat -tulpn | grep :3001
netstat -tulpn | grep :3002

# Or on Windows:
netstat -an | findstr :3001
```

Run these verification steps in order, and you'll have confidence that your APIs are ready to serve requests from the UI! 🚀