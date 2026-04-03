import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';

enum ReaderBackgroundMode { white, dark, papyrus }

enum ReaderAccentColor { green, red, gold, blue, purple }

class ReaderSettingsProvider with ChangeNotifier {
  final ApiService _apiService;

  ReaderBackgroundMode _backgroundMode = ReaderBackgroundMode.white;
  ReaderAccentColor _accentColor = ReaderAccentColor.green;

  List<ReaderBackgroundMode> _availableBackgroundModes = ReaderBackgroundMode
      .values
      .toList();
  List<ReaderAccentColor> _availableAccentColors = ReaderAccentColor.values
      .toList();

  final Map<ReaderBackgroundMode, Color> _backgroundColors = {
    ReaderBackgroundMode.white: Colors.white,
    ReaderBackgroundMode.dark: const Color(0xFF111111),
    ReaderBackgroundMode.papyrus: const Color(0xFFF4ECD8),
  };

  final Map<ReaderAccentColor, Color> _accentColors = {
    ReaderAccentColor.green: const Color(0xFF1B7F3A),
    ReaderAccentColor.red: const Color(0xFFB42318),
    ReaderAccentColor.gold: const Color(0xFFB28704),
    ReaderAccentColor.blue: const Color(0xFF1D4ED8),
    ReaderAccentColor.purple: const Color(0xFF7E22CE),
  };

  ReaderSettingsProvider(this._apiService);

  ReaderBackgroundMode get backgroundMode => _backgroundMode;
  ReaderAccentColor get accentColor => _accentColor;
  List<ReaderBackgroundMode> get availableBackgroundModes =>
      _availableBackgroundModes;
  List<ReaderAccentColor> get availableAccentColors => _availableAccentColors;

  Color get backgroundColor {
    return _backgroundColors[_backgroundMode] ?? Colors.white;
  }

  Color get cardColor {
    final bg = backgroundColor;
    if (_backgroundMode == ReaderBackgroundMode.dark ||
        bg.computeLuminance() < 0.25) {
      return Color.alphaBlend(Colors.white.withOpacity(0.06), bg);
    }
    return Color.alphaBlend(Colors.black.withOpacity(0.02), bg);
  }

  Color get primaryTextColor {
    final luminance = backgroundColor.computeLuminance();
    return luminance < 0.35 ? const Color(0xFFEAEAEA) : const Color(0xFF1E1E1E);
  }

  Color get accentTextColor {
    return _accentColors[_accentColor] ?? const Color(0xFF1B7F3A);
  }

  Color get appPrimaryColor {
    switch (_backgroundMode) {
      case ReaderBackgroundMode.dark:
        return const Color(0xFF334155);
      case ReaderBackgroundMode.papyrus:
        return const Color(0xFF8B6A3E);
      case ReaderBackgroundMode.white:
        return const Color(0xFF6366F1);
    }
  }

  LinearGradient get appPrimaryGradient {
    switch (_backgroundMode) {
      case ReaderBackgroundMode.dark:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2937), Color(0xFF475569)],
        );
      case ReaderBackgroundMode.papyrus:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C5B34), Color(0xFFB48A55)],
        );
      case ReaderBackgroundMode.white:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        );
    }
  }

  Color colorForBackgroundMode(ReaderBackgroundMode mode) {
    return _backgroundColors[mode] ?? Colors.white;
  }

  Color colorForAccent(ReaderAccentColor color) {
    return _accentColors[color] ?? const Color(0xFF1B7F3A);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final bg = prefs.getString(AppConstants.keyReaderBackgroundMode);
    final accent = prefs.getString(AppConstants.keyReaderAccentColor);
    final hasStoredBackground = bg != null;
    final hasStoredAccent = accent != null;

    if (bg != null) {
      _backgroundMode = ReaderBackgroundMode.values.firstWhere(
        (value) => value.name == bg,
        orElse: () => ReaderBackgroundMode.white,
      );
    }

    if (accent != null) {
      _accentColor = ReaderAccentColor.values.firstWhere(
        (value) => value.name == accent,
        orElse: () => ReaderAccentColor.green,
      );
    }

    await _loadThemesFromServer(
      hasStoredBackground: hasStoredBackground,
      hasStoredAccent: hasStoredAccent,
    );

    notifyListeners();
  }

  Future<void> _loadThemesFromServer({
    required bool hasStoredBackground,
    required bool hasStoredAccent,
  }) async {
    try {
      final data = await _apiService.getReaderThemes();

      final backgroundsRaw = data['backgrounds'];
      if (backgroundsRaw is List) {
        final parsed = <_OrderedBackground>[];
        for (final item in backgroundsRaw) {
          if (item is! Map<String, dynamic>) continue;
          if (item['enabled'] != true) continue;
          final mode = _backgroundModeFromKey(item['key'] as String?);
          if (mode == null) continue;
          final color = _colorFromHex(item['hex'] as String?);
          if (color != null) {
            _backgroundColors[mode] = color;
          }
          parsed.add(
            _OrderedBackground(mode, (item['order'] as num?)?.toInt() ?? 999),
          );
        }
        if (parsed.isNotEmpty) {
          parsed.sort((a, b) => a.order.compareTo(b.order));
          _availableBackgroundModes = parsed.map((e) => e.mode).toList();
        }
      }

      final accentsRaw = data['accents'];
      if (accentsRaw is List) {
        final parsed = <_OrderedAccent>[];
        for (final item in accentsRaw) {
          if (item is! Map<String, dynamic>) continue;
          if (item['enabled'] != true) continue;
          final accent = _accentColorFromKey(item['key'] as String?);
          if (accent == null) continue;
          final color = _colorFromHex(item['hex'] as String?);
          if (color != null) {
            _accentColors[accent] = color;
          }
          parsed.add(
            _OrderedAccent(accent, (item['order'] as num?)?.toInt() ?? 999),
          );
        }
        if (parsed.isNotEmpty) {
          parsed.sort((a, b) => a.order.compareTo(b.order));
          _availableAccentColors = parsed.map((e) => e.color).toList();
        }
      }

      final defaultBackground = _backgroundModeFromKey(
        data['default_background'] as String?,
      );
      final defaultAccent = _accentColorFromKey(
        data['default_accent'] as String?,
      );

      if (!hasStoredBackground &&
          defaultBackground != null &&
          _availableBackgroundModes.contains(defaultBackground)) {
        _backgroundMode = defaultBackground;
      }

      if (!hasStoredAccent &&
          defaultAccent != null &&
          _availableAccentColors.contains(defaultAccent)) {
        _accentColor = defaultAccent;
      }

      if (!_availableBackgroundModes.contains(_backgroundMode) &&
          _availableBackgroundModes.isNotEmpty) {
        _backgroundMode = _availableBackgroundModes.first;
      }

      if (!_availableAccentColors.contains(_accentColor) &&
          _availableAccentColors.isNotEmpty) {
        _accentColor = _availableAccentColors.first;
      }
    } catch (_) {
      // Keep local defaults when server settings are unavailable.
    }
  }

  ReaderBackgroundMode? _backgroundModeFromKey(String? key) {
    if (key == null) return null;
    for (final value in ReaderBackgroundMode.values) {
      if (value.name == key) return value;
    }
    return null;
  }

  ReaderAccentColor? _accentColorFromKey(String? key) {
    if (key == null) return null;
    for (final value in ReaderAccentColor.values) {
      if (value.name == key) return value;
    }
    return null;
  }

  Color? _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    if (value.length != 8) return null;
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return null;
    return Color(parsed);
  }

  Future<void> setBackgroundMode(ReaderBackgroundMode mode) async {
    if (!_availableBackgroundModes.contains(mode)) return;
    _backgroundMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyReaderBackgroundMode, mode.name);
  }

  Future<void> setAccentColor(ReaderAccentColor color) async {
    if (!_availableAccentColors.contains(color)) return;
    _accentColor = color;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyReaderAccentColor, color.name);
  }
}

class _OrderedBackground {
  final ReaderBackgroundMode mode;
  final int order;

  _OrderedBackground(this.mode, this.order);
}

class _OrderedAccent {
  final ReaderAccentColor color;
  final int order;

  _OrderedAccent(this.color, this.order);
}
