import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/error/app_error_box.dart';
import '../core/repositories/supabase/supabase_arisan_repository.dart';
import '../core/repositories/supabase/supabase_auth_repository.dart';
import '../core/repositories/supabase/supabase_energy_repository.dart';
import '../core/repositories/supabase/supabase_loan_repository.dart';
import '../core/repositories/supabase/supabase_message_repository.dart';
import '../core/repositories/supabase/supabase_snapshot_repository.dart';
import '../core/repositories/supabase/supabase_solar_repository.dart';
import '../core/state/app_state.dart';
import 'app.dart';

/// Connects to Supabase and overrides every repository provider in
/// `app_state.dart` with its hosted implementation — the swap the whole
/// architecture was built around (see docs/SUPABASE.md). Nothing above the
/// repository layer changes, and nothing here touches the default provider
/// bodies, so the existing local-mode test suite (which overrides
/// `localDatabaseProvider` and relies on those defaults) keeps working
/// unmodified; this override set only applies to the real running app.
///
/// Restores the last session (if the device still has a valid one) so the
/// first frame is already the right home screen, not a spinner.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  ErrorWidget.builder = (details) => AppErrorBox(details: details);
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };

  if (!SupabaseConfig.isConfigured) {
    throw StateError(
      'SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY not set. Run with '
      '--dart-define=SUPABASE_URL=... '
      '--dart-define=SUPABASE_PUBLISHABLE_KEY=... (see docs/SUPABASE.md).',
    );
  }
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  final client = Supabase.instance.client;

  final authRepo = SupabaseAuthRepository(client);
  final snapshotRepo = SupabaseSnapshotRepository(client);
  final energyRepo = SupabaseEnergyRepository(client);
  final messageRepo = SupabaseMessageRepository(client);

  final me = await authRepo.restoreSession();
  final initial = me == null
      ? const AppState()
      : await loadAppState(snapshotRepo, me);

  runApp(
    ProviderScope(
      overrides: [
        initialAppStateProvider.overrideWithValue(initial),
        authRepositoryProvider.overrideWithValue(authRepo),
        snapshotRepositoryProvider.overrideWithValue(snapshotRepo),
        energyRepositoryProvider.overrideWithValue(energyRepo),
        scoreRepositoryProvider.overrideWithValue(energyRepo),
        solarRepositoryProvider.overrideWithValue(
          SupabaseSolarRepository(client),
        ),
        arisanRepositoryProvider.overrideWithValue(
          SupabaseArisanRepository(client),
        ),
        loanRepositoryProvider.overrideWithValue(
          SupabaseLoanRepository(client),
        ),
        messageRepositoryProvider.overrideWithValue(messageRepo),
        cooperativeRepositoryProvider.overrideWithValue(messageRepo),
      ],
      child: const IbuDayaApp(),
    ),
  );
}
