import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/demo/demo_bill_models.dart';

const validCurrent = {'month': '2026-09', 'kwh': 145, 'total_idr': 210000};

void main() {
  test('parses a full payload: current, history, appliances', () {
    final payload = DemoBillPayload.fromMap({
      'type': kDemoBillPayloadType,
      'current': validCurrent,
      'history': [
        {'month': '2026-06', 'kwh': 112, 'total_idr': 161800},
        {'month': '2026-07', 'kwh': 118, 'total_idr': 170500},
        {'month': '2026-08', 'kwh': 109, 'total_idr': 157500},
      ],
      'appliances': [
        {
          'name': 'Oven Listrik',
          'kind': 'oven',
          'watts': 1500,
          'hours_per_day': 2,
          'days_per_week': 6,
        },
        {
          'name': 'Freezer',
          'kind': 'refrigerator',
          'watts': 150,
          'hours_per_day': 24,
          'days_per_week': 7,
        },
      ],
    });

    expect(payload, isNotNull);
    expect(payload!.current.month, DateTime(2026, 9));
    expect(payload.current.kwh, 145);
    expect(payload.current.totalIdr, 210000);
    expect(payload.history, hasLength(3));
    expect(payload.appliances, hasLength(2));
    expect(payload.appliances.first.name, 'Oven Listrik');
  });

  test('works with only a current bill (no history, no appliances)', () {
    final payload = DemoBillPayload.fromMap({
      'type': kDemoBillPayloadType,
      'current': validCurrent,
    });
    expect(payload, isNotNull);
    expect(payload!.history, isEmpty);
    expect(payload.appliances, isEmpty);
  });

  test('rejects a map with the wrong or missing type marker', () {
    expect(
      DemoBillPayload.fromMap({
        'type': 'some_other_dataset',
        'current': validCurrent,
      }),
      isNull,
    );
    expect(DemoBillPayload.fromMap({'current': validCurrent}), isNull);
  });

  test('rejects a payload missing the required current bill', () {
    expect(DemoBillPayload.fromMap({'type': kDemoBillPayloadType}), isNull);
  });

  test(
    'drops one bad history/appliance entry without failing the whole scan',
    () {
      final payload = DemoBillPayload.fromMap({
        'type': kDemoBillPayloadType,
        'current': validCurrent,
        'history': [
          {'month': 'not-a-month', 'kwh': 100, 'total_idr': 100000},
          {'month': '2026-08', 'kwh': 109, 'total_idr': 157500},
        ],
        'appliances': [
          {'name': '', 'watts': 100, 'hours_per_day': 1, 'days_per_week': 1},
          {
            'name': 'Blender',
            'watts': 350,
            'hours_per_day': 1,
            'days_per_week': 5,
          },
        ],
      });
      expect(payload, isNotNull);
      expect(payload!.history, hasLength(1));
      expect(payload.appliances, hasLength(1));
      expect(payload.appliances.single.name, 'Blender');
      // Missing "kind" falls back to the generic appliance icon.
      expect(payload.appliances.single.kind, 'other');
    },
  );

  test('rejects an implausible kWh or amount', () {
    expect(
      DemoBillPayload.fromMap({
        'type': kDemoBillPayloadType,
        'current': {'month': '2026-09', 'kwh': -5, 'total_idr': 10000},
      }),
      isNull,
    );
    expect(
      DemoBillPayload.fromMap({
        'type': kDemoBillPayloadType,
        'current': {'month': '2026-09', 'kwh': 100, 'total_idr': 0},
      }),
      isNull,
    );
  });
}
