const axios = require('axios');
const { getOne, runQuery, getAll } = require('../config/database');

class PollenService {
  constructor() {
    this.apiKey = process.env.GOOGLE_MAPS_API_KEY;
    this.baseUrl = 'https://pollen.googleapis.com/v1';
  }

  // Get current pollen data for a location
  async getCurrentPollen(latitude, longitude) {
    try {
      // Check cache first
      const cacheKey = `pollen_${latitude}_${longitude}`;
      const cached = await this.getFromCache(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }

      // Fetch from Google Pollen API
      const response = await axios.get(`${this.baseUrl}/forecast:lookup`, {
        params: {
          key: this.apiKey,
          location: {
            latitude,
            longitude
          },
          days: 1,
          plantsDescription: true
        }
      });

      const data = this.transformPollenData(response.data);

      // Cache the result
      await this.saveToCache(cacheKey, JSON.stringify(data), process.env.POLLEN_CACHE_TTL || 7200);

      return data;
    } catch (error) {
      console.error('Error fetching pollen data:', error);

      // Return last known data if available
      const fallback = await getOne(
        `SELECT * FROM pollen_history
         WHERE pin_id IN (SELECT id FROM pins WHERE latitude = ? AND longitude = ?)
         ORDER BY timestamp DESC LIMIT 1`,
        [latitude, longitude]
      );

      if (fallback) {
        return fallback;
      }

      // Return default data if no API access
      return {
        treePollen: 0,
        grassPollen: 0,
        weedPollen: 0,
        overallRisk: 'Low',
        timestamp: new Date().toISOString(),
        error: 'Pollen data unavailable'
      };
    }
  }

  // Get pollen forecast
  async getPollenForecast(latitude, longitude, days = 5) {
    try {
      const cacheKey = `pollen_forecast_${latitude}_${longitude}_${days}`;
      const cached = await this.getFromCache(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }

      // Fetch from Google Pollen API
      const response = await axios.get(`${this.baseUrl}/forecast:lookup`, {
        params: {
          key: this.apiKey,
          location: {
            latitude,
            longitude
          },
          days: days,
          plantsDescription: true
        }
      });

      const data = this.transformPollenForecast(response.data);

      // Cache the result
      await this.saveToCache(cacheKey, JSON.stringify(data), process.env.POLLEN_CACHE_TTL || 7200);

      return data;
    } catch (error) {
      console.error('Error fetching pollen forecast:', error);

      // Return default forecast
      return {
        daily: Array(days).fill(null).map((_, index) => {
          const date = new Date();
          date.setDate(date.getDate() + index);
          return {
            date: date.toISOString().split('T')[0],
            treePollen: 0,
            grassPollen: 0,
            weedPollen: 0,
            overallRisk: 'Low'
          };
        }),
        error: 'Pollen forecast unavailable'
      };
    }
  }

  // Transform Google Pollen API response to our format
  transformPollenData(data) {
    if (!data.dailyInfo || data.dailyInfo.length === 0) {
      return {
        treePollen: 0,
        grassPollen: 0,
        weedPollen: 0,
        overallRisk: 'Low',
        timestamp: new Date().toISOString()
      };
    }

    const today = data.dailyInfo[0];
    const pollenTypes = today.pollenTypeInfo || [];

    const treePollen = pollenTypes
      .filter(p => p.displayName?.toLowerCase().includes('tree'))
      .reduce((sum, p) => sum + (p.indexInfo?.value || 0), 0);

    const grassPollen = pollenTypes
      .filter(p => p.displayName?.toLowerCase().includes('grass'))
      .reduce((sum, p) => sum + (p.indexInfo?.value || 0), 0);

    const weedPollen = pollenTypes
      .filter(p => p.displayName?.toLowerCase().includes('weed') || p.displayName?.toLowerCase().includes('ragweed'))
      .reduce((sum, p) => sum + (p.indexInfo?.value || 0), 0);

    const maxPollen = Math.max(treePollen, grassPollen, weedPollen);
    const overallRisk = this.getPollenRisk(maxPollen);

    return {
      treePollen,
      grassPollen,
      weedPollen,
      overallRisk,
      plants: pollenTypes.map(p => ({
        name: p.displayName,
        level: p.indexInfo?.value || 0,
        category: p.indexInfo?.category || 'None',
        inSeason: p.inSeason || false
      })),
      timestamp: new Date().toISOString()
    };
  }

  // Transform pollen forecast data
  transformPollenForecast(data) {
    if (!data.dailyInfo) {
      return { daily: [] };
    }

    const daily = data.dailyInfo.map(day => {
      const pollenTypes = day.pollenTypeInfo || [];

      const treePollen = pollenTypes
        .filter(p => p.displayName?.toLowerCase().includes('tree'))
        .reduce((sum, p) => sum + (p.indexInfo?.value || 0), 0);

      const grassPollen = pollenTypes
        .filter(p => p.displayName?.toLowerCase().includes('grass'))
        .reduce((sum, p) => sum + (p.indexInfo?.value || 0), 0);

      const weedPollen = pollenTypes
        .filter(p => p.displayName?.toLowerCase().includes('weed') || p.displayName?.toLowerCase().includes('ragweed'))
        .reduce((sum, p) => sum + (p.indexInfo?.value || 0), 0);

      const maxPollen = Math.max(treePollen, grassPollen, weedPollen);

      return {
        date: day.date,
        treePollen,
        grassPollen,
        weedPollen,
        overallRisk: this.getPollenRisk(maxPollen),
        plants: pollenTypes.map(p => ({
          name: p.displayName,
          level: p.indexInfo?.value || 0,
          category: p.indexInfo?.category || 'None'
        }))
      };
    });

    return { daily };
  }

  // Get pollen risk level based on index
  getPollenRisk(index) {
    if (index <= 2) return 'Low';
    if (index <= 4) return 'Moderate';
    if (index <= 6) return 'High';
    return 'Very High';
  }

  // Store pollen data in history
  async storePollenHistory(pinId, data) {
    try {
      await runQuery(
        `INSERT INTO pollen_history
         (pin_id, tree_pollen, grass_pollen, weed_pollen, overall_risk, timestamp)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [
          pinId,
          data.treePollen,
          data.grassPollen,
          data.weedPollen,
          data.overallRisk,
          data.timestamp || new Date().toISOString()
        ]
      );
    } catch (error) {
      console.error('Error storing pollen history:', error);
    }
  }

  // Get historical pollen data for a pin
  async getPollenHistory(pinId, days = 7) {
    try {
      const history = await getAll(
        `SELECT * FROM pollen_history
         WHERE pin_id = ?
         AND timestamp > datetime('now', '-${days} days')
         ORDER BY timestamp DESC`,
        [pinId]
      );

      return history;
    } catch (error) {
      console.error('Error fetching pollen history:', error);
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
}

module.exports = new PollenService();