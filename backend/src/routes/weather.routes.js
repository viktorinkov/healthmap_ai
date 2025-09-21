const express = require('express');
const { query, validationResult } = require('express-validator');
const weatherService = require('../services/weather.service');
const pollenService = require('../services/pollen.service');
const wildfireService = require('../services/wildfire.service');
const { authMiddleware, optionalAuth } = require('../middleware/auth.middleware');
const { getOne, getAll } = require('../config/database');

const router = express.Router();

// Get current weather for a location
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
      const weather = await weatherService.getCurrentWeather(
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
          await weatherService.storeWeatherHistory(pin.id, weather);
        }
      }

      res.json(weather);
    } catch (error) {
      next(error);
    }
  }
);

// Get weather forecast
router.get('/forecast',
  [
    query('lat').isFloat({ min: -90, max: 90 }),
    query('lon').isFloat({ min: -180, max: 180 }),
    query('days').optional().isInt({ min: 1, max: 10 })
  ],
  async (req, res, next) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { lat, lon, days } = req.query;
      const forecast = await weatherService.getWeatherForecast(
        parseFloat(lat),
        parseFloat(lon),
        days ? parseInt(days) : 5
      );

      res.json(forecast);
    } catch (error) {
      next(error);
    }
  }
);

// Get historical weather data for coordinates (no authentication required)
router.get('/historical',
  [
    query('lat').isFloat({ min: -90, max: 90 }),
    query('lon').isFloat({ min: -180, max: 180 }),
    query('days').optional().isInt({ min: 1, max: 30 })
  ],
  async (req, res, next) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { lat, lon, days } = req.query;
      const latitude = parseFloat(lat);
      const longitude = parseFloat(lon);
      const daysBack = parseInt(days) || 7;

      // Get actual historical weather data from Google Weather API
      const historicalData = await weatherService.getHistoricalWeatherByCoordinates(latitude, longitude, daysBack);

      if (!historicalData || historicalData.length === 0) {
        return res.status(404).json({
          error: 'Historical weather data not available for this location'
        });
      }

      res.json(historicalData);
    } catch (error) {
      next(error);
    }
  }
);

// Get weather history for a pin
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

      const history = await weatherService.getWeatherHistory(pinId, days);
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
      const history = await weatherService.getWeatherHistory(parseInt(pinId), days);
      res.json(history);
    } catch (error) {
      next(error);
    }
  }
);

// Get pollen data for a location
router.get('/pollen',
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
      const pollen = await pollenService.getCurrentPollen(
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
          await pollenService.storePollenHistory(pin.id, pollen);
        }
      }

      res.json(pollen);
    } catch (error) {
      next(error);
    }
  }
);

// Get pollen forecast
router.get('/pollen/forecast',
  [
    query('lat').isFloat({ min: -90, max: 90 }),
    query('lon').isFloat({ min: -180, max: 180 }),
    query('days').optional().isInt({ min: 1, max: 5 })
  ],
  async (req, res, next) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { lat, lon, days } = req.query;
      const forecast = await pollenService.getPollenForecast(
        parseFloat(lat),
        parseFloat(lon),
        days ? parseInt(days) : 5
      );

      res.json(forecast);
    } catch (error) {
      next(error);
    }
  }
);

// Get wildfire data for a location
router.get('/wildfire',
  [
    query('lat').isFloat({ min: -90, max: 90 }),
    query('lon').isFloat({ min: -180, max: 180 }),
    query('radius').optional().isInt({ min: 10, max: 500 })
  ],
  optionalAuth,
  async (req, res, next) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { lat, lon, radius } = req.query;
      const wildfire = await wildfireService.getWildfireData(
        parseFloat(lat),
        parseFloat(lon),
        radius ? parseInt(radius) : 100
      );

      // If user is authenticated, check if this is one of their pins and store history
      if (req.user) {
        const pin = await getOne(
          'SELECT id FROM pins WHERE user_id = ? AND latitude = ? AND longitude = ?',
          [req.user.id, lat, lon]
        );

        if (pin) {
          await wildfireService.storeWildfireHistory(pin.id, wildfire);
        }
      }

      res.json(wildfire);
    } catch (error) {
      next(error);
    }
  }
);

// Get combined environmental data (weather + pollen + air quality + wildfire)
router.get('/environmental',
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
      const latitude = parseFloat(lat);
      const longitude = parseFloat(lon);

      // Fetch all data in parallel
      const [weather, pollen, airQuality, wildfire] = await Promise.all([
        weatherService.getCurrentWeather(latitude, longitude).catch(err => ({ error: err.message })),
        pollenService.getCurrentPollen(latitude, longitude).catch(err => ({ error: err.message })),
        require('../services/airQuality.service').getCurrentAirQuality(latitude, longitude).catch(err => ({ error: err.message })),
        wildfireService.getWildfireData(latitude, longitude, 100).catch(err => ({ error: err.message }))
      ]);

      res.json({
        location: { latitude, longitude },
        weather,
        pollen,
        airQuality,
        wildfire,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      next(error);
    }
  }
);

module.exports = router;