const express = require('express');
const router = express.Router();
const runningRoutesController = require('../controllers/runningRoutes.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

// All routes require authentication
router.use(authMiddleware);

// Route management
router.get('/routes', runningRoutesController.getUserRoutes);
router.get('/routes/:routeId', runningRoutesController.getRoute);
router.post('/routes', runningRoutesController.createRoute);
router.put('/routes/:routeId', runningRoutesController.updateRoute);
router.delete('/routes/:routeId', runningRoutesController.deleteRoute);

// Route generation and optimization
router.post('/routes/generate', runningRoutesController.generateExampleRoutes);
router.post('/routes/:routeId/optimize', runningRoutesController.optimizeRoute);
router.get('/routes/:routeId/optimal-times', runningRoutesController.getOptimalRunningTimes);

// Running history
router.post('/sessions', runningRoutesController.recordRunningSession);
router.get('/history', runningRoutesController.getRunningHistory);

module.exports = router;