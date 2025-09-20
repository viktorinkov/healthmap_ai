const axios = require('axios');
const { getOne, runQuery } = require('../config/database');

class AirQualityService {
  constructor() {
    this.apiKey = process.env.GOOGLE_MAPS_API_KEY;
    this.baseUrl = 'https://airquality.googleapis.com/v1';
  }

  // Get current air quality data for a location
  async getCurrentAirQuality(latitude, longitude) {
    try {
      // Check cache first
      const cacheKey = `aqi_${latitude}_${longitude}`;
      const cached = await this.getFromCache(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }

      // Fetch from Google Air Quality API
      const response = await axios.post(
        `${this.baseUrl}/currentConditions:lookup?key=${this.apiKey}`,
        {
          location: {
            latitude,
            longitude
          },
          extraComputations: [
            'HEALTH_RECOMMENDATIONS',
            'DOMINANT_POLLUTANT_CONCENTRATION',
            'POLLUTANT_CONCENTRATION',
            'LOCAL_AQI',
            'POLLUTANT_ADDITIONAL_INFO'
          ],
          languageCode: 'en',
          customLocalAqis: [
            {
              regionCode: 'US',
              aqi: 'US_EPA'
            }
          ]
        }
      );

      const data = this.transformAirQualityData(response.data);

      // Cache the result
      await this.saveToCache(cacheKey, JSON.stringify(data), process.env.AIR_QUALITY_CACHE_TTL || 1800);

      return data;
    } catch (error) {
      console.error('Error fetching air quality:', error);

      // Return last known data if available
      const fallback = await getOne(
        `SELECT * FROM air_quality_history
         WHERE pin_id IN (SELECT id FROM pins WHERE latitude = ? AND longitude = ?)
         ORDER BY timestamp DESC LIMIT 1`,
        [latitude, longitude]
      );

      if (fallback) {
        return fallback;
      }

      throw error;
    }
  }

  // Transform Google Air Quality API response to our format
  transformAirQualityData(data) {
    const indexes = data.indexes || [];
    const usAqi = indexes.find(idx => idx.code === 'uaqi') || indexes[0];
    const pollutants = data.pollutants || [];

    // Extract pollutant concentrations
    const pollutantData = {};
    pollutants.forEach(pollutant => {
      const concentration = pollutant.concentration;
      switch (pollutant.code) {
        case 'pm25':
          pollutantData.pm25 = concentration?.value || 0;
          break;
        case 'pm10':
          pollutantData.pm10 = concentration?.value || 0;
          break;
        case 'o3':
          pollutantData.o3 = concentration?.value || 0;
          break;
        case 'no2':
          pollutantData.no2 = concentration?.value || 0;
          break;
        case 'so2':
          pollutantData.so2 = concentration?.value || 0;
          break;
        case 'co':
          pollutantData.co = concentration?.value || 0;
          break;
      }
    });

    // Determine AQI category and color
    const aqi = usAqi?.aqiDisplay || usAqi?.aqi || 0;
    const { category, color } = this.getAQICategory(aqi);

    return {
      aqi,
      category,
      color,
      ...pollutantData,
      dominantPollutant: usAqi?.dominantPollutant || 'pm25',
      healthRecommendations: data.healthRecommendations,
      timestamp: new Date().toISOString()
    };
  }

  // Get AQI category and color based on value
  getAQICategory(aqi) {
    if (aqi <= 50) {
      return { category: 'Good', color: '#00e400' };
    } else if (aqi <= 100) {
      return { category: 'Moderate', color: '#ffff00' };
    } else if (aqi <= 150) {
      return { category: 'Unhealthy for Sensitive Groups', color: '#ff7e00' };
    } else if (aqi <= 200) {
      return { category: 'Unhealthy', color: '#ff0000' };
    } else if (aqi <= 300) {
      return { category: 'Very Unhealthy', color: '#8f3f97' };
    } else {
      return { category: 'Hazardous', color: '#7e0023' };
    }
  }

  // Store air quality data in history
  async storeAirQualityHistory(pinId, data) {
    try {
      await runQuery(
        `INSERT INTO air_quality_history
         (pin_id, aqi, pm25, pm10, o3, no2, so2, co, category, color, timestamp)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          pinId,
          data.aqi,
          data.pm25,
          data.pm10,
          data.o3,
          data.no2,
          data.so2,
          data.co,
          data.category,
          data.color,
          data.timestamp || new Date().toISOString()
        ]
      );
    } catch (error) {
      console.error('Error storing air quality history:', error);
    }
  }

  // Get historical air quality data for a pin
  async getAirQualityHistory(pinId, days = 7) {
    try {
      const history = await getAll(
        `SELECT * FROM air_quality_history
         WHERE pin_id = ?
         AND timestamp > datetime('now', '-${days} days')
         ORDER BY timestamp DESC`,
        [pinId]
      );

      return history;
    } catch (error) {
      console.error('Error fetching air quality history:', error);
      return [];
    }
  }

  // Cache management
  async getFromCache(key) {
    try {
      const cached = await getOne(
        'SELECT data FROM api_cache WHERE cache_key = ? AND expires_at > datetime("now")',
        [key]
      );
      return cached?.data;
    } catch (error) {
      return null;
    }
  }

  async saveToCache(key, data, ttlSeconds) {
    try {
      const expiresAt = new Date();
      expiresAt.setSeconds(expiresAt.getSeconds() + ttlSeconds);

      // Delete existing cache entry if exists
      await runQuery('DELETE FROM api_cache WHERE cache_key = ?', [key]);

      // Insert new cache entry
      await runQuery(
        'INSERT INTO api_cache (cache_key, data, expires_at) VALUES (?, ?, ?)',
        [key, data, expiresAt.toISOString()]
      );
    } catch (error) {
      console.error('Error saving to cache:', error);
    }
  }

  // Clean expired cache entries
  async cleanExpiredCache() {
    try {
      await runQuery('DELETE FROM api_cache WHERE expires_at < datetime("now")');
    } catch (error) {
      console.error('Error cleaning cache:', error);
    }
  }
}

module.exports = new AirQualityService();