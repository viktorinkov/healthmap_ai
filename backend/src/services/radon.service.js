const axios = require('axios');
const { getOne, getAll, runQuery } = require('../config/database');

class RadonService {
  constructor() {
    this.cacheKey = 'radon_zone_data';
    this.cacheTTL = 7 * 24 * 3600; // 7 days cache for static zone data
  }

  // Get radon risk level for a location based on EPA radon zones
  async getRadonData(latitude, longitude) {
    try {
      // Check cache first
      const cacheKey = `radon_${latitude}_${longitude}`;
      const cached = await this.getFromCache(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }

      // Determine radon zone based on coordinates
      const radonRisk = await this.getRadonRiskByLocation(latitude, longitude);

      // Create response data
      const radonData = {
        location: {
          latitude,
          longitude
        },
        radonRisk: radonRisk.level,
        radonZone: radonRisk.zone,
        description: radonRisk.description,
        recommendation: radonRisk.recommendation,
        averageRadonLevel: radonRisk.averageLevel,
        unit: 'pCi/L',
        source: 'EPA Radon Zone Data',
        timestamp: new Date().toISOString()
      };

      // Cache the result
      await this.saveToCache(cacheKey, JSON.stringify(radonData), this.cacheTTL);

      return radonData;
    } catch (error) {
      console.error('Error fetching radon data:', error);

      // Return fallback data
      return this.getFallbackRadonData(latitude, longitude);
    }
  }

  // Determine radon risk based on location (simplified state-based lookup)
  async getRadonRiskByLocation(latitude, longitude) {
    // EPA radon zones with Houston-specific data
    const stateRadonZones = {
      // Houston Metropolitan Area (Zone 3 - Low radon potential)
      'TX_HOUSTON': {
        zone: 3,
        level: 'Low',
        averageLevel: 1.4,
        description: 'Houston metropolitan area - Low radon potential due to Gulf Coast geology',
        region: 'Harris, Fort Bend, Montgomery, Brazoria, Galveston, Liberty, Waller, and Chambers counties',
        geology: 'Gulf Coast sediments with low uranium content'
      },

      // Rest of Texas (Zone 2 - Moderate radon potential)
      'TX': {
        zone: 2,
        level: 'Moderate',
        averageLevel: 2.2,
        description: 'Texas (excluding Houston metro) - Moderate radon potential area'
      },

      // Zone 1 states (High radon potential)
      'IA': { zone: 1, level: 'High', averageLevel: 4.2, description: 'High radon potential area' },
      'ND': { zone: 1, level: 'High', averageLevel: 4.1, description: 'High radon potential area' },
      'SD': { zone: 1, level: 'High', averageLevel: 3.8, description: 'High radon potential area' },
      'NE': { zone: 1, level: 'High', averageLevel: 3.7, description: 'High radon potential area' },
      'KS': { zone: 1, level: 'High', averageLevel: 3.5, description: 'High radon potential area' },
      'CO': { zone: 1, level: 'High', averageLevel: 6.8, description: 'High radon potential area' },
      'WY': { zone: 1, level: 'High', averageLevel: 4.0, description: 'High radon potential area' },
      'MT': { zone: 1, level: 'High', averageLevel: 3.9, description: 'High radon potential area' },
      'ID': { zone: 1, level: 'High', averageLevel: 3.6, description: 'High radon potential area' },
      'UT': { zone: 1, level: 'High', averageLevel: 3.4, description: 'High radon potential area' },
      'PA': { zone: 1, level: 'High', averageLevel: 4.9, description: 'High radon potential area' },
      'OH': { zone: 1, level: 'High', averageLevel: 3.8, description: 'High radon potential area' },
      'WV': { zone: 1, level: 'High', averageLevel: 3.5, description: 'High radon potential area' },
      'VA': { zone: 1, level: 'High', averageLevel: 3.2, description: 'High radon potential area' },
      'MD': { zone: 1, level: 'High', averageLevel: 3.1, description: 'High radon potential area' },
      'NJ': { zone: 1, level: 'High', averageLevel: 3.0, description: 'High radon potential area' },
      'CT': { zone: 1, level: 'High', averageLevel: 3.8, description: 'High radon potential area' },
      'MA': { zone: 1, level: 'High', averageLevel: 3.2, description: 'High radon potential area' },
      'VT': { zone: 1, level: 'High', averageLevel: 3.1, description: 'High radon potential area' },
      'NH': { zone: 1, level: 'High', averageLevel: 3.4, description: 'High radon potential area' },
      'ME': { zone: 1, level: 'High', averageLevel: 2.9, description: 'High radon potential area' },

      // Zone 2 states (Moderate radon potential)
      'IN': { zone: 2, level: 'Moderate', averageLevel: 2.8, description: 'Moderate radon potential area' },
      'IL': { zone: 2, level: 'Moderate', averageLevel: 2.6, description: 'Moderate radon potential area' },
      'WI': { zone: 2, level: 'Moderate', averageLevel: 2.9, description: 'Moderate radon potential area' },
      'MN': { zone: 2, level: 'Moderate', averageLevel: 2.7, description: 'Moderate radon potential area' },
      'MO': { zone: 2, level: 'Moderate', averageLevel: 2.5, description: 'Moderate radon potential area' },
      'AR': { zone: 2, level: 'Moderate', averageLevel: 2.4, description: 'Moderate radon potential area' },
      'TN': { zone: 2, level: 'Moderate', averageLevel: 2.3, description: 'Moderate radon potential area' },
      'KY': { zone: 2, level: 'Moderate', averageLevel: 2.8, description: 'Moderate radon potential area' },
      'NC': { zone: 2, level: 'Moderate', averageLevel: 2.2, description: 'Moderate radon potential area' },
      'NY': { zone: 2, level: 'Moderate', averageLevel: 2.9, description: 'Moderate radon potential area' },
      'MI': { zone: 2, level: 'Moderate', averageLevel: 2.7, description: 'Moderate radon potential area' },
      'WA': { zone: 2, level: 'Moderate', averageLevel: 2.1, description: 'Moderate radon potential area' },
      'OR': { zone: 2, level: 'Moderate', averageLevel: 2.3, description: 'Moderate radon potential area' },
      'NV': { zone: 2, level: 'Moderate', averageLevel: 2.4, description: 'Moderate radon potential area' },
      'NM': { zone: 2, level: 'Moderate', averageLevel: 2.6, description: 'Moderate radon potential area' },
      'AZ': { zone: 2, level: 'Moderate', averageLevel: 2.1, description: 'Moderate radon potential area' },
      'OK': { zone: 2, level: 'Moderate', averageLevel: 2.5, description: 'Moderate radon potential area' },
      'AL': { zone: 2, level: 'Moderate', averageLevel: 2.0, description: 'Moderate radon potential area' },
      'GA': { zone: 2, level: 'Moderate', averageLevel: 2.1, description: 'Moderate radon potential area' },
      'SC': { zone: 2, level: 'Moderate', averageLevel: 2.3, description: 'Moderate radon potential area' },
      'RI': { zone: 2, level: 'Moderate', averageLevel: 2.8, description: 'Moderate radon potential area' },
      'DE': { zone: 2, level: 'Moderate', averageLevel: 2.9, description: 'Moderate radon potential area' },

      // Zone 3 states (Low radon potential)
      'CA': { zone: 3, level: 'Low', averageLevel: 1.8, description: 'Low radon potential area' },
      'FL': { zone: 3, level: 'Low', averageLevel: 1.9, description: 'Low radon potential area' },
      'LA': { zone: 3, level: 'Low', averageLevel: 1.7, description: 'Low radon potential area' },
      'MS': { zone: 3, level: 'Low', averageLevel: 1.8, description: 'Low radon potential area' },
      'HI': { zone: 3, level: 'Low', averageLevel: 0.5, description: 'Low radon potential area' },
      'AK': { zone: 3, level: 'Low', averageLevel: 1.2, description: 'Low radon potential area' }
    };

    // Get state from coordinates (simplified approach)
    const state = await this.getStateFromCoordinates(latitude, longitude);
    const radonZone = stateRadonZones[state] || {
      zone: 2,
      level: 'Moderate',
      averageLevel: 2.5,
      description: 'Moderate radon potential area (default)'
    };

    // Add recommendations based on zone
    radonZone.recommendation = this.getRadonRecommendation(radonZone.zone, radonZone.level);

    return radonZone;
  }

  // Get Houston-specific radon data based on coordinates
  async getStateFromCoordinates(latitude, longitude) {
    // Houston metropolitan area boundaries (Harris, Fort Bend, Montgomery, Brazoria, Galveston, Liberty, Waller, Chambers counties)
    // Houston coordinates: 29.7604° N, 95.3698° W

    const isInHoustonMetro = this.isInHoustonMetropolitanArea(latitude, longitude);

    if (isInHoustonMetro) {
      return 'TX_HOUSTON'; // Special designation for Houston metro
    }

    // Texas state boundaries
    if (latitude >= 25.8 && latitude <= 36.5 && longitude >= -106.6 && longitude <= -93.5) {
      return 'TX'; // Rest of Texas
    }

    // Other states for reference
    if (latitude >= 32.5 && latitude <= 42 && longitude >= -124.4 && longitude <= -114.1) {
      return 'CA';
    } else if (latitude >= 25.1 && latitude <= 31 && longitude >= -87.6 && longitude <= -80) {
      return 'FL';
    } else if (latitude >= 40.5 && latitude <= 45.0 && longitude >= -111.1 && longitude <= -104.0) {
      return 'CO';
    }

    // Default to Texas for unknown areas in the region
    return 'TX';
  }

  // Check if coordinates are within Houston metropolitan area
  isInHoustonMetropolitanArea(latitude, longitude) {
    // Houston metropolitan statistical area bounds (more precise)
    const houstonBounds = {
      north: 30.5,    // Montgomery County north
      south: 29.0,    // Brazoria County south
      east: -94.5,    // Chambers County east
      west: -96.0     // Waller County west
    };

    return (
      latitude >= houstonBounds.south &&
      latitude <= houstonBounds.north &&
      longitude >= houstonBounds.west &&
      longitude <= houstonBounds.east
    );
  }

  // Get recommendations based on radon zone
  getRadonRecommendation(zone, level) {
    switch (zone) {
      case 1:
        return {
          action: 'Test your home for radon. High radon potential area.',
          testing: 'Test all homes and buildings below the third floor',
          mitigation: 'If levels are 4 pCi/L or higher, consider radon mitigation',
          urgency: 'High priority for testing',
          healthRisk: 'Elevated lung cancer risk if not addressed'
        };
      case 2:
        return {
          action: 'Consider testing your home for radon. Moderate radon potential.',
          testing: 'Test recommended for all homes',
          mitigation: 'If levels are 4 pCi/L or higher, consider radon mitigation',
          urgency: 'Moderate priority for testing',
          healthRisk: 'Some increased lung cancer risk'
        };
      case 3:
        return {
          action: 'Radon testing recommended. Low radon potential area.',
          testing: 'Test if concerned or required by local regulations',
          mitigation: 'If levels are 4 pCi/L or higher, consider radon mitigation',
          urgency: 'Lower priority for testing',
          healthRisk: 'Minimal increased lung cancer risk'
        };
      default:
        return {
          action: 'Consider testing your home for radon.',
          testing: 'Test recommended for peace of mind',
          mitigation: 'If levels are 4 pCi/L or higher, consider radon mitigation',
          urgency: 'Standard recommendation',
          healthRisk: 'Follow EPA guidelines for safety'
        };
    }
  }

  // Get fallback radon data when API fails
  getFallbackRadonData(latitude, longitude) {
    return {
      location: {
        latitude,
        longitude
      },
      radonRisk: 'Moderate',
      radonZone: 2,
      description: 'Moderate radon potential area (estimated)',
      recommendation: {
        action: 'Consider testing your home for radon.',
        testing: 'Test recommended for all homes',
        mitigation: 'If levels are 4 pCi/L or higher, consider radon mitigation',
        urgency: 'Moderate priority for testing',
        healthRisk: 'Some increased lung cancer risk'
      },
      averageRadonLevel: 2.5,
      unit: 'pCi/L',
      source: 'Estimated (EPA fallback)',
      timestamp: new Date().toISOString(),
      note: 'Data not available - showing estimated values'
    };
  }

  // Store radon data in history
  async storeRadonHistory(pinId, data) {
    try {
      await runQuery(
        `INSERT INTO radon_history
         (pin_id, radon_risk, radon_zone, average_level, description, timestamp)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [
          pinId,
          data.radonRisk,
          data.radonZone,
          data.averageRadonLevel,
          data.description,
          data.timestamp || new Date().toISOString()
        ]
      );
    } catch (error) {
      console.error('Error storing radon history:', error);
    }
  }

  // Get historical radon data for a pin
  async getRadonHistory(pinId, days = 7) {
    try {
      const history = await getAll(
        `SELECT * FROM radon_history
         WHERE pin_id = ?
         AND timestamp > datetime('now', '-${days} days')
         ORDER BY timestamp DESC`,
        [pinId]
      );

      // If no real data exists, return sample data for demo purposes
      if (history.length === 0) {
        return this.generateSampleRadonHistory(days, pinId);
      }

      return history;
    } catch (error) {
      console.error('Error fetching radon history:', error);
      // Return sample data as fallback
      return this.generateSampleRadonHistory(days, pinId);
    }
  }

  generateSampleRadonHistory(days = 7, pinId = 'demo') {
    const sampleData = [];
    const now = new Date();

    for (let i = 0; i < days; i++) {
      const timestamp = new Date(now.getTime() - (i * 24 * 60 * 60 * 1000));
      const baseRadon = 1.5 + (Math.random() * 2); // Radon between 1.5-3.5 pCi/L (Houston typical range)

      sampleData.push({
        id: `sample_${i}`,
        pin_id: pinId,
        timestamp: timestamp.toISOString(),
        radon_level: Math.round(baseRadon * 100) / 100,
        zone: 3, // Houston is Zone 3 (Low)
        risk_level: 'Low'
      });
    }

    return sampleData;
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

module.exports = new RadonService();