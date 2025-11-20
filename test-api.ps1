# Minimal API Test
Write-Host "Testing API endpoints..." -ForegroundColor Blue

try {
    $response = Invoke-RestMethod -Uri "http://localhost:3001/health" -TimeoutSec 5
    if ($response.status -eq "OK") {
        Write-Host "Auth Service: HEALTHY" -ForegroundColor Green
    } else {
        Write-Host "Auth Service: UNHEALTHY" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Auth Service: UNREACHABLE" -ForegroundColor Red
}

Write-Host "Test complete!"