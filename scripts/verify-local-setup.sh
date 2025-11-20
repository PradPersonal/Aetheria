#!/bin/bash

# Aetheria Local Environment Verification Script
# This script verifies that all services are running correctly

set -e

echo "🚀 Aetheria Local Environment Verification"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check service health
check_service() {
    local service_name="$1"
    local url="$2"
    local expected_status="${3:-200}"
    
    echo -n "Checking $service_name... "
    
    if response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null); then
        if [ "$response" = "$expected_status" ]; then
            echo -e "${GREEN}✅ OK${NC} (HTTP $response)"
            return 0
        else
            echo -e "${RED}❌ FAIL${NC} (HTTP $response)"
            return 1
        fi
    else
        echo -e "${RED}❌ UNREACHABLE${NC}"
        return 1
    fi
}

# Function to test API endpoint
test_api() {
    local service_name="$1"
    local url="$2"
    local expected_pattern="$3"
    
    echo -n "Testing $service_name API... "
    
    if response=$(curl -s "$url" 2>/dev/null); then
        if echo "$response" | grep -q "$expected_pattern"; then
            echo -e "${GREEN}✅ OK${NC}"
            return 0
        else
            echo -e "${RED}❌ FAIL${NC} (Unexpected response)"
            return 1
        fi
    else
        echo -e "${RED}❌ UNREACHABLE${NC}"
        return 1
    fi
}

echo ""
echo "📊 Checking Infrastructure Services..."
echo "-----------------------------------"

# Wait for services to be ready
echo "⏳ Waiting for services to start (this may take a few moments)..."
sleep 10

# Check MongoDB
check_service "MongoDB" "http://localhost:27017" "" || echo -e "${YELLOW}Note: Direct MongoDB HTTP check may not work, but service should be accessible${NC}"

# Check Redis
if command -v redis-cli &> /dev/null; then
    echo -n "Checking Redis... "
    if redis-cli -h localhost -p 6379 ping > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ redis-cli not available for direct test${NC}"
fi

# Check MinIO
check_service "MinIO Storage" "http://localhost:9000/minio/health/live"

echo ""
echo "🔧 Checking Backend Services..."
echo "-----------------------------"

# Check all backend services health endpoints
check_service "Authentication Service" "http://localhost:3001/health"
check_service "Streaming Service" "http://localhost:3002/health" 
check_service "Chat Service" "http://localhost:3003/health"
check_service "Core API Service" "http://localhost:3004/health"

echo ""
echo "🌐 Checking Frontend Service..."
echo "----------------------------"

# Check frontend
check_service "Web Frontend" "http://localhost/health"
check_service "Web Frontend (Root)" "http://localhost/"

echo ""
echo "🧪 Testing API Endpoints..."
echo "-------------------------"

# Test API endpoints with actual functionality
test_api "Auth Service Health" "http://localhost:3001/health" '"status":"OK"'
test_api "Streaming Service Health" "http://localhost:3002/health" '"status":"OK"' 
test_api "Chat Service Health" "http://localhost:3003/health" '"status":"OK"'
test_api "Core API Service Health" "http://localhost:3004/health" '"status":"OK"'

echo ""
echo "📊 Testing Sample Data..."
echo "-----------------------"

# Test if sample data exists (this requires authentication, so we'll check if the endpoint responds)
echo -n "Checking streaming videos endpoint... "
if curl -s "http://localhost:3002/api/streaming" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC} (Endpoint accessible)"
else
    echo -e "${RED}❌ FAIL${NC} (Endpoint not accessible)"
fi

echo ""
echo "🔍 Environment Information..."
echo "-------------------------"

# Show environment info
echo -e "${BLUE}Frontend URL:${NC} http://localhost"
echo -e "${BLUE}MinIO Console:${NC} http://localhost:9001 (minioadmin/minioadmin123)"
echo -e "${BLUE}API Endpoints:${NC}"
echo "  - Auth: http://localhost:3001"
echo "  - Streaming: http://localhost:3002" 
echo "  - Chat: http://localhost:3003"
echo "  - Core API: http://localhost:3004"

echo ""
echo "👤 Test Accounts..."
echo "----------------"
echo -e "${BLUE}Admin User:${NC} admin@aetheria.com / admin123"
echo -e "${BLUE}Test User:${NC} user@aetheria.com / admin123"

echo ""
echo "🐳 Docker Container Status..."
echo "---------------------------"

# Show container status
if command -v docker &> /dev/null; then
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=aetheria"
else
    echo -e "${YELLOW}Docker CLI not available${NC}"
fi

echo ""
echo "📝 Quick Tests to Try..."
echo "----------------------"
echo "1. 🌐 Open http://localhost in your browser"
echo "2. 🔐 Login with admin@aetheria.com / admin123"
echo "3. 📺 Check if sample videos are loaded"
echo "4. 💬 Test chat functionality (if enabled)"
echo "5. 📊 Check MinIO console: http://localhost:9001"

echo ""
echo "🛠️ Troubleshooting..."
echo "-------------------"
echo "If any service fails:"
echo "1. Check logs: docker-compose logs [service-name]"
echo "2. Restart specific service: docker-compose restart [service-name]" 
echo "3. Full restart: docker-compose down && docker-compose up -d"
echo "4. Check port conflicts: netstat -tulpn | grep [port]"

echo ""
echo -e "${GREEN}✨ Verification Complete!${NC}"
echo "=================================="