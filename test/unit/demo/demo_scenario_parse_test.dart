import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/demo/demo_scenario.dart';

void main() {
  group('DemoScenario.fromJson', () {
    test('parses the bundled happy-path seed asset', () {
      final file = File('assets/demo/scenario_happy_path.json');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'seed asset must exist for offline Demo Mode',
      );

      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final scenario = DemoScenario.fromJson(json);

      expect(scenario.user.displayName, 'Ibu Clara');
      expect(scenario.user.greetingName, 'Ibu Clara');
      expect(scenario.user.id, 'IDB-2404-1287');
      expect(scenario.meta.label, contains('Ibu Clara'));
      expect(scenario.meta.generatedAt.year, 2026);
    });

    test('throws a typed error on a malformed seed', () {
      expect(
        () => DemoScenario.fromJson(<String, dynamic>{'meta': 'not-an-object'}),
        throwsA(isA<DemoScenarioFormatException>()),
      );
    });
  });
}
