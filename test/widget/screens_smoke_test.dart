// Opens every screen for each role on a 360 dp phone. One test per screen so
// a failure names the screen and prints the overflowing widget.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ibudaya/core/paths.dart';
import 'package:ibudaya/core/repositories/local/sample_seeder.dart';

import 'app_flow_test.dart' show pumpApp, routerOf;

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  for (final path in [
    Paths.memberHome,
    Paths.memberSolar,
    Paths.memberMessages,
    Paths.memberProfile,
    Paths.score,
    Paths.loanApply,
    Paths.loans,
    Paths.arisan,
    Paths.quota,
    Paths.energyAnalysis,
    Paths.energy,
    Paths.booking,
    Paths.bookings,
    Paths.appliances,
    Paths.applianceEdit,
    Paths.roof,
    Paths.quotaNew,
    Paths.notifications,
    Paths.profileEdit,
    Paths.about,
  ]) {
    testWidgets('member $path', (tester) async {
      await pumpApp(
        tester,
        signedInAs: SampleSeeder.memberPhone,
        size: const Size(360, 780),
      );
      routerOf(tester).go(path);
      await tester.pumpAndSettle();
    });
  }

  for (final path in [
    Paths.adminHome,
    Paths.adminLoans,
    Paths.adminMembers,
    Paths.adminMore,
    Paths.adminPayments,
    Paths.adminArisan,
    Paths.adminArisanNew,
    Paths.adminHub,
    Paths.adminSettings,
    Paths.adminAnnounce,
    Paths.adminMessages,
  ]) {
    testWidgets('admin $path', (tester) async {
      await pumpApp(
        tester,
        signedInAs: SampleSeeder.adminPhone,
        size: const Size(360, 780),
      );
      routerOf(tester).go(path);
      await tester.pumpAndSettle();
    });
  }
}
