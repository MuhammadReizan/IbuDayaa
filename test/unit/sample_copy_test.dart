import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/l10n/l10n.dart';
import 'package:ibudaya/core/repositories/local/sample_seeder.dart';

/// What the welcome screen tells people about the sample cooperative must be
/// what the seeder really makes: the PIN they will type and how many members.
void main() {
  for (final lang in ['id', 'en']) {
    test('the sample copy matches the seeder ($lang)', () {
      final l10n = AppLocalizations.forLocale(Locale(lang));
      expect(l10n.sampleMessage, contains(SampleSeeder.pin));
      expect(
        l10n.welcomeSampleBanner,
        contains('${SampleSeeder.members.length} '),
      );
    });
  }
}
