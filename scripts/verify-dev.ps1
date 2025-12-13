# Development Environment API Verification Script
param(
    [string]$Environment = "development",
    [string]$ConfigFile = "config/dev-config.json"
)

Write-Host ">> Aetheria API Verification - DEVELOPMENT" -ForegroundColor Blue
Write-Host "===========================================" -ForegroundColor Blue

# Load development configuration
if (Test-Path $ConfigFile) {
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    Write-Host "[INFO] Loaded configuration from $ConfigFile" -ForegroundColor Cyan
} else {
    Write-Host "[WARN] Config file not found, using defaults" -ForegroundColor Yellow
    $config = @{
        services = @{
            auth = @{ url = "http://localhost:3001"; healthPath = "/health" }
            streaming = @{ url = "http://localhost:3002"; healthPath = "/health" }
            coreapi = @{ url = "http://localhost:3003"; healthPath = "/health" }
            chat = @{ url = "http://localhost:3004"; healthPath = "/health" }
        }
        ui = @{
            url = "http://localhost:3000"
            origin = "http://localhost:3000"
        }
        timeouts = @{
            health = 10
            cors = 5
        }
    }
}

$allHealthy = $true
$results = @()

Write-Host ""
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Config File: $ConfigFile" -ForegroundColor Cyan
Write-Host ""

# Test each service
foreach ($serviceName in $config.services.PSObject.Properties.Name) {
    $service = $config.services.$serviceName
    $url = $service.url + $service.healthPath
    $displayName = (Get-Culture).TextInfo.ToTitleCase($serviceName) + " Service"
    
    Write-Host "Testing $displayName..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri $url -TimeoutSec $config.timeouts.health -ErrorAction Stop
        
        if ($response.status -eq "OK" -or $response.status -eq "healthy") {
            Write-Host "[OK] $displayName is HEALTHY" -ForegroundColor Green
            $results += @{ Service = $displayName; Status = "Healthy"; URL = $url }
        } 
        else {
            Write-Host "[WARN] $displayName returned: $($response.status)" -ForegroundColor Yellow
            $allHealthy = $false
            $results += @{ Service = $displayName; Status = "Unhealthy"; URL = $url; Details = $response.status }
        }
    }
    catch {
        Write-Host "[ERROR] $displayName is UNREACHABLE - $($_.Exception.Message)" -ForegroundColor Red
        $allHealthy = $false
        $results += @{ Service = $displayName; Status = "Unreachable"; URL = $url; Error = $_.Exception.Message }
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""

# Test CORS (Development specific)
Write-Host "Testing CORS configuration..." -ForegroundColor Yellow
try {
    $corsHeaders = @{
        "Origin" = $config.ui.origin
        "Access-Control-Request-Method" = "POST"
        "Access-Control-Request-Headers" = "Content-Type,Authorization"
    }
    
    $authLoginUrl = $config.services.auth.url + "/api/auth/login"
    $corsResponse = Invoke-WebRequest -Uri $authLoginUrl -Method OPTIONS -Headers $corsHeaders -TimeoutSec $config.timeouts.cors -ErrorAction Stop
    
    $corsHeaders = $corsResponse.Headers["Access-Control-Allow-Origin"]
    if ($corsHeaders -and ($corsHeaders -eq "*" -or $corsHeaders -contains $config.ui.origin)) {
        Write-Host "[OK] CORS is configured correctly" -ForegroundColor Green
        $results += @{ Service = "CORS Configuration"; Status = "OK"; Details = "Origin allowed: $corsHeaders" }
    } 
    else {
        Write-Host "[WARN] CORS may have configuration issues" -ForegroundColor Yellow
        Write-Host "      Expected origin: $($config.ui.origin)" -ForegroundColor Gray
        Write-Host "      Allowed origins: $corsHeaders" -ForegroundColor Gray
        $allHealthy = $false
        $results += @{ Service = "CORS Configuration"; Status = "Warning"; Details = "Unexpected CORS headers" }
    }
}
catch {
    Write-Host "[ERROR] CORS test failed - $($_.Exception.Message)" -ForegroundColor Red
    $allHealthy = $false
    $results += @{ Service = "CORS Configuration"; Status = "Failed"; Error = $_.Exception.Message }
}

Write-Host ""

# Development-specific checks
Write-Host "Development Environment Checks..." -ForegroundColor Yellow

# Check for .env files
$envFiles = @(".env", "web/.env", "api/.env")
foreach ($envFile in $envFiles) {
    if (Test-Path $envFile) {
        Write-Host "[OK] Found environment file: $envFile" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Missing environment file: $envFile" -ForegroundColor Yellow
    }
}

# Check Docker containers (if using Docker)
try {
    $dockerPs = docker ps --format "table {{.Names}}\t{{.Status}}" 2>$null
    if ($dockerPs) {
        Write-Host "[INFO] Docker containers:" -ForegroundColor Cyan
        Write-Host $dockerPs -ForegroundColor Gray
    }
} catch {
    Write-Host "[INFO] Docker not available or not used" -ForegroundColor Gray
}

Write-Host ""

# Summary with detailed results
if ($allHealthy) {
    Write-Host "[SUCCESS] All APIs are ready for development!" -ForegroundColor Green
    Write-Host ">> You can now start your React development server" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. cd web && npm start" -ForegroundColor White
    Write-Host "2. Open http://localhost:3000" -ForegroundColor White
    Write-Host "3. Test UI -> API integration" -ForegroundColor White
    Write-Host "4. Use APIIntegrationTest component for live testing" -ForegroundColor White
} 
else {
    Write-Host "[WARN] Some issues detected in development environment" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Development Troubleshooting:" -ForegroundColor Cyan
    Write-Host "1. Check service logs: docker-compose logs [service-name]" -ForegroundColor White
    Write-Host "2. Restart services: docker-compose restart" -ForegroundColor White
    Write-Host "3. Rebuild if needed: docker-compose up --build" -ForegroundColor White
    Write-Host "4. Verify .env files are present and correct" -ForegroundColor White
    Write-Host "5. Check port conflicts: netstat -an | findstr :300" -ForegroundColor White
}

# Generate detailed report
Write-Host ""
Write-Host "=== DETAILED RESULTS ===" -ForegroundColor Magenta
$results | ForEach-Object {
    $status = $_
    Write-Host "Service: $($status.Service)" -ForegroundColor White
    Write-Host "Status:  $($status.Status)" -ForegroundColor $(
        switch ($status.Status) {
            "Healthy" { "Green" }
            "OK" { "Green" }
            "Unhealthy" { "Yellow" }
            "Warning" { "Yellow" }
            default { "Red" }
        }
    )
    if ($status.URL) { Write-Host "URL:     $($status.URL)" -ForegroundColor Gray }
    if ($status.Details) { Write-Host "Details: $($status.Details)" -ForegroundColor Gray }
    if ($status.Error) { Write-Host "Error:   $($status.Error)" -ForegroundColor Red }
    Write-Host ""
}

Write-Host "For production deployment, use: scripts/verify-prod.ps1" -ForegroundColor Cyan