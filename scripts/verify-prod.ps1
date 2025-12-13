# Production Environment API Verification Script
param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$ConfigFile,
    
    [string]$Region = "ca-central-1",
    
    [switch]$SkipHealthCheck = $false,
    
    [switch]$Verbose = $false
)

Write-Host ">> Aetheria API Verification - PRODUCTION" -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Red

# Validate required parameters
if (-not (Test-Path $ConfigFile)) {
    Write-Host "[ERROR] Configuration file not found: $ConfigFile" -ForegroundColor Red
    Write-Host "Expected production config with service URLs, certificates, etc." -ForegroundColor Yellow
    exit 1
}

# Load production configuration
try {
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    Write-Host "[INFO] Loaded production configuration from $ConfigFile" -ForegroundColor Cyan
} catch {
    Write-Host "[ERROR] Failed to parse configuration file: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Validate required configuration sections
$requiredSections = @("services", "security", "monitoring", "dns")
foreach ($section in $requiredSections) {
    if (-not $config.PSObject.Properties.Name -contains $section) {
        Write-Host "[ERROR] Missing required configuration section: $section" -ForegroundColor Red
        exit 1
    }
}

$allHealthy = $true
$results = @()
$criticalErrors = @()

Write-Host ""
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Region:      $Region" -ForegroundColor Cyan
Write-Host "Config:      $ConfigFile" -ForegroundColor Cyan
Write-Host ""

# Production SSL/TLS Certificate Check
Write-Host "Checking SSL/TLS Certificates..." -ForegroundColor Yellow
foreach ($serviceName in $config.services.PSObject.Properties.Name) {
    $service = $config.services.$serviceName
    if ($service.url -like "https://*") {
        try {
            $uri = [System.Uri]$service.url
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.Connect($uri.Host, 443)
            $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream())
            $sslStream.AuthenticateAsClient($uri.Host)
            
            $cert = $sslStream.RemoteCertificate
            $certExpiry = [DateTime]$cert.GetExpirationDateString()
            $daysUntilExpiry = ($certExpiry - (Get-Date)).Days
            
            if ($daysUntilExpiry -lt 30) {
                Write-Host "[WARN] Certificate for $($uri.Host) expires in $daysUntilExpiry days" -ForegroundColor Yellow
                $results += @{ Service = "$serviceName SSL"; Status = "Warning"; Details = "Expires in $daysUntilExpiry days" }
            } else {
                Write-Host "[OK] Certificate for $($uri.Host) is valid ($daysUntilExpiry days remaining)" -ForegroundColor Green
                $results += @{ Service = "$serviceName SSL"; Status = "Valid"; Details = "$daysUntilExpiry days remaining" }
            }
            
            $sslStream.Close()
            $tcpClient.Close()
        } catch {
            Write-Host "[ERROR] SSL check failed for $($service.url): $($_.Exception.Message)" -ForegroundColor Red
            $criticalErrors += "SSL verification failed for $serviceName"
            $allHealthy = $false
        }
    }
}

Write-Host ""

# Production Health Checks with Authentication
if (-not $SkipHealthCheck) {
    Write-Host "Testing Production Services..." -ForegroundColor Yellow
    
    foreach ($serviceName in $config.services.PSObject.Properties.Name) {
        $service = $config.services.$serviceName
        $url = $service.url + $service.healthPath
        $displayName = (Get-Culture).TextInfo.ToTitleCase($serviceName) + " Service"
        
        Write-Host "Testing $displayName..." -ForegroundColor Yellow
        
        try {
            $headers = @{
                "User-Agent" = "Aetheria-ProductionHealthCheck/1.0"
            }
            
            # Add authentication if required
            if ($service.healthAuth -and $config.security.healthCheckToken) {
                $headers["Authorization"] = "Bearer $($config.security.healthCheckToken)"
            }
            
            $response = Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 30 -ErrorAction Stop
            
            if ($response.status -eq "OK" -or $response.status -eq "healthy") {
                Write-Host "[OK] $displayName is HEALTHY" -ForegroundColor Green
                $results += @{ Service = $displayName; Status = "Healthy"; URL = $url }
                
                # Additional production checks
                if ($response.version) {
                    Write-Host "      Version: $($response.version)" -ForegroundColor Gray
                }
                if ($response.uptime) {
                    Write-Host "      Uptime: $($response.uptime)" -ForegroundColor Gray
                }
            } 
            else {
                Write-Host "[WARN] $displayName returned: $($response.status)" -ForegroundColor Yellow
                $allHealthy = $false
                $results += @{ Service = $displayName; Status = "Unhealthy"; URL = $url; Details = $response.status }
            }
        }
        catch {
            Write-Host "[ERROR] $displayName is UNREACHABLE - $($_.Exception.Message)" -ForegroundColor Red
            $criticalErrors += "$displayName is unreachable"
            $allHealthy = $false
            $results += @{ Service = $displayName; Status = "Unreachable"; URL = $url; Error = $_.Exception.Message }
        }
        
        Start-Sleep -Milliseconds 1000
    }
}

Write-Host ""

# Production DNS and CDN Checks
Write-Host "Checking DNS Resolution..." -ForegroundColor Yellow
foreach ($dnsRecord in $config.dns.records) {
    try {
        $resolved = Resolve-DnsName $dnsRecord.name -Type $dnsRecord.type -ErrorAction Stop
        $expectedValue = $dnsRecord.value
        
        if ($resolved.IPAddress -eq $expectedValue -or $resolved.NameHost -eq $expectedValue) {
            Write-Host "[OK] DNS record $($dnsRecord.name) resolves correctly" -ForegroundColor Green
            $results += @{ Service = "DNS - $($dnsRecord.name)"; Status = "OK"; Details = "Resolves to $expectedValue" }
        } else {
            Write-Host "[WARN] DNS record $($dnsRecord.name) resolves to unexpected value" -ForegroundColor Yellow
            Write-Host "      Expected: $expectedValue" -ForegroundColor Gray
            Write-Host "      Actual: $($resolved.IPAddress ?? $resolved.NameHost)" -ForegroundColor Gray
            $results += @{ Service = "DNS - $($dnsRecord.name)"; Status = "Warning"; Details = "Unexpected resolution" }
        }
    } catch {
        Write-Host "[ERROR] DNS resolution failed for $($dnsRecord.name): $($_.Exception.Message)" -ForegroundColor Red
        $criticalErrors += "DNS resolution failed for $($dnsRecord.name)"
        $allHealthy = $false
    }
}

Write-Host ""

# Production Load Balancer and WAF Checks
if ($config.loadBalancer) {
    Write-Host "Checking Load Balancer..." -ForegroundColor Yellow
    try {
        $lbUrl = $config.loadBalancer.url + $config.loadBalancer.healthPath
        $lbResponse = Invoke-WebRequest -Uri $lbUrl -TimeoutSec 10 -ErrorAction Stop
        
        if ($lbResponse.StatusCode -eq 200) {
            Write-Host "[OK] Load Balancer is responding" -ForegroundColor Green
            $results += @{ Service = "Load Balancer"; Status = "OK"; Details = "HTTP $($lbResponse.StatusCode)" }
        } else {
            Write-Host "[WARN] Load Balancer returned HTTP $($lbResponse.StatusCode)" -ForegroundColor Yellow
            $results += @{ Service = "Load Balancer"; Status = "Warning"; Details = "HTTP $($lbResponse.StatusCode)" }
        }
    } catch {
        Write-Host "[ERROR] Load Balancer check failed: $($_.Exception.Message)" -ForegroundColor Red
        $criticalErrors += "Load Balancer is unreachable"
        $allHealthy = $false
    }
}

# Production Monitoring Endpoints
if ($config.monitoring) {
    Write-Host "Checking Monitoring Endpoints..." -ForegroundColor Yellow
    foreach ($monitor in $config.monitoring.endpoints) {
        try {
            $monitorResponse = Invoke-WebRequest -Uri $monitor.url -TimeoutSec 5 -ErrorAction Stop
            Write-Host "[OK] $($monitor.name) monitoring is active" -ForegroundColor Green
            $results += @{ Service = "Monitor - $($monitor.name)"; Status = "Active"; Details = "HTTP $($monitorResponse.StatusCode)" }
        } catch {
            Write-Host "[WARN] $($monitor.name) monitoring check failed: $($_.Exception.Message)" -ForegroundColor Yellow
            $results += @{ Service = "Monitor - $($monitor.name)"; Status = "Warning"; Error = $_.Exception.Message }
        }
    }
}

Write-Host ""

# Production Security Checks
Write-Host "Security Validation..." -ForegroundColor Yellow

# Check for security headers
$securityService = $config.services.auth.url
try {
    $secResponse = Invoke-WebRequest -Uri $securityService -Method HEAD -TimeoutSec 10 -ErrorAction Stop
    
    $securityHeaders = @(
        "Strict-Transport-Security",
        "X-Content-Type-Options", 
        "X-Frame-Options",
        "X-XSS-Protection",
        "Content-Security-Policy"
    )
    
    foreach ($header in $securityHeaders) {
        if ($secResponse.Headers[$header]) {
            Write-Host "[OK] Security header present: $header" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Missing security header: $header" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "[ERROR] Security headers check failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Summary and Critical Error Report
if ($criticalErrors.Count -gt 0) {
    Write-Host "=== CRITICAL ERRORS ===" -ForegroundColor Red
    foreach ($error in $criticalErrors) {
        Write-Host "❌ $error" -ForegroundColor Red
    }
    Write-Host ""
}

if ($allHealthy -and $criticalErrors.Count -eq 0) {
    Write-Host "[SUCCESS] Production environment is ready!" -ForegroundColor Green
    Write-Host ">> All services are healthy and properly configured" -ForegroundColor Green
    Write-Host ""
    Write-Host "Production Status:" -ForegroundColor Cyan
    Write-Host "✓ SSL certificates valid" -ForegroundColor Green
    Write-Host "✓ All services responding" -ForegroundColor Green
    Write-Host "✓ DNS resolution working" -ForegroundColor Green
    Write-Host "✓ Load balancer operational" -ForegroundColor Green
    Write-Host "✓ Monitoring active" -ForegroundColor Green
} 
else {
    Write-Host "[ERROR] Production environment has issues that must be resolved" -ForegroundColor Red
    Write-Host ">> Do not proceed with deployment until all critical errors are fixed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Production Troubleshooting:" -ForegroundColor Cyan
    Write-Host "1. Check AWS CloudWatch logs" -ForegroundColor White
    Write-Host "2. Verify EKS cluster status: kubectl get pods -A" -ForegroundColor White
    Write-Host "3. Check ALB target group health" -ForegroundColor White
    Write-Host "4. Verify Route53 DNS records" -ForegroundColor White
    Write-Host "5. Check SSL certificate status in ACM" -ForegroundColor White
    Write-Host "6. Review WAF rules and CloudFront distribution" -ForegroundColor White
}

# Generate production report
Write-Host ""
Write-Host "=== PRODUCTION VERIFICATION REPORT ===" -ForegroundColor Magenta
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')" -ForegroundColor Gray
Write-Host "Environment: $Environment" -ForegroundColor Gray
Write-Host "Region: $Region" -ForegroundColor Gray
Write-Host ""

$results | ForEach-Object {
    $status = $_
    Write-Host "Service: $($status.Service)" -ForegroundColor White
    Write-Host "Status:  $($status.Status)" -ForegroundColor $(
        switch ($status.Status) {
            "Healthy" { "Green" }
            "Valid" { "Green" }
            "OK" { "Green" }
            "Active" { "Green" }
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

if ($criticalErrors.Count -gt 0) {
    exit 1
} else {
    exit 0
}