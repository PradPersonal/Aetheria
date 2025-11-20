#!/bin/bash
# API Endpoint Verification Script for Aetheria Platform
# Usage: ./verify-api.sh [local|staging|production] [--verbose] [--skip-cors] [--skip-auth]

set -e

# Default values
ENVIRONMENT="local"
VERBOSE=false
SKIP_CORS=false
SKIP_AUTH=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        local|staging|production)
            ENVIRONMENT="$1"
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --skip-cors)
            SKIP_CORS=true
            shift
            ;;
        --skip-auth)
            SKIP_AUTH=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [local|staging|production] [--verbose] [--skip-cors] [--skip-auth]"
            echo ""
            echo "Options:"
            echo "  --verbose     Show detailed output"
            echo "  --skip-cors   Skip CORS testing"
            echo "  --skip-auth   Skip authentication testing"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
case $ENVIRONMENT in
    local)
        BASE_URL="http://localhost"
        AUTH_PORT="3001"
        STREAMING_PORT="3002"
        COREAPI_PORT="3003"
        CHAT_PORT="3004"
        WEB_PORT="3000"
        UI_ORIGIN="http://localhost:3000"
        ;;
    staging)
        BASE_URL="https://api-staging.aetheria.example.com"
        UI_ORIGIN="https://staging.aetheria.example.com"
        ;;
    production)
        BASE_URL="https://api.aetheria.com"
        UI_ORIGIN="https://aetheria.com"
        ;;
esac

# Helper functions
log_info() {
    echo -e "${BLUE}$1${NC}"
}

log_success() {
    echo -e "${GREEN}$1${NC}"
}

log_warning() {
    echo -e "${YELLOW}$1${NC}"
}

log_error() {
    echo -e "${RED}$1${NC}"
}

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${CYAN}  $1${NC}"
    fi
}

# Test service health
test_service_health() {
    local service_name="$1"
    local url="$2"
    
    log_verbose "Testing: $url"
    
    if response=$(curl -s --max-time 10 "$url" 2>/dev/null); then
        if echo "$response" | jq -e '.status == "OK"' >/dev/null 2>&1; then
            log_success "✅ $service_name: HEALTHY"
            if [[ "$VERBOSE" == true ]]; then
                version=$(echo "$response" | jq -r '.version // "unknown"')
                database=$(echo "$response" | jq -r '.database // "unknown"')
                log_verbose "Version: $version"
                log_verbose "Database: $database"
            fi
            return 0
        elif echo "$response" | grep -q '"status":"OK"'; then
            # Fallback for systems without jq
            log_success "✅ $service_name: HEALTHY"
            return 0
        else
            log_warning "⚠️  $service_name: UNHEALTHY"
            log_verbose "Response: $response"
            return 1
        fi
    else
        log_error "❌ $service_name: UNREACHABLE"
        return 1
    fi
}

# Test CORS
test_cors() {
    local url="$1"
    local origin="$2"
    
    log_verbose "Testing CORS for: $url with origin: $origin"
    
    if cors_response=$(curl -s -I -X OPTIONS \
        -H "Origin: $origin" \
        -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: Content-Type,Authorization" \
        "$url" 2>/dev/null); then
        
        if echo "$cors_response" | grep -i "Access-Control-Allow-Origin" | grep -E "($origin|\*)" >/dev/null; then
            log_success "✅ CORS: Configured correctly"
            if [[ "$VERBOSE" == true ]]; then
                allow_origin=$(echo "$cors_response" | grep -i "Access-Control-Allow-Origin" | cut -d' ' -f2- | tr -d '\r')
                allow_methods=$(echo "$cors_response" | grep -i "Access-Control-Allow-Methods" | cut -d' ' -f2- | tr -d '\r')
                log_verbose "Allow-Origin: $allow_origin"
                log_verbose "Allow-Methods: $allow_methods"
            fi
            return 0
        else
            log_warning "⚠️  CORS: Origin not allowed"
            log_verbose "Expected: $origin"
            return 1
        fi
    else
        log_error "❌ CORS: Test failed"
        return 1
    fi
}

# Test authentication
test_authentication() {
    local auth_base_url="$1"
    local register_url="$auth_base_url/api/auth/register"
    local login_url="$auth_base_url/api/auth/login"
    
    # Generate random test user
    local random_id=$(date +%s%N | cut -c1-10)
    local test_user="{
        \"username\": \"testuser_$random_id\",
        \"email\": \"test_$random_id@example.com\",
        \"password\": \"TestPass123!\"
    }"
    
    log_verbose "Testing registration endpoint..."
    
    if register_response=$(curl -s -X POST "$register_url" \
        -H "Content-Type: application/json" \
        -d "$test_user" \
        --max-time 10 2>/dev/null); then
        
        log_verbose "Testing login endpoint..."
        
        local login_data="{
            \"email\": \"test_$random_id@example.com\",
            \"password\": \"TestPass123!\"
        }"
        
        if login_response=$(curl -s -X POST "$login_url" \
            -H "Content-Type: application/json" \
            -d "$login_data" \
            --max-time 10 2>/dev/null); then
            
            if echo "$login_response" | grep -q '"token"'; then
                log_success "✅ Authentication: Working correctly"
                if command -v jq >/dev/null 2>&1; then
                    token=$(echo "$login_response" | jq -r '.token')
                else
                    token=$(echo "$login_response" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
                fi
                if [[ "$VERBOSE" == true && -n "$token" ]]; then
                    log_verbose "Token received: ${token:0:20}..."
                fi
                echo "$token"
                return 0
            else
                log_warning "⚠️  Authentication: No token received"
                log_verbose "Response: $login_response"
                return 1
            fi
        else
            log_error "❌ Authentication: Login failed"
            return 1
        fi
    else
        log_error "❌ Authentication: Registration failed"
        return 1
    fi
}

# Test protected endpoint
test_protected_endpoint() {
    local url="$1"
    local token="$2"
    
    if curl -s -H "Authorization: Bearer $token" "$url" --max-time 10 >/dev/null 2>&1; then
        log_success "✅ Protected Endpoint: Accessible"
        return 0
    else
        log_error "❌ Protected Endpoint: Access denied"
        return 1
    fi
}

# Main execution
clear
log_info "🚀 Aetheria API Endpoint Verification"
log_info "Environment: $ENVIRONMENT"
log_info "Base URL: $BASE_URL"
log_info "=================================================="
echo ""

# Track overall health
OVERALL_HEALTH=true
declare -A HEALTH_RESULTS

# Test service health endpoints
log_info "🔍 Testing Service Health Endpoints..."

if [[ "$ENVIRONMENT" == "local" ]]; then
    services=(
        "Auth Service:$BASE_URL:$AUTH_PORT/health"
        "Streaming Service:$BASE_URL:$STREAMING_PORT/health"
        "Core API Service:$BASE_URL:$COREAPI_PORT/health"
        "Chat Service:$BASE_URL:$CHAT_PORT/health"
    )
else
    services=(
        "Auth Service:$BASE_URL/auth/health"
        "Streaming Service:$BASE_URL/streaming/health"
        "Core API Service:$BASE_URL/coreapi/health"
        "Chat Service:$BASE_URL/chat/health"
    )
fi

for service in "${services[@]}"; do
    name=$(echo "$service" | cut -d: -f1)
    url=$(echo "$service" | cut -d: -f2-)
    
    if test_service_health "$name" "$url"; then
        HEALTH_RESULTS["$name"]=true
    else
        HEALTH_RESULTS["$name"]=false
        OVERALL_HEALTH=false
    fi
done

echo ""

# Test CORS
if [[ "$SKIP_CORS" != true ]]; then
    log_info "🌐 Testing CORS Configuration..."
    if [[ "$ENVIRONMENT" == "local" ]]; then
        cors_url="$BASE_URL:$AUTH_PORT/api/auth/login"
    else
        cors_url="$BASE_URL/auth/api/auth/login"
    fi
    
    if ! test_cors "$cors_url" "$UI_ORIGIN"; then
        OVERALL_HEALTH=false
    fi
    echo ""
fi

# Test authentication
if [[ "$SKIP_AUTH" != true && "${HEALTH_RESULTS['Auth Service']}" == true ]]; then
    log_info "🔐 Testing Authentication Flow..."
    if [[ "$ENVIRONMENT" == "local" ]]; then
        auth_base_url="$BASE_URL:$AUTH_PORT"
    else
        auth_base_url="$BASE_URL/auth"
    fi
    
    if token=$(test_authentication "$auth_base_url"); then
        if [[ -n "$token" ]]; then
            log_info "🛡️  Testing Protected Endpoint..."
            protected_url="$auth_base_url/api/auth/profile"
            if ! test_protected_endpoint "$protected_url" "$token"; then
                OVERALL_HEALTH=false
            fi
        fi
    else
        OVERALL_HEALTH=false
    fi
    echo ""
fi

# Summary
log_info "📊 Verification Summary"
log_info "=============================="

for service in "${!HEALTH_RESULTS[@]}"; do
    if [[ "${HEALTH_RESULTS[$service]}" == true ]]; then
        log_success "${service^^}: ✅ PASS"
    else
        log_error "${service^^}: ❌ FAIL"
    fi
done

echo ""

if [[ "$OVERALL_HEALTH" == true ]]; then
    log_success "🎉 All systems are ready! APIs can accept requests from UI."
    log_success "🚀 You can now start your UI application."
    exit 0
else
    log_warning "⚠️  Some issues detected. Please review the failed tests above."
    log_warning "🔧 Fix the issues before connecting the UI."
    exit 1
fi