/// Persisted locale preference — reads from and writes to a small JSON file
/// separate from the main database. Defaults to Bahasa Indonesia.
///
/// IMPLEMENTATION STATUS: IMPLEMENTED — lightweight file-based persistence
/// consistent with the existing [LocalDatabase] / [FileDbStorage] pattern.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

// ---------------------------------------------------------------------------
// Persistence helper
// ---------------------------------------------------------------------------

class _LocalePrefs {
  static const _fileName = 'ibudaya_prefs.json';
  static const _key = 'locale';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<Locale?> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      final map = jsonDecode(raw);
      final code = map[_key] as String?;
      if (code == null) return null;
      return Locale(code);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(Locale locale) async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode({_key: locale.languageCode}));
    } catch (_) {
      // Persistence failure must never crash the app.
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod notifier
// ---------------------------------------------------------------------------

const _defaultLocale = Locale('id', 'ID');

class LocaleNotifier extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    return await _LocalePrefs.load() ?? _defaultLocale;
  }

  Future<void> setLocale(Locale locale) async {
    state = AsyncData(locale);
    await _LocalePrefs.save(locale);
  }
}

final localeProvider = AsyncNotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

/// Synchronous resolved locale — falls back to id while the async load is in
/// progress (typically completes in < 1 frame). Widgets that need the locale
/// watch this provider.
final resolvedLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(localeProvider).asData?.value ?? _defaultLocale;
});
