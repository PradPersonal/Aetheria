#!/bin/bash

# Aetheria One-Command Setup Script
# This script sets up the entire local development environment

set -e

echo "🚀 Aetheria Local Development Setup"
echo "===================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found. Please install Docker first.${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose not found. Please install Docker Compose first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker daemon not running. Please start Docker first.${NC}"
    exit 1
fi

echo ""
echo "🏗️  Building and starting services..."
echo "====================================="

# Build and start services
echo "Building Docker images..."
docker-compose build

echo "Starting services..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
echo "======================================"

# Wait for services to start
sleep 30

# Check if all services are healthy
echo "Checking service health..."
MAX_RETRIES=12
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HEALTHY_COUNT=0
    
    # Check each service
    for service in "auth-service" "streaming-service" "chat-service" "core-api-service" "web"; do
        if docker-compose ps | grep "$service" | grep -q "healthy\|Up"; then
            ((HEALTHY_COUNT++))
        fi
    done
    
    if [ $HEALTHY_COUNT -eq 5 ]; then
        echo -e "${GREEN}✅ All services are ready!${NC}"
        break
    fi
    
    echo "Services starting... ($((RETRY_COUNT + 1))/$MAX_RETRIES)"
    sleep 10
    ((RETRY_COUNT++))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${YELLOW}⚠️  Some services may still be starting. You can check status with: docker-compose ps${NC}"
fi

echo ""
echo "🔍 Running verification..."
echo "========================="

# Run verification if available
if [ -f "scripts/verify-local-setup.sh" ]; then
    chmod +x scripts/verify-local-setup.sh
    ./scripts/verify-local-setup.sh
else
    echo -e "${YELLOW}⚠️  Verification script not found${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo "=================="

echo ""
echo -e "${BLUE}📱 Access Your Application:${NC}"
echo "   🌐 Web App: http://localhost"
echo "   📊 MinIO Console: http://localhost:9001"
echo ""
echo -e "${BLUE}👤 Test Accounts:${NC}"
echo "   Admin: admin@aetheria.com / admin123"
echo "   User:  user@aetheria.com / admin123"
echo ""
echo -e "${BLUE}🛠️  Useful Commands:${NC}"
echo "   View logs: docker-compose logs -f"
echo "   Stop services: docker-compose down"
echo "   Restart: docker-compose restart"
echo ""

# Try to open browser (on macOS/Linux with GUI)
if command -v open &> /dev/null; then
    echo "Opening application in browser..."
    open http://localhost
elif command -v xdg-open &> /dev/null; then
    echo "Opening application in browser..."
    xdg-open http://localhost
else
    echo -e "${YELLOW}💡 Open http://localhost in your browser to get started!${NC}"
fi

echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"