import 'package:flutter/material.dart';
import '../services/api_service.dart';
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

  bool get isAuthenticated => _isAuthenticated;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token != null) {
        _apiService.setToken(token);
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

      if (response['access_token'] == null) {
        throw Exception('Токен не получен от сервера');
      }

      final token = response['access_token'] as String;

      await _storageService.saveToken(token);
      _apiService.setToken(token);
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
      final token = response['access_token'];

      await _storageService.saveToken(token);
      _apiService.setToken(token);
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

  Future<void> logout() async {
    await _storageService.deleteToken();
    _apiService.setToken(null);
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
