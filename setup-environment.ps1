# Environment Configuration Setup Script
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("development", "staging", "production")]
    [string]$Environment,
    
    [string]$Domain = "aetheria.com",
    
    [string]$Region = "ca-central-1"
)

Write-Host ">> Setting up $Environment environment configuration" -ForegroundColor Blue
Write-Host "Domain: $Domain" -ForegroundColor Cyan
Write-Host "Region: $Region" -ForegroundColor Cyan
Write-Host ""

$configPath = "config\$Environment-config.json"

if (-not (Test-Path "config")) {
    New-Item -ItemType Directory -Path "config" -Force | Out-Null
    Write-Host "[INFO] Created config directory" -ForegroundColor Green
}

switch ($Environment) {
    "development" {
        Write-Host "Development environment uses localhost - no additional setup needed" -ForegroundColor Green
        Write-Host "Ensure your services are running on ports 3001-3004" -ForegroundColor Yellow
        
        # Check if config exists
        if (Test-Path $configPath) {
            Write-Host "[OK] Development config already exists: $configPath" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Development config not found. Run script from project root." -ForegroundColor Yellow
        }
    }
    
    "staging" {
        Write-Host "Configuring staging environment..." -ForegroundColor Yellow
        
        # Prompt for staging values
        $albIp = Read-Host "Enter ALB IP address for staging"
        $cloudfrontDomain = Read-Host "Enter CloudFront domain for staging"
        $healthToken = Read-Host "Enter health check token for staging" -AsSecureString
        
        # Convert secure string
        $healthTokenPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($healthToken)
        )
        
        if (Test-Path $configPath) {
            $config = Get-Content $configPath | ConvertFrom-Json
            
            # Update DNS records
            foreach ($record in $config.dns.records) {
                if ($record.type -eq "A") {
                    $record.value = $albIp
                } elseif ($record.name -like "*staging*") {
                    $record.value = $cloudfrontDomain
                }
            }
            
            # Update security token
            $config.security.healthCheckToken = $healthTokenPlain
            
            # Save updated config
            $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
            Write-Host "[OK] Updated staging configuration" -ForegroundColor Green
        }
        
        # Set environment variables
        [Environment]::SetEnvironmentVariable("HEALTH_CHECK_TOKEN", $healthTokenPlain, "Process")
        [Environment]::SetEnvironmentVariable("ALB_IP_ADDRESS", $albIp, "Process")
        [Environment]::SetEnvironmentVariable("CLOUDFRONT_DOMAIN", $cloudfrontDomain, "Process")
        
        Write-Host "[OK] Set staging environment variables for this session" -ForegroundColor Green
    }
    
    "production" {
        Write-Host "Configuring production environment..." -ForegroundColor Red
        Write-Host "WARNING: This will set production configuration!" -ForegroundColor Red
        
        $confirm = Read-Host "Continue? (yes/no)"
        if ($confirm -ne "yes") {
            Write-Host "Aborted." -ForegroundColor Yellow
            exit 1
        }
        
        # Prompt for production values
        Write-Host "Enter production configuration values:" -ForegroundColor Yellow
        $prodAlbIp = Read-Host "ALB IP address"
        $prodCloudfrontIp = Read-Host "CloudFront IP address"  
        $distributionId = Read-Host "CloudFront Distribution ID"
        $webAclId = Read-Host "WAF Web ACL ID"
        $healthToken = Read-Host "Health check token" -AsSecureString
        
        # Convert secure string
        $healthTokenPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($healthToken)
        )
        
        if (Test-Path $configPath) {
            $config = Get-Content $configPath | ConvertFrom-Json
            
            # Update DNS records
            foreach ($record in $config.dns.records) {
                if ($record.type -eq "A" -and $record.name -notlike "*www*") {
                    if ($record.name -eq $Domain) {
                        $record.value = $prodCloudfrontIp
                    } else {
                        $record.value = $prodAlbIp
                    }
                }
            }
            
            # Update other settings
            $config.security.healthCheckToken = $healthTokenPlain
            $config.waf.web_acl_id = $webAclId
            $config.cdn.cloudfront.distribution_id = $distributionId
            
            # Save updated config
            $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
            Write-Host "[OK] Updated production configuration" -ForegroundColor Green
        }
        
        # Set environment variables (for this session only - DO NOT persist production tokens)
        [Environment]::SetEnvironmentVariable("HEALTH_CHECK_TOKEN", $healthTokenPlain, "Process")
        [Environment]::SetEnvironmentVariable("PROD_ALB_IP_ADDRESS", $prodAlbIp, "Process")
        [Environment]::SetEnvironmentVariable("PROD_CLOUDFRONT_IP", $prodCloudfrontIp, "Process")
        [Environment]::SetEnvironmentVariable("CLOUDFRONT_DISTRIBUTION_ID", $distributionId, "Process")
        [Environment]::SetEnvironmentVariable("WAF_WEB_ACL_ID", $webAclId, "Process")
        
        Write-Host "[OK] Set production environment variables for this session ONLY" -ForegroundColor Green
        Write-Host "[WARN] Production tokens should be stored securely (AWS Secrets Manager, etc.)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Magenta

switch ($Environment) {
    "development" {
        Write-Host "1. Start services: docker-compose up -d" -ForegroundColor White
        Write-Host "2. Run verification: .\scripts\verify-dev.ps1" -ForegroundColor White
        Write-Host "3. Start React app: cd web && npm start" -ForegroundColor White
    }
    
    "staging" {
        Write-Host "1. Deploy to staging environment" -ForegroundColor White
        Write-Host "2. Run verification: .\scripts\verify-prod.ps1 -Environment 'staging' -ConfigFile 'config\staging-config.json'" -ForegroundColor White
        Write-Host "3. Test staging application" -ForegroundColor White
    }
    
    "production" {
        Write-Host "1. Deploy to production environment" -ForegroundColor White
        Write-Host "2. Run verification: .\scripts\verify-prod.ps1 -Environment 'production' -ConfigFile 'config\prod-config.json'" -ForegroundColor White
        Write-Host "3. Monitor production metrics" -ForegroundColor White
        Write-Host "4. Set up automated monitoring" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "Configuration completed for $Environment environment!" -ForegroundColor Green