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

      // Fetch from OpenWeather API
      const response = await axios.get(`${this.baseUrl}/weather`, {
        params: {
          lat: latitude,
          lon: longitude,
          appid: this.apiKey,
          units: 'metric'
        }
      });

      const data = this.transformWeatherData(response.data);

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
  transformWeatherData(data) {
    return {
      temperature: data.main.temp,
      feelsLike: data.main.feels_like,
      humidity: data.main.humidity,
      pressure: data.main.pressure,
      windSpeed: data.wind.speed,
      windDirection: data.wind.deg,
      description: data.weather[0].description,
      icon: data.weather[0].icon,
      visibility: data.visibility,
      clouds: data.clouds.all,
      sunrise: new Date(data.sys.sunrise * 1000).toISOString(),
      sunset: new Date(data.sys.sunset * 1000).toISOString(),
      timestamp: new Date().toISOString()
    };
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

      return history;
    } catch (error) {
      console.error('Error fetching weather history:', error);
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

module.exports = new WeatherService();