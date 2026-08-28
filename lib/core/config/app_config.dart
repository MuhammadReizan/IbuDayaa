import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide configuration. The MVP ships a single flavour: **demo**
/// (docs/ARCHITECTURE.md §10). [isDemo] is the switch point repository
/// providers use; there is no second flavour to build yet.
class AppConfig {
  const AppConfig({
    this.isDemo = true,
    this.demoScenarioAsset = 'assets/demo/scenario_happy_path.json',
  });

  final bool isDemo;
  final String demoScenarioAsset;

  /// Android application id (com.baswaramusi.ibudaya) and display name.
  static const String applicationId = 'com.baswaramusi.ibudaya';
  static const String appName = 'IbuDaya';
}

final appConfigProvider = Provider<AppConfig>((ref) => const AppConfig());
