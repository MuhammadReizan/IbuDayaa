import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/models/models.dart';
import 'package:ibudaya/core/state/selectors.dart';
import 'package:ibudaya/core/state/snapshot.dart';

ScoreSnapshot _snap(int month, int score) => ScoreSnapshot(
  id: 'u-$month',
  userId: 'u1',
  month: DateTime(2026, month),
  score: score,
  factorPoints: const {},
  createdAt: DateTime(2026, month),
);

void main() {
  final now = DateTime(2026, 9, 15);

  test('scoreHistoryOf returns snapshots within the window, oldest first', () {
    final data = CoopSnapshot(
      scoreSnapshots: [
        _snap(3, 30), // outside the default 6-month window (Apr–Sep)
        _snap(4, 40), // the oldest month still inside the window
        _snap(9, 82),
        _snap(6, 55),
        _snap(7, 60),
      ],
    );
    final history = data.scoreHistoryOf('u1', now);
    expect(history.map((s) => s.month.month), [4, 6, 7, 9]);
    expect(history.map((s) => s.score), [40, 55, 60, 82]);
  });

  test('scoreHistoryOf ignores other users and future months', () {
    final data = CoopSnapshot(
      scoreSnapshots: [
        _snap(9, 82),
        ScoreSnapshot(
          id: 'other',
          userId: 'u2',
          month: DateTime(2026, 9),
          score: 99,
          factorPoints: const {},
          createdAt: now,
        ),
        _snap(10, 90),
      ],
    );
    final history = data.scoreHistoryOf('u1', now);
    expect(history.length, 1);
    expect(history.single.score, 82);
  });

  test('respects a custom months window', () {
    final data = CoopSnapshot(
      scoreSnapshots: [_snap(1, 10), _snap(9, 82)],
    );
    expect(data.scoreHistoryOf('u1', now, months: 12).length, 2);
    expect(data.scoreHistoryOf('u1', now, months: 3).length, 1);
  });
}
