const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(process.env.DATABASE_PATH || './database.db');
let db;

function getDatabase() {
  if (!db) {
    db = new sqlite3.Database(dbPath, (err) => {
      if (err) {
        console.error('Error opening database:', err);
      } else {
        console.log('Connected to SQLite database');
      }
    });
  }
  return db;
}

async function initializeDatabase() {
  return new Promise((resolve, reject) => {
    const database = getDatabase();

    database.serialize(() => {
      // Users table
      database.run(`
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT,
          password TEXT,
          onboarding_completed BOOLEAN DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // User medical profiles
      database.run(`
        CREATE TABLE IF NOT EXISTS medical_profiles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          age INTEGER,
          has_respiratory_condition BOOLEAN DEFAULT 0,
          has_heart_condition BOOLEAN DEFAULT 0,
          has_allergies BOOLEAN DEFAULT 0,
          is_elderly BOOLEAN DEFAULT 0,
          is_child BOOLEAN DEFAULT 0,
          is_pregnant BOOLEAN DEFAULT 0,
          exercises_outdoors BOOLEAN DEFAULT 0,
          medications TEXT,
          notes TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      `);

      // User pins/locations
      database.run(`
        CREATE TABLE IF NOT EXISTS pins (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          address TEXT,
          is_active BOOLEAN DEFAULT 1,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      `);

      // Historical air quality data
      database.run(`
        CREATE TABLE IF NOT EXISTS air_quality_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pin_id INTEGER NOT NULL,
          aqi INTEGER,
          pm25 REAL,
          pm10 REAL,
          o3 REAL,
          no2 REAL,
          so2 REAL,
          co REAL,
          category TEXT,
          color TEXT,
          timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (pin_id) REFERENCES pins (id) ON DELETE CASCADE
        )
      `);

      // Historical weather data
      database.run(`
        CREATE TABLE IF NOT EXISTS weather_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pin_id INTEGER NOT NULL,
          temperature REAL,
          humidity REAL,
          pressure REAL,
          wind_speed REAL,
          wind_direction INTEGER,
          description TEXT,
          icon TEXT,
          timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (pin_id) REFERENCES pins (id) ON DELETE CASCADE
        )
      `);

      // Historical pollen data
      database.run(`
        CREATE TABLE IF NOT EXISTS pollen_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pin_id INTEGER NOT NULL,
          tree_pollen INTEGER,
          grass_pollen INTEGER,
          weed_pollen INTEGER,
          overall_risk TEXT,
          timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (pin_id) REFERENCES pins (id) ON DELETE CASCADE
        )
      `);

      // Historical wildfire data
      database.run(`
        CREATE TABLE IF NOT EXISTS wildfire_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pin_id INTEGER NOT NULL,
          risk_level TEXT,
          nearby_fires INTEGER,
          closest_fire_distance REAL,
          smoke_impact TEXT,
          timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (pin_id) REFERENCES pins (id) ON DELETE CASCADE
        )
      `);

      // Historical radon data
      database.run(`
        CREATE TABLE IF NOT EXISTS radon_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pin_id INTEGER NOT NULL,
          radon_risk TEXT,
          radon_zone INTEGER,
          average_level REAL,
          description TEXT,
          timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (pin_id) REFERENCES pins (id) ON DELETE CASCADE
        )
      `);

      // Cache table for external API responses
      database.run(`
        CREATE TABLE IF NOT EXISTS api_cache (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cache_key TEXT UNIQUE NOT NULL,
          data TEXT NOT NULL,
          expires_at DATETIME NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // User sessions
      database.run(`
        CREATE TABLE IF NOT EXISTS sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          token TEXT UNIQUE NOT NULL,
          expires_at DATETIME NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      `);

      // Running routes tables
      database.run(`
        CREATE TABLE IF NOT EXISTS running_routes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          distance_km REAL NOT NULL,
          duration_minutes INTEGER,
          difficulty TEXT CHECK(difficulty IN ('easy', 'moderate', 'hard')),
          route_type TEXT CHECK(route_type IN ('loop', 'out_and_back', 'point_to_point')),
          is_favorite BOOLEAN DEFAULT 0,
          is_active BOOLEAN DEFAULT 1,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      `);

      database.run(`
        CREATE TABLE IF NOT EXISTS route_waypoints (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          route_id INTEGER NOT NULL,
          sequence_order INTEGER NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          elevation_meters REAL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (route_id) REFERENCES running_routes (id) ON DELETE CASCADE
        )
      `);

      database.run(`
        CREATE TABLE IF NOT EXISTS route_pollution_points (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          route_id INTEGER NOT NULL,
          waypoint_id INTEGER,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          aqi INTEGER,
          pm25 REAL,
          pm10 REAL,
          measurement_time DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (route_id) REFERENCES running_routes (id) ON DELETE CASCADE,
          FOREIGN KEY (waypoint_id) REFERENCES route_waypoints (id) ON DELETE SET NULL
        )
      `);

      database.run(`
        CREATE TABLE IF NOT EXISTS route_optimizations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          original_route_id INTEGER NOT NULL,
          optimized_route_id INTEGER,
          optimization_type TEXT CHECK(optimization_type IN ('pollution', 'time', 'combined')),
          original_pollution_score REAL,
          optimized_pollution_score REAL,
          improvement_percentage REAL,
          vertex_ai_response TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (original_route_id) REFERENCES running_routes (id) ON DELETE CASCADE,
          FOREIGN KEY (optimized_route_id) REFERENCES running_routes (id) ON DELETE SET NULL
        )
      `);

      database.run(`
        CREATE TABLE IF NOT EXISTS running_time_suggestions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          route_id INTEGER NOT NULL,
          suggested_time TIME NOT NULL,
          suggested_date DATE,
          day_of_week TEXT,
          avg_aqi_forecast INTEGER,
          weather_conditions TEXT,
          temperature_celsius REAL,
          humidity_percentage REAL,
          reason TEXT,
          score REAL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (route_id) REFERENCES running_routes (id) ON DELETE CASCADE
        )
      `);

      database.run(`
        CREATE TABLE IF NOT EXISTS running_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          route_id INTEGER,
          started_at DATETIME NOT NULL,
          completed_at DATETIME,
          actual_distance_km REAL,
          actual_duration_minutes INTEGER,
          avg_aqi INTEGER,
          avg_heart_rate INTEGER,
          calories_burned INTEGER,
          notes TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (route_id) REFERENCES running_routes (id) ON DELETE SET NULL
        )
      `);

      // Create indexes for better query performance
      database.run(`CREATE INDEX IF NOT EXISTS idx_pins_user_id ON pins(user_id)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_air_quality_pin_id ON air_quality_history(pin_id)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_weather_pin_id ON weather_history(pin_id)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_pollen_pin_id ON pollen_history(pin_id)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_wildfire_pin_id ON wildfire_history(pin_id)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_radon_pin_id ON radon_history(pin_id)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_cache_key ON api_cache(cache_key)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(token)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_running_routes_user_id ON running_routes(user_id)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_route_waypoints_route_id ON route_waypoints(route_id)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_route_pollution_route_id ON route_pollution_points(route_id)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_route_optimizations_original ON route_optimizations(original_route_id)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_running_time_route_id ON running_time_suggestions(route_id)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_running_history_user_id ON running_history(user_id)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_running_history_route_id ON running_history(route_id)`);

      database.run(`CREATE INDEX IF NOT EXISTS idx_air_quality_timestamp ON air_quality_history(timestamp)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_weather_timestamp ON weather_history(timestamp)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_wildfire_timestamp ON wildfire_history(timestamp)`);
      database.run(`CREATE INDEX IF NOT EXISTS idx_radon_timestamp ON radon_history(timestamp)`, (err) => {
        if (err) {
          reject(err);
        } else {
          resolve();
        }
      });
    });
  });
}

// Helper function to run queries with promises
function runQuery(sql, params = []) {
  return new Promise((resolve, reject) => {
    const database = getDatabase();
    database.run(sql, params, function(err) {
      if (err) {
        reject(err);
      } else {
        resolve({ id: this.lastID, changes: this.changes });
      }
    });
  });
}

// Helper function to get single row
function getOne(sql, params = []) {
  return new Promise((resolve, reject) => {
    const database = getDatabase();
    database.get(sql, params, (err, row) => {
      if (err) {
        reject(err);
      } else {
        resolve(row);
      }
    });
  });
}

// Helper function to get multiple rows
function getAll(sql, params = []) {
  return new Promise((resolve, reject) => {
    const database = getDatabase();
    database.all(sql, params, (err, rows) => {
      if (err) {
        reject(err);
      } else {
        resolve(rows);
      }
    });
  });
}

module.exports = {
  getDatabase,
  initializeDatabase,
  runQuery,
  getOne,
  getAll
};