# UI-to-API Integration Verification Guide

This guide helps you verify that your React UI project is correctly configured to communicate with your API microservices.

## 1. Environment Configuration Verification

### Check React Environment Variables
First, verify that your React app has the correct API endpoints configured.

#### Check `.env` files in the web directory:
```bash
# Navigate to web directory
cd web

# Check for environment files
ls -la | grep env
# Should show: .env, .env.local, .env.development, etc.

# View environment configuration
cat .env
cat .env.development  # if exists
cat .env.local       # if exists
```

#### Expected Environment Variables:
```bash
# .env or .env.development
REACT_APP_API_BASE_URL=http://localhost:3001
REACT_APP_AUTH_SERVICE_URL=http://localhost:3001
REACT_APP_STREAMING_SERVICE_URL=http://localhost:3002
REACT_APP_CORE_API_SERVICE_URL=http://localhost:3003
REACT_APP_CHAT_SERVICE_URL=http://localhost:3004

# Optional: API timeouts and configurations
REACT_APP_API_TIMEOUT=10000
REACT_APP_ENABLE_API_LOGGING=true
```

### Verify Environment Variables are Loaded
```bash
# Start React app in development mode
npm start

# In another terminal, check if env vars are accessible
# (Environment variables should be prefixed with REACT_APP_)
```

## 2. API Service Configuration Verification

### Check `src/services/api.js` Configuration
```javascript
// Expected API service configuration structure:

const API_BASE_URLS = {
  auth: process.env.REACT_APP_AUTH_SERVICE_URL || 'http://localhost:3001',
  streaming: process.env.REACT_APP_STREAMING_SERVICE_URL || 'http://localhost:3002',
  coreApi: process.env.REACT_APP_CORE_API_SERVICE_URL || 'http://localhost:3003',
  chat: process.env.REACT_APP_CHAT_SERVICE_URL || 'http://localhost:3004'
};

// Check for proper axios configuration
const apiClient = axios.create({
  baseURL: API_BASE_URLS.auth,
  timeout: parseInt(process.env.REACT_APP_API_TIMEOUT) || 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Verify interceptors for authentication
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('authToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);
```

### Check `src/services/auth.service.js`
```javascript
// Verify authentication service endpoints
const authService = {
  login: (credentials) => 
    apiClient.post('/api/auth/login', credentials),
  register: (userData) => 
    apiClient.post('/api/auth/register', userData),
  logout: () => 
    apiClient.post('/api/auth/logout'),
  getProfile: () => 
    apiClient.get('/api/auth/profile'),
  refreshToken: () => 
    apiClient.post('/api/auth/refresh')
};
```

## 3. Network Connectivity Tests

### Test 1: Browser Console API Calls
Open your React app in the browser and test API calls from the console:

```javascript
// Open browser console (F12) while on localhost:3000

// Test 1: Basic health check
fetch('http://localhost:3001/health')
  .then(response => response.json())
  .then(data => console.log('✅ Health Check:', data))
  .catch(error => console.error('❌ Health Check Failed:', error));

// Test 2: Authentication endpoint
fetch('http://localhost:3001/api/auth/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    email: 'test@example.com',
    password: 'testpass'
  })
})
.then(response => response.json())
.then(data => console.log('✅ Auth Test:', data))
.catch(error => console.error('❌ Auth Test Failed:', error));

// Test 3: CORS verification
fetch('http://localhost:3002/api/videos', {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json'
  }
})
.then(response => {
  console.log('✅ CORS Headers:', response.headers);
  return response.json();
})
.then(data => console.log('✅ Videos API:', data))
.catch(error => console.error('❌ Videos API Failed:', error));
```

### Test 2: Network Tab Verification
1. Open Developer Tools (F12)
2. Go to **Network** tab
3. Refresh your React app
4. Try to login or perform API calls
5. Check the network requests:

**Expected Results:**
- ✅ Status: 200 OK (or appropriate status)
- ✅ Response Type: application/json
- ✅ CORS Headers present
- ✅ No CORS errors in console

**Common Issues:**
- ❌ Status: 0 (CORS blocked)
- ❌ ERR_NETWORK (API not reachable)
- ❌ 404 Not Found (wrong endpoint)
- ❌ 500 Internal Server Error (API issue)

## 4. Authentication Flow Verification

### Test Complete Authentication Flow
Create a test component to verify the full auth flow:

```javascript
// Create: src/components/APITest.js
import React, { useState } from 'react';
import authService from '../services/auth.service';

const APITest = () => {
  const [results, setResults] = useState({});
  const [loading, setLoading] = useState(false);

  const testAPI = async () => {
    setLoading(true);
    const testResults = {};

    try {
      // Test 1: Health check
      const healthResponse = await fetch('http://localhost:3001/health');
      const healthData = await healthResponse.json();
      testResults.health = healthData.status === 'OK' ? '✅ Pass' : '❌ Fail';
    } catch (error) {
      testResults.health = `❌ Error: ${error.message}`;
    }

    try {
      // Test 2: Registration
      const registerData = {
        username: `testuser_${Date.now()}`,
        email: `test_${Date.now()}@example.com`,
        password: 'TestPass123!'
      };
      
      const registerResponse = await authService.register(registerData);
      testResults.register = registerResponse.data ? '✅ Pass' : '❌ Fail';

      // Test 3: Login
      const loginResponse = await authService.login({
        email: registerData.email,
        password: registerData.password
      });
      
      const token = loginResponse.data?.token;
      testResults.login = token ? '✅ Pass' : '❌ Fail';

      if (token) {
        // Store token
        localStorage.setItem('authToken', token);

        // Test 4: Protected endpoint
        const profileResponse = await authService.getProfile();
        testResults.protectedEndpoint = profileResponse.data ? '✅ Pass' : '❌ Fail';
      }
    } catch (error) {
      testResults.authFlow = `❌ Error: ${error.message}`;
    }

    setResults(testResults);
    setLoading(false);
  };

  return (
    <div style={{ padding: '20px', fontFamily: 'monospace' }}>
      <h3>🔧 API Integration Test</h3>
      
      <button onClick={testAPI} disabled={loading}>
        {loading ? 'Testing...' : 'Run API Tests'}
      </button>

      <div style={{ marginTop: '20px' }}>
        <h4>Test Results:</h4>
        {Object.entries(results).map(([test, result]) => (
          <div key={test} style={{ margin: '5px 0' }}>
            <strong>{test}:</strong> {result}
          </div>
        ))}
      </div>
    </div>
  );
};

export default APITest;
```

### Add Test Component to Your App
```javascript
// In src/App.js, temporarily add the test component
import APITest from './components/APITest';

function App() {
  return (
    <div className="App">
      {/* Your existing app content */}
      
      {/* Temporarily add for testing */}
      {process.env.NODE_ENV === 'development' && <APITest />}
    </div>
  );
}
```

## 5. Proxy Configuration Verification

### Check if API Proxy is Configured
For development, you might have a proxy configured to avoid CORS issues:

#### Method 1: package.json proxy
```json
// In web/package.json
{
  "name": "aetheria-web",
  "proxy": "http://localhost:3001",
  // ... other configurations
}
```

#### Method 2: setupProxy.js
```javascript
// Check for web/src/setupProxy.js
const { createProxyMiddleware } = require('http-proxy-middleware');

module.exports = function(app) {
  app.use(
    '/api',
    createProxyMiddleware({
      target: 'http://localhost:3001',
      changeOrigin: true,
      pathRewrite: {
        '^/api': '/api', // Remove this line if not needed
      },
    })
  );
};
```

### Test Proxy Configuration
If using proxy, test with relative URLs:
```javascript
// Instead of: fetch('http://localhost:3001/api/auth/login', ...)
// Use: fetch('/api/auth/login', ...)

fetch('/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email: 'test@test.com', password: 'test' })
})
.then(response => response.json())
.then(data => console.log('Proxy test:', data));
```

## 6. Error Handling Verification

### Check Error Boundary Implementation
Verify that your app handles API errors gracefully:

```javascript
// Check src/components/ErrorBoundary.js or similar
class APIErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error('API Error caught by boundary:', error, errorInfo);
    // Log to error reporting service
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="error-boundary">
          <h3>🚨 API Connection Error</h3>
          <p>Unable to connect to the API services.</p>
          <button onClick={() => window.location.reload()}>
            Retry
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
```

### Check API Error Interceptors
```javascript
// Verify error handling in API service
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Handle unauthorized - redirect to login
      localStorage.removeItem('authToken');
      window.location.href = '/login';
    }
    
    if (error.response?.status >= 500) {
      // Handle server errors
      console.error('API Server Error:', error);
    }
    
    if (error.code === 'NETWORK_ERROR') {
      // Handle network issues
      console.error('Network Error - API unreachable');
    }
    
    return Promise.reject(error);
  }
);
```

## 7. Development vs Production Configuration

### Environment-Specific API URLs
```javascript
// Check environment-specific configurations
const getApiBaseUrl = () => {
  switch (process.env.NODE_ENV) {
    case 'development':
      return process.env.REACT_APP_API_BASE_URL || 'http://localhost:3001';
    case 'staging':
      return 'https://api-staging.aetheria.example.com';
    case 'production':
      return 'https://api.aetheria.com';
    default:
      return 'http://localhost:3001';
  }
};
```

## 8. Automated UI-API Integration Test

### Create Automated Test Script
```javascript
// Create: src/utils/apiIntegrationTest.js
const runAPIIntegrationTests = async () => {
  const tests = [];
  
  // Test 1: Environment variables
  tests.push({
    name: 'Environment Variables',
    test: () => {
      const requiredEnvs = ['REACT_APP_AUTH_SERVICE_URL'];
      return requiredEnvs.every(env => process.env[env]);
    }
  });
  
  // Test 2: API connectivity
  tests.push({
    name: 'API Connectivity',
    test: async () => {
      try {
        const response = await fetch(`${process.env.REACT_APP_AUTH_SERVICE_URL}/health`);
        const data = await response.json();
        return data.status === 'OK';
      } catch {
        return false;
      }
    }
  });
  
  // Test 3: CORS configuration
  tests.push({
    name: 'CORS Configuration',
    test: async () => {
      try {
        const response = await fetch(`${process.env.REACT_APP_AUTH_SERVICE_URL}/api/auth/login`, {
          method: 'OPTIONS',
          headers: {
            'Origin': window.location.origin,
            'Access-Control-Request-Method': 'POST'
          }
        });
        return response.ok;
      } catch {
        return false;
      }
    }
  });
  
  // Run all tests
  const results = [];
  for (const test of tests) {
    try {
      const result = await test.test();
      results.push({ name: test.name, status: result ? 'PASS' : 'FAIL' });
    } catch (error) {
      results.push({ name: test.name, status: 'ERROR', error: error.message });
    }
  }
  
  return results;
};

export default runAPIIntegrationTests;
```

## 9. PowerShell UI Verification Script

```powershell
# Create: verify-ui-api.ps1
Write-Host "🌐 UI-to-API Integration Verification" -ForegroundColor Blue
Write-Host "====================================" -ForegroundColor Blue

# Check if React app is running
$uiRunning = $false
try {
    $uiResponse = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5 -ErrorAction Stop
    if ($uiResponse.StatusCode -eq 200) {
        Write-Host "✅ UI is running on localhost:3000" -ForegroundColor Green
        $uiRunning = $true
    }
} catch {
    Write-Host "❌ UI is not accessible on localhost:3000" -ForegroundColor Red
    Write-Host "   Start UI with: npm start" -ForegroundColor Yellow
}

if ($uiRunning) {
    # Check environment configuration
    Write-Host "`nChecking environment configuration..." -ForegroundColor Yellow
    
    # Test API endpoints from UI perspective
    Write-Host "Testing API calls from UI origin..." -ForegroundColor Yellow
    
    $apiTests = @(
        @{ name="Auth Health"; url="http://localhost:3001/health" },
        @{ name="Streaming Health"; url="http://localhost:3002/health" },
        @{ name="Core API Health"; url="http://localhost:3003/health" }
    )
    
    foreach ($test in $apiTests) {
        try {
            $headers = @{
                "Origin" = "http://localhost:3000"
                "Referer" = "http://localhost:3000/"
            }
            
            $response = Invoke-RestMethod -Uri $test.url -Headers $headers -TimeoutSec 5
            if ($response.status -eq "OK") {
                Write-Host "✅ $($test.name): Accessible from UI" -ForegroundColor Green
            } else {
                Write-Host "⚠️  $($test.name): Unexpected response" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "❌ $($test.name): Not accessible from UI" -ForegroundColor Red
        }
    }
    
    Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Open http://localhost:3000 in your browser" -ForegroundColor White
    Write-Host "2. Open Developer Tools (F12)" -ForegroundColor White
    Write-Host "3. Try to login or make API calls" -ForegroundColor White
    Write-Host "4. Check Console and Network tabs for errors" -ForegroundColor White
}
```

## 10. Troubleshooting Common UI-API Issues

### Issue 1: CORS Errors
**Symptoms:** Console shows "CORS policy" errors
**Solutions:**
```javascript
// Option 1: Add proxy in package.json
"proxy": "http://localhost:3001"

// Option 2: Use relative URLs instead of absolute
// Bad:  fetch('http://localhost:3001/api/login', ...)
// Good: fetch('/api/login', ...)

// Option 3: Verify API CORS configuration
// API should include UI origin in ALLOWED_ORIGINS
```

### Issue 2: Environment Variables Not Loading
**Symptoms:** `process.env.REACT_APP_*` is undefined
**Solutions:**
```bash
# 1. Restart React app after adding env vars
npm start

# 2. Verify env var naming (must start with REACT_APP_)
# 3. Check .env file location (should be in project root)
# 4. Verify no spaces around = in .env file
```

### Issue 3: API Requests Failing
**Symptoms:** Network errors, timeout errors
**Solutions:**
```javascript
// 1. Check if API services are running
// docker-compose ps

// 2. Verify correct URLs in environment
console.log(process.env.REACT_APP_AUTH_SERVICE_URL);

// 3. Test API endpoints manually
curl http://localhost:3001/health

// 4. Check for typos in API endpoints
// Ensure /api prefix is correct
```

### Issue 4: Authentication Not Persisting
**Symptoms:** User gets logged out on refresh
**Solutions:**
```javascript
// 1. Verify token storage
localStorage.setItem('authToken', token);

// 2. Check token retrieval in API service
const token = localStorage.getItem('authToken');

// 3. Verify token is included in requests
axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;

// 4. Handle token refresh logic
```

## 11. Final Verification Checklist

### UI Setup Checklist:
- [ ] React app starts without errors (`npm start`)
- [ ] Environment variables are loaded correctly
- [ ] API service files are configured with correct URLs
- [ ] Authentication service is properly implemented
- [ ] Error handling is in place
- [ ] CORS is configured (proxy or server-side)

### Integration Checklist:
- [ ] Health endpoints accessible from browser console
- [ ] Login flow works end-to-end
- [ ] Protected routes work with authentication
- [ ] API errors are handled gracefully
- [ ] Network tab shows successful API calls
- [ ] No CORS errors in browser console

### Success Indicators:
- ✅ UI loads without console errors
- ✅ API calls return expected data
- ✅ Authentication flow works completely
- ✅ User can navigate between pages
- ✅ Real-time features work (if implemented)

Run these verification steps to ensure your UI is properly configured to communicate with your API services! 🚀