import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'app_data.dart';

/// Where the user's records live.
///
/// The interface exists so a future synced/remote implementation can replace
/// the local one without touching anything above it (docs/ARCHITECTURE.md §4).
abstract interface class AppStore {
  Future<AppData> load();
  Future<void> save(AppData data);
  Future<void> clear();
}

/// Reads and writes the whole document as one JSON file in the app's documents
/// directory.
///
/// Writes go to a temp file and are then renamed over the real one, so a crash
/// or a kill mid-write can never leave a half-written document behind — the
/// user either keeps the previous save or gets the new one, never a corrupt
/// mix. At this scale (a few hundred records over years) a single document is
/// both faster and far less failure-prone than a database.
class FileAppStore implements AppStore {
  FileAppStore({this.fileName = 'ibudaya_data.json'});

  final String fileName;
  File? _cached;

  Future<File> _file() async {
    final cached = _cached;
    if (cached != null) return cached;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    _cached = file;
    return file;
  }

  @override
  Future<AppData> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return AppData.empty;
      final text = await file.readAsString();
      if (text.trim().isEmpty) return AppData.empty;
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return AppData.empty;
      return AppData.fromJson(decoded);
    } catch (_) {
      // A damaged file must not brick the app; the user starts clean rather
      // than facing a crash loop they cannot escape.
      return AppData.empty;
    }
  }

  @override
  Future<void> save(AppData data) async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(data.toJson()), flush: true);
    await tmp.rename(file.path);
  }

  @override
  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) await file.delete();
  }
}

/// In-memory store for tests and previews.
class MemoryAppStore implements AppStore {
  MemoryAppStore([this._data = AppData.empty]);

  AppData _data;

  @override
  Future<AppData> load() async => _data;

  @override
  Future<void> save(AppData data) async => _data = data;

  @override
  Future<void> clear() async => _data = AppData.empty;
}
