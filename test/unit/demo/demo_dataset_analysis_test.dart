// Guards the bundled demo dataset against the exact bug this file was added
// to catch: appliance watts/hours picked without checking their combined
// kWh against the bill triggers `declaredExceedsUsage` in
// energy_insights.dart, which swaps the appliance breakdown for a "data
// alat perlu dicek" warning and hides the Solar Hub CTA on the analysis
// screen — silently breaking the demo presenters actually see.
import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/demo/demo_bill_repository.dart';
import 'package:ibudaya/core/logic/energy_insights.dart';
import 'package:ibudaya/core/models/models.dart';

const _tariff = 1444.70;
const _barcode = '5629123456789012';

void main() {
  final payload = DemoBillRepository.findByBarcode(_barcode)!;

  EnergyRecord bill(int i, ({DateTime month, double kwh, int totalIdr}) e) =>
      EnergyRecord(
        id: 'bill-$i',
        userId: 'demo',
        kind: EnergyKind.postpaid,
        periodMonth: e.month,
        kwh: e.kwh,
        totalIdr: e.totalIdr,
        source: RecordSource.scan,
        createdAt: e.month,
      );

  final records = [
    bill(0, (
      month: payload.current.month,
      kwh: payload.current.kwh,
      totalIdr: payload.current.totalIdr,
    )),
    for (int i = 0; i < payload.history.length; i++)
      bill(i + 1, (
        month: payload.history[i].month,
        kwh: payload.history[i].kwh,
        totalIdr: payload.history[i].totalIdr,
      )),
  ];

  final appliances = [
    for (final a in payload.appliances)
      Appliance(
        id: a.name,
        userId: 'demo',
        name: a.name,
        kind: a.kind,
        watts: a.watts,
        hoursPerDay: a.hoursPerDay,
        daysPerWeek: a.daysPerWeek,
        createdAt: payload.current.month,
      ),
  ];

  final insight = buildEnergyInsight(
    records: records,
    appliances: appliances,
    tariff: _tariff,
  )!;

  test('demo appliances never trip the "data alat perlu dicek" mismatch', () {
    expect(
      insight.declaredExceedsUsage,
      isFalse,
      reason:
          'declared appliance kWh (${insight.declaredKwh}) must stay under '
          '1.05x the bill (${insight.latest.kwh}) or the breakdown card and '
          'the Solar Hub CTA both disappear from the analysis screen',
    );
  });

  test('the analysis screen has a top contributor to power its CTA', () {
    expect(insight.contributors, isNotEmpty);
    // Oven is the schedulable load the "move it to Solar Hub hours" advice
    // and the pre-filled booking are actually about — not the always-on
    // freezer.
    expect(insight.contributors.first.appliance.name, 'Oven Listrik');
  });

  test('the demo bill still reads as a real spike against its own history', () {
    expect(insight.spikeDetected, isTrue);
  });
}
