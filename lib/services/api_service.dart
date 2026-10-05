import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/poem.dart';
import '../models/subscription.dart';
import '../models/stats.dart';
import '../models/app_config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class LetterPoemIndexEntry {
  final int count;
  final int? firstPoemId;

  const LetterPoemIndexEntry({required this.count, this.firstPoemId});
}

class ApiService {
  final String baseUrl;
  final StorageService? _storageService;
  String? _token;
  Future<bool>? _refreshFuture;
  Future<void> Function()? _authFailureHandler;

  ApiService({String? baseUrl, StorageService? storageService})
    : baseUrl = baseUrl ?? AppConstants.baseUrl,
      _storageService = storageService;

  void setAuthFailureHandler(Future<void> Function()? handler) {
    _authFailureHandler = handler;
  }

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

  dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return json.decode(response.body);
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> _handleResponse(
    http.Response response, {
    String? endpoint,
  }) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    }

    final body = _decodeBody(response);
    final detail = body is Map<String, dynamic>
        ? (body['detail']?.toString() ?? body['message']?.toString())
        : null;

    if (response.statusCode == 401) {
      throw ApiException(detail ?? 'Требуется авторизация.', 401);
    }

    if (response.statusCode == 403) {
      if (endpoint == '/payment/create') {
        throw ApiException('Оплата временно недоступна.', 403);
      }
      throw ApiException(detail ?? 'Доступ запрещен. Требуется подписка.', 403);
    }

    if (response.statusCode == 404) {
      throw ApiException(detail ?? 'Ресурс не найден.', 404);
    }

    if (response.statusCode == 502 && endpoint == '/payment/create') {
      throw ApiException('Ошибка платежной системы, попробуйте позже.', 502);
    }

    throw ApiException(detail ?? 'Произошла ошибка.', response.statusCode);
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    _refreshFuture = _refreshAccessTokenInternal();
    final result = await _refreshFuture!;
    _refreshFuture = null;
    return result;
  }

  Future<bool> _refreshAccessTokenInternal() async {
    if (_storageService == null) return false;

    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: _getHeaders(),
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final data = _decodeBody(response);
      if (data is! Map<String, dynamic>) return false;

      final newAccessToken = data['access_token']?.toString();
      final newRefreshToken = data['refresh_token']?.toString();

      if (newAccessToken == null || newAccessToken.isEmpty) {
        return false;
      }

      _token = newAccessToken;
      await _storageService.saveAccessToken(newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storageService.saveRefreshToken(newRefreshToken);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<dynamic> _requestWithAuthRetry(
    Future<http.Response> Function() requestBuilder, {
    required bool requiresAuth,
    String? endpoint,
  }) async {
    var response = await requestBuilder();

    if (requiresAuth && response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        if (_authFailureHandler != null) {
          await _authFailureHandler!();
        }
        throw ApiException('Сессия истекла. Войдите снова.', 401);
      }
      response = await requestBuilder();
    }

    return _handleResponse(response, endpoint: endpoint);
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register(String email, String password) async {
    final data = await _requestWithAuthRetry(
      () => http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _getHeaders(),
        body: json.encode({'email': email, 'password': password}),
      ),
      requiresAuth: false,
      endpoint: '/auth/register',
    );
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _requestWithAuthRetry(
      () => http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _getHeaders(),
        body: json.encode({'email': email, 'password': password}),
      ),
      requiresAuth: false,
      endpoint: '/auth/login',
    );
    return data as Map<String, dynamic>;
  }

  Future<void> requestCode(String email) async {
    await _requestWithAuthRetry(
      () => http.post(
        Uri.parse('$baseUrl/auth/request-code'),
        headers: _getHeaders(),
        body: json.encode({'email': email}),
      ),
      requiresAuth: false,
      endpoint: '/auth/request-code',
    );
  }

  Future<Map<String, dynamic>> loginByCode(String email, String code) async {
    final data = await _requestWithAuthRetry(
      () => http.post(
        Uri.parse('$baseUrl/auth/login-by-code'),
        headers: _getHeaders(),
        body: json.encode({'email': email, 'code': code}),
      ),
      requiresAuth: false,
      endpoint: '/auth/login-by-code',
    );
    return data as Map<String, dynamic>;
  }

  // Config endpoint
  Future<AppConfig> getConfig() async {
    final data = await _requestWithAuthRetry(
      () => http.get(Uri.parse('$baseUrl/config'), headers: _getHeaders()),
      requiresAuth: false,
      endpoint: '/config',
    );
    return AppConfig.fromJson(data);
  }

  // Reader themes endpoint
  Future<Map<String, dynamic>> getReaderThemes() async {
    final data = await _requestWithAuthRetry(
      () =>
          http.get(Uri.parse('$baseUrl/reader/themes'), headers: _getHeaders()),
      requiresAuth: false,
      endpoint: '/reader/themes',
    );
    if (data is! Map<String, dynamic>) {
      throw ApiException('Invalid reader themes response format');
    }
    return data;
  }

  // Poems endpoints
  Future<List<Poem>> getPoemsByLetter(String letter) async {
    final data = await _requestWithAuthRetry(
      () => http.get(
        Uri.parse('$baseUrl/poems?letter=$letter'),
        headers: _getHeaders(includeAuth: _token != null),
      ),
      requiresAuth: _token != null,
      endpoint: '/poems',
    );
    // API возвращает {items: [...], total: N}
    final items = data['items'] as List;
    return items.map((poem) => Poem.fromJson(poem)).toList();
  }

  /// Full poems by id (up to 50) without marking them as read.
  Future<List<Poem>> getPoemsByIds(List<int> ids) async {
    final data = await _requestWithAuthRetry(
      () => http.get(
        Uri.parse('$baseUrl/poems?ids=${ids.join(',')}'),
        headers: _getHeaders(includeAuth: _token != null),
      ),
      requiresAuth: _token != null,
      endpoint: '/poems',
    );
    final items = data['items'] as List;
    return items.map((poem) => Poem.fromJson(poem)).toList();
  }

  /// Poems of all letters with the given meaning counts, without text.
  Future<List<Poem>> getPoemsByMeanings({
    required Set<int> counts,
    int? atLeast,
  }) async {
    final query = [
      'counts=${counts.join(',')}',
      if (atLeast != null) 'at_least=$atLeast',
    ].join('&');
    final data = await _requestWithAuthRetry(
      () => http.get(
        Uri.parse('$baseUrl/poems/by-meanings?$query'),
        headers: _getHeaders(includeAuth: _token != null),
      ),
      requiresAuth: _token != null,
      endpoint: '/poems/by-meanings',
    );
    final items = data['items'] as List;
    return items.map((poem) => Poem.fromJson(poem)).toList();
  }

  /// {meaning count: number of poems} across the whole catalogue.
  Future<Map<int, int>> getMeaningCounts() async {
    final data = await _requestWithAuthRetry(
      () => http.get(
        Uri.parse('$baseUrl/poems/meaning-counts'),
        headers: _getHeaders(includeAuth: _token != null),
      ),
      requiresAuth: _token != null,
      endpoint: '/poems/meaning-counts',
    );
    final counts = data['counts'] as Map<String, dynamic>;
    return {
      for (final entry in counts.entries)
        int.parse(entry.key): (entry.value as num).toInt(),
    };
  }

  Future<Map<String, LetterPoemIndexEntry>> getPoemLetterIndex() async {
    final data = await _requestWithAuthRetry(
      () => http.get(
        Uri.parse('$baseUrl/poems/letter-counts'),
        headers: _getHeaders(includeAuth: _token != null),
      ),
      requiresAuth: _token != null,
      endpoint: '/poems/letter-counts',
    );

    final index = <String, LetterPoemIndexEntry>{};

    if (data is Map<String, dynamic>) {
      final nestedCounts = data['counts'];

      if (nestedCounts is Map<String, dynamic>) {
        nestedCounts.forEach((letter, value) {
          final count = _extractCount(value);
          final firstPoemId = _extractFirstPoemId(value);
          if (count != null) {
            index[letter.toUpperCase()] = LetterPoemIndexEntry(
              count: count,
              firstPoemId: firstPoemId,
            );
          }
        });
      }

      final items = data['items'];
      if (items is List) {
        for (final item in items) {
          if (item is! Map<String, dynamic>) continue;
          final letter = item['letter']?.toString();
          final count = _extractCount(item);
          final firstPoemId = _extractFirstPoemId(item);
          if (letter != null && count != null) {
            index[letter.toUpperCase()] = LetterPoemIndexEntry(
              count: count,
              firstPoemId: firstPoemId,
            );
          }
        }
      }

      data.forEach((key, value) {
        final count = _extractCount(value);
        final firstPoemId = _extractFirstPoemId(value);
        if (count != null) {
          index[key.toUpperCase()] = LetterPoemIndexEntry(
            count: count,
            firstPoemId: firstPoemId,
          );
        }
      });

      if (index.isNotEmpty) {
        return index;
      }
    }

    if (data is List) {
      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;
        final letter = item['letter']?.toString();
        final count = _extractCount(item);
        final firstPoemId = _extractFirstPoemId(item);
        if (letter != null && count != null) {
          index[letter.toUpperCase()] = LetterPoemIndexEntry(
            count: count,
            firstPoemId: firstPoemId,
          );
        }
      }

      if (index.isNotEmpty) {
        return index;
      }
    }

    throw ApiException('Invalid letter counts response format');
  }

  Future<Map<String, int>> getPoemCountsByLetter() async {
    final index = await getPoemLetterIndex();
    return index.map((letter, entry) => MapEntry(letter, entry.count));
  }

  int? _extractCount(dynamic value) {
    if (value is Map<String, dynamic>) {
      return _parseCountValue(value['count']);
    }
    return _parseCountValue(value);
  }

  int? _extractFirstPoemId(dynamic value) {
    if (value is! Map<String, dynamic>) return null;
    return _parseCountValue(value['first_poem_id'] ?? value['firstPoemId']);
  }

  int? _parseCountValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<Poem> getPoemById(int id) async {
    final url = '$baseUrl/poems/$id';
    final data = await _requestWithAuthRetry(
      () => http.get(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: _token != null),
      ),
      requiresAuth: _token != null,
      endpoint: '/poems/$id',
    );
    return Poem.fromJson(data as Map<String, dynamic>);
  }

  /// Load poem with all poems from the same letter
  /// If API supports it, returns poems_for_letter; otherwise returns just the poem
  Future<Map<String, dynamic>> getPoemWithLetterPoems(int id) async {
    try {
      // Try new API endpoint that includes letter poems
      final data = await _requestWithAuthRetry(
        () => http.get(
          Uri.parse('$baseUrl/poems/$id?include_letter_poems=true'),
          headers: _getHeaders(includeAuth: _token != null),
        ),
        requiresAuth: _token != null,
        endpoint: '/poems/$id',
      );

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
    final data = await _requestWithAuthRetry(
      () => http.get(
        Uri.parse('$baseUrl/search?q=$query'),
        headers: _getHeaders(includeAuth: _token != null),
      ),
      requiresAuth: _token != null,
      endpoint: '/search',
    );
    // API возвращает {items: [...], total: N}
    final items = data['items'] as List;
    return items.map((poem) => Poem.fromJson(poem)).toList();
  }

  // Subscription endpoints
  Future<Subscription> getSubscriptionStatus() async {
    final data = await _requestWithAuthRetry(
      () => http.get(
        Uri.parse('$baseUrl/subscription/status'),
        headers: _getHeaders(includeAuth: true),
      ),
      requiresAuth: true,
      endpoint: '/subscription/status',
    );
    return Subscription.fromJson(data);
  }

  // Stats endpoint
  Future<Stats> getStats() async {
    final data = await _requestWithAuthRetry(
      () => http.get(
        Uri.parse('$baseUrl/stats'),
        headers: _getHeaders(includeAuth: true),
      ),
      requiresAuth: true,
      endpoint: '/stats',
    );
    return Stats.fromJson(data);
  }

  // Read history endpoint
  Future<List<Poem>> getReadHistory() async {
    final data = await _requestWithAuthRetry(
      () => http.get(
        Uri.parse('$baseUrl/stats/read-poems'),
        headers: _getHeaders(includeAuth: true),
      ),
      requiresAuth: true,
      endpoint: '/stats/read-poems',
    );

    if (data is! List) {
      throw ApiException('Invalid read history response format');
    }

    return data.whereType<Map<String, dynamic>>().map(Poem.fromJson).toList();
  }

  // Payment endpoint
  Future<Map<String, dynamic>> createPayment({
    required String planId,
    required String returnUrl,
  }) async {
    final data = await _requestWithAuthRetry(
      () => http.post(
        Uri.parse('$baseUrl/payment/create'),
        headers: _getHeaders(includeAuth: true),
        body: json.encode({'plan_id': planId, 'return_url': returnUrl}),
      ),
      requiresAuth: true,
      endpoint: '/payment/create',
    );

    if (data is! Map<String, dynamic>) {
      throw ApiException('Некорректный ответ сервера оплаты.');
    }
    return data;
  }

  // Favorites endpoints (placeholder for future implementation)
  Future<List<Poem>> getFavorites() async {
    final data = await _requestWithAuthRetry(
      () => http.get(
        Uri.parse('$baseUrl/favorites'),
        headers: _getHeaders(includeAuth: true),
      ),
      requiresAuth: true,
      endpoint: '/favorites',
    );
    return (data as List).map((poem) => Poem.fromJson(poem)).toList();
  }

  Future<void> addToFavorites(int poemId) async {
    await _requestWithAuthRetry(
      () => http.post(
        Uri.parse('$baseUrl/favorites'),
        headers: _getHeaders(includeAuth: true),
        body: json.encode({'poem_id': poemId}),
      ),
      requiresAuth: true,
      endpoint: '/favorites',
    );
  }

  Future<void> removeFromFavorites(int poemId) async {
    await _requestWithAuthRetry(
      () => http.delete(
        Uri.parse('$baseUrl/favorites/$poemId'),
        headers: _getHeaders(includeAuth: true),
      ),
      requiresAuth: true,
      endpoint: '/favorites/$poemId',
    );
  }

  Future<void> deleteAccount() async {
    await _requestWithAuthRetry(
      () => http.delete(
        Uri.parse('$baseUrl/auth/me'),
        headers: _getHeaders(includeAuth: true),
      ),
      requiresAuth: true,
      endpoint: '/auth/me',
    );
  }

  Future<void> markAsLearned(int poemId) async {
    await _requestWithAuthRetry(
      () => http.post(
        Uri.parse('$baseUrl/learned'),
        headers: _getHeaders(includeAuth: true),
        body: json.encode({'poem_id': poemId}),
      ),
      requiresAuth: true,
      endpoint: '/learned',
    );
  }
}
