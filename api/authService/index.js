const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Environment-driven configuration
const config = {
  port: PORT,
  nodeEnv: process.env.NODE_ENV || 'development',
  corsOrigin: process.env.CORS_ORIGIN || 'http://localhost:3000',
  serviceName: process.env.SERVICE_NAME || 'Authentication Service',
  version: process.env.SERVICE_VERSION || '1.0.0',
  jwt: {
    secret: process.env.JWT_SECRET || 'your-secret-key',
    expiresIn: process.env.JWT_EXPIRES_IN || '24h'
  },
  database: {
    uri: process.env.MONGO_URI || 'mongodb://localhost:27017/streamingapp'
  },
  email: {
    host: process.env.EMAIL_HOST,
    port: process.env.EMAIL_PORT || 587,
    user: process.env.EMAIL_USER,
    password: process.env.EMAIL_PASSWORD
  }
};

// Configure CORS
app.use(cors({
  origin: config.corsOrigin, // Environment-driven CORS origin
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Middleware
app.use(express.json());
app.use(cookieParser());

// Database connection
require('./util/conn');

// Routes
const healthCheckRoute = require('./routes/healthCheck.route');
const userRoute = require('./routes/user.route');

app.use('/health', healthCheckRoute);
app.use('/api', userRoute); // Changed from /apiv1 to /api

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Something went wrong on the server'
  });
});

app.listen(config.port, () => {
  console.log(`${config.serviceName} running on port ${config.port} in ${config.nodeEnv} mode`);
});

// Export config for use in other modules
module.exports = { app, config };