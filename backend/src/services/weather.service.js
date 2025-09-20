const axios = require('axios');
const { getOne, runQuery, getAll } = require('../config/database');

class WeatherService {
  constructor() {
    this.apiKey = process.env.OPENWEATHER_API_KEY;
    this.baseUrl = 'https://api.openweathermap.org/data/2.5';
  }

  // Get current weather data for a location
  async getCurrentWeather(latitude, longitude) {
    try {
      // Check cache first
      const cacheKey = `weather_${latitude}_${longitude}`;
      const cached = await this.getFromCache(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }

      // Fetch both current weather and UV data in parallel
      const [weatherResponse, uvResponse] = await Promise.all([
        axios.get(`${this.baseUrl}/weather`, {
          params: {
            lat: latitude,
            lon: longitude,
            appid: this.apiKey,
            units: 'metric'
          }
        }),
        axios.get(`${this.baseUrl}/uvi`, {
          params: {
            lat: latitude,
            lon: longitude,
            appid: this.apiKey
          }
        }).catch(() => null) // UV data might not be available
      ]);

      const data = this.transformWeatherData(weatherResponse.data, uvResponse?.data);

      // Cache the result
      await this.saveToCache(cacheKey, JSON.stringify(data), process.env.WEATHER_CACHE_TTL || 3600);

      return data;
    } catch (error) {
      console.error('Error fetching weather:', error);

      // Return last known data if available
      const fallback = await getOne(
        `SELECT * FROM weather_history
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

  // Get weather forecast
  async getWeatherForecast(latitude, longitude, days = 5) {
    try {
      const cacheKey = `forecast_${latitude}_${longitude}_${days}`;
      const cached = await this.getFromCache(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }

      // Fetch forecast from OpenWeather API
      const response = await axios.get(`${this.baseUrl}/forecast`, {
        params: {
          lat: latitude,
          lon: longitude,
          appid: this.apiKey,
          units: 'metric',
          cnt: days * 8 // 8 data points per day (3-hour intervals)
        }
      });

      const data = this.transformForecastData(response.data);

      // Cache the result
      await this.saveToCache(cacheKey, JSON.stringify(data), process.env.WEATHER_CACHE_TTL || 3600);

      return data;
    } catch (error) {
      console.error('Error fetching weather forecast:', error);
      throw error;
    }
  }

  // Transform OpenWeather API response to our format
  transformWeatherData(weatherData, uvData) {
    const baseData = {
      temperature: weatherData.main.temp,
      feelsLike: weatherData.main.feels_like,
      humidity: weatherData.main.humidity,
      pressure: weatherData.main.pressure,
      windSpeed: weatherData.wind?.speed || 0,
      windDirection: weatherData.wind?.deg || 0,
      description: weatherData.weather[0].description,
      icon: weatherData.weather[0].icon,
      visibility: weatherData.visibility || 0,
      clouds: weatherData.clouds?.all || 0,
      sunrise: new Date(weatherData.sys.sunrise * 1000).toISOString(),
      sunset: new Date(weatherData.sys.sunset * 1000).toISOString(),
      timestamp: new Date().toISOString()
    };

    // Add UV Index if available
    if (uvData) {
      baseData.uvIndex = uvData.value || 0;
      baseData.uvRisk = this.getUVRiskLevel(uvData.value || 0);
    } else {
      baseData.uvIndex = null;
      baseData.uvRisk = 'No data available';
    }

    // Detect stagnation events
    baseData.stagnationEvent = this.detectStagnationEvent(baseData);

    // Add weather alerts
    baseData.alerts = this.generateWeatherAlerts(baseData);

    return baseData;
  }

  // Get UV risk level
  getUVRiskLevel(uvIndex) {
    if (uvIndex <= 2) return 'Low';
    if (uvIndex <= 5) return 'Moderate';
    if (uvIndex <= 7) return 'High';
    if (uvIndex <= 10) return 'Very High';
    return 'Extreme';
  }

  // Detect atmospheric stagnation conditions
  detectStagnationEvent(weatherData) {
    const isStagnant =
      weatherData.windSpeed < 3 && // Low wind speed (< 3 m/s)
      weatherData.visibility < 5000 && // Reduced visibility (< 5km)
      weatherData.pressure > 1020; // High pressure system

    if (isStagnant) {
      return {
        active: true,
        severity: weatherData.windSpeed < 1 ? 'High' : 'Moderate',
        description: 'Atmospheric stagnation event detected - limited air movement',
        recommendations: [
          'Air pollutants may accumulate',
          'Avoid outdoor activities if sensitive to air quality',
          'Monitor air quality conditions closely'
        ]
      };
    }

    return {
      active: false,
      severity: 'None',
      description: 'Normal atmospheric circulation',
      recommendations: []
    };
  }

  // Generate weather-based health alerts
  generateWeatherAlerts(weatherData) {
    const alerts = [];

    // Temperature extremes
    if (weatherData.temperature > 35) {
      alerts.push({
        type: 'heat',
        severity: 'High',
        title: 'Extreme Heat Warning',
        description: `Temperature: ${weatherData.temperature}°C`,
        recommendations: [
          'Avoid outdoor activities during peak hours',
          'Stay hydrated',
          'Seek air-conditioned spaces',
          'Watch for heat exhaustion symptoms'
        ]
      });
    } else if (weatherData.temperature > 30) {
      alerts.push({
        type: 'heat',
        severity: 'Moderate',
        title: 'Heat Advisory',
        description: `Temperature: ${weatherData.temperature}°C`,
        recommendations: [
          'Limit prolonged outdoor exposure',
          'Drink plenty of water',
          'Take frequent breaks in shade'
        ]
      });
    }

    if (weatherData.temperature < -10) {
      alerts.push({
        type: 'cold',
        severity: 'High',
        title: 'Extreme Cold Warning',
        description: `Temperature: ${weatherData.temperature}°C`,
        recommendations: [
          'Limit outdoor exposure',
          'Dress in layers',
          'Protect exposed skin',
          'Watch for frostbite and hypothermia'
        ]
      });
    }

    // UV Index alerts
    if (weatherData.uvIndex && weatherData.uvIndex > 7) {
      alerts.push({
        type: 'uv',
        severity: weatherData.uvIndex > 10 ? 'High' : 'Moderate',
        title: 'High UV Exposure',
        description: `UV Index: ${weatherData.uvIndex} (${weatherData.uvRisk})`,
        recommendations: [
          'Use SPF 30+ sunscreen',
          'Wear protective clothing',
          'Seek shade during peak hours (10 AM - 4 PM)',
          'Wear sunglasses'
        ]
      });
    }

    // Humidity alerts
    if (weatherData.humidity > 85) {
      alerts.push({
        type: 'humidity',
        severity: 'Moderate',
        title: 'High Humidity',
        description: `Humidity: ${weatherData.humidity}%`,
        recommendations: [
          'Increased heat stress risk',
          'Stay in air-conditioned areas',
          'Reduce physical activity outdoors'
        ]
      });
    }

    // Visibility alerts
    if (weatherData.visibility < 1000) {
      alerts.push({
        type: 'visibility',
        severity: 'High',
        title: 'Poor Visibility',
        description: `Visibility: ${weatherData.visibility}m`,
        recommendations: [
          'Avoid outdoor activities',
          'Air quality may be compromised',
          'Use caution if travel is necessary'
        ]
      });
    }

    // Stagnation alert
    if (weatherData.stagnationEvent.active) {
      alerts.push({
        type: 'stagnation',
        severity: weatherData.stagnationEvent.severity,
        title: 'Atmospheric Stagnation',
        description: weatherData.stagnationEvent.description,
        recommendations: weatherData.stagnationEvent.recommendations
      });
    }

    return alerts;
  }

  // Transform forecast data
  transformForecastData(data) {
    const forecasts = data.list.map(item => ({
      datetime: new Date(item.dt * 1000).toISOString(),
      temperature: item.main.temp,
      feelsLike: item.main.feels_like,
      humidity: item.main.humidity,
      pressure: item.main.pressure,
      windSpeed: item.wind.speed,
      windDirection: item.wind.deg,
      description: item.weather[0].description,
      icon: item.weather[0].icon,
      clouds: item.clouds.all,
      pop: item.pop // Probability of precipitation
    }));

    // Group by day
    const dailyForecasts = {};
    forecasts.forEach(forecast => {
      const date = forecast.datetime.split('T')[0];
      if (!dailyForecasts[date]) {
        dailyForecasts[date] = [];
      }
      dailyForecasts[date].push(forecast);
    });

    // Calculate daily summaries
    const dailySummaries = Object.entries(dailyForecasts).map(([date, dayForecasts]) => {
      const temps = dayForecasts.map(f => f.temperature);
      const pops = dayForecasts.map(f => f.pop);

      return {
        date,
        minTemp: Math.min(...temps),
        maxTemp: Math.max(...temps),
        avgHumidity: dayForecasts.reduce((sum, f) => sum + f.humidity, 0) / dayForecasts.length,
        maxPop: Math.max(...pops),
        description: dayForecasts[Math.floor(dayForecasts.length / 2)].description,
        icon: dayForecasts[Math.floor(dayForecasts.length / 2)].icon
      };
    });

    return {
      hourly: forecasts,
      daily: dailySummaries
    };
  }

  // Store weather data in history
  async storeWeatherHistory(pinId, data) {
    try {
      await runQuery(
        `INSERT INTO weather_history
         (pin_id, temperature, humidity, pressure, wind_speed, wind_direction, description, icon, timestamp)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          pinId,
          data.temperature,
          data.humidity,
          data.pressure,
          data.windSpeed,
          data.windDirection,
          data.description,
          data.icon,
          data.timestamp || new Date().toISOString()
        ]
      );
    } catch (error) {
      console.error('Error storing weather history:', error);
    }
  }

  // Get historical weather data for a pin
  async getWeatherHistory(pinId, days = 7) {
    try {
      const history = await getAll(
        `SELECT * FROM weather_history
         WHERE pin_id = ?
         AND timestamp > datetime('now', '-${days} days')
         ORDER BY timestamp DESC`,
        [pinId]
      );

      // If no real data exists, return sample data for demo purposes
      if (history.length === 0) {
        return this.generateSampleWeatherHistory(days, pinId);
      }

      return history;
    } catch (error) {
      console.error('Error fetching weather history:', error);
      // Return sample data as fallback
      return this.generateSampleWeatherHistory(days, pinId);
    }
  }

  generateSampleWeatherHistory(days = 7, pinId = 'demo') {
    const sampleData = [];
    const now = new Date();

    for (let i = 0; i < days; i++) {
      const timestamp = new Date(now.getTime() - (i * 24 * 60 * 60 * 1000));
      const baseTemp = 22 + (Math.random() * 10); // Temperature between 22-32°C
      const baseHumidity = 50 + (Math.random() * 30); // Humidity between 50-80%
      const baseUvIndex = 3 + (Math.random() * 7); // UV Index between 3-10

      sampleData.push({
        id: `sample_${i}`,
        pin_id: pinId,
        timestamp: timestamp.toISOString(),
        temperature: Math.round(baseTemp * 10) / 10,
        humidity: Math.round(baseHumidity),
        pressure: Math.round((1010 + Math.random() * 20) * 10) / 10,
        wind_speed: Math.round((5 + Math.random() * 15) * 10) / 10,
        wind_direction: Math.round(Math.random() * 360),
        uv_index: Math.round(baseUvIndex * 10) / 10,
        visibility: Math.round((15 + Math.random() * 10) * 10) / 10,
        description: 'Partly cloudy'
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

module.exports = new WeatherService();