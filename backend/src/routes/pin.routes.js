const express = require('express');
const { body, validationResult } = require('express-validator');
const { runQuery, getOne, getAll } = require('../config/database');
const { authMiddleware } = require('../middleware/auth.middleware');
const airQualityService = require('../services/airQuality.service');
const weatherService = require('../services/weather.service');
const pollenService = require('../services/pollen.service');
const radonService = require('../services/radon.service');

const router = express.Router();

// Get all user pins
router.get('/', authMiddleware, async (req, res, next) => {
  try {
    const pins = await getAll(
      'SELECT * FROM pins WHERE user_id = ? AND is_active = 1 ORDER BY created_at DESC',
      [req.user.id]
    );

    // Optionally fetch current data for each pin
    if (req.query.includeCurrentData === 'true') {
      const pinsWithData = await Promise.all(
        pins.map(async (pin) => {
          try {
            const [airQuality, weather, pollen, radon] = await Promise.all([
              airQualityService.getCurrentAirQuality(pin.latitude, pin.longitude).catch(() => null),
              weatherService.getCurrentWeather(pin.latitude, pin.longitude).catch(() => null),
              pollenService.getCurrentPollen(pin.latitude, pin.longitude).catch(() => null),
              radonService.getRadonData(pin.latitude, pin.longitude).catch(() => null)
            ]);

            return {
              ...pin,
              currentData: {
                airQuality,
                weather,
                pollen,
                radon
              }
            };
          } catch (error) {
            return pin;
          }
        })
      );

      return res.json(pinsWithData);
    }

    res.json(pins);
  } catch (error) {
    next(error);
  }
});

// Get a specific pin
router.get('/:id', authMiddleware, async (req, res, next) => {
  try {
    const pin = await getOne(
      'SELECT * FROM pins WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );

    if (!pin) {
      return res.status(404).json({ error: 'Pin not found' });
    }

    // Optionally fetch current and historical data
    if (req.query.includeData === 'true') {
      const days = parseInt(req.query.days) || 7;

      const [currentAirQuality, currentWeather, currentPollen, airQualityHistory, weatherHistory, pollenHistory] = await Promise.all([
        airQualityService.getCurrentAirQuality(pin.latitude, pin.longitude).catch(() => null),
        weatherService.getCurrentWeather(pin.latitude, pin.longitude).catch(() => null),
        pollenService.getCurrentPollen(pin.latitude, pin.longitude).catch(() => null),
        airQualityService.getAirQualityHistory(pin.id, days),
        weatherService.getWeatherHistory(pin.id, days),
        pollenService.getPollenHistory(pin.id, days)
      ]);

      return res.json({
        ...pin,
        currentData: {
          airQuality: currentAirQuality,
          weather: currentWeather,
          pollen: currentPollen
        },
        history: {
          airQuality: airQualityHistory,
          weather: weatherHistory,
          pollen: pollenHistory
        }
      });
    }

    res.json(pin);
  } catch (error) {
    next(error);
  }
});

// Create a new pin
router.post('/',
  authMiddleware,
  [
    body('name').trim().notEmpty(),
    body('latitude').isFloat({ min: -90, max: 90 }),
    body('longitude').isFloat({ min: -180, max: 180 }),
    body('address').optional().trim()
  ],
  async (req, res, next) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { name, latitude, longitude, address } = req.body;

      // Check if pin already exists at this location for this user
      const existingPin = await getOne(
        'SELECT id FROM pins WHERE user_id = ? AND latitude = ? AND longitude = ?',
        [req.user.id, latitude, longitude]
      );

      if (existingPin) {
        return res.status(409).json({ error: 'Pin already exists at this location' });
      }

      // Create the pin
      const result = await runQuery(
        'INSERT INTO pins (user_id, name, latitude, longitude, address) VALUES (?, ?, ?, ?, ?)',
        [req.user.id, name, latitude, longitude, address]
      );

      const newPin = await getOne('SELECT * FROM pins WHERE id = ?', [result.id]);

      // Start collecting initial data for this pin
      Promise.all([
        airQualityService.getCurrentAirQuality(latitude, longitude)
          .then(data => airQualityService.storeAirQualityHistory(result.id, data))
          .catch(console.error),
        weatherService.getCurrentWeather(latitude, longitude)
          .then(data => weatherService.storeWeatherHistory(result.id, data))
          .catch(console.error),
        pollenService.getCurrentPollen(latitude, longitude)
          .then(data => pollenService.storePollenHistory(result.id, data))
          .catch(console.error)
      ]);

      res.status(201).json(newPin);
    } catch (error) {
      next(error);
    }
  }
);

// Update a pin
router.put('/:id',
  authMiddleware,
  [
    body('name').optional().trim().notEmpty(),
    body('address').optional().trim()
  ],
  async (req, res, next) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      // Verify pin belongs to user
      const pin = await getOne(
        'SELECT id FROM pins WHERE id = ? AND user_id = ?',
        [req.params.id, req.user.id]
      );

      if (!pin) {
        return res.status(404).json({ error: 'Pin not found' });
      }

      const { name, address } = req.body;
      const updates = [];
      const params = [];

      if (name !== undefined) {
        updates.push('name = ?');
        params.push(name);
      }

      if (address !== undefined) {
        updates.push('address = ?');
        params.push(address);
      }

      if (updates.length > 0) {
        params.push(req.params.id);

        await runQuery(
          `UPDATE pins SET ${updates.join(', ')} WHERE id = ?`,
          params
        );
      }

      const updatedPin = await getOne('SELECT * FROM pins WHERE id = ?', [req.params.id]);
      res.json(updatedPin);
    } catch (error) {
      next(error);
    }
  }
);

// Delete a pin (soft delete)
router.delete('/:id', authMiddleware, async (req, res, next) => {
  try {
    // Verify pin belongs to user
    const pin = await getOne(
      'SELECT id FROM pins WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );

    if (!pin) {
      return res.status(404).json({ error: 'Pin not found' });
    }

    // Soft delete by setting is_active to false
    await runQuery(
      'UPDATE pins SET is_active = 0 WHERE id = ?',
      [req.params.id]
    );

    res.json({ message: 'Pin deleted successfully' });
  } catch (error) {
    next(error);
  }
});

// Get aggregated data for all pins
router.get('/aggregate/all', authMiddleware, async (req, res, next) => {
  try {
    const pins = await getAll(
      'SELECT * FROM pins WHERE user_id = ? AND is_active = 1',
      [req.user.id]
    );

    const aggregatedData = await Promise.all(
      pins.map(async (pin) => {
        const [airQuality, weather, pollen] = await Promise.all([
          airQualityService.getCurrentAirQuality(pin.latitude, pin.longitude).catch(() => null),
          weatherService.getCurrentWeather(pin.latitude, pin.longitude).catch(() => null),
          pollenService.getCurrentPollen(pin.latitude, pin.longitude).catch(() => null)
        ]);

        return {
          pin: {
            id: pin.id,
            name: pin.name,
            latitude: pin.latitude,
            longitude: pin.longitude,
            address: pin.address
          },
          data: {
            airQuality,
            weather,
            pollen
          }
        };
      })
    );

    res.json(aggregatedData);
  } catch (error) {
    next(error);
  }
});

module.exports = router;