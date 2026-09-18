// The best-production-window panel must stop reading as a live
// recommendation once the window it names is over — see
// _WeatherOutlookCard in solar_hub_screen.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ibudaya/app/app.dart';
import 'package:ibudaya/core/db/local_database.dart';
import 'package:ibudaya/core/db/tables.dart';
import 'package:ibudaya/core/paths.dart';
import 'package:ibudaya/core/repositories/local/local_auth_repository.dart';
import 'package:ibudaya/core/repositories/local/local_snapshot_repository.dart';
import 'package:ibudaya/core/repositories/local/sample_seeder.dart';
import 'package:ibudaya/core/state/app_state.dart';
import 'package:ibudaya/core/weather/weather_models.dart';
import 'package:ibudaya/core/weather/weather_providers.dart';
import 'package:ibudaya/core/weather/weather_service.dart';
import 'package:ibudaya/features/credit_score/data/rule_based_credit_scoring_engine.dart';

import 'app_flow_test.dart' show routerOf;

class _FakeWeatherService implements WeatherService {
  const _FakeWeatherService(this.points);
  final List<WeatherPoint> points;

  @override
  Future<List<WeatherPoint>> fetchForecast(String adm4Code) async => points;
}

Future<void> _pumpHub(
  WidgetTester tester,
  DateTime clock,
  List<WeatherPoint> points,
) async {
  DateTime now() => clock;
  tester.view.physicalSize = const Size(412, 915) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final db = await LocalDatabase.open(MemoryDbStorage());
  await SampleSeeder(db, now, const RuleBasedCreditScoringEngine()).seed();
  final hubId = db.select(Tbl.solarHubs, (_) => true).first['id'] as String;
  await db.update(Tbl.solarHubs, hubId, {'weather_adm4_code': '16.71.05.1001'});

  final me = await LocalAuthRepository(
    db,
    now,
  ).login(phone: SampleSeeder.memberPhone, pin: SampleSeeder.pin);
  final initial = await loadAppState(LocalSnapshotRepository(db, now), me);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(now),
        initialAppStateProvider.overrideWithValue(initial),
        weatherServiceProvider.overrideWithValue(_FakeWeatherService(points)),
      ],
      child: const IbuDayaApp(),
    ),
  );
  await tester.pumpAndSettle();
  routerOf(tester).go(Paths.memberSolar);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  final points = [
    WeatherPoint(
      time: DateTime(2026, 9, 17, 10),
      cloudCoverPct: 10,
      condition: 'Cerah',
      temperatureC: 30,
    ),
    WeatherPoint(
      time: DateTime(2026, 9, 17, 13),
      cloudCoverPct: 40,
      condition: 'Berawan',
      temperatureC: 29,
    ),
  ];

  testWidgets('the best window today is shown as live before it ends', (
    tester,
  ) async {
    await _pumpHub(tester, DateTime(2026, 9, 17, 11), points);

    expect(find.text('Jam terbaik untuk produksi hari ini'), findsOneWidget);
    expect(find.text('10.00–13.00'), findsOneWidget);
    expect(find.text('Jam terbaik hari ini sudah lewat'), findsNothing);
  });

  testWidgets(
    'a member opening the screen after the window has ended sees past-tense copy, not a live recommendation',
    (tester) async {
      await _pumpHub(tester, DateTime(2026, 9, 17, 16), points);

      expect(find.text('Jam terbaik hari ini sudah lewat'), findsOneWidget);
      expect(find.text('Coba lagi besok pagi.'), findsOneWidget);
      expect(find.text('Jam terbaik untuk produksi hari ini'), findsNothing);
    },
  );

  testWidgets(
    "once today's window has passed, tomorrow's forecast (already fetched from BMKG) is shown instead of a dead end",
    (tester) async {
      await _pumpHub(tester, DateTime(2026, 9, 17, 16), [
        ...points,
        WeatherPoint(
          time: DateTime(2026, 9, 18, 10),
          cloudCoverPct: 15,
          condition: 'Cerah Berawan',
          temperatureC: 28,
        ),
      ]);

      expect(find.text('Jam terbaik untuk produksi besok'), findsOneWidget);
      expect(find.text('10.00–13.00'), findsOneWidget);
      expect(find.text('Jam terbaik hari ini sudah lewat'), findsNothing);
      // Tomorrow is now the actionable one, so the dead-end hint drops out.
      expect(find.text('Coba lagi besok pagi.'), findsNothing);
    },
  );
}
