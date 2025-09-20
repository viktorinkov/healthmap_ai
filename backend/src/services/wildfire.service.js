const axios = require('axios');
const { getOne, runQuery, getAll } = require('../config/database');

class WildfireService {
  constructor() {
    // NASA FIRMS API - no key required for basic access
    this.firmsBaseUrl = 'https://firms.modaps.eosdis.nasa.gov/mapserver/wfs/fires';
    // Alternative: USGS API for active wildfires
    this.usgsBaseUrl = 'https://services9.arcgis.com/RHVPKKiFTONKtxq3/arcgis/rest/services';
  }

  // Get wildfire data within radius of location
  async getWildfireData(latitude, longitude, radiusKm = 100) {
    try {
      // Check cache first
      const cacheKey = `wildfire_${latitude}_${longitude}_${radiusKm}`;
      const cached = await this.getFromCache(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }

      // Get active fires from NASA FIRMS
      const fires = await this.getFIRMSData(latitude, longitude, radiusKm);

      // Calculate wildfire risk and smoke impact
      const wildfireData = this.calculateWildfireRisk(fires, latitude, longitude);

      // Cache the result (shorter TTL for wildfire data)
      await this.saveToCache(cacheKey, JSON.stringify(wildfireData), 3600); // 1 hour

      return wildfireData;
    } catch (error) {
      console.error('Error fetching wildfire data:', error);

      // Return last known data if available
      const fallback = await this.getLastKnownData(latitude, longitude);
      if (fallback) {
        return fallback;
      }

      // Return default data structure
      return {
        riskLevel: 'Unknown',
        nearbyFires: 0,
        closestFireDistance: null,
        smokeImpact: 'No data available',
        airQualityImpact: 'Unknown',
        recommendations: ['Wildfire data unavailable'],
        fires: [],
        timestamp: new Date().toISOString(),
        error: 'Wildfire data unavailable'
      };
    }
  }

  // Fetch data from NASA FIRMS
  async getFIRMSData(latitude, longitude, radiusKm) {
    try {
      // FIRMS WFS service for MODIS active fires (last 24 hours)
      const bbox = this.calculateBoundingBox(latitude, longitude, radiusKm);

      const response = await axios.get(this.firmsBaseUrl, {
        params: {
          service: 'WFS',
          version: '1.1.0',
          request: 'GetFeature',
          typeName: 'ms:fires_modis_24hrs',
          outputFormat: 'json',
          bbox: `${bbox.west},${bbox.south},${bbox.east},${bbox.north}`,
          srsName: 'EPSG:4326'
        },
        timeout: 10000
      });

      if (response.data && response.data.features) {
        return response.data.features.map(feature => ({
          latitude: feature.geometry.coordinates[1],
          longitude: feature.geometry.coordinates[0],
          brightness: feature.properties.brightness || 0,
          confidence: feature.properties.confidence || 0,
          frp: feature.properties.frp || 0, // Fire Radiative Power
          acq_date: feature.properties.acq_date,
          acq_time: feature.properties.acq_time,
          satellite: feature.properties.satellite || 'MODIS',
          distance: this.calculateDistance(
            latitude, longitude,
            feature.geometry.coordinates[1],
            feature.geometry.coordinates[0]
          )
        }));
      }

      return [];
    } catch (error) {
      console.error('FIRMS API error:', error.message);

      // Try alternative USGS data source
      return await this.getUSGSWildfireData(latitude, longitude, radiusKm);
    }
  }

  // Alternative: USGS wildfire data
  async getUSGSWildfireData(latitude, longitude, radiusKm) {
    try {
      const bbox = this.calculateBoundingBox(latitude, longitude, radiusKm);

      const response = await axios.get(
        `${this.usgsBaseUrl}/USA_Wildfires_v1/FeatureServer/0/query`,
        {
          params: {
            f: 'json',
            where: '1=1',
            geometry: `${bbox.west},${bbox.south},${bbox.east},${bbox.north}`,
            geometryType: 'esriGeometryEnvelope',
            spatialRel: 'esriSpatialRelIntersects',
            outFields: '*',
            returnGeometry: true
          },
          timeout: 10000
        }
      );

      if (response.data && response.data.features) {
        return response.data.features.map(feature => ({
          latitude: feature.geometry.y,
          longitude: feature.geometry.x,
          name: feature.attributes.IncidentName || 'Unknown Fire',
          acres: feature.attributes.DailyAcres || 0,
          containment: feature.attributes.PercentContained || 0,
          startDate: feature.attributes.FireDiscoveryDateTime,
          status: feature.attributes.IncidentTypeCategory || 'Unknown',
          distance: this.calculateDistance(
            latitude, longitude,
            feature.geometry.y,
            feature.geometry.x
          )
        }));
      }

      return [];
    } catch (error) {
      console.error('USGS API error:', error.message);
      return [];
    }
  }

  // Calculate wildfire risk based on nearby fires
  calculateWildfireRisk(fires, userLat, userLon) {
    if (!fires || fires.length === 0) {
      return {
        riskLevel: 'Low',
        nearbyFires: 0,
        closestFireDistance: null,
        smokeImpact: 'Minimal',
        airQualityImpact: 'No significant impact expected',
        recommendations: ['No active wildfires detected in your area'],
        fires: [],
        timestamp: new Date().toISOString()
      };
    }

    // Sort fires by distance
    const sortedFires = fires.sort((a, b) => a.distance - b.distance);
    const closestFire = sortedFires[0];
    const firesWithin50km = fires.filter(f => f.distance <= 50);
    const firesWithin100km = fires.filter(f => f.distance <= 100);

    // Calculate risk level
    let riskLevel = 'Low';
    let smokeImpact = 'Minimal';
    let airQualityImpact = 'No significant impact expected';
    const recommendations = [];

    if (closestFire.distance <= 10) {
      riskLevel = 'Critical';
      smokeImpact = 'Severe';
      airQualityImpact = 'Very unhealthy air quality likely';
      recommendations.push('Immediate evacuation may be necessary');
      recommendations.push('Stay indoors with windows closed');
      recommendations.push('Use air purifiers if available');
    } else if (closestFire.distance <= 25) {
      riskLevel = 'High';
      smokeImpact = 'Heavy';
      airQualityImpact = 'Unhealthy air quality expected';
      recommendations.push('Avoid outdoor activities');
      recommendations.push('Keep windows closed');
      recommendations.push('Monitor evacuation alerts');
    } else if (closestFire.distance <= 50) {
      riskLevel = 'Moderate';
      smokeImpact = 'Moderate';
      airQualityImpact = 'Air quality may be affected';
      recommendations.push('Limit outdoor activities, especially for sensitive groups');
      recommendations.push('Monitor air quality conditions');
    } else if (closestFire.distance <= 100) {
      riskLevel = 'Low';
      smokeImpact = 'Light';
      airQualityImpact = 'Minor air quality impacts possible';
      recommendations.push('Monitor wildfire conditions');
      recommendations.push('Be prepared for changing conditions');
    }

    return {
      riskLevel,
      nearbyFires: fires.length,
      firesWithin50km: firesWithin50km.length,
      firesWithin100km: firesWithin100km.length,
      closestFireDistance: Math.round(closestFire.distance * 10) / 10,
      smokeImpact,
      airQualityImpact,
      recommendations,
      fires: sortedFires.slice(0, 10), // Limit to 10 closest fires
      timestamp: new Date().toISOString()
    };
  }

  // Calculate bounding box around point
  calculateBoundingBox(lat, lon, radiusKm) {
    const earthRadius = 6371; // km
    const latDelta = (radiusKm / earthRadius) * (180 / Math.PI);
    const lonDelta = (radiusKm / earthRadius) * (180 / Math.PI) / Math.cos(lat * Math.PI / 180);

    return {
      north: lat + latDelta,
      south: lat - latDelta,
      east: lon + lonDelta,
      west: lon - lonDelta
    };
  }

  // Calculate distance between two points in kilometers
  calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Earth's radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
              Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
              Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
  }

  // Store wildfire data in history
  async storeWildfireHistory(pinId, data) {
    try {
      await runQuery(
        `INSERT INTO wildfire_history
         (pin_id, risk_level, nearby_fires, closest_fire_distance, smoke_impact, timestamp)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [
          pinId,
          data.riskLevel,
          data.nearbyFires,
          data.closestFireDistance,
          data.smokeImpact,
          data.timestamp || new Date().toISOString()
        ]
      );
    } catch (error) {
      console.error('Error storing wildfire history:', error);
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

      await runQuery('DELETE FROM api_cache WHERE cache_key = ?', [key]);
      await runQuery(
        'INSERT INTO api_cache (cache_key, data, expires_at) VALUES (?, ?, ?)',
        [key, data, expiresAt.toISOString()]
      );
    } catch (error) {
      console.error('Error saving to cache:', error);
    }
  }

  async getLastKnownData(latitude, longitude) {
    try {
      const data = await getOne(
        `SELECT * FROM wildfire_history
         WHERE pin_id IN (SELECT id FROM pins WHERE latitude = ? AND longitude = ?)
         ORDER BY timestamp DESC LIMIT 1`,
        [latitude, longitude]
      );
      return data;
    } catch (error) {
      return null;
    }
  }
}

module.exports = new WildfireService();