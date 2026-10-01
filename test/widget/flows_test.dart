// Walks the main flows by tapping, the way a person does, instead of calling
// the repositories: a member books a slot with several appliances, a borrower
// sends an installment payment, an admin confirms or rejects it, and a member
// can no longer mark her own session as used.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ibudaya/core/db/row.dart';
import 'package:ibudaya/core/models/models.dart';
import 'package:ibudaya/core/paths.dart';
import 'package:ibudaya/core/repositories/local/sample_seeder.dart';
import 'package:ibudaya/core/state/actions.dart';
import 'package:ibudaya/core/state/app_state.dart';
import 'package:ibudaya/core/state/selectors.dart';

import 'app_flow_test.dart' show containerOf, pumpApp, routerOf, tapText;

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('a member books a slot with two appliances and sees her quota '
      'drop', (tester) async {
    await pumpApp(tester, signedInAs: SampleSeeder.memberPhone);
    routerOf(tester).go(Paths.booking);
    await tester.pumpAndSettle();

    // Oven is picked first; add the blender, then choose the afternoon slot.
    await tapText(tester, 'Blender');
    await tapText(tester, '12.00–15.00');
    await tapText(tester, 'Pesan slot 12.00–15.00');
    expect(tester.takeException(), isNull);

    final data = containerOf(tester).read(appStateProvider).data;
    final me = containerOf(tester).read(appStateProvider).me!;
    final booking = data
        .bookingsOf(me.id)
        .firstWhere((b) => b.status == BookingStatus.booked);
    expect(booking.applianceName, 'Oven, Blender');
    // (1500 W + 350 W) × 3 h
    expect(booking.estKwh, closeTo(5.55, 1e-9));
    expect(booking.loadKw, closeTo(1.85, 1e-9));
    expect(
      data
          .availabilityOn(booking.bookingDate)
          .firstWhere((a) => a.slot.id == booking.slotId)
          .bookedMembers,
      1,
    );
    // The month's allowance comes down by what was booked.
    final q = data.quotaOf(me.id, booking.bookingDate);
    expect(q.reservedKwh, closeTo(5.55, 1e-9));
    expect(q.usedKwh, closeTo(7.4, 1e-9), reason: 'nothing new was used');
  });

  testWidgets('a member whose payment was rejected sees why and sends it '
      'again', (tester) async {
    // Ibu Lina: her first installment was rejected and is overdue.
    await pumpApp(tester, signedInAs: '081200000004');
    routerOf(tester).go(Paths.installments);
    await tester.pumpAndSettle();
    expect(find.textContaining('Ditolak admin'), findsWidgets);

    await tapText(tester, 'Saya sudah bayar');
    await tapText(tester, 'Kirim');
    expect(tester.takeException(), isNull);

    final data = containerOf(tester).read(appStateProvider).data;
    final mine = data.installmentsAwaiting.single;
    expect(mine.seq, 1);
    expect(mine.reviewNote, isNull, reason: 'the old rejection is cleared');
    expect(find.textContaining('Menunggu konfirmasi'), findsWidgets);
    // Sending twice is refused.
    expect(find.text('Saya sudah bayar'), findsNothing);
  });

  testWidgets('an admin confirms a payment after checking it', (tester) async {
    await pumpApp(tester, signedInAs: SampleSeeder.adminPhone);
    routerOf(tester).go(Paths.adminInstallments);
    await tester.pumpAndSettle();

    expect(find.text('Ibu Putri'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Konfirmasi').first);
    await tester.pumpAndSettle();
    // The money-related action asks first.
    expect(find.text('Batal'), findsWidgets);
    await tapText(tester, 'Konfirmasi');
    expect(tester.takeException(), isNull);

    final data = containerOf(tester).read(appStateProvider).data;
    expect(data.installmentsAwaiting, isEmpty);
    final putri = data.members.firstWhere((m) => m.fullName == 'Ibu Putri');
    final loan = data.loansOf(putri.id).single;
    expect(
      data.installmentsOf(loan.id).where((i) => i.isPaid).map((i) => i.seq),
      [1, 2],
    );
  });

  testWidgets('an admin rejects a payment only with a reason', (tester) async {
    await pumpApp(tester, signedInAs: SampleSeeder.adminPhone);
    routerOf(tester).go(Paths.adminInstallments);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Tolak').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Uang belum masuk');
    await tester.pump();
    await tapText(tester, 'Tolak');
    expect(tester.takeException(), isNull);

    final data = containerOf(tester).read(appStateProvider).data;
    expect(data.installmentsAwaiting, isEmpty);
    final rejected = data.installments.where((i) => i.wasRejected).toList();
    expect(rejected.map((i) => i.reviewNote), contains('Uang belum masuk'));
  });

  testWidgets('a member has a scan button for today\'s booking and no way to '
      'mark it used herself', (tester) async {
    await pumpApp(tester, signedInAs: SampleSeeder.memberPhone);
    final container = containerOf(tester);
    final clock = container.read(clockProvider)();
    final slot = container
        .read(appStateProvider)
        .data
        .orderedSlots
        .firstWhere((s) => s.endHour > clock.hour);
    await container
        .read(actionsProvider)
        .book(
          slotId: slot.id,
          date: dayOf(clock),
          applianceName: 'Oven',
          estKwh: 3,
          loadKw: 1.5,
        );

    routerOf(tester).go(Paths.bookings);
    await tester.pumpAndSettle();
    expect(find.text('Scan QR'), findsOneWidget);
    expect(find.text('Selesai'), findsNothing);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
