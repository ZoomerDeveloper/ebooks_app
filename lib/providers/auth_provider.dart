import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_navigation_service.dart';
import '../services/storage_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  bool _isAuthenticated = false;
  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._apiService, this._storageService);

  Future<void> _handleAuthFailure() async {
    await logout(redirectToLogin: true);
  }

  bool get isAuthenticated => _isAuthenticated;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _apiService.setAuthFailureHandler(_handleAuthFailure);

      final accessToken = await _storageService.getAccessToken();
      if (accessToken != null) {
        _apiService.setToken(accessToken);
        _isAuthenticated = true;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Registration now sends verification code to email
      // No token is returned, just success response
      await _apiService.register(email, password);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginByCode(String email, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.loginByCode(email, code);

      if (response['access_token'] == null || response['refresh_token'] == null) {
        throw Exception('Токены не получены от сервера');
      }

      final accessToken = response['access_token'] as String;
      final refreshToken = response['refresh_token'] as String;

      await _storageService.saveAuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      _apiService.setToken(accessToken);
      _isAuthenticated = true;

      if (response['user'] != null) {
        _user = User.fromJson(response['user']);
      } else if (response['email'] != null) {
        _user = User.fromJson(response);
      } else {
        _user = User(email: email);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      final accessToken = response['access_token']?.toString();
      final refreshToken = response['refresh_token']?.toString();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Токен доступа не получен от сервера');
      }

      if (refreshToken == null || refreshToken.isEmpty) {
        throw Exception('Refresh токен не получен от сервера');
      }

      await _storageService.saveAuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      _apiService.setToken(accessToken);
      _isAuthenticated = true;

      if (response['user'] != null) {
        _user = User.fromJson(response['user']);
      } else {
        _user = User(email: email);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestCode(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.requestCode(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout({bool redirectToLogin = false}) async {
    await _storageService.deleteAuthTokens();
    _apiService.setToken(null);
    _isAuthenticated = false;
    _user = null;
    notifyListeners();

    if (redirectToLogin) {
      final navigator = AppNavigationService.navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteAccount();
      await _storageService.deleteAuthTokens();
      _apiService.setToken(null);
      _isAuthenticated = false;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
