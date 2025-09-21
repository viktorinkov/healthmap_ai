const axios = require('axios');
const { getOne, runQuery, getAll } = require('../config/database');

class WildfireService {
  constructor() {
    // NASA FIRMS API v4 - requires free MAP_KEY
    this.firmsBaseUrl = 'https://firms.modaps.eosdis.nasa.gov/api/area/csv';
    // Get your free MAP_KEY at: https://firms.modaps.eosdis.nasa.gov/api/
    // Set environment variable: FIRMS_MAP_KEY=your_key_here
    this.firmsMapKey = process.env.FIRMS_MAP_KEY || null;
  }

  // Get count of fires within 100km
  async getWildfireData(latitude, longitude, radiusKm = 100) {
    try {
      // Check cache first
      const cacheKey = `wildfire_count_${latitude}_${longitude}_${radiusKm}`;
      const cached = await this.getFromCache(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }

      // Try to get active fires from NASA FIRMS first
      let fires = await this.getFIRMSData(latitude, longitude, radiusKm);

      // If FIRMS fails or returns no data, try USGS as backup
      if (!fires || fires.length === 0) {
        console.log('No FIRMS data available, trying USGS fallback...');
        fires = await this.getUSGSWildfireData(latitude, longitude, radiusKm);
      }

      // Filter fires within the specified radius and count them
      const firesWithin100km = fires.filter(fire => fire.distance <= radiusKm);

      const wildfireData = {
        fireCount: firesWithin100km.length,
        timestamp: new Date().toISOString()
      };

      // Cache the result (shorter TTL for wildfire data)
      await this.saveToCache(cacheKey, JSON.stringify(wildfireData), 3600); // 1 hour

      return wildfireData;
    } catch (error) {
      console.error('Error fetching wildfire data:', error);

      // Return a safe default response indicating service issues
      return {
        fireCount: 0,
        timestamp: new Date().toISOString(),
        error: 'Unable to fetch wildfire data at this time'
      };
    }
  }

  // Fetch data from NASA FIRMS
  async getFIRMSData(latitude, longitude, radiusKm) {
    try {
      // Check if we have a MAP_KEY
      if (!this.firmsMapKey) {
        console.log('No FIRMS MAP_KEY available, falling back to USGS data');
        return await this.getUSGSWildfireData(latitude, longitude, radiusKm);
      }

      // Calculate bounding box for the area
      const bbox = this.calculateBoundingBox(latitude, longitude, radiusKm);
      const areaCoords = `${bbox.west},${bbox.south},${bbox.east},${bbox.north}`;

      // FIRMS API v4 endpoint: /api/area/csv/[MAP_KEY]/[SOURCE]/[AREA_COORDINATES]/[DAY_RANGE]
      const source = 'VIIRS_SNPP_NRT'; // Use VIIRS for better coverage
      const dayRange = 1; // Last 24 hours
      
      const firmUrl = `${this.firmsBaseUrl}/${this.firmsMapKey}/${source}/${areaCoords}/${dayRange}`;

      const response = await axios.get(firmUrl, {
        timeout: 10000,
        headers: {
          'Accept': 'text/csv'
        }
      });

      if (response.data) {
        // Parse CSV response
        return this.parseFIRMSCSV(response.data, latitude, longitude);
      }

      return [];
    } catch (error) {
      console.error('FIRMS API error:', error.message);

      // Try alternative USGS data source
      return await this.getUSGSWildfireData(latitude, longitude, radiusKm);
    }
  }

  // Parse CSV response from FIRMS API
  parseFIRMSCSV(csvData, userLat, userLon) {
    try {
      const lines = csvData.split('\n');
      if (lines.length <= 1) return []; // No data or header only

      const headers = lines[0].split(',');
      const fires = [];

      for (let i = 1; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line) continue;

        const values = line.split(',');
        if (values.length < headers.length) continue;

        // Create object from CSV row
        const fireData = {};
        headers.forEach((header, index) => {
          fireData[header.trim()] = values[index]?.trim();
        });

        // Extract relevant fields (VIIRS/MODIS have different column names)
        const lat = parseFloat(fireData.latitude || fireData.lat);
        const lon = parseFloat(fireData.longitude || fireData.lon);
        
        if (isNaN(lat) || isNaN(lon)) continue;

        const fire = {
          latitude: lat,
          longitude: lon,
          brightness: parseFloat(fireData.brightness || fireData.bright_ti4 || fireData.bright_ti5 || 0),
          confidence: parseFloat(fireData.confidence || 0),
          frp: parseFloat(fireData.frp || 0), // Fire Radiative Power
          acq_date: fireData.acq_date,
          acq_time: fireData.acq_time,
          satellite: fireData.satellite || fireData.instrument || 'VIIRS',
          distance: this.calculateDistance(userLat, userLon, lat, lon)
        };

        fires.push(fire);
      }

      return fires;
    } catch (error) {
      console.error('Error parsing FIRMS CSV:', error);
      return [];
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

  // Store wildfire count in history
  async storeWildfireHistory(pinId, data) {
    try {
      await runQuery(
        `INSERT INTO wildfire_history
         (pin_id, nearby_fires, timestamp)
         VALUES (?, ?, ?)`,
        [
          pinId,
          data.fireCount,
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