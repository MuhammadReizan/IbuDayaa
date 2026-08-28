import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/demo/demo_providers.dart';
import 'package:ibudaya/core/demo/demo_session.dart';
import 'package:ibudaya/features/arisan/domain/arisan_rules.dart';

import '../../support/demo_seed.dart';

/// End-to-end domain behaviour of the Arisan quota mutations through
/// [DemoSessionNotifier] — the immutable-state path the UI observes.
void main() {
  late ProviderContainer c;
  late DemoSessionNotifier notifier;

  setUp(() {
    c = newDemoContainer();
    notifier = c.read(demoSessionProvider.notifier);
  });

  DemoSessionState get() => c.read(demoSessionProvider);

  group('shareQuota', () {
    test('a valid 2 kWh share reduces available quota 12 → 10', () {
      expect(get().scenario.quota.availableKwh, 12.0);

      final outcome = notifier.shareQuota(
        kwh: 2,
        slotLabel: 'Sabtu, 08.00–10.00',
      );

      expect(outcome.isSuccess, isTrue);
      expect(get().scenario.quota.availableKwh, 10.0);
    });

    test('appends an open offer owned by the current user', () {
      final before = get().allOffers.length;
      notifier.shareQuota(kwh: 2, slotLabel: 'Sabtu, 08.00–10.00');

      final offers = get().allOffers;
      expect(offers.length, before + 1);
      final mine = offers.firstWhere((o) => o.ownerName == 'Ibu Clara');
      expect(mine.status, 'open');
      expect(mine.amountKwh, 2.0);
    });

    test('appends a quotaShared ledger entry (newest first)', () {
      final before = get().scenario.arisan.ledger.length;
      notifier.shareQuota(kwh: 2, slotLabel: 'Sabtu, 08.00–10.00');

      final ledger = get().scenario.arisan.ledger;
      expect(ledger.length, before + 1);
      expect(ledger.first.type, 'quotaShared');
      expect(ledger.first.amountKwh, 2.0);
    });

    test('cannot overshare — quota and offers are untouched', () {
      final outcome = notifier.shareQuota(
        kwh: 99,
        slotLabel: 'Sabtu, 08.00–10.00',
      );

      expect(outcome.isSuccess, isFalse);
      expect(outcome.error, ShareQuotaError.exceedsAvailable);
      expect(get().scenario.quota.availableKwh, 12.0);
      expect(get().sessionOffers, isEmpty);
    });

    test('cannot share zero or a negative amount', () {
      expect(
        notifier.shareQuota(kwh: 0, slotLabel: 's').error,
        ShareQuotaError.nonPositiveAmount,
      );
      expect(
        notifier.shareQuota(kwh: -3, slotLabel: 's').error,
        ShareQuotaError.nonPositiveAmount,
      );
      expect(get().scenario.quota.availableKwh, 12.0);
    });
  });

  group('takeOffer', () {
    test('taking a foreign open offer reduces needed quota 5 → 2', () {
      expect(get().scenario.quota.neededKwh, 5.0);

      final outcome = notifier.takeOffer('off-002'); // 3 kWh, owner m-003
      expect(outcome.isSuccess, isTrue);
      expect(get().scenario.quota.neededKwh, 2.0);
    });

    test('marks the offer taken and appends a quotaReceived ledger entry', () {
      final before = get().scenario.arisan.ledger.length;
      notifier.takeOffer('off-002');

      final taken = get().allOffers.firstWhere((o) => o.id == 'off-002');
      expect(taken.status, 'taken');

      final ledger = get().scenario.arisan.ledger;
      expect(ledger.length, before + 1);
      expect(ledger.first.type, 'quotaReceived');
    });

    test('cannot take the same offer twice', () {
      expect(notifier.takeOffer('off-002').isSuccess, isTrue);

      final second = notifier.takeOffer('off-002');
      expect(second.isSuccess, isFalse);
      expect(second.error, TakeOfferError.duplicateTake);
      // Needed quota only dropped once.
      expect(get().scenario.quota.neededKwh, 2.0);
    });

    test('cannot take your own offer', () {
      final outcome = notifier.takeOffer('off-own');
      expect(outcome.isSuccess, isFalse);
      expect(outcome.error, TakeOfferError.ownOffer);
      expect(get().scenario.quota.neededKwh, 5.0);
    });

    test('cannot take an unknown offer', () {
      expect(notifier.takeOffer('nope').error, TakeOfferError.unknownOffer);
    });
  });

  group('reset', () {
    test('restores the exact canonical seed after mutations', () {
      notifier.shareQuota(kwh: 3, slotLabel: 'Sabtu, 08.00–10.00');
      notifier.takeOffer('off-001');

      notifier.reset();

      final s = get();
      final seed = demoSeedScenario();
      expect(s.scenario.quota.availableKwh, seed.quota.availableKwh);
      expect(s.scenario.quota.neededKwh, seed.quota.neededKwh);
      expect(s.scenario.arisan.ledger.length, seed.arisan.ledger.length);
      expect(s.sessionOffers, isEmpty);
      expect(s.quotaRequests, isEmpty);
      expect(s.bookings, isEmpty);
      expect(
        s.allOffers.where((o) => o.status == 'taken'),
        isEmpty,
        reason: 'seeded offer status must be restored',
      );
    });
  });
}
