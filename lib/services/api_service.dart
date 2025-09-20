import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';
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

  // Get headers with auth token
  static Map<String, String> _getHeaders({bool includeAuth = true}) {
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
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      await _saveToken(data['token']);
    }

    return data;
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await _saveToken(data['token']);
    }

    return data;
  }

  static Future<void> logout() async {
    if (_authToken != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: _getHeaders(),
        );
      } catch (e) {
        // Ignore errors during logout
      }
    }
    await clearToken();
  }

  // User profile endpoints
  static Future<Map<String, dynamic>> getUserProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: _getHeaders(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateMedicalProfile(
    Map<String, dynamic> profileData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/medical-profile'),
      headers: _getHeaders(),
      body: jsonEncode(profileData),
    );

    return jsonDecode(response.body);
  }

  // Pin management endpoints
  static Future<List<dynamic>> getPins({bool includeCurrentData = false}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pins?includeCurrentData=$includeCurrentData'),
      headers: _getHeaders(),
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
      headers: _getHeaders(),
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
      headers: _getHeaders(),
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
      headers: _getHeaders(),
    );
  }

  // Environmental data endpoints
  static Future<Map<String, dynamic>> getCurrentAirQuality({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/air-quality/current?lat=$latitude&lon=$longitude'),
      headers: _getHeaders(includeAuth: false),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/current?lat=$latitude&lon=$longitude'),
      headers: _getHeaders(includeAuth: false),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getPollenData({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/pollen?lat=$latitude&lon=$longitude'),
      headers: _getHeaders(includeAuth: false),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getAllEnvironmentalData({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/environmental?lat=$latitude&lon=$longitude'),
      headers: _getHeaders(includeAuth: false),
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
      headers: _getHeaders(includeAuth: false),
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
      headers: _getHeaders(includeAuth: false),
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
      headers: _getHeaders(includeAuth: false),
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
      headers: _getHeaders(),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getHealthAlerts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/health/alerts'),
      headers: _getHeaders(),
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
      headers: _getHeaders(),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getWeatherHistory({
    required int pinId,
    int days = 7,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/demo/history/$pinId?days=$days'),
      headers: _getHeaders(),
    );

    return jsonDecode(response.body);
  }

  // Radon data endpoints
  static Future<Map<String, dynamic>> getRadonData({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/radon/current?lat=$latitude&lon=$longitude'),
      headers: _getHeaders(includeAuth: false),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getRadonZones() async {
    final response = await http.get(
      Uri.parse('$baseUrl/radon/zones'),
      headers: _getHeaders(includeAuth: false),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getRadonHistory({
    required int pinId,
    int days = 7,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/radon/demo/history/$pinId?days=$days'),
      headers: _getHeaders(),
    );

    // Extract history array from the wrapped response
    final data = jsonDecode(response.body);
    return data['history'] ?? data;
  }

  static Future<Map<String, dynamic>> getRadonBatch(
    List<Map<String, double>> locations,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/radon/batch'),
      headers: _getHeaders(includeAuth: false),
      body: jsonEncode({
        'locations': locations.map((loc) => {
          'lat': loc['latitude'],
          'lon': loc['longitude'],
        }).toList(),
      }),
    );

    return jsonDecode(response.body);
  }

  // Batch operations
  static Future<List<dynamic>> getAirQualityBatch(
    List<Map<String, double>> locations,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/air-quality/batch'),
      headers: _getHeaders(includeAuth: false),
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