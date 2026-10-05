import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token Management
  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(
      key: AppConstants.keyAccessToken,
      value: accessToken,
    );
    await _secureStorage.write(
      key: AppConstants.keyRefreshToken,
      value: refreshToken,
    );
  }

  Future<void> saveAccessToken(String accessToken) async {
    await _secureStorage.write(
      key: AppConstants.keyAccessToken,
      value: accessToken,
    );
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await _secureStorage.write(
      key: AppConstants.keyRefreshToken,
      value: refreshToken,
    );
  }

  Future<void> saveToken(String token) async {
    await saveAccessToken(token);
  }

  Future<String?> getAccessToken() async {
    final token = await _secureStorage.read(key: AppConstants.keyAccessToken);
    if (token != null && token.isNotEmpty) {
      return token;
    }

    final legacyToken = await _secureStorage.read(
      key: AppConstants.keyLegacyToken,
    );
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await saveAccessToken(legacyToken);
      await _secureStorage.delete(key: AppConstants.keyLegacyToken);
      return legacyToken;
    }

    return null;
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.keyRefreshToken);
  }

  Future<String?> getToken() async {
    return await getAccessToken();
  }

  Future<void> deleteAuthTokens() async {
    await _secureStorage.delete(key: AppConstants.keyAccessToken);
    await _secureStorage.delete(key: AppConstants.keyRefreshToken);
    await _secureStorage.delete(key: AppConstants.keyLegacyToken);
  }

  Future<void> deleteToken() async {
    await deleteAuthTokens();
  }

  // Onboarding
  Future<void> setOnboardingComplete() async {
    await _prefs?.setBool(AppConstants.keyOnboardingComplete, true);
  }

  bool isOnboardingComplete() {
    return _prefs?.getBool(AppConstants.keyOnboardingComplete) ?? false;
  }

  // Last poem per letter (resume by letter)
  Future<void> saveLastPoemIdForLetter(String letter, int id) async {
    await _prefs?.setInt(
      '${AppConstants.keyLastPoemByLetterPrefix}${letter.toUpperCase()}',
      id,
    );
  }

  int? getLastPoemIdForLetter(String letter) {
    return _prefs?.getInt(
      '${AppConstants.keyLastPoemByLetterPrefix}${letter.toUpperCase()}',
    );
  }

  // Clear all data
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs?.clear();
  }
}
