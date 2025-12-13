// Environment configuration utility
// This file provides a centralized way to access environment variables
// that can be injected at runtime in Docker containers

class Config {
  constructor() {
    // Runtime environment variables (injected via Docker)
    this.runtimeEnv = window._env || {};
    
    // Build-time environment variables (fallback)
    this.buildEnv = {
      REACT_APP_API_URL: process.env.REACT_APP_API_URL,
      REACT_APP_STREAMING_URL: process.env.REACT_APP_STREAMING_URL,
      REACT_APP_CHAT_URL: process.env.REACT_APP_CHAT_URL,
      REACT_APP_CORE_API_URL: process.env.REACT_APP_CORE_API_URL,
      REACT_APP_WS_URL: process.env.REACT_APP_WS_URL,
      REACT_APP_APP_NAME: process.env.REACT_APP_APP_NAME,
      REACT_APP_VERSION: process.env.REACT_APP_VERSION,
      REACT_APP_ENVIRONMENT: process.env.REACT_APP_ENVIRONMENT,
      REACT_APP_ENABLE_CHAT: process.env.REACT_APP_ENABLE_CHAT,
      REACT_APP_ENABLE_ANALYTICS: process.env.REACT_APP_ENABLE_ANALYTICS,
      REACT_APP_ENABLE_DEBUG: process.env.REACT_APP_ENABLE_DEBUG,
      REACT_APP_ANALYTICS_ID: process.env.REACT_APP_ANALYTICS_ID,
      REACT_APP_SENTRY_DSN: process.env.REACT_APP_SENTRY_DSN
    };
  }

  // Get environment variable with fallback chain
  get(key, defaultValue = null) {
    // 1. Try runtime environment (Docker injection)
    if (this.runtimeEnv[key] && this.runtimeEnv[key] !== `%%${key}%%`) {
      return this.runtimeEnv[key];
    }
    
    // 2. Try build-time environment
    if (this.buildEnv[key]) {
      return this.buildEnv[key];
    }
    
    // 3. Return default value
    return defaultValue;
  }

  // Get boolean value
  getBoolean(key, defaultValue = false) {
    const value = this.get(key);
    if (value === null || value === undefined) return defaultValue;
    return String(value).toLowerCase() === 'true';
  }

  // Get number value
  getNumber(key, defaultValue = 0) {
    const value = this.get(key);
    const parsed = parseInt(value, 10);
    return isNaN(parsed) ? defaultValue : parsed;
  }

  // API Endpoints
  get apiUrl() {
    return this.get('REACT_APP_API_URL', 'http://localhost:3001/api');
  }

  get streamingUrl() {
    return this.get('REACT_APP_STREAMING_URL', 'http://localhost:3002/api');
  }

  get chatUrl() {
    return this.get('REACT_APP_CHAT_URL', 'http://localhost:3003/api');
  }

  get coreApiUrl() {
    return this.get('REACT_APP_CORE_API_URL', 'http://localhost:3004/api');
  }

  get wsUrl() {
    return this.get('REACT_APP_WS_URL', 'ws://localhost:3003');
  }

  // App Configuration
  get appName() {
    return this.get('REACT_APP_APP_NAME', 'Aetheria');
  }

  get version() {
    return this.get('REACT_APP_VERSION', '1.0.0');
  }

  get environment() {
    return this.get('REACT_APP_ENVIRONMENT', 'development');
  }

  get isProduction() {
    return this.environment === 'production';
  }

  get isDevelopment() {
    return this.environment === 'development';
  }

  // Feature Flags
  get isChatEnabled() {
    return this.getBoolean('REACT_APP_ENABLE_CHAT', true);
  }

  get isAnalyticsEnabled() {
    return this.getBoolean('REACT_APP_ENABLE_ANALYTICS', false);
  }

  get isDebugEnabled() {
    return this.getBoolean('REACT_APP_ENABLE_DEBUG', !this.isProduction);
  }

  // External Services
  get analyticsId() {
    return this.get('REACT_APP_ANALYTICS_ID');
  }

  get sentryDsn() {
    return this.get('REACT_APP_SENTRY_DSN');
  }

  // Debug method to log all configuration
  logConfig() {
    if (this.isDebugEnabled) {
      console.group('🔧 Aetheria Configuration');
      console.log('Environment:', this.environment);
      console.log('API URL:', this.apiUrl);
      console.log('Streaming URL:', this.streamingUrl);
      console.log('Chat URL:', this.chatUrl);
      console.log('Core API URL:', this.coreApiUrl);
      console.log('WebSocket URL:', this.wsUrl);
      console.log('Chat Enabled:', this.isChatEnabled);
      console.log('Analytics Enabled:', this.isAnalyticsEnabled);
      console.log('Debug Enabled:', this.isDebugEnabled);
      console.groupEnd();
    }
  }
}

// Create singleton instance
const config = new Config();

// Log configuration in development/debug mode
config.logConfig();

export default config;