const express = require('express');
const cookieParser = require('cookie-parser');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3002;

// Environment-driven configuration
const config = {
  port: PORT,
  nodeEnv: process.env.NODE_ENV || 'development',
  corsOrigin: process.env.CORS_ORIGIN || 'http://localhost:3000',
  serviceName: process.env.SERVICE_NAME || 'Streaming Service',
  version: process.env.SERVICE_VERSION || '1.0.0',
  database: {
    uri: process.env.MONGO_URI || 'mongodb://localhost:27017/streamingapp'
  },
  aws: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    region: process.env.AWS_REGION || 'us-east-1',
    s3Bucket: process.env.AWS_S3_BUCKET
  }
};

// Configure CORS
app.use(cors({
  origin: config.corsOrigin, // Environment-driven CORS origin
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Middleware
app.use(cookieParser());
app.use(express.json());

// Database connection
require('./util/conn');

// Routes
const healthRoutes = require('./routes/health.route');
const streamingRoutes = require('./routes/streaming.route');
const adminRoutes = require('./routes/admin.route');

app.use('/api/health', healthRoutes);
app.use('/api/streaming', streamingRoutes);
app.use('/api/admin', adminRoutes);

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