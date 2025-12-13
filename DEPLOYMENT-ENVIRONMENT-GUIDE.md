# Environment-Specific API Verification Guide

## Overview

The verification scripts need different configurations and approaches for each environment. This guide covers the necessary changes and configurations for Development, Staging, and Production environments.

## 🏗️ **Environment Structure**

```
scripts/
├── verify-dev.ps1          # Development verification
├── verify-prod.ps1         # Production verification  
└── quick-verify.ps1        # Local development (simple)

config/
├── dev-config.json         # Development configuration
├── staging-config.json     # Staging configuration
└── prod-config.json        # Production configuration
```

## 🔧 **Development Environment**

### **Usage:**
```powershell
# Simple local verification (current script)
.\quick-verify.ps1

# Advanced development verification
.\scripts\verify-dev.ps1 -Environment "development" -ConfigFile "config\dev-config.json"
```

### **Features:**
- Tests localhost services (3001-3004)
- Checks .env files
- Docker container status
- CORS configuration for localhost
- Detailed error reporting
- Development-specific troubleshooting

### **Requirements:**
- Docker containers running locally
- Environment files present
- Localhost ports available

---

## 🚀 **Staging Environment**

### **Usage:**
```powershell
.\scripts\verify-prod.ps1 -Environment "staging" -ConfigFile "config\staging-config.json" -Region "ca-central-1"
```

### **Additional Checks:**
- SSL certificate validation
- DNS resolution (staging domains)
- Load balancer health
- Security headers verification
- Monitoring endpoint checks

### **Configuration Updates Needed:**

1. **Replace placeholder values in `config/staging-config.json`:**
```json
{
  "security": {
    "healthCheckToken": "actual-staging-token-here"
  },
  "dns": {
    "records": [
      {
        "value": "actual-alb-ip-here"
      }
    ]
  }
}
```

2. **Set environment variables:**
```powershell
$env:HEALTH_CHECK_TOKEN = "your-staging-token"
$env:ALB_IP_ADDRESS = "your-alb-ip"
$env:CLOUDFRONT_DOMAIN = "your-cloudfront-domain"
```

---

## 🏭 **Production Environment**

### **Usage:**
```powershell
.\scripts\verify-prod.ps1 -Environment "production" -ConfigFile "config\prod-config.json" -Region "ca-central-1" -Verbose
```

### **Critical Production Checks:**
- ✅ SSL certificates (30+ days validity)
- ✅ All security headers present
- ✅ DNS resolution to correct IPs
- ✅ Load balancer target groups healthy
- ✅ WAF rules active
- ✅ CloudFront distribution operational
- ✅ Monitoring endpoints responding
- ✅ SLA compliance checks

### **Configuration Updates Needed:**

1. **Replace ALL placeholder values in `config/prod-config.json`:**
```json
{
  "security": {
    "healthCheckToken": "${PROD_HEALTH_TOKEN}"
  },
  "dns": {
    "records": [
      {
        "name": "auth.aetheria.com",
        "value": "52.60.123.456"  // Actual ALB IP
      }
    ]
  },
  "waf": {
    "web_acl_id": "actual-waf-acl-id"
  }
}
```

2. **Set production environment variables:**
```powershell
$env:HEALTH_CHECK_TOKEN = "secure-production-token"
$env:PROD_ALB_IP_ADDRESS = "production-alb-ip"
$env:PROD_CLOUDFRONT_IP = "production-cf-ip"
$env:CLOUDFRONT_DISTRIBUTION_ID = "actual-distribution-id"
```

---

## 🔐 **Security Considerations**

### **Development:**
- Uses HTTP (localhost)
- No authentication tokens
- CORS allows localhost origins
- Relaxed timeouts

### **Staging:**
- Uses HTTPS with valid certificates
- Requires health check authentication
- Stricter CORS policies
- Medium timeout values

### **Production:**
- Enforces HTTPS everywhere
- Requires authentication for all health checks
- Strict security headers validation
- WAF protection verification
- Monitoring and alerting checks
- SLA compliance validation

---

## 🛠️ **Required Changes by Environment**

### **URLs and Endpoints:**
```powershell
# Development
$authUrl = "http://localhost:3001"

# Staging  
$authUrl = "https://auth-staging.aetheria.com"

# Production
$authUrl = "https://auth.aetheria.com"
```

### **Authentication:**
```powershell
# Development - No auth
$headers = @{ "Content-Type" = "application/json" }

# Production - With auth
$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer $healthToken"
}
```

### **Timeouts:**
```powershell
# Development - Fast fail
-TimeoutSec 5

# Production - Allow for network latency
-TimeoutSec 30
```

### **Certificate Checks:**
```powershell
# Development - Skip SSL
# No certificate validation

# Production - Strict SSL
$sslStream.AuthenticateAsClient($uri.Host)
$cert = $sslStream.RemoteCertificate
```

---

## 📋 **Deployment Checklist**

### **Before Deploying to Staging:**
- [ ] Update `config/staging-config.json` with actual values
- [ ] Set staging environment variables
- [ ] Test staging verification script
- [ ] Verify SSL certificates are deployed
- [ ] Confirm DNS records are set
- [ ] Test health check authentication

### **Before Deploying to Production:**
- [ ] Update `config/prod-config.json` with actual values
- [ ] Set production environment variables (securely)
- [ ] Test production verification script in staging
- [ ] Verify all security headers are configured
- [ ] Confirm WAF rules are active
- [ ] Test monitoring endpoints
- [ ] Validate SLA thresholds
- [ ] Schedule verification in CI/CD pipeline

---

## 🔄 **CI/CD Integration**

### **GitHub Actions Example:**
```yaml
# .github/workflows/verify-deployment.yml
name: Verify Deployment
on:
  deployment_status:

jobs:
  verify:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Verify Staging
        if: github.event.deployment.environment == 'staging'
        run: |
          .\scripts\verify-prod.ps1 -Environment "staging" -ConfigFile "config\staging-config.json"
        env:
          HEALTH_CHECK_TOKEN: ${{ secrets.STAGING_HEALTH_TOKEN }}
          
      - name: Verify Production  
        if: github.event.deployment.environment == 'production'
        run: |
          .\scripts\verify-prod.ps1 -Environment "production" -ConfigFile "config\prod-config.json"
        env:
          HEALTH_CHECK_TOKEN: ${{ secrets.PROD_HEALTH_TOKEN }}
```

### **AWS CodePipeline Integration:**
```json
{
  "Name": "VerifyDeployment",
  "ActionTypeId": {
    "Category": "Invoke",
    "Owner": "AWS", 
    "Provider": "Lambda"
  },
  "Configuration": {
    "FunctionName": "aetheria-deployment-verifier"
  }
}
```

---

## 🚨 **Troubleshooting by Environment**

### **Development Issues:**
```powershell
# Check containers
docker-compose ps
docker-compose logs auth-service

# Check ports
netstat -an | findstr :3001

# Restart services
docker-compose restart
```

### **Staging Issues:**
```powershell
# Check EKS pods
kubectl get pods -n aetheria-staging

# Check ALB targets
aws elbv2 describe-target-health --target-group-arn $STAGING_TG_ARN

# Check Route53
aws route53 list-resource-record-sets --hosted-zone-id $STAGING_ZONE_ID
```

### **Production Issues:**
```powershell
# Check EKS cluster
kubectl get pods -n aetheria-production
kubectl describe pod $POD_NAME -n aetheria-production

# Check ALB health
aws elbv2 describe-load-balancers --load-balancer-arns $PROD_ALB_ARN
aws elbv2 describe-target-health --target-group-arn $PROD_TG_ARN

# Check CloudFront
aws cloudfront get-distribution --id $DISTRIBUTION_ID

# Check WAF
aws wafv2 get-web-acl --scope CLOUDFRONT --id $WEB_ACL_ID

# Check CloudWatch
aws logs describe-log-groups --log-group-name-prefix "/aetheria/production"
```

---

## 📊 **Monitoring and Alerting**

### **Production Monitoring Setup:**
```powershell
# Set up CloudWatch alarms
aws cloudwatch put-metric-alarm \
  --alarm-name "Aetheria-API-Health" \
  --alarm-description "API health check failure" \
  --metric-name "HealthCheckFailure" \
  --namespace "Aetheria/Production" \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold

# Set up SNS notifications
aws sns create-topic --name "aetheria-production-alerts"
```

### **Automated Verification Schedule:**
```yaml
# CloudWatch Events Rule
ScheduleExpression: "rate(5 minutes)"
Target: 
  - Arn: "arn:aws:lambda:ca-central-1:account:function:aetheria-verify"
    Input: |
      {
        "environment": "production",
        "configFile": "config/prod-config.json"
      }
```

This comprehensive setup ensures your verification scripts work correctly across all environments with appropriate security, monitoring, and troubleshooting capabilities.