import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:meo_sinhton/models/survival_tip.dart';

class TipRepository {
  static const String _tipAssetPath = 'assets/data/tips.json';
  static List<SurvivalTip>? _cachedTips;
  static Future<List<SurvivalTip>>? _loadingFuture;

  static Future<List<SurvivalTip>> loadTips() async {
    final cached = _cachedTips;
    if (cached != null) {
      return cached;
    }

    final loading = _loadingFuture;
    if (loading != null) {
      return loading;
    }

    _loadingFuture = _loadAndCacheTips();
    try {
      return await _loadingFuture!;
    } finally {
      _loadingFuture = null;
    }
  }

  static Future<List<SurvivalTip>> _loadAndCacheTips() async {
    final raw = await rootBundle.loadString(_tipAssetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    final tips = decoded
        .map((item) => SurvivalTip.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    _cachedTips = tips;
    return tips;
  }

  static void clearCache() {
    _cachedTips = null;
    _loadingFuture = null;
  }
}
