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

  // Reader themes endpoint
  Future<Map<String, dynamic>> getReaderThemes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reader/themes'),
      headers: _getHeaders(),
    );
    final data = await _handleResponse(response);
    if (data is! Map<String, dynamic>) {
      throw ApiException('Invalid reader themes response format');
    }
    return data;
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

  Future<Map<String, int>> getPoemCountsByLetter() async {
    final response = await http.get(
      Uri.parse('$baseUrl/poems/letter-counts'),
      headers: _getHeaders(includeAuth: _token != null),
    );
    final data = await _handleResponse(response);

    final counts = <String, int>{};

    if (data is Map<String, dynamic>) {
      final nestedCounts = data['counts'];

      if (nestedCounts is Map<String, dynamic>) {
        nestedCounts.forEach((letter, value) {
          final count = _parseCountValue(value);
          if (count != null) {
            counts[letter.toUpperCase()] = count;
          }
        });
        return counts;
      }

      final items = data['items'];
      if (items is List) {
        for (final item in items) {
          if (item is! Map<String, dynamic>) continue;
          final letter = item['letter']?.toString();
          final count = _parseCountValue(item['count']);
          if (letter != null && count != null) {
            counts[letter.toUpperCase()] = count;
          }
        }
        return counts;
      }

      data.forEach((key, value) {
        final count = _parseCountValue(value);
        if (count != null) {
          counts[key.toUpperCase()] = count;
        }
      });

      if (counts.isNotEmpty) {
        return counts;
      }
    }

    if (data is List) {
      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;
        final letter = item['letter']?.toString();
        final count = _parseCountValue(item['count']);
        if (letter != null && count != null) {
          counts[letter.toUpperCase()] = count;
        }
      }

      if (counts.isNotEmpty) {
        return counts;
      }
    }

    throw ApiException('Invalid letter counts response format');
  }

  int? _parseCountValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<Poem> getPoemById(int id) async {
    final url = '$baseUrl/poems/$id';
    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(includeAuth: _token != null),
    );
    final data = await _handleResponse(response);
    return Poem.fromJson(data as Map<String, dynamic>);
  }

  /// Load poem with all poems from the same letter
  /// If API supports it, returns poems_for_letter; otherwise returns just the poem
  Future<Map<String, dynamic>> getPoemWithLetterPoems(int id) async {
    try {
      // Try new API endpoint that includes letter poems
      final response = await http.get(
        Uri.parse('$baseUrl/poems/$id?include_letter_poems=true'),
        headers: _getHeaders(includeAuth: _token != null),
      );
      final data = await _handleResponse(response);

      if (data is! Map<String, dynamic>) {
        throw ApiException('Invalid response format');
      }

      // Check if we got the extended format
      if (data.containsKey('poems_for_letter')) {
        return {
          'poem': Poem.fromJson(data['poem'] as Map<String, dynamic>),
          'poemsForLetter': (data['poems_for_letter'] as List)
              .map((p) => Poem.fromJson(p as Map<String, dynamic>))
              .toList(),
          'letter': data['letter'] as String? ?? '',
        };
      } else {
        // Server just returned the poem, fetch letter poems separately
        final poem = Poem.fromJson(data);
        final letterPoems = await getPoemsByLetter(poem.letter);
        return {
          'poem': poem,
          'poemsForLetter': letterPoems,
          'letter': poem.letter,
        };
      }
    } catch (e) {
      // Fallback: load poem directly
      try {
        final poem = await getPoemById(id);
        final letterPoems = await getPoemsByLetter(poem.letter);
        return {
          'poem': poem,
          'poemsForLetter': letterPoems,
          'letter': poem.letter,
        };
      } catch (fallbackError) {
        rethrow;
      }
    }
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
