# API Endpoint Verification Script for Aetheria Platform
# Run with: .\verify-api.ps1

param(
    [string]$Environment = "local",  # local, staging, production
    [switch]$Verbose,
    [switch]$SkipCORS,
    [switch]$SkipAuth
)

# Configuration based on environment
$config = @{
    local = @{
        baseUrl = "http://localhost"
        services = @{
            auth = "3001"
            streaming = "3002"
            coreapi = "3003"
            chat = "3004"
            web = "3000"
        }
        uiOrigin = "http://localhost:3000"
    }
    staging = @{
        baseUrl = "https://api-staging.aetheria.example.com"
        services = @{
            auth = ""
            streaming = ""
            coreapi = ""
            chat = ""
        }
        uiOrigin = "https://staging.aetheria.example.com"
    }
    production = @{
        baseUrl = "https://api.aetheria.com"
        services = @{
            auth = ""
            streaming = ""
            coreapi = ""
            chat = ""
        }
        uiOrigin = "https://aetheria.com"
    }
}

$currentConfig = $config[$Environment]

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $colorMap = @{
        "Red" = [ConsoleColor]::Red
        "Green" = [ConsoleColor]::Green
        "Yellow" = [ConsoleColor]::Yellow
        "Blue" = [ConsoleColor]::Blue
        "Cyan" = [ConsoleColor]::Cyan
        "White" = [ConsoleColor]::White
    }
    
    Write-Host $Message -ForegroundColor $colorMap[$Color]
}

function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$Url,
        [int]$TimeoutSeconds = 10
    )
    
    try {
        if ($Verbose) {
            Write-ColorOutput "  Testing: $Url" "Cyan"
        }
        
        $response = Invoke-RestMethod -Uri $Url -TimeoutSec $TimeoutSeconds -ErrorAction Stop
        
        if ($response.status -eq "OK") {
            Write-ColorOutput "✅ $ServiceName`: HEALTHY" "Green"
            if ($Verbose -and $response.version) {
                Write-ColorOutput "   Version: $($response.version)" "Cyan"
            }
            if ($Verbose -and $response.database) {
                Write-ColorOutput "   Database: $($response.database)" "Cyan"
            }
            return $true
        }
        else {
            Write-ColorOutput "⚠️  $ServiceName`: UNHEALTHY - Status: $($response.status)" "Yellow"
            return $false
        }
    }
    catch {
        Write-ColorOutput "❌ $ServiceName`: UNREACHABLE" "Red"
        if ($Verbose) {
            Write-ColorOutput "   Error: $($_.Exception.Message)" "Red"
        }
        return $false
    }
}

function Test-CORS {
    param(
        [string]$Url,
        [string]$Origin
    )
    
    try {
        $headers = @{
            "Origin" = $Origin
            "Access-Control-Request-Method" = "POST"
            "Access-Control-Request-Headers" = "Content-Type,Authorization"
        }
        
        $response = Invoke-WebRequest -Uri $Url -Method OPTIONS -Headers $headers -TimeoutSec 10 -ErrorAction Stop
        
        $allowOrigin = $response.Headers["Access-Control-Allow-Origin"]
        $allowMethods = $response.Headers["Access-Control-Allow-Methods"]
        $allowHeaders = $response.Headers["Access-Control-Allow-Headers"]
        
        if ($allowOrigin -and ($allowOrigin -eq $Origin -or $allowOrigin -eq "*")) {
            Write-ColorOutput "✅ CORS: Configured correctly" "Green"
            if ($Verbose) {
                Write-ColorOutput "   Allow-Origin: $allowOrigin" "Cyan"
                Write-ColorOutput "   Allow-Methods: $allowMethods" "Cyan"
                Write-ColorOutput "   Allow-Headers: $allowHeaders" "Cyan"
            }
            return $true
        }
        else {
            Write-ColorOutput "⚠️  CORS: Origin not allowed" "Yellow"
            if ($Verbose) {
                Write-ColorOutput "   Expected: $Origin" "Yellow"
                Write-ColorOutput "   Got: $allowOrigin" "Yellow"
            }
            return $false
        }
    }
    catch {
        Write-ColorOutput "❌ CORS: Test failed" "Red"
        if ($Verbose) {
            Write-ColorOutput "   Error: $($_.Exception.Message)" "Red"
        }
        return $false
    }
}

function Test-Authentication {
    param(
        [string]$AuthUrl
    )
    
    try {
        # Test registration endpoint
        $registerUrl = "$AuthUrl/api/auth/register"
        $testUser = @{
            username = "testuser_$(Get-Random)"
            email = "test_$(Get-Random)@example.com"
            password = "TestPass123!"
        }
        
        if ($Verbose) {
            Write-ColorOutput "  Testing registration endpoint..." "Cyan"
        }
        
        $registerResponse = Invoke-RestMethod -Uri $registerUrl -Method POST -Body ($testUser | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10
        
        # Test login endpoint
        $loginUrl = "$AuthUrl/api/auth/login"
        $loginData = @{
            email = $testUser.email
            password = $testUser.password
        }
        
        if ($Verbose) {
            Write-ColorOutput "  Testing login endpoint..." "Cyan"
        }
        
        $loginResponse = Invoke-RestMethod -Uri $loginUrl -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10
        
        if ($loginResponse.token) {
            Write-ColorOutput "✅ Authentication: Working correctly" "Green"
            if ($Verbose) {
                Write-ColorOutput "   Token received: $($loginResponse.token.Substring(0, 20))..." "Cyan"
            }
            return $loginResponse.token
        }
        else {
            Write-ColorOutput "⚠️  Authentication: No token received" "Yellow"
            return $null
        }
    }
    catch {
        Write-ColorOutput "❌ Authentication: Test failed" "Red"
        if ($Verbose) {
            Write-ColorOutput "   Error: $($_.Exception.Message)" "Red"
        }
        return $null
    }
}

function Test-ProtectedEndpoint {
    param(
        [string]$Url,
        [string]$Token
    )
    
    try {
        $headers = @{
            "Authorization" = "Bearer $Token"
        }
        
        $response = Invoke-RestMethod -Uri $Url -Headers $headers -TimeoutSec 10
        Write-ColorOutput "✅ Protected Endpoint: Accessible" "Green"
        return $true
    }
    catch {
        Write-ColorOutput "❌ Protected Endpoint: Access denied" "Red"
        if ($Verbose) {
            Write-ColorOutput "   Error: $($_.Exception.Message)" "Red"
        }
        return $false
    }
}

# Main execution
Clear-Host
Write-ColorOutput "🚀 Aetheria API Endpoint Verification" "Blue"
Write-ColorOutput "Environment: $Environment" "Blue"
Write-ColorOutput "Base URL: $($currentConfig.baseUrl)" "Blue"
Write-ColorOutput "=" * 50 "Blue"
Write-Host ""

$healthResults = @{}
$overallHealth = $true

# Test individual service health endpoints
Write-ColorOutput "🔍 Testing Service Health Endpoints..." "Blue"
foreach ($service in $currentConfig.services.GetEnumerator()) {
    $serviceName = $service.Key
    $port = $service.Value
    
    if ($Environment -eq "local" -and $port) {
        $healthUrl = "$($currentConfig.baseUrl):$port/health"
    } elseif ($Environment -ne "local") {
        $healthUrl = "$($currentConfig.baseUrl)/$serviceName/health"
    } else {
        continue
    }
    
    $isHealthy = Test-ServiceHealth -ServiceName $serviceName -Url $healthUrl
    $healthResults[$serviceName] = $isHealthy
    if (-not $isHealthy) { $overallHealth = $false }
}

Write-Host ""

# Test CORS if not skipped
if (-not $SkipCORS) {
    Write-ColorOutput "🌐 Testing CORS Configuration..." "Blue"
    $authPort = $currentConfig.services.auth
    if ($Environment -eq "local" -and $authPort) {
        $corsUrl = "$($currentConfig.baseUrl):$authPort/api/auth/login"
    } else {
        $corsUrl = "$($currentConfig.baseUrl)/auth/api/auth/login"
    }
    
    $corsResult = Test-CORS -Url $corsUrl -Origin $currentConfig.uiOrigin
    if (-not $corsResult) { $overallHealth = $false }
    Write-Host ""
}

# Test authentication flow if not skipped
if (-not $SkipAuth -and $healthResults.auth) {
    Write-ColorOutput "🔐 Testing Authentication Flow..." "Blue"
    $authPort = $currentConfig.services.auth
    if ($Environment -eq "local" -and $authPort) {
        $authBaseUrl = "$($currentConfig.baseUrl):$authPort"
    } else {
        $authBaseUrl = "$($currentConfig.baseUrl)/auth"
    }
    
    $token = Test-Authentication -AuthUrl $authBaseUrl
    
    if ($token) {
        Write-ColorOutput "🛡️  Testing Protected Endpoint..." "Blue"
        $protectedUrl = "$authBaseUrl/api/auth/profile"
        $protectedResult = Test-ProtectedEndpoint -Url $protectedUrl -Token $token
        if (-not $protectedResult) { $overallHealth = $false }
    } else {
        $overallHealth = $false
    }
    Write-Host ""
}

# Summary
Write-ColorOutput "📊 Verification Summary" "Blue"
Write-ColorOutput "=" * 30 "Blue"

foreach ($result in $healthResults.GetEnumerator()) {
    $status = if ($result.Value) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($result.Value) { "Green" } else { "Red" }
    Write-ColorOutput "$($result.Key.ToUpper()): $status" $color
}

Write-Host ""

if ($overallHealth) {
    Write-ColorOutput "🎉 All systems are ready! APIs can accept requests from UI." "Green"
    Write-ColorOutput "🚀 You can now start your UI application." "Green"
} else {
    Write-ColorOutput "⚠️  Some issues detected. Please review the failed tests above." "Yellow"
    Write-ColorOutput "🔧 Fix the issues before connecting the UI." "Yellow"
}

Write-Host ""
Write-ColorOutput "💡 For detailed troubleshooting, run with -Verbose flag" "Cyan"
Write-ColorOutput "💡 To skip CORS testing, use -SkipCORS flag" "Cyan" 
Write-ColorOutput "💡 To skip auth testing, use -SkipAuth flag" "Cyan"

# Exit with appropriate code
if ($overallHealth) {
    exit 0
} else {
    exit 1
}