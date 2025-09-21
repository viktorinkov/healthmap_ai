const cron = require('node-cron');
const { getOne, getAll } = require('../config/database');
const airQualityService = require('./airQuality.service');
const weatherService = require('./weather.service');
const pollenService = require('./pollen.service');

// Collect data for all active pins once per hour
function startScheduledTasks() {
  // Collect environmental data every hour at the top of the hour
  cron.schedule('0 * * * *', async () => {
    console.log('Starting hourly data collection...');
    await collectEnvironmentalData();
  });

  // Clean expired cache every 6 hours
  cron.schedule('0 */6 * * *', async () => {
    console.log('Cleaning expired cache...');
    await cleanExpiredCache();
  });

  // Clean old historical data every day at 2 AM
  cron.schedule('0 2 * * *', async () => {
    console.log('Cleaning old historical data...');
    await cleanOldHistoricalData();
  });

  console.log('Scheduled tasks initialized');
}

async function collectEnvironmentalData() {
  try {
    // Get all active pins
    const pins = await getAll(
      'SELECT * FROM pins WHERE is_active = 1'
    );

    console.log(`Collecting data for ${pins.length} pins...`);

    // Collect data for each pin
    for (const pin of pins) {
      try {
        // Fetch and store air quality data
        const airQuality = await airQualityService.getCurrentAirQuality(
          pin.latitude,
          pin.longitude
        );
        await airQualityService.storeAirQualityHistory(pin.id, airQuality);

        // Fetch and store weather data
        const weather = await weatherService.getCurrentWeather(
          pin.latitude,
          pin.longitude
        );
        await weatherService.storeWeatherHistory(pin.id, weather);

        // Fetch and store pollen data (less frequent, only if not recently updated)
        const recentPollen = await getOne(
          `SELECT id FROM pollen_history
           WHERE pin_id = ?
           AND timestamp > datetime('now', '-2 hours')
           LIMIT 1`,
          [pin.id]
        );

        if (!recentPollen) {
          const pollen = await pollenService.getCurrentPollen(
            pin.latitude,
            pin.longitude
          );
          await pollenService.storePollenHistory(pin.id, pollen);
        }

      } catch (error) {
        console.error(`Error collecting data for pin ${pin.id}:`, error.message);
      }
    }

    console.log('Data collection completed');
  } catch (error) {
    console.error('Error in scheduled data collection:', error);
  }
}

async function cleanExpiredCache() {
  try {
    await airQualityService.cleanExpiredCache();
    console.log('Cache cleaned successfully');
  } catch (error) {
    console.error('Error cleaning cache:', error);
  }
}

async function cleanOldHistoricalData() {
  try {
    const { runQuery } = require('../config/database');

    // Keep only 30 days of historical data
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const cutoffDate = thirtyDaysAgo.toISOString();

    await runQuery(
      'DELETE FROM air_quality_history WHERE timestamp < ?',
      [cutoffDate]
    );

    await runQuery(
      'DELETE FROM weather_history WHERE timestamp < ?',
      [cutoffDate]
    );

    await runQuery(
      'DELETE FROM pollen_history WHERE timestamp < ?',
      [cutoffDate]
    );

    // Clean expired sessions
    await runQuery(
      'DELETE FROM sessions WHERE expires_at < datetime("now")'
    );

    console.log('Old historical data cleaned successfully');
  } catch (error) {
    console.error('Error cleaning old historical data:', error);
  }
}

module.exports = {
  startScheduledTasks,
  collectEnvironmentalData,
  cleanExpiredCache,
  cleanOldHistoricalData
};