# Aetheria One-Command Setup Script (PowerShell)
# This script sets up the entire local development environment

Write-Host "🚀 Aetheria Local Development Setup" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Cyan

try {
    docker --version | Out-Null
    Write-Host "✅ Docker found" -ForegroundColor Green
}
catch {
    Write-Host "❌ Docker not found. Please install Docker first." -ForegroundColor Red
    exit 1
}

try {
    docker-compose --version | Out-Null
    Write-Host "✅ Docker Compose found" -ForegroundColor Green
}
catch {
    Write-Host "❌ Docker Compose not found. Please install Docker Compose first." -ForegroundColor Red
    exit 1
}

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Host "✅ Docker daemon is running" -ForegroundColor Green
}
catch {
    Write-Host "❌ Docker daemon not running. Please start Docker first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🏗️ Building and starting services..." -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Build and start services
Write-Host "Building Docker images..."
docker-compose build

Write-Host "Starting services..."
docker-compose up -d

Write-Host ""
Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow

# Wait for services to start
Start-Sleep -Seconds 30

# Check if all services are healthy
Write-Host "Checking service health..."
$maxRetries = 12
$retryCount = 0

while ($retryCount -lt $maxRetries) {
    $healthyCount = 0
    
    # Check each service
    $services = @("auth-service", "streaming-service", "chat-service", "core-api-service", "web")
    
    foreach ($service in $services) {
        $status = docker-compose ps | Select-String $service
        if ($status -and ($status -match "healthy|Up")) {
            $healthyCount++
        }
    }
    
    if ($healthyCount -eq 5) {
        Write-Host "✅ All services are ready!" -ForegroundColor Green
        break
    }
    
    Write-Host "Services starting... ($($retryCount + 1)/$maxRetries)"
    Start-Sleep -Seconds 10
    $retryCount++
}

if ($retryCount -eq $maxRetries) {
    Write-Host "⚠️ Some services may still be starting. You can check status with: docker-compose ps" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Running verification..." -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

# Run verification if available
if (Test-Path "scripts\verify-local-setup.ps1") {
    & ".\scripts\verify-local-setup.ps1"
}
else {
    Write-Host "⚠️ Verification script not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green

Write-Host ""
Write-Host "📱 Access Your Application:" -ForegroundColor Blue
Write-Host "   🌐 Web App: http://localhost"
Write-Host "   📊 MinIO Console: http://localhost:9001"
Write-Host ""
Write-Host "👤 Test Accounts:" -ForegroundColor Blue
Write-Host "   Admin: admin@aetheria.com / admin123"
Write-Host "   User:  user@aetheria.com / admin123"
Write-Host ""
Write-Host "🛠️ Useful Commands:" -ForegroundColor Blue
Write-Host "   View logs: docker-compose logs -f"
Write-Host "   Stop services: docker-compose down"
Write-Host "   Restart: docker-compose restart"
Write-Host ""

# Try to open browser
try {
    Write-Host "Opening application in browser..."
    Start-Process "http://localhost"
}
catch {
    Write-Host "💡 Open http://localhost in your browser to get started!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Happy coding! 🚀" -ForegroundColor Green