import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'tables.dart';

typedef Row = Map<String, dynamic>;

/// Where the database bytes live.
abstract interface class DbStorage {
  Future<String?> read();
  Future<void> write(String contents);
  Future<void> clear();
}

/// One JSON file in the app documents directory, written atomically: the new
/// contents go to a temp file that is then renamed over the old one, so a kill
/// mid-write leaves either the previous save or the new one — never a mix.
class FileDbStorage implements DbStorage {
  FileDbStorage({this.fileName = 'ibudaya_db.json'});

  final String fileName;
  File? _file;

  Future<File> _resolve() async {
    final existing = _file;
    if (existing != null) return existing;
    final dir = await getApplicationDocumentsDirectory();
    return _file = File('${dir.path}/$fileName');
  }

  @override
  Future<String?> read() async {
    final file = await _resolve();
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String contents) async {
    final file = await _resolve();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(contents, flush: true);
    await tmp.rename(file.path);
  }

  @override
  Future<void> clear() async {
    final file = await _resolve();
    if (await file.exists()) await file.delete();
  }
}

class MemoryDbStorage implements DbStorage {
  String? contents;

  @override
  Future<String?> read() async => contents;

  @override
  Future<void> write(String value) async => contents = value;

  @override
  Future<void> clear() async => contents = null;
}

/// A small table store that stands in for Postgres in local mode.
///
/// Rows are plain `Map<String, dynamic>` with snake_case columns — the exact
/// shape `supabase.from(table).select()` returns — so repositories map rows to
/// models the same way against either backend.
class LocalDatabase {
  LocalDatabase._(this._storage, this._tables);

  static const int schemaVersion = 1;

  final DbStorage _storage;
  Map<String, List<Row>> _tables;
  int _txDepth = 0;
  bool _dirty = false;
  Future<void> _writes = Future.value();

  static Future<LocalDatabase> open(DbStorage storage) async {
    final tables = {for (final t in Tbl.all) t: <Row>[]};
    try {
      final raw = await storage.read();
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        final stored = decoded is Map ? decoded['tables'] : null;
        if (stored is Map) {
          stored.forEach((name, rows) {
            if (name is String && rows is List) {
              tables[name] = [
                for (final r in rows)
                  if (r is Map) Map<String, dynamic>.from(r),
              ];
            }
          });
        }
      }
    } catch (_) {
      // A damaged file must not brick the app. Start clean instead of trapping
      // the user in a crash loop they cannot get out of.
    }
    return LocalDatabase._(storage, tables);
  }

  List<Row> _t(String table) => _tables.putIfAbsent(table, () => <Row>[]);

  /// Copies of matching rows; callers can never mutate stored rows directly.
  List<Row> select(String table, [bool Function(Row r)? where]) => [
    for (final r in _t(table))
      if (where == null || where(r)) Map<String, dynamic>.of(r),
  ];

  Row? find(String table, String id) => first(table, (r) => r['id'] == id);

  Row? first(String table, bool Function(Row r) where) {
    for (final r in _t(table)) {
      if (where(r)) return Map<String, dynamic>.of(r);
    }
    return null;
  }

  Future<void> insert(String table, Row row) {
    if (row['id'] is! String) {
      throw ArgumentError('Row for $table needs a String id');
    }
    _t(table).add(Map<String, dynamic>.of(row));
    return _changed();
  }

  Future<void> update(String table, String id, Row patch) {
    final row = _t(table).firstWhere(
      (r) => r['id'] == id,
      orElse: () => throw StateError('$table/$id not found'),
    );
    row.addAll(patch);
    return _changed();
  }

  Future<int> deleteWhere(String table, bool Function(Row r) where) async {
    final rows = _t(table);
    final before = rows.length;
    rows.removeWhere(where);
    final removed = before - rows.length;
    if (removed > 0) await _changed();
    return removed;
  }

  Future<void> delete(String table, String id) =>
      deleteWhere(table, (r) => r['id'] == id);

  /// Runs [body] as one unit: a single write at the end, and every change
  /// rolled back if it throws. Multi-table operations (approving a loan writes
  /// the loan, its schedule, an event and a notification) use this.
  Future<T> transaction<T>(Future<T> Function() body) async {
    final backup = _copyTables();
    _txDepth++;
    try {
      final result = await body();
      _txDepth--;
      if (_txDepth == 0 && _dirty) await _flush();
      return result;
    } catch (_) {
      _txDepth--;
      if (_txDepth == 0) {
        _tables = backup;
        _dirty = false;
      }
      rethrow;
    }
  }

  /// Removes every row and the file itself.
  Future<void> wipe() async {
    _tables = {for (final t in Tbl.all) t: <Row>[]};
    _dirty = false;
    await _writes.catchError((_) {});
    await _storage.clear();
  }

  Map<String, List<Row>> _copyTables() => {
    for (final e in _tables.entries)
      e.key: [for (final r in e.value) Map<String, dynamic>.of(r)],
  };

  Future<void> _changed() {
    _dirty = true;
    return _txDepth == 0 ? _flush() : Future.value();
  }

  Future<void> _flush() {
    _dirty = false;
    final snapshot = jsonEncode({
      'schema_version': schemaVersion,
      'tables': _tables,
    });
    // Serialise writes so an older snapshot can never land after a newer one.
    final next = _writes
        .catchError((_) {})
        .then((_) => _storage.write(snapshot));
    _writes = next;
    return next;
  }
}
