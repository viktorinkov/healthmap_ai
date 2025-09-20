-- Running routes table
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
);

-- Route waypoints table (stores the path of the route)
CREATE TABLE IF NOT EXISTS route_waypoints (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  route_id INTEGER NOT NULL,
  sequence_order INTEGER NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  elevation_meters REAL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (route_id) REFERENCES running_routes (id) ON DELETE CASCADE
);

-- Route pollution data (stores pollution levels at different points)
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
);

-- Route optimizations table (stores optimization history)
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
);

-- Running time suggestions table
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
);

-- User running history
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
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_running_routes_user_id ON running_routes(user_id);
CREATE INDEX IF NOT EXISTS idx_route_waypoints_route_id ON route_waypoints(route_id);
CREATE INDEX IF NOT EXISTS idx_route_pollution_route_id ON route_pollution_points(route_id);
CREATE INDEX IF NOT EXISTS idx_route_optimizations_original ON route_optimizations(original_route_id);
CREATE INDEX IF NOT EXISTS idx_running_time_route_id ON running_time_suggestions(route_id);
CREATE INDEX IF NOT EXISTS idx_running_history_user_id ON running_history(user_id);
CREATE INDEX IF NOT EXISTS idx_running_history_route_id ON running_history(route_id);