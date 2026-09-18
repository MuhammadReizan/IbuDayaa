/// The random draw ("kocok arisan") that decides turn order when an admin
/// creates a group: every member is drawn exactly once, so nobody repeats
/// until everyone else has had a turn — the same guarantee the manual
/// tap-to-order flow already gives, just decided by chance instead of by
/// the admin's own pick.
library;

import 'dart:math';

/// Draws [memberIds] into a random turn order. Each id appears exactly once
/// in the result, in the sequence it was drawn (index 0 = turn 1).
///
/// Pure given [random]: pass a seeded [Random] in tests for a deterministic
/// sequence, or leave it unset for a real draw.
List<String> drawArisanOrder(List<String> memberIds, {Random? random}) {
  final rng = random ?? Random();
  final pool = List<String>.from(memberIds);
  final drawn = <String>[];
  while (pool.isNotEmpty) {
    final i = rng.nextInt(pool.length);
    drawn.add(pool.removeAt(i));
  }
  return drawn;
}
