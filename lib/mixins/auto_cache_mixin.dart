import 'package:flutter/foundation.dart';

/// Mixin для автоматического кэширования данных с управлением временем жизни
mixin AutoCacheMixin on ChangeNotifier {
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, bool> _loadingStates = {};

  // Время жизни кэша по умолчанию (5 минут)
  Duration get defaultCacheDuration => const Duration(minutes: 5);

  /// Проверяет, актуален ли кэш для данного ключа
  bool _isCacheValid(String key, Duration? cacheDuration) {
    if (!_cache.containsKey(key)) return false;

    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;

    final duration = cacheDuration ?? defaultCacheDuration;
    return DateTime.now().difference(timestamp) < duration;
  }

  /// Получает данные из кэша
  T? getCached<T>(String key) {
    return _cache[key] as T?;
  }

  /// Сохраняет данные в кэш
  void setCached<T>(String key, T data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Проверяет, идет ли сейчас загрузка для данного ключа
  bool isLoadingFor(String key) {
    return _loadingStates[key] ?? false;
  }

  /// Устанавливает состояние загрузки для ключа
  void setLoadingFor(String key, bool loading) {
    _loadingStates[key] = loading;
    notifyListeners();
  }

  /// Очищает кэш для конкретного ключа
  void clearCache(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Очищает весь кэш
  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Загружает данные с автоматическим кэшированием
  ///
  /// [key] - уникальный ключ для кэша
  /// [fetcher] - функция загрузки данных
  /// [forceRefresh] - принудительно обновить даже если кэш актуален
  /// [cacheDuration] - время жизни кэша (по умолчанию 5 минут)
  /// [showLoading] - показывать ли загрузку при обновлении существующих данных
  Future<T?> fetchWithCache<T>({
    required String key,
    required Future<T> Function() fetcher,
    bool forceRefresh = false,
    Duration? cacheDuration,
    bool showLoading = true,
  }) async {
    // Если кэш актуален и не требуется принудительное обновление
    if (!forceRefresh && _isCacheValid(key, cacheDuration)) {
      return getCached<T>(key);
    }

    // Если уже идет загрузка, ждем ее завершения
    if (isLoadingFor(key)) {
      // Возвращаем кэшированные данные если они есть
      return getCached<T>(key);
    }

    // Показываем загрузку только если данных еще нет или явно запрошено
    final shouldShowLoading =
        showLoading && (getCached<T>(key) == null || forceRefresh);

    if (shouldShowLoading) {
      setLoadingFor(key, true);
    }

    try {
      final data = await fetcher();
      setCached<T>(key, data);
      setLoadingFor(key, false);
      notifyListeners();
      return data;
    } catch (e) {
      setLoadingFor(key, false);
      notifyListeners();
      rethrow;
    }
  }
}
