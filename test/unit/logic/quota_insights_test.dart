import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/logic/quota_insights.dart';
import 'package:ibudaya/core/logic/quota_ledger.dart';
import 'package:ibudaya/core/models/models.dart';

QuotaOffer _offer(
  String id, {
  required QuotaKind kind,
  required double kwh,
  String owner = 'other',
  QuotaStatus status = QuotaStatus.open,
  DateTime? createdAt,
  DateTime? updatedAt,
  String? counterparty,
}) => QuotaOffer(
  id: id,
  cooperativeId: 'c',
  ownerId: owner,
  kind: kind,
  kwh: kwh,
  slotNote: '',
  status: status,
  counterpartyId: counterparty,
  createdAt: createdAt ?? DateTime(2026, 9, 1),
  updatedAt: updatedAt ?? DateTime(2026, 9, 1),
);

QuotaBalance _bal({
  double allocation = 30,
  double booked = 0,
  double given = 0,
  double received = 0,
}) => QuotaBalance(
  allocationKwh: allocation,
  bookedKwh: booked,
  givenKwh: given,
  receivedKwh: received,
);

void main() {
  group('matchQuotaOffers', () {
    test(
      'a member who needs quota sees shares, best fit then longest wait',
      () {
        final matches = matchQuotaOffers(
          offers: [
            _offer('big', kind: QuotaKind.share, kwh: 10),
            _offer(
              'exact-new',
              kind: QuotaKind.share,
              kwh: 5,
              createdAt: DateTime(2026, 9, 10),
            ),
            _offer(
              'exact-old',
              kind: QuotaKind.share,
              kwh: 5,
              createdAt: DateTime(2026, 9, 2),
            ),
            _offer('small', kind: QuotaKind.share, kwh: 2),
            _offer('a-need', kind: QuotaKind.need, kwh: 5),
            _offer('mine', kind: QuotaKind.share, kwh: 5, owner: 'me'),
            _offer(
              'taken',
              kind: QuotaKind.share,
              kwh: 5,
              status: QuotaStatus.completed,
            ),
          ],
          myId: 'me',
          wantKind: QuotaKind.need,
          wantedKwh: 5,
          availableKwh: 0,
        );
        expect(matches.map((m) => m.offer.id), [
          'exact-old',
          'exact-new',
          'big',
          'small',
        ]);
        expect(matches.map((m) => m.covers), [true, true, true, false]);
      },
    );

    test('a member who shares only sees needs she can fully fund', () {
      final matches = matchQuotaOffers(
        offers: [
          _offer('fits', kind: QuotaKind.need, kwh: 4),
          _offer('too-big', kind: QuotaKind.need, kwh: 12),
          _offer('a-share', kind: QuotaKind.share, kwh: 4),
        ],
        myId: 'me',
        wantKind: QuotaKind.share,
        wantedKwh: 5,
        availableKwh: 8,
      );
      expect(matches.map((m) => m.offer.id), ['fits']);
    });
  });

  group('quotaImpact', () {
    test('sums this month\'s completed trades and hub utilisation', () {
      final now = DateTime(2026, 9, 20);
      final impact = quotaImpact(
        offers: [
          _offer(
            'a',
            kind: QuotaKind.share,
            kwh: 3,
            owner: 'x',
            status: QuotaStatus.completed,
            counterparty: 'y',
            updatedAt: DateTime(2026, 9, 5),
          ),
          _offer(
            'b',
            kind: QuotaKind.need,
            kwh: 2,
            owner: 'y',
            status: QuotaStatus.completed,
            counterparty: 'x',
            updatedAt: DateTime(2026, 9, 6),
          ),
          _offer(
            'old',
            kind: QuotaKind.share,
            kwh: 9,
            owner: 'x',
            status: QuotaStatus.completed,
            counterparty: 'y',
            updatedAt: DateTime(2026, 8, 6),
          ),
          _offer('open', kind: QuotaKind.share, kwh: 9, owner: 'x'),
        ],
        balances: [_bal(booked: 15), _bal(booked: 30), _bal(booked: 0)],
        now: now,
      );
      expect(impact.tradedKwh, 5);
      expect(impact.trades, 2);
      expect(impact.sharers, 1);
      expect(impact.utilizationPct, 50);
      expect(impact.hasActivity, isTrue);
    });
  });
}
