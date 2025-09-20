const express = require('express');
const { query, validationResult } = require('express-validator');
const { authMiddleware } = require('../middleware/auth.middleware');
const { getOne, getAll } = require('../config/database');
const airQualityService = require('../services/airQuality.service');
const weatherService = require('../services/weather.service');
const pollenService = require('../services/pollen.service');

const router = express.Router();

// Get personalized health recommendations based on location and user profile
router.get('/recommendations',
  authMiddleware,
  [
    query('lat').isFloat({ min: -90, max: 90 }),
    query('lon').isFloat({ min: -180, max: 180 })
  ],
  async (req, res, next) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { lat, lon } = req.query;
      const latitude = parseFloat(lat);
      const longitude = parseFloat(lon);

      // Get user's medical profile
      const medicalProfile = await getOne(
        'SELECT * FROM medical_profiles WHERE user_id = ?',
        [req.user.id]
      );

      // Get current environmental data
      const [airQuality, weather, pollen] = await Promise.all([
        airQualityService.getCurrentAirQuality(latitude, longitude),
        weatherService.getCurrentWeather(latitude, longitude),
        pollenService.getCurrentPollen(latitude, longitude)
      ]);

      // Generate personalized recommendations
      const recommendations = generateHealthRecommendations(
        medicalProfile,
        airQuality,
        weather,
        pollen
      );

      res.json({
        location: { latitude, longitude },
        environmentalData: {
          airQuality,
          weather,
          pollen
        },
        medicalProfile,
        recommendations,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      next(error);
    }
  }
);

// Generate health recommendations based on conditions
function generateHealthRecommendations(medicalProfile, airQuality, weather, pollen) {
  const recommendations = {
    general: [],
    outdoor: [],
    indoor: [],
    medication: [],
    precautions: [],
    riskLevel: 'Low'
  };

  // AQI-based recommendations
  if (airQuality?.aqi) {
    if (airQuality.aqi > 150) {
      recommendations.riskLevel = 'High';
      recommendations.general.push('Air quality is poor. Limit outdoor activities.');
      recommendations.indoor.push('Keep windows closed and use air purifiers if available.');

      if (medicalProfile?.has_respiratory_condition) {
        recommendations.riskLevel = 'Very High';
        recommendations.precautions.push('Avoid all outdoor activities. Monitor symptoms closely.');
        recommendations.medication.push('Keep rescue medications readily available.');
      }
    } else if (airQuality.aqi > 100) {
      recommendations.riskLevel = 'Moderate';
      recommendations.general.push('Air quality is moderate. Sensitive groups should limit prolonged outdoor exposure.');

      if (medicalProfile?.has_respiratory_condition || medicalProfile?.has_heart_condition) {
        recommendations.riskLevel = 'High';
        recommendations.outdoor.push('Reduce prolonged or heavy outdoor exertion.');
      }
    } else if (airQuality.aqi > 50) {
      recommendations.general.push('Air quality is acceptable for most people.');

      if (medicalProfile?.has_respiratory_condition) {
        recommendations.outdoor.push('Consider reducing prolonged outdoor exertion.');
      }
    } else {
      recommendations.general.push('Air quality is good. Enjoy outdoor activities!');
    }
  }

  // Weather-based recommendations
  if (weather?.temperature) {
    if (weather.temperature > 32) {
      recommendations.outdoor.push('High temperature alert. Stay hydrated and seek shade.');

      if (medicalProfile?.is_elderly || medicalProfile?.has_heart_condition) {
        recommendations.riskLevel = Math.max(recommendations.riskLevel, 'High');
        recommendations.precautions.push('Avoid outdoor activities during peak heat hours (10 AM - 4 PM).');
      }
    } else if (weather.temperature < 0) {
      recommendations.outdoor.push('Cold weather alert. Dress warmly in layers.');

      if (medicalProfile?.has_respiratory_condition) {
        recommendations.precautions.push('Cover nose and mouth to warm air before breathing.');
      }
    }

    if (weather.humidity > 80) {
      recommendations.general.push('High humidity may make breathing more difficult.');

      if (medicalProfile?.has_respiratory_condition) {
        recommendations.indoor.push('Use dehumidifiers if available to maintain comfortable indoor humidity.');
      }
    }
  }

  // Pollen-based recommendations
  if (pollen && medicalProfile?.has_allergies) {
    const maxPollen = Math.max(
      pollen.treePollen || 0,
      pollen.grassPollen || 0,
      pollen.weedPollen || 0
    );

    if (maxPollen > 4) {
      recommendations.riskLevel = 'High';
      recommendations.precautions.push('High pollen levels detected. Take allergy medications as prescribed.');
      recommendations.outdoor.push('Wear sunglasses and consider a mask when outdoors.');
      recommendations.indoor.push('Keep windows closed and shower after being outdoors.');
    } else if (maxPollen > 2) {
      recommendations.riskLevel = 'Moderate';
      recommendations.general.push('Moderate pollen levels. Allergy sufferers should take precautions.');
    }
  }

  // Exercise recommendations
  if (medicalProfile?.exercises_outdoors) {
    if (airQuality?.aqi > 100 || (pollen && Math.max(pollen.treePollen || 0, pollen.grassPollen || 0, pollen.weedPollen || 0) > 4)) {
      recommendations.outdoor.push('Consider indoor exercise today due to air quality or pollen levels.');
    } else if (weather?.temperature > 28 || weather?.temperature < 5) {
      recommendations.outdoor.push('Exercise during cooler parts of the day or consider indoor alternatives.');
    } else {
      recommendations.outdoor.push('Good conditions for outdoor exercise. Stay hydrated!');
    }
  }

  // Special population recommendations
  if (medicalProfile?.is_pregnant) {
    if (airQuality?.aqi > 100) {
      recommendations.precautions.push('Limit outdoor exposure to protect both maternal and fetal health.');
    }
  }

  if (medicalProfile?.is_child || medicalProfile?.is_elderly) {
    if (airQuality?.aqi > 50 || weather?.temperature > 30 || weather?.temperature < 5) {
      recommendations.general.push('Extra care needed for vulnerable age groups in current conditions.');
    }
  }

  // Calculate final risk level
  const riskLevels = { 'Low': 1, 'Moderate': 2, 'High': 3, 'Very High': 4 };
  const riskValues = Object.keys(riskLevels);
  const currentRiskValue = riskLevels[recommendations.riskLevel] || 1;
  recommendations.riskLevel = riskValues[Math.min(currentRiskValue - 1, 3)];

  return recommendations;
}

// Get health alerts for all user pins
router.get('/alerts', authMiddleware, async (req, res, next) => {
  try {
    const pins = await getAll(
      'SELECT * FROM pins WHERE user_id = ? AND is_active = 1',
      [req.user.id]
    );

    const medicalProfile = await getOne(
      'SELECT * FROM medical_profiles WHERE user_id = ?',
      [req.user.id]
    );

    const alerts = await Promise.all(
      pins.map(async (pin) => {
        try {
          const [airQuality, weather, pollen] = await Promise.all([
            airQualityService.getCurrentAirQuality(pin.latitude, pin.longitude),
            weatherService.getCurrentWeather(pin.latitude, pin.longitude),
            pollenService.getCurrentPollen(pin.latitude, pin.longitude)
          ]);

          const recommendations = generateHealthRecommendations(
            medicalProfile,
            airQuality,
            weather,
            pollen
          );

          const hasAlert = recommendations.riskLevel === 'High' || recommendations.riskLevel === 'Very High';

          return {
            pinId: pin.id,
            pinName: pin.name,
            location: {
              latitude: pin.latitude,
              longitude: pin.longitude
            },
            hasAlert,
            riskLevel: recommendations.riskLevel,
            alerts: hasAlert ? recommendations.precautions : []
          };
        } catch (error) {
          return {
            pinId: pin.id,
            pinName: pin.name,
            hasAlert: false,
            error: 'Unable to fetch data'
          };
        }
      })
    );

    res.json(alerts);
  } catch (error) {
    next(error);
  }
});

module.exports = router;