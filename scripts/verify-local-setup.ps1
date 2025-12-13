# Aetheria Local Environment Verification Script (PowerShell)
# This script verifies that all services are running correctly

Write-Host "🚀 Aetheria Local Environment Verification" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green

# Function to check service health
function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$Url,
        [int]$ExpectedStatus = 200
    )
    
    Write-Host "Checking $ServiceName... " -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -eq $ExpectedStatus) {
            Write-Host "✅ OK" -ForegroundColor Green -NoNewline
            Write-Host " (HTTP $($response.StatusCode))"
            return $true
        } else {
            Write-Host "❌ FAIL" -ForegroundColor Red -NoNewline  
            Write-Host " (HTTP $($response.StatusCode))"
            return $false
        }
    }
    catch {
        Write-Host "❌ UNREACHABLE" -ForegroundColor Red
        return $false
    }
}

# Function to test API endpoint content
function Test-ApiEndpoint {
    param(
        [string]$ServiceName,
        [string]$Url,
        [string]$ExpectedPattern
    )
    
    Write-Host "Testing $ServiceName API... " -NoNewline
    
    try {
        $response = Invoke-RestMethod -Uri $Url -UseBasicParsing -TimeoutSec 10
        $responseText = $response | ConvertTo-Json
        
        if ($responseText -match $ExpectedPattern) {
            Write-Host "✅ OK" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ FAIL" -ForegroundColor Red -NoNewline
            Write-Host " (Unexpected response)"
            return $false
        }
    }
    catch {
        Write-Host "❌ UNREACHABLE" -ForegroundColor Red
        return $false
    }
}

Write-Host ""
Write-Host "📊 Checking Infrastructure Services..." -ForegroundColor Cyan
Write-Host "-----------------------------------" -ForegroundColor Cyan

# Wait for services to be ready
Write-Host "⏳ Waiting for services to start (this may take a few moments)..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Check MinIO
Test-ServiceHealth "MinIO Storage" "http://localhost:9000/minio/health/live" | Out-Null

Write-Host ""
Write-Host "🔧 Checking Backend Services..." -ForegroundColor Cyan
Write-Host "-----------------------------" -ForegroundColor Cyan

# Check all backend services health endpoints
Test-ServiceHealth "Authentication Service" "http://localhost:3001/health" | Out-Null
Test-ServiceHealth "Streaming Service" "http://localhost:3002/health" | Out-Null
Test-ServiceHealth "Chat Service" "http://localhost:3003/health" | Out-Null
Test-ServiceHealth "Core API Service" "http://localhost:3004/health" | Out-Null

Write-Host ""
Write-Host "🌐 Checking Frontend Service..." -ForegroundColor Cyan
Write-Host "----------------------------" -ForegroundColor Cyan

# Check frontend
Test-ServiceHealth "Web Frontend" "http://localhost/health" | Out-Null
Test-ServiceHealth "Web Frontend (Root)" "http://localhost/" | Out-Null

Write-Host ""
Write-Host "🧪 Testing API Endpoints..." -ForegroundColor Cyan
Write-Host "-------------------------" -ForegroundColor Cyan

# Test API endpoints with actual functionality
Test-ApiEndpoint "Auth Service Health" "http://localhost:3001/health" '"status":"OK"' | Out-Null
Test-ApiEndpoint "Streaming Service Health" "http://localhost:3002/health" '"status":"OK"' | Out-Null
Test-ApiEndpoint "Chat Service Health" "http://localhost:3003/health" '"status":"OK"' | Out-Null  
Test-ApiEndpoint "Core API Service Health" "http://localhost:3004/health" '"status":"OK"' | Out-Null

Write-Host ""
Write-Host "📊 Testing Sample Data..." -ForegroundColor Cyan
Write-Host "-----------------------" -ForegroundColor Cyan

# Test if sample data endpoint is accessible
Write-Host "Checking streaming videos endpoint... " -NoNewline
try {
    Invoke-WebRequest -Uri "http://localhost:3002/api/streaming" -UseBasicParsing -TimeoutSec 5 | Out-Null
    Write-Host "✅ OK" -ForegroundColor Green -NoNewline
    Write-Host " (Endpoint accessible)"
}
catch {
    Write-Host "❌ FAIL" -ForegroundColor Red -NoNewline
    Write-Host " (Endpoint not accessible)"
}

Write-Host ""
Write-Host "🔍 Environment Information..." -ForegroundColor Cyan
Write-Host "-------------------------" -ForegroundColor Cyan

# Show environment info
Write-Host "Frontend URL: " -NoNewline -ForegroundColor Blue
Write-Host "http://localhost"
Write-Host "MinIO Console: " -NoNewline -ForegroundColor Blue
Write-Host "http://localhost:9001 (minioadmin/minioadmin123)"
Write-Host "API Endpoints:" -ForegroundColor Blue
Write-Host "  - Auth: http://localhost:3001"
Write-Host "  - Streaming: http://localhost:3002"
Write-Host "  - Chat: http://localhost:3003"
Write-Host "  - Core API: http://localhost:3004"

Write-Host ""
Write-Host "👤 Test Accounts..." -ForegroundColor Cyan
Write-Host "----------------" -ForegroundColor Cyan
Write-Host "Admin User: " -NoNewline -ForegroundColor Blue
Write-Host "admin@aetheria.com / admin123"
Write-Host "Test User: " -NoNewline -ForegroundColor Blue
Write-Host "user@aetheria.com / admin123"

Write-Host ""
Write-Host "🐳 Docker Container Status..." -ForegroundColor Cyan
Write-Host "---------------------------" -ForegroundColor Cyan

# Show container status
try {
    $containers = docker ps --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}" --filter "name=aetheria" 2>$null
    if ($containers) {
        Write-Host $containers
    } else {
        Write-Host "No Aetheria containers found or Docker not accessible" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Docker CLI not available or not accessible" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📝 Quick Tests to Try..." -ForegroundColor Cyan
Write-Host "----------------------" -ForegroundColor Cyan
Write-Host "1. 🌐 Open http://localhost in your browser"
Write-Host "2. 🔐 Login with admin@aetheria.com / admin123"
Write-Host "3. 📺 Check if sample videos are loaded"
Write-Host "4. 💬 Test chat functionality (if enabled)"
Write-Host "5. 📊 Check MinIO console: http://localhost:9001"

Write-Host ""
Write-Host "🛠️ Troubleshooting..." -ForegroundColor Cyan
Write-Host "-------------------" -ForegroundColor Cyan
Write-Host "If any service fails:"
Write-Host "1. Check logs: docker-compose logs [service-name]"
Write-Host "2. Restart specific service: docker-compose restart [service-name]"
Write-Host "3. Full restart: docker-compose down && docker-compose up -d"
Write-Host "4. Check port conflicts: netstat -an | findstr [port]"

Write-Host ""
Write-Host "✨ Verification Complete!" -ForegroundColor Green
Write-Host "==========================" -ForegroundColor Green