const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3003;

// Environment-driven configuration
const config = {
  port: PORT,
  nodeEnv: process.env.NODE_ENV || 'development',
  corsOrigin: process.env.CORS_ORIGIN || 'http://localhost:3000',
  serviceName: process.env.SERVICE_NAME || 'Chat Service',
  version: process.env.SERVICE_VERSION || '1.0.0'
};

// Configure CORS
app.use(cors({
  origin: config.corsOrigin,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Middleware
app.use(express.json());

// Health check route
app.get('/health', (req, res) => {
  const healthStatus = {
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: config.serviceName,
    version: config.version,
    environment: config.nodeEnv,
    uptime: process.uptime(),
    memory: process.memoryUsage()
  };

  res.status(200).json(healthStatus);
});

// Basic chat endpoint (placeholder)
app.get('/api/chat', (req, res) => {
  res.json({
    message: 'Chat service is running',
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Something went wrong on the server',
    timestamp: new Date().toISOString()
  });
});

app.listen(config.port, () => {
  console.log(`${config.serviceName} running on port ${config.port} in ${config.nodeEnv} mode`);
});

module.exports = app;