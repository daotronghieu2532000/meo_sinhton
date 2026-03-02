import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/scenario_item.dart';

class ScenarioRepository {
  static const String _assetPath = 'assets/data/scenarios.json';

  Future<List<ScenarioItem>> loadScenarios() async {
    final raw = await rootBundle.loadString(_assetPath);
    final dynamic decoded = json.decode(raw);

    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ScenarioItem.fromJson)
        .where((item) => item.id.isNotEmpty && item.steps.isNotEmpty)
        .toList(growable: false);
  }
}
