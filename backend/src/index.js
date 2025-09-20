require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');

const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const airQualityRoutes = require('./routes/airQuality.routes');
const weatherRoutes = require('./routes/weather.routes');
const pinRoutes = require('./routes/pin.routes');
const healthRoutes = require('./routes/health.routes');
const radonRoutes = require('./routes/radon.routes');

const { initializeDatabase } = require('./config/database');
const { startScheduledTasks } = require('./services/scheduler.service');
const errorHandler = require('./middleware/error.middleware');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(compression());

// CORS configuration
app.use(cors({
  origin: ['http://localhost:*', 'http://127.0.0.1:*'],
  credentials: true
}));

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100
});
app.use('/api/', limiter);

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/air-quality', airQualityRoutes);
app.use('/api/weather', weatherRoutes);
app.use('/api/pins', pinRoutes);
app.use('/api/health', healthRoutes);
app.use('/api/radon', radonRoutes);

// Health check endpoint
app.get('/api/health-check', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV
  });
});

// Error handling middleware
app.use(errorHandler);

// Initialize database and start server
async function startServer() {
  try {
    await initializeDatabase();
    console.log('✅ Database initialized successfully');

    // Start scheduled tasks for data collection
    startScheduledTasks();
    console.log('✅ Scheduled tasks started');

    app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 HealthMap AI Backend running on http://0.0.0.0:${PORT}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV}`);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

startServer();