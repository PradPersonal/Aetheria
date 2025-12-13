# Simple API Verification Script
# Usage: .\simple-verify-api.ps1

Write-Host "🚀 Aetheria API Verification" -ForegroundColor Blue
Write-Host "============================" -ForegroundColor Blue

$services = @{
    "Auth Service" = "http://localhost:3001/health"
    "Streaming Service" = "http://localhost:3002/health" 
    "Core API Service" = "http://localhost:3003/health"
    "Chat Service" = "http://localhost:3004/health"
}

$allHealthy = $true

# Test each service
foreach ($service in $services.GetEnumerator()) {
    $name = $service.Key
    $url = $service.Value
    
    try {
        Write-Host "Testing $name..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri $url -TimeoutSec 5 -ErrorAction Stop
        
        if ($response.status -eq "OK") {
            Write-Host "✅ $name is HEALTHY" -ForegroundColor Green
        } else {
            Write-Host "⚠️  $name is UNHEALTHY (Status: $($response.status))" -ForegroundColor Yellow
            $allHealthy = $false
        }
    }
    catch {
        Write-Host "❌ $name is UNREACHABLE" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
        $allHealthy = $false
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""

# Test CORS
Write-Host "Testing CORS configuration..." -ForegroundColor Yellow
try {
    $corsHeaders = @{
        "Origin" = "http://localhost:3000"
        "Access-Control-Request-Method" = "POST"
        "Access-Control-Request-Headers" = "Content-Type,Authorization"
    }
    
    $corsResponse = Invoke-WebRequest -Uri "http://localhost:3001/api/auth/login" -Method OPTIONS -Headers $corsHeaders -TimeoutSec 5 -ErrorAction Stop
    
    if ($corsResponse.Headers["Access-Control-Allow-Origin"]) {
        Write-Host "✅ CORS is configured correctly" -ForegroundColor Green
    } else {
        Write-Host "⚠️  CORS may have configuration issues" -ForegroundColor Yellow
        $allHealthy = $false
    }
}
catch {
    Write-Host "❌ CORS test failed" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    $allHealthy = $false
}

Write-Host ""

# Summary
if ($allHealthy) {
    Write-Host "🎉 SUCCESS: All APIs are ready!" -ForegroundColor Green
    Write-Host "🚀 You can now connect your UI to the APIs" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Start your React application: npm start" -ForegroundColor White
    Write-Host "2. Navigate to http://localhost:3000" -ForegroundColor White
    Write-Host "3. Test the UI -> API integration" -ForegroundColor White
} else {
    Write-Host "⚠️  ISSUES DETECTED: Some APIs are not ready" -ForegroundColor Yellow
    Write-Host "🔧 Please fix the issues above before connecting the UI" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Cyan
    Write-Host "1. Check if Docker containers are running: docker-compose ps" -ForegroundColor White
    Write-Host "2. Check container logs: docker-compose logs [service-name]" -ForegroundColor White
    Write-Host "3. Restart services: docker-compose restart" -ForegroundColor White
}

Write-Host ""
Write-Host "For more detailed verification, see API-VERIFICATION.md" -ForegroundColor Cyan