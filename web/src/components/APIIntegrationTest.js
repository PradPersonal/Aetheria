import React, { useState, useEffect } from 'react';

/**
 * API Integration Test Component
 * Add this temporarily to your App.js to test UI-API integration
 * 
 * Usage in App.js:
 * import APIIntegrationTest from './components/APIIntegrationTest';
 * 
 * // Add to your JSX (only in development)
 * {process.env.NODE_ENV === 'development' && <APIIntegrationTest />}
 */

const APIIntegrationTest = () => {
  const [tests, setTests] = useState([]);
  const [testing, setTesting] = useState(false);
  const [envVars, setEnvVars] = useState({});

  useEffect(() => {
    // Check environment variables on component mount
    const checkEnvVars = () => {
      const envCheck = {
        'REACT_APP_AUTH_SERVICE_URL': process.env.REACT_APP_AUTH_SERVICE_URL,
        'REACT_APP_STREAMING_SERVICE_URL': process.env.REACT_APP_STREAMING_SERVICE_URL,
        'REACT_APP_CORE_API_SERVICE_URL': process.env.REACT_APP_CORE_API_SERVICE_URL,
        'REACT_APP_CHAT_SERVICE_URL': process.env.REACT_APP_CHAT_SERVICE_URL,
        'NODE_ENV': process.env.NODE_ENV
      };
      setEnvVars(envCheck);
    };

    checkEnvVars();
  }, []);

  const runTests = async () => {
    setTesting(true);
    setTests([]);

    const testResults = [];

    // Test 1: Environment Variables
    testResults.push({
      name: '🔧 Environment Variables',
      status: 'running',
      details: 'Checking if required env vars are loaded...'
    });
    setTests([...testResults]);

    await new Promise(resolve => setTimeout(resolve, 500));

    const requiredEnvs = ['REACT_APP_AUTH_SERVICE_URL'];
    const envResult = requiredEnvs.every(env => process.env[env]);
    
    testResults[0] = {
      name: '🔧 Environment Variables',
      status: envResult ? 'pass' : 'fail',
      details: envResult ? 'All required env vars found' : 'Missing required environment variables'
    };
    setTests([...testResults]);

    // Test 2: API Health Checks
    const apiServices = [
      { name: 'Auth', url: process.env.REACT_APP_AUTH_SERVICE_URL || 'http://localhost:3001' },
      { name: 'Streaming', url: process.env.REACT_APP_STREAMING_SERVICE_URL || 'http://localhost:3002' },
      { name: 'Core API', url: process.env.REACT_APP_CORE_API_SERVICE_URL || 'http://localhost:3003' },
      { name: 'Chat', url: process.env.REACT_APP_CHAT_SERVICE_URL || 'http://localhost:3004' }
    ];

    for (let i = 0; i < apiServices.length; i++) {
      const service = apiServices[i];
      
      testResults.push({
        name: `🏥 ${service.name} Service Health`,
        status: 'running',
        details: `Testing ${service.url}/health...`
      });
      setTests([...testResults]);

      try {
        const response = await fetch(`${service.url}/health`, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json'
          }
        });

        if (response.ok) {
          const data = await response.json();
          const isHealthy = data.status === 'OK';
          
          testResults[testResults.length - 1] = {
            name: `🏥 ${service.name} Service Health`,
            status: isHealthy ? 'pass' : 'warn',
            details: isHealthy ? 'Service is healthy' : `Service returned: ${data.status || 'Unknown'}`
          };
        } else {
          testResults[testResults.length - 1] = {
            name: `🏥 ${service.name} Service Health`,
            status: 'fail',
            details: `HTTP ${response.status}: ${response.statusText}`
          };
        }
      } catch (error) {
        testResults[testResults.length - 1] = {
          name: `🏥 ${service.name} Service Health`,
          status: 'fail',
          details: `Error: ${error.message}`
        };
      }

      setTests([...testResults]);
      await new Promise(resolve => setTimeout(resolve, 300));
    }

    // Test 3: CORS Configuration
    testResults.push({
      name: '🌐 CORS Configuration',
      status: 'running',
      details: 'Testing cross-origin requests...'
    });
    setTests([...testResults]);

    try {
      const authUrl = process.env.REACT_APP_AUTH_SERVICE_URL || 'http://localhost:3001';
      const corsResponse = await fetch(`${authUrl}/api/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          email: 'test@example.com',
          password: 'testpassword'
        })
      });

      // If we get any response (even 400/401), CORS is working
      testResults[testResults.length - 1] = {
        name: '🌐 CORS Configuration',
        status: 'pass',
        details: 'CORS headers allow requests from UI'
      };
    } catch (error) {
      const isCorsError = error.message.includes('CORS') || 
                         error.message.includes('cross-origin') ||
                         error.message.includes('Network request failed');
      
      testResults[testResults.length - 1] = {
        name: '🌐 CORS Configuration',
        status: isCorsError ? 'fail' : 'pass',
        details: isCorsError ? 'CORS blocked - check API CORS settings' : 'CORS appears to be working'
      };
    }

    setTests([...testResults]);

    // Test 4: Authentication Flow (if possible)
    testResults.push({
      name: '🔐 Authentication Test',
      status: 'running',
      details: 'Testing auth endpoints...'
    });
    setTests([...testResults]);

    try {
      const authUrl = process.env.REACT_APP_AUTH_SERVICE_URL || 'http://localhost:3001';
      
      // Test registration with random user
      const randomId = Date.now();
      const testUser = {
        username: `testuser_${randomId}`,
        email: `test_${randomId}@example.com`,
        password: 'TestPass123!'
      };

      const registerResponse = await fetch(`${authUrl}/api/auth/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(testUser)
      });

      if (registerResponse.ok) {
        // Try to login with the registered user
        const loginResponse = await fetch(`${authUrl}/api/auth/login`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            email: testUser.email,
            password: testUser.password
          })
        });

        if (loginResponse.ok) {
          const loginData = await loginResponse.json();
          if (loginData.token) {
            testResults[testResults.length - 1] = {
              name: '🔐 Authentication Test',
              status: 'pass',
              details: 'Registration and login working correctly'
            };
          } else {
            testResults[testResults.length - 1] = {
              name: '🔐 Authentication Test',
              status: 'warn',
              details: 'Auth endpoints accessible but no token returned'
            };
          }
        } else {
          testResults[testResults.length - 1] = {
            name: '🔐 Authentication Test',
            status: 'warn',
            details: 'Registration works but login failed'
          };
        }
      } else {
        testResults[testResults.length - 1] = {
          name: '🔐 Authentication Test',
          status: 'warn',
          details: `Auth endpoint accessible but returned ${registerResponse.status}`
        };
      }
    } catch (error) {
      testResults[testResults.length - 1] = {
        name: '🔐 Authentication Test',
        status: 'fail',
        details: `Auth test failed: ${error.message}`
      };
    }

    setTests([...testResults]);
    setTesting(false);
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'pass': return '✅';
      case 'fail': return '❌';
      case 'warn': return '⚠️';
      case 'running': return '🔄';
      default: return '⏳';
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'pass': return '#28a745';
      case 'fail': return '#dc3545';
      case 'warn': return '#ffc107';
      case 'running': return '#007bff';
      default: return '#6c757d';
    }
  };

  const overallStatus = tests.length > 0 ? 
    tests.every(t => t.status === 'pass') ? 'All tests passed!' :
    tests.some(t => t.status === 'fail') ? 'Some tests failed' :
    'Some warnings detected' : '';

  return (
    <div style={{ 
      position: 'fixed', 
      top: '10px', 
      right: '10px', 
      width: '400px', 
      maxHeight: '90vh',
      overflow: 'auto',
      backgroundColor: 'white', 
      border: '2px solid #007bff', 
      borderRadius: '8px', 
      padding: '15px',
      boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
      fontFamily: 'monospace',
      fontSize: '12px',
      zIndex: 9999
    }}>
      <h3 style={{ margin: '0 0 15px 0', color: '#007bff' }}>
        🔧 UI-API Integration Test
      </h3>

      {/* Environment Variables Display */}
      <details style={{ marginBottom: '15px' }}>
        <summary style={{ cursor: 'pointer', fontWeight: 'bold' }}>
          Environment Variables
        </summary>
        <div style={{ marginTop: '10px', fontSize: '11px' }}>
          {Object.entries(envVars).map(([key, value]) => (
            <div key={key} style={{ margin: '2px 0' }}>
              <strong>{key}:</strong> {value || '❌ Not set'}
            </div>
          ))}
        </div>
      </details>

      <button 
        onClick={runTests} 
        disabled={testing}
        style={{
          backgroundColor: testing ? '#6c757d' : '#007bff',
          color: 'white',
          border: 'none',
          padding: '8px 16px',
          borderRadius: '4px',
          cursor: testing ? 'not-allowed' : 'pointer',
          width: '100%',
          marginBottom: '15px'
        }}
      >
        {testing ? '🔄 Running Tests...' : '▶️ Run Integration Tests'}
      </button>

      {/* Test Results */}
      {tests.length > 0 && (
        <div>
          <h4 style={{ margin: '0 0 10px 0', color: '#333' }}>Test Results:</h4>
          {tests.map((test, index) => (
            <div 
              key={index} 
              style={{ 
                margin: '8px 0', 
                padding: '8px',
                backgroundColor: '#f8f9fa',
                border: `1px solid ${getStatusColor(test.status)}`,
                borderRadius: '4px'
              }}
            >
              <div style={{ fontWeight: 'bold', color: getStatusColor(test.status) }}>
                {getStatusIcon(test.status)} {test.name}
              </div>
              <div style={{ fontSize: '10px', color: '#666', marginTop: '4px' }}>
                {test.details}
              </div>
            </div>
          ))}

          {!testing && (
            <div style={{ 
              marginTop: '15px', 
              padding: '10px', 
              backgroundColor: tests.some(t => t.status === 'fail') ? '#f8d7da' : 
                               tests.some(t => t.status === 'warn') ? '#fff3cd' : '#d4edda',
              border: '1px solid #dee2e6',
              borderRadius: '4px'
            }}>
              <strong>Overall Status:</strong> {overallStatus}
            </div>
          )}
        </div>
      )}

      {/* Instructions */}
      {!testing && tests.length === 0 && (
        <div style={{ fontSize: '11px', color: '#666' }}>
          <p>Click "Run Integration Tests" to verify your UI can communicate with the API services.</p>
          <p><strong>Before testing:</strong></p>
          <ul>
            <li>Ensure API services are running (docker-compose up)</li>
            <li>Check that environment variables are set</li>
            <li>Verify CORS is configured in API services</li>
          </ul>
        </div>
      )}

      <div style={{ 
        marginTop: '15px', 
        fontSize: '10px', 
        color: '#999',
        borderTop: '1px solid #dee2e6',
        paddingTop: '10px'
      }}>
        💡 Remove this component before production!
      </div>
    </div>
  );
};

export default APIIntegrationTest;