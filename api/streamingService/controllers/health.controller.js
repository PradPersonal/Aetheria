const mongoose = require('mongoose');

const healthCheck = async (req, res) => {
    try {
        // Check database connection
        const dbStatus = mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';
        
        const healthStatus = {
            status: 'OK',
            timestamp: new Date().toISOString(),
            service: 'Streaming Service',
            version: process.env.SERVICE_VERSION || '1.0.0',
            environment: process.env.NODE_ENV || 'development',
            uptime: process.uptime(),
            memory: process.memoryUsage(),
            database: {
                status: dbStatus,
                name: mongoose.connection.name || 'unknown'
            }
        };

        res.status(200).json(healthStatus);
    } catch (err) {
        console.error('Health check failed:', err);
        res.status(503).json({
            status: 'DOWN',
            timestamp: new Date().toISOString(),
            service: 'Streaming Service',
            error: err.message
        });
    }
}

module.exports = { healthCheck }