// Opens every screen for each role on a 360 dp phone. One test per screen so
// a failure names the screen and prints the overflowing widget.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ibudaya/core/paths.dart';
import 'package:ibudaya/core/repositories/local/sample_seeder.dart';
import 'package:ibudaya/core/state/app_state.dart';

import 'app_flow_test.dart' show containerOf, pumpApp, routerOf;

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  for (final path in [
    Paths.memberHome,
    Paths.memberSolar,
    Paths.memberMessages,
    Paths.memberProfile,
    Paths.score,
    Paths.creditReport,
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
    Paths.hubConnect,
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
    Paths.adminHubRequests,
    Paths.adminHubBoard,
    Paths.adminSummary,
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

  testWidgets('admin member detail (hub allocation field)', (tester) async {
    await pumpApp(
      tester,
      signedInAs: SampleSeeder.adminPhone,
      size: const Size(360, 780),
    );
    final clara = containerOf(tester)
        .read(appStateProvider)
        .data
        .members
        .firstWhere((m) => m.fullName == 'Ibu Clara');
    routerOf(tester).go(Paths.adminMember(clara.id));
    await tester.pumpAndSettle();
  });
}
