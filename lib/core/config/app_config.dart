import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide constants.
class AppConfig {
  const AppConfig();

  /// Android application id and display name.
  static const String applicationId = 'com.baswaramusi.ibudaya';
  static const String appName = 'IbuDaya';

  /// Marketing version (mirrors `pubspec.yaml`).
  static const String version = '1.0.0';

  /// User-facing build label.
  static const String versionLabel = 'IbuDaya versi $version';

  /// Team behind the app.
  static const String teamName = 'Baswara Musi';
}

final appConfigProvider = Provider<AppConfig>((ref) => const AppConfig());
