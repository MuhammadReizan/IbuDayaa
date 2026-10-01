import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/errors.dart';

/// A message the user reads must exist in both languages. This fails the
/// moment someone adds `AppException('...')` without an English `en:`.
void main() {
  test('every AppException carries an English message', () {
    final missing = <String>[];
    final backslash = String.fromCharCode(92);
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.replaceAll(backslash, '/').endsWith('core/errors.dart')) {
        continue;
      }
      final src = file.readAsStringSync();
      for (final m in RegExp(r'AppException\(').allMatches(src)) {
        var depth = 1;
        String? quote;
        var i = m.end;
        while (depth > 0 && i < src.length) {
          final c = src[i];
          if (quote != null) {
            if (c == backslash) {
              i++;
            } else if (c == quote) {
              quote = null;
            }
          } else if (c == "'" || c == '"') {
            quote = c;
          } else if (c == '(') {
            depth++;
          } else if (c == ')') {
            depth--;
          }
          i++;
        }
        final args = src.substring(m.end, i - 1);
        if (!RegExp(r'\ben:').hasMatch(args)) {
          final line = src.substring(0, m.start).split('\n').length;
          missing.add('${file.path}:$line');
        }
      }
    }
    expect(missing, isEmpty, reason: 'AppException without en: $missing');
  });

  test('AppException.localized picks the language, Indonesian by default', () {
    const both = AppException('Halo', en: 'Hello');
    expect(both.localized(english: false), 'Halo');
    expect(both.localized(english: true), 'Hello');
    const onlyId = AppException('Halo');
    expect(onlyId.localized(english: true), 'Halo');
  });
}
