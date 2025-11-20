# UI-to-API Integration Verification Script
Write-Host "🌐 Aetheria UI-API Integration Verification" -ForegroundColor Blue
Write-Host "==========================================" -ForegroundColor Blue
Write-Host ""

$allGood = $true

# Step 1: Check if UI is running
Write-Host "Step 1: Checking UI Application..." -ForegroundColor Yellow
try {
    $uiResponse = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    if ($uiResponse.StatusCode -eq 200) {
        Write-Host "✅ UI is running on localhost:3000" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ UI is not running on localhost:3000" -ForegroundColor Red
    Write-Host "   Please start UI with: npm start" -ForegroundColor Yellow
    $allGood = $false
}

Write-Host ""

# Step 2: Check environment configuration files
Write-Host "Step 2: Checking Environment Configuration..." -ForegroundColor Yellow

$envFiles = @(".env", ".env.local", ".env.development")
$envFound = $false

foreach ($envFile in $envFiles) {
    $envPath = "web\$envFile"
    if (Test-Path $envPath) {
        Write-Host "✅ Found: $envFile" -ForegroundColor Green
        $envFound = $true
        
        # Check for required environment variables
        $content = Get-Content $envPath -ErrorAction SilentlyContinue
        if ($content -match "REACT_APP_.*API.*URL") {
            Write-Host "   Contains API URL configuration" -ForegroundColor Cyan
        }
    }
}

if (-not $envFound) {
    Write-Host "⚠️  No environment files found in web/ directory" -ForegroundColor Yellow
    Write-Host "   Create .env file with API URLs" -ForegroundColor Yellow
}

Write-Host ""

# Step 3: Check API service configuration
Write-Host "Step 3: Checking API Service Configuration..." -ForegroundColor Yellow

$apiServicePath = "web\src\services\api.js"
if (Test-Path $apiServicePath) {
    Write-Host "✅ Found: API service file" -ForegroundColor Green
    
    $apiContent = Get-Content $apiServicePath -Raw -ErrorAction SilentlyContinue
    if ($apiContent -match "process\.env\.REACT_APP") {
        Write-Host "   Uses environment variables ✓" -ForegroundColor Cyan
    }
    if ($apiContent -match "axios") {
        Write-Host "   Uses axios HTTP client ✓" -ForegroundColor Cyan
    }
    if ($apiContent -match "Authorization.*Bearer") {
        Write-Host "   Has authentication headers ✓" -ForegroundColor Cyan
    }
} else {
    Write-Host "⚠️  API service file not found at expected location" -ForegroundColor Yellow
    Write-Host "   Expected: web/src/services/api.js" -ForegroundColor Yellow
}

$authServicePath = "web\src\services\auth.service.js"
if (Test-Path $authServicePath) {
    Write-Host "✅ Found: Authentication service file" -ForegroundColor Green
} else {
    Write-Host "⚠️  Auth service file not found" -ForegroundColor Yellow
    Write-Host "   Expected: web/src/services/auth.service.js" -ForegroundColor Yellow
}

Write-Host ""

# Step 4: Test API connectivity from UI perspective
Write-Host "Step 4: Testing API Connectivity from UI Origin..." -ForegroundColor Yellow

$apiEndpoints = @{
    "Auth Service" = "http://localhost:3001/health"
    "Streaming Service" = "http://localhost:3002/health"
    "Core API Service" = "http://localhost:3003/health"
    "Chat Service" = "http://localhost:3004/health"
}

foreach ($service in $apiEndpoints.GetEnumerator()) {
    try {
        # Simulate request from UI origin
        $headers = @{
            "Origin" = "http://localhost:3000"
            "Referer" = "http://localhost:3000/"
            "User-Agent" = "Mozilla/5.0 (UI-Integration-Test)"
        }
        
        $response = Invoke-RestMethod -Uri $service.Value -Headers $headers -TimeoutSec 5 -ErrorAction Stop
        
        if ($response.status -eq "OK") {
            Write-Host "✅ $($service.Key): Accessible from UI" -ForegroundColor Green
        } else {
            Write-Host "⚠️  $($service.Key): Unexpected response" -ForegroundColor Yellow
            $allGood = $false
        }
    } catch {
        Write-Host "❌ $($service.Key): Not accessible from UI" -ForegroundColor Red
        $allGood = $false
    }
}

Write-Host ""

# Step 5: Test CORS configuration
Write-Host "Step 5: Testing CORS Configuration..." -ForegroundColor Yellow

try {
    $corsHeaders = @{
        "Origin" = "http://localhost:3000"
        "Access-Control-Request-Method" = "POST"
        "Access-Control-Request-Headers" = "Content-Type,Authorization"
    }
    
    $corsResponse = Invoke-WebRequest -Uri "http://localhost:3001/api/auth/login" -Method OPTIONS -Headers $corsHeaders -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    
    # Check for CORS headers in response
    $allowOrigin = $corsResponse.Headers["Access-Control-Allow-Origin"]
    $allowMethods = $corsResponse.Headers["Access-Control-Allow-Methods"]
    
    if ($allowOrigin -and ($allowOrigin -contains "http://localhost:3000" -or $allowOrigin -contains "*")) {
        Write-Host "✅ CORS: Configured correctly" -ForegroundColor Green
        Write-Host "   Allow-Origin: $allowOrigin" -ForegroundColor Cyan
    } else {
        Write-Host "❌ CORS: UI origin not allowed" -ForegroundColor Red
        Write-Host "   Expected: http://localhost:3000 or *" -ForegroundColor Yellow
        $allGood = $false
    }
} catch {
    Write-Host "❌ CORS: Test failed" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    $allGood = $false
}

Write-Host ""

# Step 6: Check package.json for proxy configuration
Write-Host "Step 6: Checking Proxy Configuration..." -ForegroundColor Yellow

$packageJsonPath = "web\package.json"
if (Test-Path $packageJsonPath) {
    $packageContent = Get-Content $packageJsonPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
    
    if ($packageContent.proxy) {
        Write-Host "✅ Proxy configured: $($packageContent.proxy)" -ForegroundColor Green
        Write-Host "   This will help avoid CORS issues" -ForegroundColor Cyan
    } else {
        Write-Host "ℹ️  No proxy configured in package.json" -ForegroundColor Cyan
        Write-Host "   This is OK if CORS is handled server-side" -ForegroundColor Cyan
    }
} else {
    Write-Host "⚠️  package.json not found in web/ directory" -ForegroundColor Yellow
}

# Check for setupProxy.js
$setupProxyPath = "web\src\setupProxy.js"
if (Test-Path $setupProxyPath) {
    Write-Host "✅ Custom proxy configuration found: setupProxy.js" -ForegroundColor Green
} else {
    Write-Host "ℹ️  No custom proxy configuration (setupProxy.js)" -ForegroundColor Cyan
}

Write-Host ""

# Summary and recommendations
Write-Host "📋 Summary and Recommendations" -ForegroundColor Blue
Write-Host "==============================" -ForegroundColor Blue

if ($allGood) {
    Write-Host "🎉 UI-API Integration Setup: READY!" -ForegroundColor Green
    Write-Host ""
    Write-Host "✅ All checks passed. Your UI should be able to communicate with APIs." -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Open http://localhost:3000 in your browser" -ForegroundColor White
    Write-Host "2. Open Developer Tools (F12) -> Console tab" -ForegroundColor White
    Write-Host "3. Try to register/login to test the complete flow" -ForegroundColor White
    Write-Host "4. Monitor Network tab for API calls" -ForegroundColor White
    Write-Host "5. Check console for any errors" -ForegroundColor White
    
} else {
    Write-Host "⚠️  UI-API Integration Setup: ISSUES DETECTED" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🔧 Required Actions:" -ForegroundColor Yellow
    Write-Host "1. Fix the issues marked with ❌ above" -ForegroundColor White
    Write-Host "2. Ensure all API services are running (docker-compose up)" -ForegroundColor White
    Write-Host "3. Verify environment variables in .env files" -ForegroundColor White
    Write-Host "4. Check CORS configuration in API services" -ForegroundColor White
    Write-Host "5. Re-run this script after fixes" -ForegroundColor White
}

Write-Host ""
Write-Host "🧪 Manual Testing:" -ForegroundColor Cyan
Write-Host "Open browser console at localhost:3000 and test:" -ForegroundColor White
Write-Host "  fetch('/health').then(r=>r.json()).then(console.log)" -ForegroundColor Gray
Write-Host "  // Should return API health status" -ForegroundColor Gray

Write-Host ""
Write-Host "📚 For detailed troubleshooting, see:" -ForegroundColor Cyan
Write-Host "  - UI-API-VERIFICATION.md" -ForegroundColor White
Write-Host "  - API-VERIFICATION.md" -ForegroundColor White