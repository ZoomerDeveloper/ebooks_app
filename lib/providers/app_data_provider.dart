import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/subscription.dart';
import '../models/stats.dart';
import '../models/app_config.dart';
import '../models/poem.dart';

class AppDataProvider with ChangeNotifier {
  final ApiService _apiService;

  Subscription? _subscription;
  Stats? _stats;
  AppConfig? _appConfig;
  List<Poem> _favorites = [];
  bool _isLoading = false;
  String? _error;

  AppDataProvider(this._apiService);

  Subscription? get subscription => _subscription;
  Stats? get stats => _stats;
  AppConfig? get appConfig => _appConfig;
  List<Poem> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAppConfig() async {
    try {
      _appConfig = await _apiService.getConfig();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadSubscription() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _subscription = await _apiService.getSubscriptionStatus();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _apiService.getStats();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _favorites = await _apiService.getFavorites();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToFavorites(int poemId) async {
    try {
      await _apiService.addToFavorites(poemId);
      await loadFavorites();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFromFavorites(int poemId) async {
    try {
      await _apiService.removeFromFavorites(poemId);
      await loadFavorites();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  bool isFavorite(int poemId) {
    return _favorites.any((poem) => poem.id == poemId);
  }

  Future<String?> createPayment() async {
    try {
      return await _apiService.createPayment();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
