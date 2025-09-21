import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'rate_limited_http_client.dart';

class ApiService {
  static String get baseUrl {
    // Use localhost for web and desktop, 10.0.2.2 for Android emulator
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      return dotenv.env['API_BASE_URL']?.replaceAll('10.0.2.2', 'localhost') ?? 'http://localhost:3000/api';
    }
    return dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';
  }
  static String? _authToken;

  // Initialize and load saved token
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  // Save auth token
  static Future<void> _saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear auth token
  static Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Get headers with auth token (made public for other services)
  static Map<String, String> getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  // Check if user is authenticated
  static bool get isAuthenticated => _authToken != null;

  // Authentication endpoints
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
  }) async {
    return await RateLimitedHttpClient.makeRequest(
      'auth/register',
      () async {
        final response = await http.post(
          Uri.parse('$baseUrl/auth/register'),
          headers: getHeaders(includeAuth: false),
          body: jsonEncode({
            'username': username,
            'password': password,
          }),
        );

        final data = jsonDecode(response.body);

        // Check for rate limiting or other HTTP errors
        if (response.statusCode == 429) {
          throw Exception('Too many requests. Please wait and try again.');
        } else if (response.statusCode == 400) {
          throw Exception(data['error'] ?? 'Registration failed. Please check your input.');
        } else if (response.statusCode != 201) {
          throw Exception(data['error'] ?? 'Registration failed with status ${response.statusCode}');
        }

        await _saveToken(data['token']);
        return data;
      },
    );
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    return await RateLimitedHttpClient.makeRequest(
      'auth/login',
      () async {
        final response = await http.post(
          Uri.parse('$baseUrl/auth/login'),
          headers: getHeaders(includeAuth: false),
          body: jsonEncode({
            'username': username,
            'password': password,
          }),
        );

        final data = jsonDecode(response.body);

        // Check for rate limiting or other HTTP errors
        if (response.statusCode == 429) {
          throw Exception('Too many requests. Please wait and try again.');
        } else if (response.statusCode == 401) {
          throw Exception('Invalid credentials. Please check your username and password.');
        } else if (response.statusCode != 200) {
          throw Exception(data['error'] ?? 'Login failed with status ${response.statusCode}');
        }

        await _saveToken(data['token']);
        return data;
      },
    );
  }

  static Future<void> logout() async {
    if (_authToken != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: getHeaders(),
        );
      } catch (e) {
        // Ignore errors during logout
      }
    }
    await clearToken();
  }

  static Future<Map<String, dynamic>> completeOnboarding() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/complete-onboarding'),
      headers: getHeaders(),
    );

    return jsonDecode(response.body);
  }

  // User profile endpoints
  static Future<Map<String, dynamic>> getUserProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user profile: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> updateMedicalProfile(
    Map<String, dynamic> profileData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/medical-profile'),
      headers: getHeaders(),
      body: jsonEncode(profileData),
    );

    return jsonDecode(response.body);
  }

  // Pin management endpoints
  static Future<List<dynamic>> getPins({bool includeCurrentData = false}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pins?includeCurrentData=$includeCurrentData'),
      headers: getHeaders(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createPin({
    required String name,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pins'),
      headers: getHeaders(),
      body: jsonEncode({
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updatePin({
    required int pinId,
    String? name,
    String? address,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/pins/$pinId'),
      headers: getHeaders(),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (address != null) 'address': address,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<void> deletePin(int pinId) async {
    await http.delete(
      Uri.parse('$baseUrl/pins/$pinId'),
      headers: getHeaders(),
    );
  }

  // Environmental data endpoints
  static Future<Map<String, dynamic>> getCurrentAirQuality({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/air-quality/current?lat=$latitude&lon=$longitude'),
      headers: getHeaders(includeAuth: false),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/current?lat=$latitude&lon=$longitude'),
      headers: getHeaders(includeAuth: false),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getPollenData({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/pollen?lat=$latitude&lon=$longitude'),
      headers: getHeaders(includeAuth: false),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getAllEnvironmentalData({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/environmental?lat=$latitude&lon=$longitude'),
      headers: getHeaders(includeAuth: false),
    );

    return jsonDecode(response.body);
  }

  // Wildfire data
  static Future<Map<String, dynamic>> getWildfireData({
    required double latitude,
    required double longitude,
    int radius = 100,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/wildfire?lat=$latitude&lon=$longitude&radius=$radius'),
      headers: getHeaders(includeAuth: false),
    );

    return jsonDecode(response.body);
  }

  // Weather forecast
  static Future<Map<String, dynamic>> getWeatherForecast({
    required double latitude,
    required double longitude,
    int days = 5,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/forecast?lat=$latitude&lon=$longitude&days=$days'),
      headers: getHeaders(includeAuth: false),
    );

    return jsonDecode(response.body);
  }

  // Pollen forecast
  static Future<Map<String, dynamic>> getPollenForecast({
    required double latitude,
    required double longitude,
    int days = 5,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/pollen/forecast?lat=$latitude&lon=$longitude&days=$days'),
      headers: getHeaders(includeAuth: false),
    );

    return jsonDecode(response.body);
  }

  // Health recommendations
  static Future<Map<String, dynamic>> getHealthRecommendations({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/health/recommendations?lat=$latitude&lon=$longitude'),
      headers: getHeaders(),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getHealthAlerts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/health/alerts'),
      headers: getHeaders(),
    );

    return jsonDecode(response.body);
  }

  // Historical data
  static Future<List<dynamic>> getAirQualityHistory({
    required int pinId,
    int days = 7,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/air-quality/demo/history/$pinId?days=$days'),
      headers: getHeaders(),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getWeatherHistory({
    required int pinId,
    int days = 7,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/demo/history/$pinId?days=$days'),
      headers: getHeaders(),
    );

    return jsonDecode(response.body);
  }

  // Weather data endpoints (using backend Google Weather API)
  static Future<Map<String, dynamic>> getBackendCurrentWeather({
    required double latitude,
    required double longitude,
    String? locationName,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/current?lat=$latitude&lon=$longitude${locationName != null ? '&location=$locationName' : ''}'),
      headers: getHeaders(includeAuth: false),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch weather data: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getBackendWeatherForecast({
    required double latitude,
    required double longitude,
    int days = 5,
    String? locationName,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/forecast?lat=$latitude&lon=$longitude&days=$days${locationName != null ? '&location=$locationName' : ''}'),
      headers: getHeaders(includeAuth: false),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch weather forecast: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getBackendHourlyWeatherForecast({
    required double latitude,
    required double longitude,
    int hours = 240,
    String? locationName,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/hourly?lat=$latitude&lon=$longitude&hours=$hours${locationName != null ? '&location=$locationName' : ''}'),
      headers: getHeaders(includeAuth: false),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch hourly weather forecast: ${response.statusCode}');
    }
  }

  // Pollen data endpoints (using backend Google Pollen API)
  static Future<Map<String, dynamic>> getBackendCurrentPollen({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/pollen?lat=$latitude&lon=$longitude'),
      headers: getHeaders(includeAuth: false),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch pollen data: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getBackendPollenForecast({
    required double latitude,
    required double longitude,
    int days = 5,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/pollen/forecast?lat=$latitude&lon=$longitude&days=$days'),
      headers: getHeaders(includeAuth: false),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch pollen forecast: ${response.statusCode}');
    }
  }


  // Batch operations
  static Future<List<dynamic>> getAirQualityBatch(
    List<Map<String, double>> locations,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/air-quality/batch'),
      headers: getHeaders(includeAuth: false),
      body: jsonEncode({
        'locations': locations.map((loc) => {
          'latitude': loc['latitude'],
          'longitude': loc['longitude'],
        }).toList(),
      }),
    );

    return jsonDecode(response.body);
  }
}