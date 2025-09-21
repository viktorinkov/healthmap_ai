const axios = require('axios');
const { getOne, runQuery, getAll } = require('../config/database');

class WeatherService {
  constructor() {
    this.googleApiKey = process.env.GOOGLE_MAPS_API_KEY;
    this.googleWeatherBaseUrl = 'https://weather.googleapis.com/v1';
  }

  // Get current weather data for a location using Google Weather API
  async getCurrentWeather(latitude, longitude, locationName = null) {
    try {
      // Check cache first
      const cacheKey = `weather_${latitude.toFixed(4)}_${longitude.toFixed(4)}`;
      const cached = await this.getFromCache(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }

      // Fetch current weather from Google Weather API
      const response = await axios.get(`${this.googleWeatherBaseUrl}/currentConditions:lookup`, {
        params: {
          key: this.googleApiKey,
          'location.latitude': latitude,
          'location.longitude': longitude,
        },
        headers: {
          'Content-Type': 'application/json',
        }
      });

      if (response.status === 200 && response.data) {
        const data = this.transformGoogleWeatherData(response.data, locationName);

        // Cache the result for 1 hour
        await this.saveToCache(cacheKey, JSON.stringify(data), 3600);

        return data;
      } else {
        throw new Error(`Google Weather API returned status ${response.status}`);
      }
    } catch (error) {
      console.error('Error fetching weather from Google API:', error);

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

      // If no fallback available, return null to indicate no data
      return null;
    }
  }

  // Get weather forecast using Google Weather API
  async getWeatherForecast(latitude, longitude, days = 5, locationName = null) {
    try {
      const cacheKey = `forecast_${latitude.toFixed(4)}_${longitude.toFixed(4)}_${days}`;
      const cached = await this.getFromCache(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }

      // Fetch forecast from Google Weather API
      const response = await axios.get(`${this.googleWeatherBaseUrl}/forecast/days:lookup`, {
        params: {
          key: this.googleApiKey,
          'location.latitude': latitude,
          'location.longitude': longitude,
          days: days.toString(),
        },
        headers: {
          'Content-Type': 'application/json',
        }
      });

      if (response.status === 200 && response.data) {
        const data = this.transformGoogleForecastData(response.data, locationName);

        // Cache the result for 1 hour
        await this.saveToCache(cacheKey, JSON.stringify(data), 3600);

        return data;
      } else {
        throw new Error(`Google Weather API returned status ${response.status}`);
      }
    } catch (error) {
      console.error('Error fetching weather forecast from Google API:', error);
      return null;
    }
  }

  // Get hourly weather forecast using Google Weather API
  async getHourlyForecast(latitude, longitude, hours = 240, locationName = null) {
    try {
      const cacheKey = `hourly_${latitude.toFixed(4)}_${longitude.toFixed(4)}_${hours}`;
      const cached = await this.getFromCache(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }

      // Fetch hourly forecast from Google Weather API
      const response = await axios.get(`${this.googleWeatherBaseUrl}/forecast/hours:lookup`, {
        params: {
          key: this.googleApiKey,
          'location.latitude': latitude,
          'location.longitude': longitude,
          hours: hours.toString(),
        },
        headers: {
          'Content-Type': 'application/json',
        }
      });

      if (response.status === 200 && response.data) {
        const data = this.transformGoogleHourlyForecastData(response.data, locationName);

        // Cache the result for 1 hour
        await this.saveToCache(cacheKey, JSON.stringify(data), 3600);

        return data;
      } else {
        throw new Error(`Google Weather API returned status ${response.status}`);
      }
    } catch (error) {
      console.error('Error fetching hourly weather forecast from Google API:', error);
      return null;
    }
  }

  // Transform Google Weather API response to our format
  transformGoogleWeatherData(data, locationName = null) {
    const temperature = data.temperature?.degrees || 0;
    const feelsLike = data.feelsLikeTemperature?.degrees || temperature;
    const humidity = data.relativeHumidity || 0;
    const pressure = data.airPressure?.meanSeaLevelMillibars || 0;
    const windSpeed = data.wind?.speed?.value || 0;
    const windDirection = data.wind?.direction?.degrees || 0;
    const uvIndex = data.uvIndex || 0;
    const visibility = (data.visibility?.distance || 10) * 1000; // Convert km to meters
    const cloudCover = data.cloudCover || 0;
    const dewPoint = data.dewPoint?.degrees || 0;

    // Parse weather condition
    const weatherCondition = data.weatherCondition;
    const description = weatherCondition?.description?.text || 'Unknown';
    const iconUri = weatherCondition?.iconBaseUri || '';
    const icon = this.extractIconFromUri(iconUri);

    // Parse precipitation
    const precipitation = data.precipitation;
    const precipitationProbability = (precipitation?.probability?.percent || 0) / 100;

    const baseData = {
      temperature,
      feelsLike,
      humidity,
      pressure,
      windSpeed,
      windDirection,
      description,
      icon,
      uvIndex,
      uvRisk: this.getUVRiskLevel(uvIndex),
      visibility,
      cloudCover,
      dewPoint,
      precipitationProbability,
      timestamp: new Date().toISOString(),
      locationName
    };

    // Detect stagnation events
    baseData.stagnationEvent = this.detectStagnationEvent(baseData);

    // Detect extreme temperature alerts
    baseData.heatWaveAlert = this.checkHeatWave(temperature);
    baseData.coldWaveAlert = this.checkColdWave(temperature);

    // Add weather alerts
    baseData.alerts = this.generateWeatherAlerts(baseData);

    return baseData;
  }

  // Transform Google Weather API forecast response to our format
  transformGoogleForecastData(data, locationName = null) {
    const dailyData = [];
    const forecastDays = data.forecastDays || [];

    for (const day of forecastDays) {
      const maxTemp = day.maxTemperature?.degrees || 0;
      const minTemp = day.minTemperature?.degrees || 0;
      const avgTemp = (maxTemp + minTemp) / 2;

      const feelsLikeMax = day.feelsLikeMaxTemperature?.degrees || maxTemp;
      const feelsLikeMin = day.feelsLikeMinTemperature?.degrees || minTemp;
      const avgFeelsLike = (feelsLikeMax + feelsLikeMin) / 2;

      // Get daytime forecast for most weather data
      const daytimeForecast = day.daytimeForecast || {};
      const nighttimeForecast = day.nighttimeForecast || {};

      // Average humidity between day and night
      const dayHumidity = daytimeForecast.relativeHumidity || 50;
      const nightHumidity = nighttimeForecast.relativeHumidity || 50;
      const avgHumidity = (dayHumidity + nightHumidity) / 2;

      // Use daytime wind data
      const windSpeed = daytimeForecast.wind?.speed?.value || 0;
      const windDirection = daytimeForecast.wind?.direction?.degrees || 0;

      // Weather condition from daytime
      const weatherCondition = daytimeForecast.weatherCondition || {};
      const description = weatherCondition.description?.text || 'Unknown';
      const iconUri = weatherCondition.iconBaseUri || '';
      const icon = this.extractIconFromUri(iconUri);

      // Other metrics
      const uvIndex = daytimeForecast.uvIndex || 0;
      const cloudCover = daytimeForecast.cloudCover || 0;

      // Precipitation data
      const dayPrecip = daytimeForecast.precipitation?.probability?.percent || 0;
      const nightPrecip = nighttimeForecast.precipitation?.probability?.percent || 0;
      const avgPrecipProb = Math.max(dayPrecip, nightPrecip) / 100;

      // Parse date
      const displayDate = day.displayDate || {};
      const year = displayDate.year || new Date().getFullYear();
      const month = displayDate.month || new Date().getMonth() + 1;
      const dayOfMonth = displayDate.day || new Date().getDate();
      const date = new Date(year, month - 1, dayOfMonth);

      // Detect stagnation event and extreme temperatures
      const stagnationEvent = this.detectStagnationEvent({ windSpeed, pressure: 1013.25 });
      const heatWaveAlert = this.checkHeatWave(maxTemp);
      const coldWaveAlert = this.checkColdWave(minTemp);

      dailyData.push({
        date: date.toISOString().split('T')[0],
        temperature: avgTemp,
        minTemp,
        maxTemp,
        feelsLike: avgFeelsLike,
        humidity: avgHumidity,
        pressure: 1013.25, // Standard pressure if not provided
        windSpeed,
        windDirection,
        description,
        icon,
        uvIndex,
        visibility: 10000, // Default visibility in meters
        cloudCover,
        dewPoint: this.calculateDewPoint(avgTemp, avgHumidity),
        precipitationProbability: avgPrecipProb,
        timestamp: date.toISOString(),
        heatWaveAlert,
        coldWaveAlert,
        stagnationEvent,
        locationName
      });
    }

    return {
      daily: dailyData,
      lastUpdated: new Date().toISOString()
    };
  }

  // Transform Google Weather API hourly forecast response to our format
  transformGoogleHourlyForecastData(data, locationName = null) {
    const hourlyData = [];
    const forecastHours = data.forecasts || [];

    for (const hour of forecastHours) {
      const temperature = hour.temperature?.degrees || 0;
      const feelsLike = hour.feelsLikeTemperature?.degrees || temperature;
      const humidity = hour.relativeHumidity || 0;
      const pressure = hour.airPressure?.meanSeaLevelMillibars || 0;
      const windSpeed = hour.wind?.speed?.value || 0;
      const windDirection = hour.wind?.direction?.degrees || 0;
      const uvIndex = hour.uvIndex || 0;
      const visibility = (hour.visibility?.distance || 10) * 1000;
      const cloudCover = hour.cloudCover || 0;
      const dewPoint = hour.dewPoint?.degrees || 0;

      // Parse weather condition
      const weatherCondition = hour.weatherCondition || {};
      const description = weatherCondition.description?.text || 'Unknown';
      const iconUri = weatherCondition.iconBaseUri || '';
      const icon = this.extractIconFromUri(iconUri);

      // Parse precipitation
      const precipitation = hour.precipitation || {};
      const precipitationProbability = (precipitation.probability?.percent || 0) / 100;

      // Parse time
      const timeStr = hour.time;
      const timestamp = timeStr ? new Date(timeStr) : new Date();

      // Detect conditions
      const stagnationEvent = this.detectStagnationEvent({ windSpeed, pressure });
      const heatWaveAlert = this.checkHeatWave(temperature);
      const coldWaveAlert = this.checkColdWave(temperature);

      hourlyData.push({
        datetime: timestamp.toISOString(),
        temperature,
        feelsLike,
        humidity,
        pressure,
        windSpeed,
        windDirection,
        description,
        icon,
        uvIndex,
        visibility,
        cloudCover,
        dewPoint,
        precipitationProbability,
        timestamp: timestamp.toISOString(),
        heatWaveAlert,
        coldWaveAlert,
        stagnationEvent,
        locationName
      });
    }

    return {
      hourly: hourlyData,
      lastUpdated: new Date().toISOString()
    };
  }

  // Extract icon name from Google Weather API icon URI
  extractIconFromUri(iconUri) {
    if (!iconUri) return '01d';

    const segments = iconUri.split('/');
    const iconName = segments.length > 0 ? segments[segments.length - 1] : '';

    // Map Google Weather icons to standard weather icon names
    switch (iconName) {
      case 'sunny':
        return '01d';
      case 'partly_cloudy':
        return '02d';
      case 'cloudy':
        return '03d';
      case 'overcast':
        return '04d';
      case 'drizzle':
      case 'light_rain':
        return '09d';
      case 'rain':
      case 'showers':
        return '10d';
      case 'thunderstorm':
        return '11d';
      case 'snow':
        return '13d';
      case 'fog':
      case 'mist':
        return '50d';
      default:
        return '01d';
    }
  }

  // Check for heat wave conditions
  checkHeatWave(temperature) {
    return temperature > 35.0;
  }

  // Check for cold wave conditions
  checkColdWave(temperature) {
    return temperature < -10.0;
  }

  // Calculate dew point from temperature and humidity
  calculateDewPoint(temperature, humidity) {
    if (humidity <= 0) return temperature - 10;

    // Magnus formula for dew point calculation
    const a = 17.27;
    const b = 237.7;

    const alpha = ((a * temperature) / (b + temperature)) + Math.log(humidity / 100.0);
    return (b * alpha) / (a - alpha);
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