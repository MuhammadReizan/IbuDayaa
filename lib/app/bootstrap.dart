import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../core/db/local_database.dart';
import '../core/error/app_error_box.dart';
import '../core/repositories/local/local_auth_repository.dart';
import '../core/repositories/local/local_snapshot_repository.dart';
import '../core/state/app_state.dart';
import 'app.dart';

/// Opens the on-device database, restores the last session, and starts the
/// app already knowing who is signed in — so the first frame is the right
/// home screen, not a spinner.
///
/// Supabase mode replaces the two local repositories here with
/// `Supabase.initialize` and the hosted implementations.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  ErrorWidget.builder = (details) => AppErrorBox(details: details);
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };

  final db = await LocalDatabase.open(
    kIsWeb ? MemoryDbStorage() : FileDbStorage(),
  );
  final me = await LocalAuthRepository(db, DateTime.now).restoreSession();
  final initial = me == null
      ? const AppState()
      : await loadAppState(LocalSnapshotRepository(db, DateTime.now), me);

  runApp(
    ProviderScope(
      overrides: [
        localDatabaseProvider.overrideWithValue(db),
        initialAppStateProvider.overrideWithValue(initial),
      ],
      child: const IbuDayaApp(),
    ),
  );
}
