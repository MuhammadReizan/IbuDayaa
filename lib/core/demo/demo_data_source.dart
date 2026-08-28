import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'demo_scenario.dart';

/// DATA SOURCE layer (docs/ARCHITECTURE.md §2).
///
/// Abstracts *where* the demo scenario comes from. The MVP has exactly one
/// implementation ([AssetDemoDataSource]); a future build could add a remote or
/// file-backed source without changing repositories or UI.
abstract interface class DemoDataSource {
  Future<DemoScenario> load();
}

/// Loads the bundled JSON seed. No network — this is what makes offline Demo
/// Mode possible.
class AssetDemoDataSource implements DemoDataSource {
  AssetDemoDataSource(this.assetPath, {AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  @override
  Future<DemoScenario> load() async {
    final String raw = await _bundle.loadString(assetPath);
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw DemoScenarioFormatException(
        'root of $assetPath is not a JSON object',
      );
    }
    return DemoScenario.fromJson(decoded);
  }
}
