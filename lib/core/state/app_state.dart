import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/credit_score/application/credit_score_provider.dart';
import '../db/local_database.dart';
import '../models/models.dart';
import '../repositories/local/local_arisan_repository.dart';
import '../repositories/local/local_auth_repository.dart';
import '../repositories/local/local_energy_repository.dart';
import '../repositories/local/local_loan_repository.dart';
import '../repositories/local/local_message_repository.dart';
import '../repositories/local/local_snapshot_repository.dart';
import '../repositories/local/local_solar_repository.dart';
import '../repositories/repositories.dart';
import 'snapshot.dart';

@immutable
class AppState {
  const AppState({this.me, this.data = CoopSnapshot.empty});

  final Profile? me;
  final CoopSnapshot data;

  bool get isSignedIn => me != null;
  Cooperative? get coop => data.cooperative;
}

/// Overridden in `bootstrap()` with the opened database.
final localDatabaseProvider = Provider<LocalDatabase>(
  (ref) => throw StateError('localDatabaseProvider must be overridden'),
);

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

// -- Repositories ------------------------------------------------------------
// Swap these for Supabase implementations; nothing above them changes.

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => LocalAuthRepository(
    ref.watch(localDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final snapshotRepositoryProvider = Provider<SnapshotRepository>(
  (ref) => LocalSnapshotRepository(
    ref.watch(localDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final energyRepositoryProvider = Provider<EnergyRepository>(
  (ref) => LocalEnergyRepository(
    ref.watch(localDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final scoreRepositoryProvider = Provider<ScoreRepository>(
  (ref) => LocalEnergyRepository(
    ref.watch(localDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final solarRepositoryProvider = Provider<SolarRepository>(
  (ref) => LocalSolarRepository(
    ref.watch(localDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final arisanRepositoryProvider = Provider<ArisanRepository>(
  (ref) => LocalArisanRepository(
    ref.watch(localDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final loanRepositoryProvider = Provider<LoanRepository>(
  (ref) => LocalLoanRepository(
    ref.watch(localDatabaseProvider),
    ref.watch(clockProvider),
    ref.watch(creditScoringEngineProvider),
  ),
);

final messageRepositoryProvider = Provider<MessageRepository>(
  (ref) => LocalMessageRepository(
    ref.watch(localDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

final cooperativeRepositoryProvider = Provider<CooperativeRepository>(
  (ref) => LocalMessageRepository(
    ref.watch(localDatabaseProvider),
    ref.watch(clockProvider),
  ),
);

// -- State -------------------------------------------------------------------

/// Overridden in `bootstrap()` with the restored session, so the first frame
/// already knows who is signed in and there is no loading flash.
final initialAppStateProvider = Provider<AppState>((ref) => const AppState());

/// The single source of truth screens watch.
///
/// Screens read it with `ref.watch(appStateProvider)` and derive what they need
/// with the pure helpers in `selectors.dart`. There are deliberately no
/// provider-to-provider chains on top of it: Riverpod pauses subscriptions for
/// off-screen routes, and a chained provider that changed while paused gets
/// flushed mid-build on resume, which throws. One flat notifier avoids that.
final appStateProvider = NotifierProvider<AppStateController, AppState>(
  AppStateController.new,
);

class AppStateController extends Notifier<AppState> {
  @override
  AppState build() => ref.read(initialAppStateProvider);

  Future<void> refresh() async {
    final me = state.me;
    if (me == null) return;
    state = await loadAppState(ref.read(snapshotRepositoryProvider), me);
  }

  Future<void> enter(Profile me) async {
    state = await loadAppState(ref.read(snapshotRepositoryProvider), me);
  }

  void leave() => state = const AppState();
}

Future<AppState> loadAppState(SnapshotRepository repo, Profile me) async {
  final data = await repo.load(me);
  return AppState(me: data.profile(me.id) ?? me, data: data);
}
