import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:meo_sinhton/models/survival_tip.dart';

class TipRepository {
  static const String _defaultTipAssetPath = 'assets/data/tips.json';
  static const String _lifeTipAssetPath = 'assets/data/tips_life.json';
  static final Map<String, List<SurvivalTip>> _cachedTipsMap = {};
  static final Map<String, Future<List<SurvivalTip>>?> _loadingFutures = {};

  /// Load tips from the default file (tips.json)
  static Future<List<SurvivalTip>> loadTips() async {
    return loadTipsFromAsset(_defaultTipAssetPath);
  }

  /// Load tips from the life tips file (tips_life.json)
  static Future<List<SurvivalTip>> loadLifeTips() async {
    return loadTipsFromAsset(_lifeTipAssetPath);
  }

  /// Load tips from a custom asset path
  static Future<List<SurvivalTip>> loadTipsFromAsset(String assetPath) async {
    final cached = _cachedTipsMap[assetPath];
    if (cached != null) {
      return cached;
    }

    final loading = _loadingFutures[assetPath];
    if (loading != null) {
      return loading;
    }

    _loadingFutures[assetPath] = _loadAndCacheTips(assetPath);
    try {
      return await _loadingFutures[assetPath]!;
    } finally {
      _loadingFutures[assetPath] = null;
    }
  }

  static Future<List<SurvivalTip>> _loadAndCacheTips(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    final tips = decoded
        .map((item) => SurvivalTip.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    _cachedTipsMap[assetPath] = tips;
    return tips;
  }

  static void clearCache() {
    _cachedTipsMap.clear();
    _loadingFutures.clear();
  }
}
