import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../models/subscription.dart';
import '../models/stats.dart';
import '../models/app_config.dart';
import '../models/poem.dart';
import '../mixins/auto_cache_mixin.dart';

class AppDataProvider with ChangeNotifier, AutoCacheMixin {
  final ApiService _apiService;

  Subscription? _subscription;
  Stats? _stats;
  AppConfig? _appConfig;
  List<Poem> _favorites = [];
  List<Poem> _readHistory = [];
  String? _error;

  // Ключи для кэша
  static const _statsKey = 'stats';
  static const _favoritesKey = 'favorites';
  static const _readHistoryKey = 'readHistory';
  static const _subscriptionKey = 'subscription';
  static const _appConfigKey = 'appConfig';

  AppDataProvider(this._apiService);

  Subscription? get subscription =>
      getCached<Subscription>(_subscriptionKey) ?? _subscription;
  Stats? get stats => getCached<Stats>(_statsKey) ?? _stats;
  AppConfig? get appConfig => getCached<AppConfig>(_appConfigKey) ?? _appConfig;
  List<Poem> get favorites =>
      getCached<List<Poem>>(_favoritesKey) ?? _favorites;
  List<Poem> get readHistory => getCached<List<Poem>>(_readHistoryKey) ?? _readHistory;

  // Общий isLoading проверяет загрузку любого ресурса
  bool get isLoading =>
      isLoadingFor(_statsKey) ||
      isLoadingFor(_favoritesKey) ||
      isLoadingFor(_readHistoryKey) ||
      isLoadingFor(_subscriptionKey) ||
      isLoadingFor(_appConfigKey);

  bool get isLoadingReadHistory => isLoadingFor(_readHistoryKey);

  String? get error => _error;

  Future<void> loadAppConfig({bool forceRefresh = false}) async {
    try {
      _appConfig = await fetchWithCache<AppConfig>(
        key: _appConfigKey,
        fetcher: () => _apiService.getConfig(),
        forceRefresh: forceRefresh,
        cacheDuration: const Duration(hours: 1), // Конфиг редко меняется
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadSubscription({bool forceRefresh = false}) async {
    _error = null;

    try {
      _subscription = await fetchWithCache<Subscription>(
        key: _subscriptionKey,
        fetcher: () => _apiService.getSubscriptionStatus(),
        forceRefresh: forceRefresh,
        cacheDuration: const Duration(minutes: 2),
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadStats({bool forceRefresh = false}) async {
    _error = null;

    try {
      _stats = await fetchWithCache<Stats>(
        key: _statsKey,
        fetcher: () => _apiService.getStats(),
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadFavorites({bool forceRefresh = false}) async {
    _error = null;

    try {
      _favorites =
          await fetchWithCache<List<Poem>>(
            key: _favoritesKey,
            fetcher: () => _apiService.getFavorites(),
            forceRefresh: forceRefresh,
          ) ??
          [];
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadReadHistory({bool forceRefresh = false}) async {
    _error = null;

    try {
      _readHistory =
          await fetchWithCache<List<Poem>>(
                key: _readHistoryKey,
                fetcher: () => _apiService.getReadHistory(),
                forceRefresh: forceRefresh,
              ) ??
          [];
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addToFavorites(int poemId) async {
    try {
      await _apiService.addToFavorites(poemId);
      // Инвалидируем кэш и загружаем заново
      clearCache(_favoritesKey);
      await loadFavorites(forceRefresh: true);
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
      // Инвалидируем кэш и загружаем заново
      clearCache(_favoritesKey);
      await loadFavorites(forceRefresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAsLearned(int poemId) async {
    try {
      await _apiService.markAsLearned(poemId);
      clearCache(_statsKey);
      await loadStats(forceRefresh: true);
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

  Future<Map<String, dynamic>?> createPayment({required String planId}) async {
    try {
      return await _apiService.createPayment(
        planId: planId,
        returnUrl: AppConstants.paymentReturnUrl,
      );
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
