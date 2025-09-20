const express = require('express');
const { query, validationResult } = require('express-validator');
const airQualityService = require('../services/airQuality.service');
const { authMiddleware, optionalAuth } = require('../middleware/auth.middleware');
const { getOne, getAll } = require('../config/database');

const router = express.Router();

// Get current air quality for a location
router.get('/current',
  [
    query('lat').isFloat({ min: -90, max: 90 }),
    query('lon').isFloat({ min: -180, max: 180 })
  ],
  optionalAuth,
  async (req, res, next) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { lat, lon } = req.query;
      const data = await airQualityService.getCurrentAirQuality(
        parseFloat(lat),
        parseFloat(lon)
      );

      // If user is authenticated, check if this is one of their pins and store history
      if (req.user) {
        const pin = await getOne(
          'SELECT id FROM pins WHERE user_id = ? AND latitude = ? AND longitude = ?',
          [req.user.id, lat, lon]
        );

        if (pin) {
          await airQualityService.storeAirQualityHistory(pin.id, data);
        }
      }

      res.json(data);
    } catch (error) {
      next(error);
    }
  }
);

// Get air quality history for a pin
router.get('/history/:pinId',
  authMiddleware,
  async (req, res, next) => {
    try {
      const { pinId } = req.params;
      const days = parseInt(req.query.days) || 7;

      // Verify pin belongs to user
      const pin = await getOne(
        'SELECT id FROM pins WHERE id = ? AND user_id = ?',
        [pinId, req.user.id]
      );

      if (!pin) {
        return res.status(404).json({ error: 'Pin not found' });
      }

      const history = await airQualityService.getAirQualityHistory(pinId, days);
      res.json(history);
    } catch (error) {
      next(error);
    }
  }
);

// Demo endpoint for sample data (no authentication required)
router.get('/demo/history/:pinId',
  async (req, res, next) => {
    try {
      const { pinId } = req.params;
      const days = parseInt(req.query.days) || 7;

      // Use real historical data when available, fallback to sample data
      const history = await airQualityService.getAirQualityHistory(parseInt(pinId), days);
      res.json(history);
    } catch (error) {
      next(error);
    }
  }
);

// Get air quality for multiple locations (batch request)
router.post('/batch',
  optionalAuth,
  async (req, res, next) => {
    try {
      const { locations } = req.body;

      if (!Array.isArray(locations) || locations.length === 0) {
        return res.status(400).json({ error: 'Locations array is required' });
      }

      if (locations.length > 10) {
        return res.status(400).json({ error: 'Maximum 10 locations allowed per request' });
      }

      const results = await Promise.all(
        locations.map(async (location) => {
          try {
            const data = await airQualityService.getCurrentAirQuality(
              location.latitude,
              location.longitude
            );
            return {
              location,
              data,
              success: true
            };
          } catch (error) {
            return {
              location,
              error: error.message,
              success: false
            };
          }
        })
      );

      res.json(results);
    } catch (error) {
      next(error);
    }
  }
);

// Get aggregated statistics for user's pins
router.get('/stats',
  authMiddleware,
  async (req, res, next) => {
    try {
      const days = parseInt(req.query.days) || 7;

      // Get all user's pins
      const pins = await getAll(
        'SELECT id, name FROM pins WHERE user_id = ? AND is_active = 1',
        [req.user.id]
      );

      const stats = await Promise.all(
        pins.map(async (pin) => {
          const history = await airQualityService.getAirQualityHistory(pin.id, days);

          if (history.length === 0) {
            return {
              pinId: pin.id,
              pinName: pin.name,
              averageAqi: null,
              maxAqi: null,
              minAqi: null
            };
          }

          const aqiValues = history.map(h => h.aqi).filter(v => v != null);

          return {
            pinId: pin.id,
            pinName: pin.name,
            averageAqi: aqiValues.reduce((a, b) => a + b, 0) / aqiValues.length,
            maxAqi: Math.max(...aqiValues),
            minAqi: Math.min(...aqiValues),
            dataPoints: history.length
          };
        })
      );

      res.json(stats);
    } catch (error) {
      next(error);
    }
  }
);

module.exports = router;