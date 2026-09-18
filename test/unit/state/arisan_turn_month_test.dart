// arisanTurnMonth must keep recurring a member's turn every `memberCount`
// months, not just report her first-cycle date forever — that was the bug
// (see selectors.dart / arisan_screen.dart's HeroCard and member rows).
import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/state/selectors.dart';

void main() {
  final start = DateTime(2026, 5); // May 2026, 4-member group.

  test('before the group starts, a member sees her first-cycle turn', () {
    final month = arisanTurnMonth(
      startMonth: start,
      turnOrder: 3,
      memberCount: 4,
      now: DateTime(2026, 5),
    );
    expect(month, DateTime(2026, 7)); // turn 3 → +2 months.
  });

  test("on a member's own turn month, it reports that same month", () {
    final month = arisanTurnMonth(
      startMonth: start,
      turnOrder: 1,
      memberCount: 4,
      now: DateTime(2026, 5),
    );
    expect(month, DateTime(2026, 5));
  });

  test('once the first cycle has fully passed, the turn recurs — this was '
      'the bug: it used to stay stuck on the first-cycle month forever', () {
    // Turn 1 recurs every 4 months: May, Sep, Jan 2027, May 2027... By
    // December both May and September have already passed, so the next
    // occurrence is January 2027, not a date stuck back in the first cycle.
    final month = arisanTurnMonth(
      startMonth: start,
      turnOrder: 1,
      memberCount: 4,
      now: DateTime(2026, 12),
    );
    expect(month, DateTime(2027, 1));
  });

  test('exactly on a later cycle boundary, it reports that cycle, not the '
      'next one', () {
    // Turn 1 recurs at May, Sep, Jan... — asking exactly in September should
    // return September, not jump ahead to January.
    final month = arisanTurnMonth(
      startMonth: start,
      turnOrder: 1,
      memberCount: 4,
      now: DateTime(2026, 9),
    );
    expect(month, DateTime(2026, 9));
  });

  test('different turn orders recur independently within the same cycle', () {
    // At elapsed = 4 months (September), turn order 1 has just recurred
    // (offset 4) while turn order 2 (offset 1, 5, 9...) has not yet reached
    // its second occurrence — the next one is October.
    final turn1 = arisanTurnMonth(
      startMonth: start,
      turnOrder: 1,
      memberCount: 4,
      now: DateTime(2026, 9),
    );
    final turn2 = arisanTurnMonth(
      startMonth: start,
      turnOrder: 2,
      memberCount: 4,
      now: DateTime(2026, 9),
    );
    expect(turn1, DateTime(2026, 9));
    expect(turn2, DateTime(2026, 10));
  });
}
