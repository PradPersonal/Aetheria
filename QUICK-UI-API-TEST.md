# Quick UI-API Integration Testing

## Overview
This guide helps you quickly test the integration between your React UI and API services using the provided test component.

## Step 1: Add Test Component (Temporary)

Add this to your `src/App.js` to temporarily include the test component:

```javascript
import APIIntegrationTest from './components/APIIntegrationTest';

// Inside your App component's JSX (add at the end before closing div)
{process.env.NODE_ENV === 'development' && <APIIntegrationTest />}
```

Example integration in App.js:
```javascript
function App() {
  return (
    <div className="App">
      {/* Your existing components */}
      <Routes>
        {/* Your routes */}
      </Routes>
      
      {/* Add this line for testing (development only) */}
      {process.env.NODE_ENV === 'development' && <APIIntegrationTest />}
    </div>
  );
}
```

## Step 2: Environment Setup

Create or verify your `.env` file in the web directory:
```env
REACT_APP_AUTH_SERVICE_URL=http://localhost:3001
REACT_APP_STREAMING_SERVICE_URL=http://localhost:3002
REACT_APP_CORE_API_SERVICE_URL=http://localhost:3003
REACT_APP_CHAT_SERVICE_URL=http://localhost:3004
NODE_ENV=development
```

## Step 3: Start Services

1. **Start API Services:**
   ```bash
   # In the project root
   docker-compose up -d
   
   # Or start individual services
   cd api/authService && npm start &
   cd api/streamingService && npm start &
   # etc.
   ```

2. **Start React UI:**
   ```bash
   cd web
   npm start
   ```

## Step 4: Run Tests

1. Open your React app in the browser
2. Look for the blue test panel in the top-right corner
3. Click "Run Integration Tests"
4. Review results for each service

## Test Results Interpretation

### ✅ Green (Pass)
- Service is responding correctly
- CORS is configured properly
- Authentication flow is working

### ⚠️ Yellow (Warning)
- Service is reachable but may have configuration issues
- Authentication endpoints work but responses are unexpected
- Check API logs for details

### ❌ Red (Fail)
- Service is not reachable
- CORS is blocking requests
- Network connectivity issues

## Common Issues & Solutions

### CORS Errors
```
CORS blocked - check API CORS settings
```
**Solution:** Add CORS middleware to your API services:
```javascript
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:3001'],
  credentials: true
}));
```

### Service Not Reachable
```
Error: fetch request failed
```
**Solution:** 
1. Verify service is running: `docker ps` or check individual processes
2. Check port availability: `netstat -an | findstr :3001`
3. Verify environment variables are loaded

### Environment Variables Not Found
```
❌ Not set
```
**Solution:**
1. Restart React development server after changing `.env`
2. Verify `.env` file is in the web directory (not project root)
3. Ensure variables start with `REACT_APP_`

## Step 5: Cleanup (Important!)

**Remove the test component before production:**

1. Remove import from `App.js`:
   ```javascript
   // Remove this line
   import APIIntegrationTest from './components/APIIntegrationTest';
   ```

2. Remove component usage:
   ```javascript
   // Remove this line
   {process.env.NODE_ENV === 'development' && <APIIntegrationTest />}
   ```

3. Delete the test file:
   ```bash
   rm src/components/APIIntegrationTest.js
   ```

## Advanced Testing

For production-ready testing, consider:

1. **Jest Integration Tests:**
   ```javascript
   // __tests__/api-integration.test.js
   import { render, screen } from '@testing-library/react';
   import api from '../services/api';
   
   test('API health check', async () => {
     const response = await api.get('/health');
     expect(response.status).toBe(200);
   });
   ```

2. **Cypress E2E Tests:**
   ```javascript
   // cypress/integration/api.spec.js
   describe('API Integration', () => {
     it('should login successfully', () => {
       cy.request('POST', '/api/auth/login', {
         email: 'test@example.com',
         password: 'password'
       }).should((response) => {
         expect(response.status).to.eq(200);
         expect(response.body).to.have.property('token');
       });
     });
   });
   ```

3. **Automated Health Monitoring:**
   ```javascript
   // src/hooks/useHealthCheck.js
   import { useState, useEffect } from 'react';
   
   export const useHealthCheck = () => {
     const [status, setStatus] = useState('checking');
     
     useEffect(() => {
       const checkHealth = async () => {
         try {
           const response = await fetch('/api/health');
           setStatus(response.ok ? 'healthy' : 'unhealthy');
         } catch (error) {
           setStatus('error');
         }
       };
       
       checkHealth();
       const interval = setInterval(checkHealth, 30000);
       return () => clearInterval(interval);
     }, []);
     
     return status;
   };
   ```

## Next Steps

After verifying integration:

1. **Implement Error Boundaries:**
   ```javascript
   class APIErrorBoundary extends Component {
     constructor(props) {
       super(props);
       this.state = { hasError: false };
     }
   
     static getDerivedStateFromError(error) {
       return { hasError: true };
     }
   
     render() {
       if (this.state.hasError) {
         return <div>API Error - Please try again</div>;
       }
       return this.props.children;
     }
   }
   ```

2. **Add Request Interceptors:**
   ```javascript
   // src/services/api.js
   axios.interceptors.request.use(
     config => {
       const token = localStorage.getItem('token');
       if (token) {
         config.headers.Authorization = `Bearer ${token}`;
       }
       return config;
     },
     error => Promise.reject(error)
   );
   ```

3. **Implement Retry Logic:**
   ```javascript
   const apiCall = async (url, options, retries = 3) => {
     try {
       return await fetch(url, options);
     } catch (error) {
       if (retries > 0) {
         await new Promise(resolve => setTimeout(resolve, 1000));
         return apiCall(url, options, retries - 1);
       }
       throw error;
     }
   };
   ```

## Troubleshooting Checklist

- [ ] All API services are running and healthy
- [ ] Environment variables are properly set
- [ ] CORS is configured on all API endpoints
- [ ] Network connectivity between UI and APIs
- [ ] Authentication flows are working
- [ ] Error handling is implemented
- [ ] Request/response logging is available
- [ ] Health check endpoints are responding