const { VertexAI } = require('@google-cloud/vertexai');
const airQualityService = require('./airQuality.service');
const weatherService = require('./weather.service');

// Initialize Vertex AI with your project and location
const vertex_ai = new VertexAI({
  project: process.env.GOOGLE_CLOUD_PROJECT || 'healthmap-ai',
  location: process.env.GOOGLE_CLOUD_LOCATION || 'us-central1',
});

// Get the Gemini model
const model = 'gemini-1.5-flash';
const generativeModel = vertex_ai.preview.getGenerativeModel({
  model: model,
  generationConfig: {
    maxOutputTokens: 2048,
    temperature: 0.7,
    topP: 0.8,
    topK: 20,
  },
});

/**
 * Optimize a running route based on pollution data
 * @param {Array} waypoints - Array of {latitude, longitude} waypoints
 * @param {String} optimizationType - 'pollution', 'time', or 'combined'
 * @param {Object} medicalProfile - User's medical profile and health conditions
 * @param {Array} runningHistory - User's recent running sessions
 * @param {Array} historicalAirQuality - Historical air quality data for the area
 * @returns {Object} Optimized route with waypoints and metadata
 */
async function optimizeRoute(waypoints, optimizationType = 'pollution', medicalProfile = null, runningHistory = [], historicalAirQuality = []) {
  try {
    // Get pollution data for each waypoint
    const pollutionData = await Promise.all(
      waypoints.map(async (point) => {
        const airQuality = await airQualityService.getCurrentAirQuality(
          point.latitude,
          point.longitude
        );
        return {
          ...point,
          aqi: airQuality.aqi,
          pm25: airQuality.pm25,
          pm10: airQuality.pm10,
        };
      })
    );

    // Calculate average pollution score for original route
    const originalScore = calculatePollutionScore(pollutionData);

    // Analyze historical air quality patterns
    const historicalAnalysis = historicalAirQuality.length > 0 ?
      `\nHistorical Air Quality Data (last 7 days):
      ${JSON.stringify(historicalAirQuality.slice(0, 20), null, 2)}` :
      '\nNo historical air quality data available.';

    // Analyze running history patterns
    const historyAnalysis = runningHistory.length > 0 ?
      `\nRecent Running History:
      ${JSON.stringify(runningHistory.map(session => ({
        distance: session.actual_distance_km,
        duration: session.actual_duration_minutes,
        avgAqi: session.avg_aqi,
        date: session.started_at,
        notes: session.notes
      })), null, 2)}` :
      '\nNo running history available.';

    // Health profile analysis
    const healthAnalysis = medicalProfile ?
      `\nUser Health Profile:
      - Age: ${medicalProfile.age || 'Not specified'}
      - Has respiratory condition: ${medicalProfile.has_respiratory_condition ? 'Yes' : 'No'}
      - Has heart condition: ${medicalProfile.has_heart_condition ? 'Yes' : 'No'}
      - Has allergies: ${medicalProfile.has_allergies ? 'Yes' : 'No'}
      - Is elderly: ${medicalProfile.is_elderly ? 'Yes' : 'No'}
      - Is child: ${medicalProfile.is_child ? 'Yes' : 'No'}
      - Is pregnant: ${medicalProfile.is_pregnant ? 'Yes' : 'No'}
      - Exercises outdoors regularly: ${medicalProfile.exercises_outdoors ? 'Yes' : 'No'}
      - Medications: ${medicalProfile.medications || 'None listed'}
      - Additional notes: ${medicalProfile.notes || 'None'}` :
      '\nNo health profile available.';

    // Create prompt for Vertex AI
    const prompt = `
    You are a specialized route optimization AI for runners with expertise in air pollution exposure and personalized health considerations.

    Current route waypoints with AQI values:
    ${JSON.stringify(pollutionData, null, 2)}

    Optimization type: ${optimizationType}
    ${healthAnalysis}
    ${historyAnalysis}
    ${historicalAnalysis}

    Please analyze this running route and suggest optimizations considering:

    HEALTH-SPECIFIC CONSIDERATIONS:
    ${medicalProfile?.has_respiratory_condition ? '- CRITICAL: User has respiratory conditions - minimize PM2.5 and ozone exposure' : ''}
    ${medicalProfile?.has_heart_condition ? '- CRITICAL: User has heart conditions - avoid high-pollution areas that increase cardiovascular stress' : ''}
    ${medicalProfile?.has_allergies ? '- User has allergies - consider pollen-producing vegetation along route' : ''}
    ${medicalProfile?.is_elderly || medicalProfile?.is_child ? '- User is in vulnerable age group - apply stricter air quality thresholds' : ''}
    ${medicalProfile?.is_pregnant ? '- CRITICAL: User is pregnant - apply strictest air quality standards for fetal health' : ''}

    AIR QUALITY THRESHOLDS (adjust based on health profile):
    ${medicalProfile?.has_respiratory_condition || medicalProfile?.has_heart_condition || medicalProfile?.is_pregnant ?
      '- Target AQI: < 30 (Very sensitive individual)\n- Concerning: AQI > 35\n- Avoid: AQI > 50' :
      medicalProfile?.is_elderly || medicalProfile?.is_child ?
      '- Target AQI: < 40 (Sensitive individual)\n- Concerning: AQI > 50\n- Avoid: AQI > 75' :
      '- Target AQI: < 50 (General population)\n- Concerning: AQI > 75\n- Avoid: AQI > 100'
    }

    ROUTE OPTIMIZATION GOALS:
    1. Minimize exposure to air pollution based on user's health sensitivity
    2. Maintain approximately the same total distance
    3. Keep the route practical and runnable
    4. Consider historical air quality patterns in the area
    5. Account for user's running experience and preferences

    ROUTE CONSIDERATIONS:
    - Green spaces and parks (typically have better air quality)
    - Routes away from major roads and highways
    - Elevation changes that might affect breathing
    - Wind patterns that help disperse pollution
    - Time-of-day pollution patterns from historical data
    ${medicalProfile?.exercises_outdoors ? '- User is experienced with outdoor exercise' : '- Consider user may be new to outdoor exercise'}

    Return a JSON response with:
    {
      "optimized_waypoints": [
        {"latitude": number, "longitude": number, "sequence_order": number, "expected_aqi": number}
      ],
      "optimization_reasoning": "detailed string explaining the changes, health considerations, and rationale",
      "expected_improvement": "percentage improvement in pollution exposure",
      "health_specific_benefits": "string explaining specific health benefits for this user",
      "alternative_suggestions": ["list of general suggestions for the area and user's health profile"],
      "pollution_risk_assessment": "assessment of remaining pollution exposure risks for this user"
    }

    IMPORTANT: Return ONLY valid JSON, no markdown formatting or additional text.
    `;

    // Get optimization from Vertex AI
    const request = {
      contents: [
        {
          role: 'user',
          parts: [{ text: prompt }],
        },
      ],
    };

    const result = await generativeModel.generateContent(request);
    const response = result.response;
    const textResponse = response.candidates[0].content.parts[0].text;

    // Parse the JSON response
    let optimizedRoute;
    try {
      // Clean the response to ensure valid JSON
      const cleanedResponse = textResponse
        .replace(/```json\n?/g, '')
        .replace(/```\n?/g, '')
        .trim();
      optimizedRoute = JSON.parse(cleanedResponse);
    } catch (parseError) {
      console.error('Error parsing Vertex AI response:', parseError);
      // Fallback to original route if parsing fails
      return {
        optimized_waypoints: waypoints,
        optimization_reasoning: 'Unable to optimize route at this time',
        expected_improvement: 0,
        original_pollution_score: originalScore,
        optimized_pollution_score: originalScore,
      };
    }

    // Get actual AQI for optimized waypoints
    const optimizedPollutionData = await Promise.all(
      optimizedRoute.optimized_waypoints.map(async (point) => {
        const airQuality = await airQualityService.getCurrentAirQuality(
          point.latitude,
          point.longitude
        );
        return {
          ...point,
          actual_aqi: airQuality.aqi,
          pm25: airQuality.pm25,
          pm10: airQuality.pm10,
        };
      })
    );

    const optimizedScore = calculatePollutionScore(optimizedPollutionData);
    const improvementPercentage = ((originalScore - optimizedScore) / originalScore) * 100;

    return {
      optimized_waypoints: optimizedPollutionData,
      optimization_reasoning: optimizedRoute.optimization_reasoning,
      expected_improvement: optimizedRoute.expected_improvement,
      actual_improvement: improvementPercentage.toFixed(2),
      original_pollution_score: originalScore,
      optimized_pollution_score: optimizedScore,
      alternative_suggestions: optimizedRoute.alternative_suggestions,
      health_specific_benefits: optimizedRoute.health_specific_benefits || '',
      pollution_risk_assessment: optimizedRoute.pollution_risk_assessment || '',
    };
  } catch (error) {
    console.error('Error optimizing route:', error);
    throw error;
  }
}

/**
 * Suggest optimal running times for a route based on pollution forecasts
 * @param {Array} waypoints - Array of {latitude, longitude} waypoints
 * @param {Number} days - Number of days to forecast (default 3)
 * @returns {Array} Array of suggested times with scores
 */
async function suggestOptimalRunningTimes(waypoints, days = 3) {
  try {
    // Get the center point of the route for forecast data
    const centerPoint = calculateCenterPoint(waypoints);

    // Get weather and air quality forecasts
    const weatherForecast = await weatherService.getWeatherForecast(
      centerPoint.latitude,
      centerPoint.longitude,
      days
    );

    // Get current and historical AQI patterns (since we don't have forecast API)
    // We'll use patterns to estimate best times
    const currentAQI = await airQualityService.getCurrentAirQuality(
      centerPoint.latitude,
      centerPoint.longitude
    );

    // Create prompt for Vertex AI to analyze patterns
    const prompt = `
    You are an AI assistant helping runners find the optimal time to run based on air quality and weather conditions.

    Route center location: ${JSON.stringify(centerPoint)}
    Current AQI: ${currentAQI.aqi}
    Weather forecast for next ${days} days:
    ${JSON.stringify(weatherForecast, null, 2)}

    Based on typical air quality patterns:
    - Early morning (5-8 AM): Usually best air quality, before traffic increases
    - Late morning (9-11 AM): Increasing pollution from morning traffic
    - Afternoon (12-4 PM): Often highest pollution, especially on hot days
    - Early evening (5-7 PM): Rush hour traffic increases pollution
    - Night (8-11 PM): Pollution starts to decrease

    Analyze the weather forecast and suggest the best times to run for each day.
    Consider:
    1. Temperature (ideal: 10-20°C)
    2. Humidity (ideal: 40-60%)
    3. Wind (helps disperse pollution)
    4. Precipitation (cleans air but makes running difficult)
    5. Typical pollution patterns

    Return a JSON response with top 5 suggestions:
    {
      "suggestions": [
        {
          "date": "YYYY-MM-DD",
          "time": "HH:MM",
          "day_of_week": "Monday/Tuesday/etc",
          "estimated_aqi": number,
          "temperature_celsius": number,
          "humidity_percentage": number,
          "weather_conditions": "string",
          "reason": "brief explanation",
          "score": number (0-100, higher is better)
        }
      ],
      "general_recommendations": ["list of general tips for this location and season"]
    }

    IMPORTANT: Return ONLY valid JSON, no markdown formatting or additional text.
    `;

    const request = {
      contents: [
        {
          role: 'user',
          parts: [{ text: prompt }],
        },
      ],
    };

    const result = await generativeModel.generateContent(request);
    const response = result.response;
    const textResponse = response.candidates[0].content.parts[0].text;

    // Parse the JSON response
    let suggestions;
    try {
      const cleanedResponse = textResponse
        .replace(/```json\n?/g, '')
        .replace(/```\n?/g, '')
        .trim();
      suggestions = JSON.parse(cleanedResponse);
    } catch (parseError) {
      console.error('Error parsing Vertex AI response:', parseError);
      // Fallback suggestions
      return {
        suggestions: [
          {
            date: new Date().toISOString().split('T')[0],
            time: '06:00',
            day_of_week: new Date().toLocaleDateString('en-US', { weekday: 'long' }),
            estimated_aqi: currentAQI.aqi,
            temperature_celsius: 15,
            humidity_percentage: 50,
            weather_conditions: 'Clear',
            reason: 'Early morning typically has the best air quality',
            score: 75,
          },
        ],
        general_recommendations: [
          'Run early in the morning for best air quality',
          'Avoid running during rush hours',
          'Check real-time AQI before heading out',
        ],
      };
    }

    return suggestions;
  } catch (error) {
    console.error('Error suggesting optimal running times:', error);
    throw error;
  }
}

/**
 * Calculate pollution score for a route
 * @param {Array} pollutionData - Array of waypoints with AQI data
 * @returns {Number} Average pollution score
 */
function calculatePollutionScore(pollutionData) {
  if (!pollutionData || pollutionData.length === 0) return 0;

  const totalAQI = pollutionData.reduce((sum, point) => {
    return sum + (point.aqi || point.actual_aqi || 0);
  }, 0);

  return totalAQI / pollutionData.length;
}

/**
 * Calculate center point of a route
 * @param {Array} waypoints - Array of {latitude, longitude}
 * @returns {Object} Center point {latitude, longitude}
 */
function calculateCenterPoint(waypoints) {
  if (!waypoints || waypoints.length === 0) {
    return { latitude: 0, longitude: 0 };
  }

  const sumLat = waypoints.reduce((sum, point) => sum + point.latitude, 0);
  const sumLon = waypoints.reduce((sum, point) => sum + point.longitude, 0);

  return {
    latitude: sumLat / waypoints.length,
    longitude: sumLon / waypoints.length,
  };
}

/**
 * Generate example running routes for a location
 * @param {Number} latitude - User's latitude
 * @param {Number} longitude - User's longitude
 * @param {Number} count - Number of routes to generate
 * @returns {Array} Array of example routes
 */
async function generateExampleRoutes(latitude, longitude, count = 3) {
  const routes = [];
  const distances = [3, 5, 8]; // km
  const difficulties = ['easy', 'moderate', 'hard'];
  const types = ['loop', 'out_and_back', 'loop'];

  for (let i = 0; i < Math.min(count, 3); i++) {
    const route = {
      name: `Example Route ${i + 1}`,
      description: `A ${difficulties[i]} ${distances[i]}km ${types[i].replace('_', ' ')} route`,
      distance_km: distances[i],
      duration_minutes: Math.round(distances[i] * 6), // Assuming 6 min/km pace
      difficulty: difficulties[i],
      route_type: types[i],
      waypoints: generateWaypoints(latitude, longitude, distances[i], types[i]),
    };

    routes.push(route);
  }

  return routes;
}

/**
 * Generate waypoints for a route
 * @param {Number} centerLat - Center latitude
 * @param {Number} centerLon - Center longitude
 * @param {Number} distanceKm - Total distance in km
 * @param {String} routeType - Type of route
 * @returns {Array} Array of waypoints
 */
function generateWaypoints(centerLat, centerLon, distanceKm, routeType) {
  const waypoints = [];
  const numPoints = Math.max(10, Math.floor(distanceKm * 3)); // More points for longer routes

  if (routeType === 'loop') {
    // Generate circular route
    const radiusKm = distanceKm / (2 * Math.PI);
    for (let i = 0; i < numPoints; i++) {
      const angle = (i / numPoints) * 2 * Math.PI;
      const lat = centerLat + (radiusKm / 111) * Math.cos(angle);
      const lon = centerLon + (radiusKm / (111 * Math.cos(centerLat * Math.PI / 180))) * Math.sin(angle);
      waypoints.push({
        latitude: lat,
        longitude: lon,
        sequence_order: i,
      });
    }
  } else if (routeType === 'out_and_back') {
    // Generate straight line out and back
    const halfDistance = distanceKm / 2;
    const latOffset = halfDistance / 111;

    // Out
    for (let i = 0; i < numPoints / 2; i++) {
      const progress = i / (numPoints / 2);
      waypoints.push({
        latitude: centerLat + (latOffset * progress),
        longitude: centerLon,
        sequence_order: i,
      });
    }

    // Back
    for (let i = numPoints / 2; i < numPoints; i++) {
      const progress = 1 - ((i - numPoints / 2) / (numPoints / 2));
      waypoints.push({
        latitude: centerLat + (latOffset * progress),
        longitude: centerLon,
        sequence_order: i,
      });
    }
  } else {
    // Point to point
    const latOffset = distanceKm / 111;
    for (let i = 0; i < numPoints; i++) {
      const progress = i / numPoints;
      waypoints.push({
        latitude: centerLat + (latOffset * progress),
        longitude: centerLon,
        sequence_order: i,
      });
    }
  }

  return waypoints;
}

module.exports = {
  optimizeRoute,
  suggestOptimalRunningTimes,
  generateExampleRoutes,
  calculatePollutionScore,
  calculateCenterPoint,
};