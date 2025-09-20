import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/air_quality.dart';
import '../models/user_health_profile.dart';
import '../models/pinned_location.dart';
import '../models/neighborhood.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'healthmap.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // User Health Profile table
    await db.execute('''
      CREATE TABLE user_health_profiles(
        id TEXT PRIMARY KEY,
        conditions TEXT,
        age_group TEXT,
        is_pregnant INTEGER,
        sensitivity_level INTEGER,
        lifestyle_risks TEXT,
        domestic_risks TEXT,
        last_updated TEXT
      )
    ''');

    // Pinned Locations table
    await db.execute('''
      CREATE TABLE pinned_locations(
        id TEXT PRIMARY KEY,
        name TEXT,
        type TEXT,
        latitude REAL,
        longitude REAL,
        address TEXT,
        created_at TEXT,
        is_active INTEGER
      )
    ''');

    // Air Quality Data table
    await db.execute('''
      CREATE TABLE air_quality_data(
        id TEXT PRIMARY KEY,
        location_name TEXT,
        latitude REAL,
        longitude REAL,
        timestamp TEXT,
        pm25 REAL,
        pm10 REAL,
        o3 REAL,
        no2 REAL,
        wildfire_index REAL,
        radon REAL,
        status TEXT,
        status_reason TEXT
      )
    ''');

    // Neighborhoods table
    await db.execute('''
      CREATE TABLE neighborhoods(
        id TEXT PRIMARY KEY,
        name TEXT,
        latitude REAL,
        longitude REAL,
        zip_codes TEXT,
        health_score REAL,
        ranking INTEGER
      )
    ''');

    // Daily Tasks table
    await db.execute('''
      CREATE TABLE daily_tasks(
        id TEXT PRIMARY KEY,
        date_key TEXT,
        tasks_json TEXT,
        created_at TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add daily tasks table in version 2
      await db.execute('''
        CREATE TABLE daily_tasks(
          id TEXT PRIMARY KEY,
          date_key TEXT,
          tasks_json TEXT,
          created_at TEXT
        )
      ''');
    }
  }

  // User Health Profile operations
  Future<void> saveUserHealthProfile(UserHealthProfile profile) async {
    final db = await database;
    await db.insert(
      'user_health_profiles',
      {
        'id': profile.id,
        'conditions': jsonEncode(profile.conditions.map((e) => e.name).toList()),
        'age_group': profile.ageGroup.name,
        'is_pregnant': profile.isPregnant ? 1 : 0,
        'sensitivity_level': profile.sensitivityLevel,
        'lifestyle_risks': jsonEncode(profile.lifestyleRisks.map((e) => e.name).toList()),
        'domestic_risks': jsonEncode(profile.domesticRisks.map((e) => e.name).toList()),
        'last_updated': profile.lastUpdated.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserHealthProfile?> getUserHealthProfile(String id) async {
    final db = await database;
    final maps = await db.query(
      'user_health_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      return UserHealthProfile(
        id: map['id'] as String,
        conditions: (jsonDecode(map['conditions'] as String) as List)
            .map((e) => HealthCondition.values.firstWhere((c) => c.name == e))
            .toList(),
        ageGroup: AgeGroup.values.firstWhere((a) => a.name == map['age_group']),
        isPregnant: (map['is_pregnant'] as int) == 1,
        sensitivityLevel: map['sensitivity_level'] as int,
        lifestyleRisks: (jsonDecode(map['lifestyle_risks'] as String) as List)
            .map((e) => LifestyleRisk.values.firstWhere((r) => r.name == e))
            .toList(),
        domesticRisks: (jsonDecode(map['domestic_risks'] as String) as List)
            .map((e) => DomesticRisk.values.firstWhere((r) => r.name == e))
            .toList(),
        lastUpdated: DateTime.parse(map['last_updated'] as String),
      );
    }
    return null;
  }

  // Pinned Locations operations
  Future<void> savePinnedLocation(PinnedLocation location) async {
    final db = await database;
    await db.insert(
      'pinned_locations',
      {
        'id': location.id,
        'name': location.name,
        'type': location.type.name,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'address': location.address,
        'created_at': location.createdAt.toIso8601String(),
        'is_active': location.isActive ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PinnedLocation>> getPinnedLocations() async {
    final db = await database;
    final maps = await db.query(
      'pinned_locations',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => PinnedLocation(
      id: map['id'] as String,
      name: map['name'] as String,
      type: LocationType.values.firstWhere((t) => t.name == map['type']),
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isActive: (map['is_active'] as int) == 1,
    )).toList();
  }

  Future<void> deletePinnedLocation(String id) async {
    final db = await database;
    await db.update(
      'pinned_locations',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Air Quality Data operations
  Future<void> saveAirQualityData(AirQualityData data) async {
    final db = await database;
    await db.insert(
      'air_quality_data',
      {
        'id': data.id,
        'location_name': data.locationName,
        'latitude': data.latitude,
        'longitude': data.longitude,
        'timestamp': data.timestamp.toIso8601String(),
        'pm25': data.metrics.pm25,
        'pm10': data.metrics.pm10,
        'o3': data.metrics.o3,
        'no2': data.metrics.no2,
        'wildfire_index': data.metrics.wildfireIndex,
        'radon': data.metrics.radon,
        'status': data.status.name,
        'status_reason': data.statusReason,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AirQualityData>> getAirQualityData() async {
    final db = await database;
    final maps = await db.query(
      'air_quality_data',
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => AirQualityData(
      id: map['id'] as String,
      locationName: map['location_name'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      timestamp: DateTime.parse(map['timestamp'] as String),
      metrics: AirQualityMetrics(
        pm25: map['pm25'] as double,
        pm10: map['pm10'] as double,
        o3: map['o3'] as double,
        no2: map['no2'] as double,
        wildfireIndex: map['wildfire_index'] as double,
        radon: map['radon'] as double,
      ),
      status: AirQualityStatus.values.firstWhere((s) => s.name == map['status']),
      statusReason: map['status_reason'] as String,
    )).toList();
  }

  // Neighborhoods operations
  Future<void> saveNeighborhoods(List<Neighborhood> neighborhoods) async {
    final db = await database;
    final batch = db.batch();

    for (final neighborhood in neighborhoods) {
      batch.insert(
        'neighborhoods',
        {
          'id': neighborhood.id,
          'name': neighborhood.name,
          'latitude': neighborhood.latitude,
          'longitude': neighborhood.longitude,
          'zip_codes': jsonEncode(neighborhood.zipCodes),
          'health_score': neighborhood.healthScore,
          'ranking': neighborhood.ranking,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  Future<List<Neighborhood>> getNeighborhoods() async {
    final db = await database;
    final maps = await db.query(
      'neighborhoods',
      orderBy: 'ranking ASC',
    );

    return maps.map((map) => Neighborhood(
      id: map['id'] as String,
      name: map['name'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      zipCodes: (jsonDecode(map['zip_codes'] as String) as List<dynamic>)
          .cast<String>(),
      healthScore: map['health_score'] as double,
      ranking: map['ranking'] as int,
    )).toList();
  }

  // Daily Tasks operations
  Future<void> saveDailyTasks(String dateKey, List<dynamic> tasks) async {
    final db = await database;
    await db.insert(
      'daily_tasks',
      {
        'id': dateKey,
        'date_key': dateKey,
        'tasks_json': jsonEncode(tasks.map((task) => task.toJson()).toList()),
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<dynamic>> getDailyTasks(String dateKey) async {
    final db = await database;
    final maps = await db.query(
      'daily_tasks',
      where: 'date_key = ?',
      whereArgs: [dateKey],
    );

    if (maps.isNotEmpty) {
      final tasksJson = maps.first['tasks_json'] as String;
      final tasksList = jsonDecode(tasksJson) as List;
      // Import the DailyTask class dynamically to avoid circular dependency
      return tasksList.map((taskJson) {
        // Return a map instead of DailyTask to avoid import issues
        return taskJson;
      }).toList();
    }
    return [];
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('user_health_profiles');
    await db.delete('pinned_locations');
    await db.delete('air_quality_data');
    await db.delete('neighborhoods');
    await db.delete('daily_tasks');
  }
}