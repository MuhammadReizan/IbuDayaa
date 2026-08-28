import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/demo/demo_providers.dart';
import 'package:ibudaya/core/demo/demo_scenario.dart';
import 'package:ibudaya/core/demo/demo_session.dart';

import '../../support/demo_seed.dart';

/// Booking mutations now flow through [DemoSessionNotifier]; the repository
/// facade exposes an immutable view.
void main() {
  DemoSolarBooking booking(String id) => DemoSolarBooking(
    id: id,
    applianceKind: 'oven',
    applianceName: 'Oven',
    slotId: 'slot-1',
    slotLabel: '08.00–10.00',
    date: DateTime(2026, 8, 1),
    createdAt: DateTime(2026, 8, 1, 12),
  );

  group('DemoSession — bookings', () {
    test('starts empty', () {
      final c = newDemoContainer();
      expect(c.read(demoRepositoryProvider).bookings, isEmpty);
    });

    test('addBooking publishes a new snapshot the facade reflects', () {
      final c = newDemoContainer();
      c.read(demoSessionProvider.notifier).addBooking(booking('BKG-001'));

      final bookings = c.read(demoRepositoryProvider).bookings;
      expect(bookings.length, 1);
      expect(bookings.first.id, 'BKG-001');
    });

    test('bookings view is unmodifiable', () {
      final c = newDemoContainer();
      expect(
        () => c.read(demoRepositoryProvider).bookings.add(booking('x')),
        throwsUnsupportedError,
      );
    });

    test('can add multiple bookings', () {
      final c = newDemoContainer();
      final notifier = c.read(demoSessionProvider.notifier);
      for (var i = 0; i < 3; i++) {
        notifier.addBooking(booking('BKG-00$i'));
      }
      expect(c.read(demoRepositoryProvider).bookings.length, 3);
    });

    test('reset clears bookings', () {
      final c = newDemoContainer();
      c.read(demoSessionProvider.notifier).addBooking(booking('BKG-001'));
      expect(c.read(demoRepositoryProvider).bookings.length, 1);

      c.read(demoSessionProvider.notifier).reset();
      expect(c.read(demoRepositoryProvider).bookings, isEmpty);
    });
  });
}
