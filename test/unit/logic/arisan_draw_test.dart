import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/logic/arisan_draw.dart';

void main() {
  final members = ['clara', 'siti', 'lina', 'putri'];

  test('draws every member exactly once — nobody repeats in the same cycle', () {
    final order = drawArisanOrder(members, random: Random(1));
    expect(order.toSet(), members.toSet());
    expect(order.length, members.length);
  });

  test('is a real shuffle, not an identity pass-through', () {
    // Across several seeds, at least one produces an order different from
    // the input — proves the function actually randomizes rather than
    // returning the list unchanged.
    final anyDifferent = List.generate(
      10,
      (seed) => drawArisanOrder(members, random: Random(seed)),
    ).any((order) => !_sameOrder(order, members));
    expect(anyDifferent, isTrue);
  });

  test('same seed draws the same order — deterministic given a fixed Random', () {
    final a = drawArisanOrder(members, random: Random(42));
    final b = drawArisanOrder(members, random: Random(42));
    expect(a, b);
  });

  test('once someone is drawn, she cannot be drawn again this pass', () {
    final order = drawArisanOrder(members, random: Random(7));
    // No duplicates anywhere in a single draw.
    expect(order.toSet().length, order.length);
  });

  test('works for the minimum group size of two', () {
    final order = drawArisanOrder(['a', 'b'], random: Random(3));
    expect(order.toSet(), {'a', 'b'});
  });
}

bool _sameOrder(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
