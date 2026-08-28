import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/demo/demo_scenario.dart';
import 'package:ibudaya/features/arisan/domain/arisan_rules.dart';

void main() {
  DemoQuotaOffer offer({
    String id = 'off-1',
    String owner = 'm-002',
    double amount = 5.0,
    String status = 'open',
  }) => DemoQuotaOffer(
    id: id,
    ownerMemberId: owner,
    ownerName: 'Owner',
    amountKwh: amount,
    slotLabel: 'Sabtu, 08.00–10.00',
    status: status,
    createdAt: DateTime(2026, 7, 30),
  );

  group('validateShareQuota', () {
    test('accepts an amount within the available quota', () {
      expect(validateShareQuota(kwh: 2, availableKwh: 12), isNull);
    });

    test('accepts sharing the whole available quota', () {
      expect(validateShareQuota(kwh: 12, availableKwh: 12), isNull);
    });

    test('rejects zero', () {
      expect(
        validateShareQuota(kwh: 0, availableKwh: 12),
        ShareQuotaError.nonPositiveAmount,
      );
    });

    test('rejects a negative amount', () {
      expect(
        validateShareQuota(kwh: -1, availableKwh: 12),
        ShareQuotaError.nonPositiveAmount,
      );
    });

    test('rejects more than the available quota (no clamping)', () {
      expect(
        validateShareQuota(kwh: 13, availableKwh: 12),
        ShareQuotaError.exceedsAvailable,
      );
    });
  });

  group('validateTakeOffer', () {
    test('accepts an open, foreign offer when quota is needed', () {
      expect(
        validateTakeOffer(
          offer: offer(),
          currentUserId: 'IDB-2404-1287',
          neededKwh: 5,
          alreadyRequested: false,
        ),
        isNull,
      );
    });

    test('rejects an unknown offer', () {
      expect(
        validateTakeOffer(
          offer: null,
          currentUserId: 'IDB-2404-1287',
          neededKwh: 5,
          alreadyRequested: false,
        ),
        TakeOfferError.unknownOffer,
      );
    });

    test('rejects an already-taken offer', () {
      expect(
        validateTakeOffer(
          offer: offer(status: 'taken'),
          currentUserId: 'IDB-2404-1287',
          neededKwh: 5,
          alreadyRequested: false,
        ),
        TakeOfferError.alreadyTaken,
      );
    });

    test('rejects a non-open offer', () {
      expect(
        validateTakeOffer(
          offer: offer(status: 'cancelled'),
          currentUserId: 'IDB-2404-1287',
          neededKwh: 5,
          alreadyRequested: false,
        ),
        TakeOfferError.notOpen,
      );
    });

    test('rejects the current user\'s own offer', () {
      expect(
        validateTakeOffer(
          offer: offer(owner: 'IDB-2404-1287'),
          currentUserId: 'IDB-2404-1287',
          neededKwh: 5,
          alreadyRequested: false,
        ),
        TakeOfferError.ownOffer,
      );
    });

    test('rejects a take when no quota is needed', () {
      expect(
        validateTakeOffer(
          offer: offer(),
          currentUserId: 'IDB-2404-1287',
          neededKwh: 0,
          alreadyRequested: false,
        ),
        TakeOfferError.noQuotaNeeded,
      );
    });

    test('rejects a duplicate take (double-tap guard)', () {
      expect(
        validateTakeOffer(
          offer: offer(),
          currentUserId: 'IDB-2404-1287',
          neededKwh: 5,
          alreadyRequested: true,
        ),
        TakeOfferError.duplicateTake,
      );
    });
  });
}
