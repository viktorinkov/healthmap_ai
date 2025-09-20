const express = require('express');
const radonService = require('../services/radon.service');
const { authMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

// Get current radon data for a location (public endpoint)
router.get('/current', async (req, res) => {
  try {
    const { lat, lon } = req.query;

    // Validate coordinates
    if (!lat || !lon) {
      return res.status(400).json({
        error: 'Missing required parameters: lat and lon'
      });
    }

    const latitude = parseFloat(lat);
    const longitude = parseFloat(lon);

    // Validate coordinate ranges
    if (isNaN(latitude) || isNaN(longitude)) {
      return res.status(400).json({
        error: 'Invalid coordinates: lat and lon must be valid numbers'
      });
    }

    if (latitude < -90 || latitude > 90) {
      return res.status(400).json({
        error: 'Invalid latitude: must be between -90 and 90'
      });
    }

    if (longitude < -180 || longitude > 180) {
      return res.status(400).json({
        error: 'Invalid longitude: must be between -180 and 180'
      });
    }

    // Get radon data
    const radonData = await radonService.getRadonData(latitude, longitude);

    res.json(radonData);
  } catch (error) {
    console.error('Error in GET /radon/current:', error);
    res.status(500).json({
      error: 'Failed to fetch radon data',
      details: error.message
    });
  }
});

// Get radon data for multiple locations (public endpoint)
router.post('/batch', async (req, res) => {
  try {
    const { locations } = req.body;

    if (!locations || !Array.isArray(locations)) {
      return res.status(400).json({
        error: 'Missing or invalid locations array'
      });
    }

    if (locations.length === 0) {
      return res.status(400).json({
        error: 'Locations array cannot be empty'
      });
    }

    if (locations.length > 10) {
      return res.status(400).json({
        error: 'Maximum 10 locations allowed per batch request'
      });
    }

    // Validate all locations first
    for (const location of locations) {
      if (!location.lat || !location.lon) {
        return res.status(400).json({
          error: 'Each location must have lat and lon properties'
        });
      }

      const lat = parseFloat(location.lat);
      const lon = parseFloat(location.lon);

      if (isNaN(lat) || isNaN(lon)) {
        return res.status(400).json({
          error: 'All coordinates must be valid numbers'
        });
      }

      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        return res.status(400).json({
          error: 'All coordinates must be within valid ranges'
        });
      }
    }

    // Fetch radon data for all locations
    const radonDataPromises = locations.map(location =>
      radonService.getRadonData(parseFloat(location.lat), parseFloat(location.lon))
        .catch(error => ({
          error: 'Failed to fetch data for this location',
          location: { latitude: location.lat, longitude: location.lon }
        }))
    );

    const radonDataResults = await Promise.all(radonDataPromises);

    res.json({
      results: radonDataResults,
      count: radonDataResults.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error in POST /radon/batch:', error);
    res.status(500).json({
      error: 'Failed to fetch batch radon data',
      details: error.message
    });
  }
});

// Get radon history for a specific pin (authenticated endpoint)
router.get('/history/:pinId', authMiddleware, async (req, res) => {
  try {
    const { pinId } = req.params;
    const { days = 7 } = req.query;

    // Validate pin ID
    if (!pinId || isNaN(parseInt(pinId))) {
      return res.status(400).json({
        error: 'Invalid pin ID'
      });
    }

    // Validate days parameter
    const daysNum = parseInt(days);
    if (isNaN(daysNum) || daysNum < 1 || daysNum > 365) {
      return res.status(400).json({
        error: 'Days parameter must be between 1 and 365'
      });
    }

    // TODO: Add authorization check to ensure user owns this pin
    // const pinOwner = await checkPinOwnership(req.user.id, pinId);
    // if (!pinOwner) {
    //   return res.status(403).json({ error: 'Access denied to this pin' });
    // }

    const history = await radonService.getRadonHistory(parseInt(pinId), daysNum);

    res.json({
      pinId: parseInt(pinId),
      days: daysNum,
      history,
      count: history.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error in GET /radon/history/:pinId:', error);
    res.status(500).json({
      error: 'Failed to fetch radon history',
      details: error.message
    });
  }
});

// Get radon zone information (public endpoint)
router.get('/zones', async (req, res) => {
  try {
    const zones = {
      1: {
        name: 'Zone 1 - High Radon Potential',
        description: 'Counties with predicted average indoor radon screening levels greater than 4 pCi/L',
        recommendation: 'Test all homes and buildings below the third floor',
        averageLevel: '>4.0 pCi/L',
        color: '#ff4444',
        riskLevel: 'High'
      },
      2: {
        name: 'Zone 2 - Moderate Radon Potential',
        description: 'Counties with predicted average indoor radon screening levels from 2 to 4 pCi/L',
        recommendation: 'Test all homes; state or local requirements may apply',
        averageLevel: '2.0-4.0 pCi/L',
        color: '#ffaa00',
        riskLevel: 'Moderate'
      },
      3: {
        name: 'Zone 3 - Low Radon Potential',
        description: 'Counties with predicted average indoor radon screening levels less than 2 pCi/L',
        recommendation: 'Testing recommended; follow state or local guidance',
        averageLevel: '<2.0 pCi/L',
        color: '#44ff44',
        riskLevel: 'Low'
      }
    };

    res.json({
      zones,
      epaNationalAverage: 1.3,
      epaActionLevel: 4.0,
      unit: 'pCi/L',
      source: 'EPA Map of Radon Zones',
      lastUpdated: '2023',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error in GET /radon/zones:', error);
    res.status(500).json({
      error: 'Failed to fetch radon zone information',
      details: error.message
    });
  }
});

// Health check endpoint for radon service
router.get('/health', async (req, res) => {
  try {
    // Test the service with sample coordinates
    const testData = await radonService.getRadonData(39.7392, -104.9903); // Denver, CO

    res.json({
      status: 'healthy',
      service: 'radon',
      timestamp: new Date().toISOString(),
      testLocation: 'Denver, CO',
      testResult: {
        zone: testData.radonZone,
        risk: testData.radonRisk
      }
    });
  } catch (error) {
    console.error('Error in radon health check:', error);
    res.status(500).json({
      status: 'unhealthy',
      service: 'radon',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;