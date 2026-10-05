import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConstants {
  // API Configuration
  // static const String baseUrl = 'https://vm261731.hosted-by-robovps.ru';
  static const String prodBaseUrl = 'https://api.smartpoems.ru';
  // Mac's LAN IP: physical devices can't reach the backend via 127.0.0.1.
  static const String localBaseUrl = 'http://192.168.1.112:8000';
  static const String simulatorBaseUrl = 'http://127.0.0.1:8000';
  static const bool useLocalServer = true;

  // Release builds always use production, regardless of useLocalServer.
  static String get baseUrl {
    if (!useLocalServer || kReleaseMode) return prodBaseUrl;
    // Platform.environment is always empty on iOS, so detect the simulator
    // by its executable path instead.
    if (Platform.isIOS &&
        Platform.resolvedExecutable.contains('/CoreSimulator/')) {
      return simulatorBaseUrl;
    }
    return localBaseUrl;
  }

  static const String paymentReturnUrl = 'epoems://payment/result';
  static const String privacyPolicyUrl = 'https://api.smartpoems.ru/privacy';

  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyLegacyToken = 'auth_token';
  static const String keyToken = keyAccessToken;
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyReaderBackgroundMode = 'reader_background_mode';
  static const String keyReaderAccentColor = 'reader_accent_color';
  static const String keyFontSizeScale = 'font_size_scale';
  static const String keyLastPoemByLetterPrefix = 'last_poem_letter_';
  static const String keyMeaningFilterAllLetters = 'meaning_filter_all_letters';
  static const String keyMeaningFilterGlobal = 'meaning_filter_global';
  static const String keyMeaningFilterByLetter = 'meaning_filter_by_letter';

  // Meaning-count filter buckets: 1..(max - 1) exact, max means "max or more".
  static const int meaningFilterMaxBucket = 21;

  // Alphabet
  static const List<String> alphabet = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'Y',
    'Z',
  ];

  // Animation Durations
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
}
