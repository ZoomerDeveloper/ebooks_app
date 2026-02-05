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
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConstants.keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConstants.keyToken);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: AppConstants.keyToken);
  }

  // Onboarding
  Future<void> setOnboardingComplete() async {
    await _prefs?.setBool(AppConstants.keyOnboardingComplete, true);
  }

  bool isOnboardingComplete() {
    return _prefs?.getBool(AppConstants.keyOnboardingComplete) ?? false;
  }

  // Clear all data
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs?.clear();
  }
}
