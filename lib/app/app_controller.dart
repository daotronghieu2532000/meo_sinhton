import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

enum AppLanguage { vietnamese, english }

class AppController extends ChangeNotifier {
  AppController._({
    required this.language,
    required this.themeMode,
    required this.userId,
    required SharedPreferences? prefs,
  }) : _prefs = prefs;

  static const String _languageKey = 'app_language';
  static const String _darkModeKey = 'dark_mode_enabled';
  static const String _adFreeUntilKey = 'ad_free_until_epoch_ms';
  static const String _savedTipIdsKey = 'saved_tip_ids';
  static const String _userIdKey = 'app_user_id';

  final SharedPreferences? _prefs;
  final String userId;
  AppLanguage language;
  ThemeMode themeMode;
  DateTime? _adFreeUntil;
  Timer? _adFreeExpiryTimer;
  final Set<String> _savedTipIds = <String>{};

  bool get isEnglish => language == AppLanguage.english;
  DateTime? get adFreeUntil => _adFreeUntil;
  Set<String> get savedTipIds => Set.unmodifiable(_savedTipIds);

  bool isTipSaved(String tipId) => _savedTipIds.contains(tipId);

  Future<void> toggleTipSaved(String tipId) async {
    if (_savedTipIds.contains(tipId)) {
      _savedTipIds.remove(tipId);
    } else {
      _savedTipIds.add(tipId);
    }
    notifyListeners();
    if (_prefs != null) {
      await _prefs.setStringList(_savedTipIdsKey, _savedTipIds.toList());
    }
  }

  bool get areAdsTemporarilyDisabled {
    final until = _adFreeUntil;
    if (until == null) {
      return false;
    }
    return DateTime.now().isBefore(until);
  }

  Duration? get adFreeRemaining {
    final until = _adFreeUntil;
    if (until == null) {
      return null;
    }
    final remaining = until.difference(DateTime.now());
    if (remaining.isNegative) {
      return null;
    }
    return remaining;
  }

  static Future<AppController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);
    final darkModeEnabled = prefs.getBool(_darkModeKey) ?? false;
    final savedTipIds = prefs.getStringList(_savedTipIdsKey) ?? const [];
    final adFreeUntilEpochMs = prefs.getInt(_adFreeUntilKey);
    final adFreeUntil = adFreeUntilEpochMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(adFreeUntilEpochMs);
    
    String? userId = prefs.getString(_userIdKey);
    if (userId == null || userId.startsWith('user_')) {
      // Pure numeric ID: timestamp + 4 random digits (Total ~17 digits, fits in BIGINT)
      final now = DateTime.now().millisecondsSinceEpoch;
      final random = (1000 + (DateTime.now().microsecond % 9000)).toString();
      userId = '$now$random';
      await prefs.setString(_userIdKey, userId);
    }

    final controller = AppController._(
      language: savedLanguage == 'en'
          ? AppLanguage.english
          : AppLanguage.vietnamese,
      themeMode: darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      userId: userId,
      prefs: prefs,
    );

    controller._adFreeUntil = adFreeUntil;
    controller._savedTipIds
      ..clear()
      ..addAll(savedTipIds);
    controller._scheduleAdFreeExpiryTimer();
    return controller;
  }

  factory AppController.fallback() {
    return AppController._(
      language: AppLanguage.vietnamese,
      themeMode: ThemeMode.light,
      userId: 'offline_user',
      prefs: null,
    );
  }

  Future<void> setLanguage(AppLanguage value) async {
    if (language == value) {
      return;
    }
    language = value;
    notifyListeners();
    if (_prefs != null) {
      await _prefs.setString(
        _languageKey,
        value == AppLanguage.english ? 'en' : 'vi',
      );
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    final newTheme = enabled ? ThemeMode.dark : ThemeMode.light;
    if (themeMode == newTheme) {
      return;
    }
    themeMode = newTheme;
    notifyListeners();
    if (_prefs != null) {
      await _prefs.setBool(_darkModeKey, enabled);
    }
  }

  Future<void> grantAdFreeForOneHour() async {
    _adFreeUntil = DateTime.now().add(const Duration(hours: 1));
    _scheduleAdFreeExpiryTimer();
    notifyListeners();
    if (_prefs != null) {
      await _prefs.setInt(
        _adFreeUntilKey,
        _adFreeUntil!.millisecondsSinceEpoch,
      );
    }
  }

  void _scheduleAdFreeExpiryTimer() {
    _adFreeExpiryTimer?.cancel();
    final until = _adFreeUntil;
    if (until == null) {
      return;
    }

    final duration = until.difference(DateTime.now());
    if (duration.isNegative || duration.inMilliseconds <= 0) {
      _adFreeUntil = null;
      unawaited(_prefs?.remove(_adFreeUntilKey));
      notifyListeners();
      return;
    }

    _adFreeExpiryTimer = Timer(duration, () {
      _adFreeUntil = null;
      unawaited(_prefs?.remove(_adFreeUntilKey));
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _adFreeExpiryTimer?.cancel();
    super.dispose();
  }
}
