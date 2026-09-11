import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/data/app_data.dart';
import 'package:ibudaya/core/data/app_data_controller.dart';
import 'package:ibudaya/core/data/models.dart';

import '../../support/fixtures.dart';

void main() {
  group('AppData JSON round-trip', () {
    test('survives a full encode/decode cycle', () {
      final original = AppData(
        profile: testProfile(tariff: 1444.7),
        bills: [testBill(id: 'b1', monthsAgo: 0, kwh: 120)],
        appliances: [testAppliance(id: 'a1', name: 'Oven', watts: 1500)],
        sessions: [
          SolarSession(
            id: 's1',
            applianceName: 'Oven',
            date: DateTime(2026, 3, 4),
            slotLabel: '10.00–12.00',
            kwh: 3,
            recordedAt: DateTime(2026, 3, 4),
          ),
        ],
        arisan: ArisanGroup(
          name: 'Melati',
          contributionIdr: 150000,
          members: const [
            ArisanMember(id: 'm1', name: 'Ibu Sari', isMe: true),
            ArisanMember(id: 'm2', name: 'Siti'),
          ],
          startedAt: DateTime(2026, 1, 1),
        ),
        ledger: [
          LedgerEntry(
            id: 'l1',
            type: 'contribution',
            memberId: 'm1',
            memberName: 'Ibu Sari',
            amountIdr: 150000,
            at: DateTime(2026, 2, 1),
          ),
        ],
        offers: [
          QuotaOffer(
            id: 'o1',
            ownerId: 'm1',
            ownerName: 'Ibu Sari',
            amountKwh: 2,
            slotLabel: 'Sabtu',
            status: 'open',
            createdAt: DateTime(2026, 2, 2),
          ),
        ],
        calculations: [
          SavedCalculation(
            id: 'c1',
            label: 'Oven baru',
            principalIdr: 2000000,
            tenorMonths: 6,
            monthlyRatePct: 2,
            savedAt: DateTime(2026, 2, 3),
          ),
        ],
        readNotificationIds: const {'obs-spike'},
      );

      final restored = AppData.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored.profile!.name, 'Ibu Sari');
      expect(restored.profile!.tariffIdrPerKwh, closeTo(1444.7, 0.001));
      expect(restored.bills.single.kwh, 120);
      expect(restored.appliances.single.watts, 1500);
      expect(restored.sessions.single.kwh, 3);
      expect(restored.arisan!.members.length, 2);
      expect(restored.arisan!.members.first.isMe, isTrue);
      expect(restored.ledger.single.amountIdr, 150000);
      expect(restored.offers.single.status, 'open');
      expect(restored.calculations.single.tenorMonths, 6);
      expect(restored.readNotificationIds, contains('obs-spike'));
    });

    test('a corrupt record is dropped without losing the rest', () {
      final json = {
        'profile': {'name': 'Ibu Sari', 'joinedAt': '2026-01-01T00:00:00'},
        'bills': [
          {
            'id': 'ok',
            'periodMonth': '2026-01-01T00:00:00',
            'kwh': 10,
            'totalIdr': 100,
            'recordedAt': '2026-01-01T00:00:00',
          },
          {'id': 'broken'}, // missing required fields
          'not-even-an-object',
        ],
      };

      final data = AppData.fromJson(json);

      expect(data.profile, isNotNull);
      expect(data.bills, hasLength(1));
      expect(data.bills.single.id, 'ok');
    });

    test('an empty document is a valid, un-onboarded state', () {
      final data = AppData.fromJson(const <String, dynamic>{});
      expect(data.isOnboarded, isFalse);
      expect(data.hasAnyRecords, isFalse);
      expect(data.bills, isEmpty);
    });
  });

  group('AppDataController', () {
    test('persists a bill so a fresh read sees it', () async {
      final container = testContainer();
      await loadData(container);

      await container
          .read(appDataProvider.notifier)
          .addBill(periodMonth: DateTime(2026, 3), kwh: 120, totalIdr: 173000);

      // Re-read through the same store, as a relaunch would.
      final stored = await container.read(appStoreProvider).load();
      expect(stored.bills.single.kwh, 120);
    });

    test(
      're-recording a month replaces that month rather than duplicating',
      () async {
        final container = testContainer();
        await loadData(container);
        final controller = container.read(appDataProvider.notifier);

        await controller.addBill(
          periodMonth: DateTime(2026, 3),
          kwh: 100,
          totalIdr: 100000,
        );
        await controller.addBill(
          periodMonth: DateTime(2026, 3),
          kwh: 130,
          totalIdr: 130000,
        );

        final data = container.read(dataProvider);
        expect(data.bills, hasLength(1));
        expect(data.bills.single.kwh, 130);
      },
    );

    test(
      'clearAll erases the profile and returns to an un-onboarded state',
      () async {
        final container = testContainer(AppData(profile: testProfile()));
        await loadData(container);
        expect(container.read(dataProvider).isOnboarded, isTrue);

        await container.read(appDataProvider.notifier).clearAll();

        expect(container.read(dataProvider).isOnboarded, isFalse);
        expect(await container.read(appStoreProvider).load(), isA<AppData>());
      },
    );
  });
}
