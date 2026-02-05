import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/poem.dart';
import '../models/subscription.dart';
import '../models/stats.dart';
import '../models/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  final String baseUrl;
  String? _token;

  ApiService({this.baseUrl = AppConstants.baseUrl});

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {'Content-Type': 'application/json'};

    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized. Please log in again.', 401);
    } else if (response.statusCode == 403) {
      throw ApiException('Access forbidden. Subscription required.', 403);
    } else if (response.statusCode == 404) {
      throw ApiException('Resource not found.', 404);
    } else {
      final body = json.decode(response.body);
      final message = body['detail'] ?? 'An error occurred';
      throw ApiException(message, response.statusCode);
    }
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _getHeaders(),
      body: json.encode({'email': email, 'password': password}),
    );
    return await _handleResponse(response);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _getHeaders(),
      body: json.encode({'email': email, 'password': password}),
    );
    return await _handleResponse(response);
  }

  Future<void> requestCode(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/request-code'),
      headers: _getHeaders(),
      body: json.encode({'email': email}),
    );
    await _handleResponse(response);
  }

  Future<Map<String, dynamic>> loginByCode(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login-by-code'),
      headers: _getHeaders(),
      body: json.encode({'email': email, 'code': code}),
    );
    return await _handleResponse(response);
  }

  // Config endpoint
  Future<AppConfig> getConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/config'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    return AppConfig.fromJson(data);
  }

  // Poems endpoints
  Future<List<Poem>> getPoemsByLetter(String letter) async {
    final response = await http.get(
      Uri.parse('$baseUrl/poems?letter=$letter'),
      headers: _getHeaders(includeAuth: _token != null),
    );
    final data = await _handleResponse(response);
    // API возвращает {items: [...], total: N}
    final items = data['items'] as List;
    return items.map((poem) => Poem.fromJson(poem)).toList();
  }

  Future<Poem> getPoemById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/poems/$id'),
      headers: _getHeaders(includeAuth: _token != null),
    );
    final data = await _handleResponse(response);
    return Poem.fromJson(data);
  }

  Future<List<Poem>> searchPoems(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search?q=$query'),
      headers: _getHeaders(includeAuth: _token != null),
    );
    final data = await _handleResponse(response);
    // API возвращает {items: [...], total: N}
    final items = data['items'] as List;
    return items.map((poem) => Poem.fromJson(poem)).toList();
  }

  // Subscription endpoints
  Future<Subscription> getSubscriptionStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/subscription/status'),
      headers: _getHeaders(includeAuth: true),
    );
    final data = await _handleResponse(response);
    return Subscription.fromJson(data);
  }

  // Stats endpoint
  Future<Stats> getStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/stats'),
      headers: _getHeaders(includeAuth: true),
    );
    final data = await _handleResponse(response);
    return Stats.fromJson(data);
  }

  // Payment endpoint
  Future<String> createPayment() async {
    final response = await http.post(
      Uri.parse('$baseUrl/payment/create'),
      headers: _getHeaders(includeAuth: true),
      body: json.encode({}),
    );
    final data = await _handleResponse(response);
    return data['checkout_url'];
  }

  // Favorites endpoints (placeholder for future implementation)
  Future<List<Poem>> getFavorites() async {
    final response = await http.get(
      Uri.parse('$baseUrl/favorites'),
      headers: _getHeaders(includeAuth: true),
    );
    final data = await _handleResponse(response);
    return (data as List).map((poem) => Poem.fromJson(poem)).toList();
  }

  Future<void> addToFavorites(int poemId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/favorites'),
      headers: _getHeaders(includeAuth: true),
      body: json.encode({'poem_id': poemId}),
    );
    await _handleResponse(response);
  }

  Future<void> removeFromFavorites(int poemId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/favorites/$poemId'),
      headers: _getHeaders(includeAuth: true),
    );
    await _handleResponse(response);
  }
}
