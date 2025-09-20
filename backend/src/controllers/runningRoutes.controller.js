const { getOne, getAll, runQuery } = require('../config/database');
const vertexAiService = require('../services/vertexAi.service');
const airQualityService = require('../services/airQuality.service');

/**
 * Get all routes for a user
 */
async function getUserRoutes(req, res) {
  try {
    const userId = req.user.id;
    const { includeWaypoints = false } = req.query;

    let routes = await getAll(
      `SELECT * FROM running_routes
       WHERE user_id = ? AND is_active = 1
       ORDER BY is_favorite DESC, created_at DESC`,
      [userId]
    );

    if (includeWaypoints) {
      for (let route of routes) {
        route.waypoints = await getAll(
          `SELECT * FROM route_waypoints
           WHERE route_id = ?
           ORDER BY sequence_order`,
          [route.id]
        );
      }
    }

    res.json(routes);
  } catch (error) {
    console.error('Error fetching user routes:', error);
    res.status(500).json({ error: 'Failed to fetch routes' });
  }
}

/**
 * Get a single route with details
 */
async function getRoute(req, res) {
  try {
    const { routeId } = req.params;
    const userId = req.user.id;

    const route = await getOne(
      `SELECT * FROM running_routes
       WHERE id = ? AND user_id = ? AND is_active = 1`,
      [routeId, userId]
    );

    if (!route) {
      return res.status(404).json({ error: 'Route not found' });
    }

    // Get waypoints
    route.waypoints = await getAll(
      `SELECT * FROM route_waypoints
       WHERE route_id = ?
       ORDER BY sequence_order`,
      [routeId]
    );

    // Get latest pollution data if available
    route.pollution_points = await getAll(
      `SELECT * FROM route_pollution_points
       WHERE route_id = ?
       ORDER BY measurement_time DESC
       LIMIT 20`,
      [routeId]
    );

    // Get optimization history
    route.optimizations = await getAll(
      `SELECT * FROM route_optimizations
       WHERE original_route_id = ?
       ORDER BY created_at DESC
       LIMIT 5`,
      [routeId]
    );

    res.json(route);
  } catch (error) {
    console.error('Error fetching route:', error);
    res.status(500).json({ error: 'Failed to fetch route' });
  }
}

/**
 * Create a new route
 */
async function createRoute(req, res) {
  try {
    const userId = req.user.id;
    const {
      name,
      description,
      distance_km,
      duration_minutes,
      difficulty,
      route_type,
      waypoints,
    } = req.body;

    // Validate required fields
    if (!name || !distance_km || !waypoints || waypoints.length < 2) {
      return res.status(400).json({
        error: 'Missing required fields: name, distance_km, and at least 2 waypoints',
      });
    }

    // Insert route
    const routeResult = await runQuery(
      `INSERT INTO running_routes
       (user_id, name, description, distance_km, duration_minutes, difficulty, route_type)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        userId,
        name,
        description || null,
        distance_km,
        duration_minutes || null,
        difficulty || 'moderate',
        route_type || 'loop',
      ]
    );

    const routeId = routeResult.id;

    // Insert waypoints
    for (let i = 0; i < waypoints.length; i++) {
      const waypoint = waypoints[i];
      await runQuery(
        `INSERT INTO route_waypoints
         (route_id, sequence_order, latitude, longitude, elevation_meters)
         VALUES (?, ?, ?, ?, ?)`,
        [
          routeId,
          i,
          waypoint.latitude,
          waypoint.longitude,
          waypoint.elevation_meters || null,
        ]
      );

      // Get initial pollution data for waypoint
      try {
        const airQuality = await airQualityService.getCurrentAirQuality(
          waypoint.latitude,
          waypoint.longitude
        );

        await runQuery(
          `INSERT INTO route_pollution_points
           (route_id, latitude, longitude, aqi, pm25, pm10)
           VALUES (?, ?, ?, ?, ?, ?)`,
          [
            routeId,
            waypoint.latitude,
            waypoint.longitude,
            airQuality.aqi,
            airQuality.pm25,
            airQuality.pm10,
          ]
        );
      } catch (aqError) {
        console.error('Error fetching AQI for waypoint:', aqError);
      }
    }

    res.status(201).json({
      id: routeId,
      message: 'Route created successfully',
    });
  } catch (error) {
    console.error('Error creating route:', error);
    res.status(500).json({ error: 'Failed to create route' });
  }
}

/**
 * Generate example routes for the user
 */
async function generateExampleRoutes(req, res) {
  try {
    const userId = req.user.id;
    const { latitude, longitude } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        error: 'Latitude and longitude are required',
      });
    }

    // Generate example routes using Vertex AI service
    const exampleRoutes = await vertexAiService.generateExampleRoutes(
      parseFloat(latitude),
      parseFloat(longitude),
      3
    );

    // Save routes to database
    const savedRoutes = [];
    for (const route of exampleRoutes) {
      const routeResult = await runQuery(
        `INSERT INTO running_routes
         (user_id, name, description, distance_km, duration_minutes, difficulty, route_type)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [
          userId,
          route.name,
          route.description,
          route.distance_km,
          route.duration_minutes,
          route.difficulty,
          route.route_type,
        ]
      );

      const routeId = routeResult.id;

      // Save waypoints
      for (const waypoint of route.waypoints) {
        await runQuery(
          `INSERT INTO route_waypoints
           (route_id, sequence_order, latitude, longitude)
           VALUES (?, ?, ?, ?)`,
          [
            routeId,
            waypoint.sequence_order,
            waypoint.latitude,
            waypoint.longitude,
          ]
        );
      }

      savedRoutes.push({
        id: routeId,
        ...route,
      });
    }

    res.json({
      message: 'Example routes generated successfully',
      routes: savedRoutes,
    });
  } catch (error) {
    console.error('Error generating example routes:', error);
    res.status(500).json({ error: 'Failed to generate example routes' });
  }
}

/**
 * Optimize a route based on pollution data
 */
async function optimizeRoute(req, res) {
  try {
    const { routeId } = req.params;
    const userId = req.user.id;
    const { optimization_type = 'pollution' } = req.body;

    // Get the route
    const route = await getOne(
      `SELECT * FROM running_routes
       WHERE id = ? AND user_id = ? AND is_active = 1`,
      [routeId, userId]
    );

    if (!route) {
      return res.status(404).json({ error: 'Route not found' });
    }

    // Get waypoints
    const waypoints = await getAll(
      `SELECT latitude, longitude FROM route_waypoints
       WHERE route_id = ?
       ORDER BY sequence_order`,
      [routeId]
    );

    // Get user's medical profile
    const medicalProfile = await getOne(
      `SELECT * FROM medical_profiles WHERE user_id = ?`,
      [userId]
    );

    // Get recent running history for pattern analysis
    const runningHistory = await getAll(
      `SELECT * FROM running_history
       WHERE user_id = ?
       ORDER BY started_at DESC
       LIMIT 10`,
      [userId]
    );

    // Get historical air quality data around route waypoints (last 7 days)
    const centerLat = waypoints.reduce((sum, wp) => sum + wp.latitude, 0) / waypoints.length;
    const centerLon = waypoints.reduce((sum, wp) => sum + wp.longitude, 0) / waypoints.length;

    // Find nearest pin for historical data
    const nearestPin = await getOne(
      `SELECT id, name, latitude, longitude,
        ((latitude - ?) * (latitude - ?) + (longitude - ?) * (longitude - ?)) as distance
       FROM pins
       WHERE user_id = ? AND is_active = 1
       ORDER BY distance ASC
       LIMIT 1`,
      [centerLat, centerLat, centerLon, centerLon, userId]
    );

    let historicalAirQuality = [];
    if (nearestPin) {
      historicalAirQuality = await getAll(
        `SELECT aqi, pm25, pm10, timestamp
         FROM air_quality_history
         WHERE pin_id = ? AND timestamp >= datetime('now', '-7 days')
         ORDER BY timestamp DESC`,
        [nearestPin.id]
      );
    }

    // Optimize route using Vertex AI with enhanced context
    const optimizationResult = await vertexAiService.optimizeRoute(
      waypoints,
      optimization_type,
      medicalProfile,
      runningHistory,
      historicalAirQuality
    );

    // Save optimized route as new route
    const optimizedRouteResult = await runQuery(
      `INSERT INTO running_routes
       (user_id, name, description, distance_km, duration_minutes, difficulty, route_type)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        userId,
        `${route.name} (Optimized)`,
        `Optimized version of ${route.name}. ${optimizationResult.optimization_reasoning}`,
        route.distance_km,
        route.duration_minutes,
        route.difficulty,
        route.route_type,
      ]
    );

    const optimizedRouteId = optimizedRouteResult.id;

    // Save optimized waypoints
    for (let i = 0; i < optimizationResult.optimized_waypoints.length; i++) {
      const waypoint = optimizationResult.optimized_waypoints[i];
      await runQuery(
        `INSERT INTO route_waypoints
         (route_id, sequence_order, latitude, longitude)
         VALUES (?, ?, ?, ?)`,
        [
          optimizedRouteId,
          i,
          waypoint.latitude,
          waypoint.longitude,
        ]
      );
    }

    // Save optimization record
    await runQuery(
      `INSERT INTO route_optimizations
       (original_route_id, optimized_route_id, optimization_type,
        original_pollution_score, optimized_pollution_score, improvement_percentage, vertex_ai_response)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        routeId,
        optimizedRouteId,
        optimization_type,
        optimizationResult.original_pollution_score,
        optimizationResult.optimized_pollution_score,
        optimizationResult.actual_improvement,
        JSON.stringify(optimizationResult),
      ]
    );

    res.json({
      message: 'Route optimized successfully',
      optimized_route_id: optimizedRouteId,
      optimization_result: optimizationResult,
    });
  } catch (error) {
    console.error('Error optimizing route:', error);
    res.status(500).json({ error: 'Failed to optimize route' });
  }
}

/**
 * Get optimal running times for a route
 */
async function getOptimalRunningTimes(req, res) {
  try {
    const { routeId } = req.params;
    const userId = req.user.id;
    const { days = 3 } = req.query;

    // Get the route
    const route = await getOne(
      `SELECT * FROM running_routes
       WHERE id = ? AND user_id = ? AND is_active = 1`,
      [routeId, userId]
    );

    if (!route) {
      return res.status(404).json({ error: 'Route not found' });
    }

    // Get waypoints
    const waypoints = await getAll(
      `SELECT latitude, longitude FROM route_waypoints
       WHERE route_id = ?
       ORDER BY sequence_order`,
      [routeId]
    );

    // Get optimal times using Vertex AI
    const suggestions = await vertexAiService.suggestOptimalRunningTimes(
      waypoints,
      parseInt(days)
    );

    // Save suggestions to database
    for (const suggestion of suggestions.suggestions) {
      await runQuery(
        `INSERT INTO running_time_suggestions
         (route_id, suggested_time, suggested_date, day_of_week,
          avg_aqi_forecast, weather_conditions, temperature_celsius,
          humidity_percentage, reason, score)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          routeId,
          suggestion.time,
          suggestion.date,
          suggestion.day_of_week,
          suggestion.estimated_aqi,
          suggestion.weather_conditions,
          suggestion.temperature_celsius,
          suggestion.humidity_percentage,
          suggestion.reason,
          suggestion.score,
        ]
      );
    }

    res.json(suggestions);
  } catch (error) {
    console.error('Error getting optimal running times:', error);
    res.status(500).json({ error: 'Failed to get optimal running times' });
  }
}

/**
 * Update a route
 */
async function updateRoute(req, res) {
  try {
    const { routeId } = req.params;
    const userId = req.user.id;
    const { name, description, is_favorite } = req.body;

    const route = await getOne(
      `SELECT * FROM running_routes
       WHERE id = ? AND user_id = ? AND is_active = 1`,
      [routeId, userId]
    );

    if (!route) {
      return res.status(404).json({ error: 'Route not found' });
    }

    const updates = [];
    const params = [];

    if (name !== undefined) {
      updates.push('name = ?');
      params.push(name);
    }
    if (description !== undefined) {
      updates.push('description = ?');
      params.push(description);
    }
    if (is_favorite !== undefined) {
      updates.push('is_favorite = ?');
      params.push(is_favorite ? 1 : 0);
    }

    if (updates.length > 0) {
      params.push(routeId, userId);
      await runQuery(
        `UPDATE running_routes
         SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP
         WHERE id = ? AND user_id = ?`,
        params
      );
    }

    res.json({ message: 'Route updated successfully' });
  } catch (error) {
    console.error('Error updating route:', error);
    res.status(500).json({ error: 'Failed to update route' });
  }
}

/**
 * Delete a route
 */
async function deleteRoute(req, res) {
  try {
    const { routeId } = req.params;
    const userId = req.user.id;

    const route = await getOne(
      `SELECT * FROM running_routes
       WHERE id = ? AND user_id = ? AND is_active = 1`,
      [routeId, userId]
    );

    if (!route) {
      return res.status(404).json({ error: 'Route not found' });
    }

    // Soft delete
    await runQuery(
      `UPDATE running_routes
       SET is_active = 0, updated_at = CURRENT_TIMESTAMP
       WHERE id = ? AND user_id = ?`,
      [routeId, userId]
    );

    res.json({ message: 'Route deleted successfully' });
  } catch (error) {
    console.error('Error deleting route:', error);
    res.status(500).json({ error: 'Failed to delete route' });
  }
}

/**
 * Record a running session
 */
async function recordRunningSession(req, res) {
  try {
    const userId = req.user.id;
    const {
      route_id,
      started_at,
      completed_at,
      actual_distance_km,
      actual_duration_minutes,
      avg_aqi,
      avg_heart_rate,
      calories_burned,
      notes,
    } = req.body;

    if (!started_at) {
      return res.status(400).json({ error: 'Start time is required' });
    }

    const result = await runQuery(
      `INSERT INTO running_history
       (user_id, route_id, started_at, completed_at, actual_distance_km,
        actual_duration_minutes, avg_aqi, avg_heart_rate, calories_burned, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId,
        route_id || null,
        started_at,
        completed_at || null,
        actual_distance_km || null,
        actual_duration_minutes || null,
        avg_aqi || null,
        avg_heart_rate || null,
        calories_burned || null,
        notes || null,
      ]
    );

    res.status(201).json({
      id: result.id,
      message: 'Running session recorded successfully',
    });
  } catch (error) {
    console.error('Error recording running session:', error);
    res.status(500).json({ error: 'Failed to record running session' });
  }
}

/**
 * Get running history
 */
async function getRunningHistory(req, res) {
  try {
    const userId = req.user.id;
    const { limit = 20, offset = 0 } = req.query;

    const history = await getAll(
      `SELECT rh.*, rr.name as route_name
       FROM running_history rh
       LEFT JOIN running_routes rr ON rh.route_id = rr.id
       WHERE rh.user_id = ?
       ORDER BY rh.started_at DESC
       LIMIT ? OFFSET ?`,
      [userId, parseInt(limit), parseInt(offset)]
    );

    res.json(history);
  } catch (error) {
    console.error('Error fetching running history:', error);
    res.status(500).json({ error: 'Failed to fetch running history' });
  }
}

module.exports = {
  getUserRoutes,
  getRoute,
  createRoute,
  generateExampleRoutes,
  optimizeRoute,
  getOptimalRunningTimes,
  updateRoute,
  deleteRoute,
  recordRunningSession,
  getRunningHistory,
};