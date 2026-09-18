/// Everything the member dashboard says about electricity, computed from the
/// member's own bills, tokens, appliances and completed hub sessions.
library;

import 'package:flutter/foundation.dart';

import '../db/row.dart';
import '../l10n/l10n.dart';
import '../models/energy.dart';
import '../models/solar.dart';

/// ASSUMPTION: 0.87 kg CO₂e per kWh, the commonly cited factor for Indonesia's
/// Jawa–Bali grid. Not measured by the app; always shown as an estimate.
const double kGridEmissionFactorKgPerKwh = 0.87;

@immutable
class MonthlyUsage {
  const MonthlyUsage({
    required this.month,
    required this.kwh,
    required this.totalIdr,
    required this.fromTokens,
    required this.recordCount,
  });

  final DateTime month;
  final double kwh;
  final int totalIdr;

  /// True when the month is built from token purchases, which reflect when
  /// energy was bought rather than exactly when it was used.
  final bool fromTokens;
  final int recordCount;
}

/// One entry per month, newest first. A month with a bill uses the bill;
/// otherwise its token purchases are summed.
List<MonthlyUsage> monthlyUsage(Iterable<EnergyRecord> records) {
  final byMonth = <DateTime, List<EnergyRecord>>{};
  for (final r in records) {
    byMonth.putIfAbsent(monthOf(r.periodMonth), () => []).add(r);
  }
  final out = <MonthlyUsage>[];
  byMonth.forEach((month, list) {
    final bills = list.where((r) => r.kind == EnergyKind.postpaid).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (bills.isNotEmpty) {
      out.add(
        MonthlyUsage(
          month: month,
          kwh: bills.first.kwh,
          totalIdr: bills.first.totalIdr,
          fromTokens: false,
          recordCount: 1,
        ),
      );
    } else {
      out.add(
        MonthlyUsage(
          month: month,
          kwh: list.fold(0, (s, r) => s + r.kwh),
          totalIdr: list.fold(0, (s, r) => s + r.totalIdr),
          fromTokens: true,
          recordCount: list.length,
        ),
      );
    }
  });
  out.sort((a, b) => b.month.compareTo(a.month));
  return out;
}

@immutable
class ApplianceCost {
  const ApplianceCost({
    required this.name,
    required this.kind,
    required this.monthlyKwh,
    required this.monthlyCostIdr,
    required this.share,
  });

  final String name;

  /// Appliance kind key (see `kApplianceKinds`), 'other' when unknown.
  final String kind;
  final double monthlyKwh;
  final int monthlyCostIdr;

  /// Share of the latest month's hub usage, 0–1.
  final double share;
}

@immutable
class EnergyInsight {
  const EnergyInsight({
    required this.latest,
    required this.previous,
    required this.contributors,
    required this.changePct,
    required this.spikeDetected,
  });

  final MonthlyUsage latest;
  final MonthlyUsage? previous;

  /// Which appliances used the hub in the latest month, from completed hub
  /// sessions only (kWh × the member's tariff) — never from declared hours.
  final List<ApplianceCost> contributors;

  /// kWh change vs the previous month, percent.
  final double? changePct;

  /// Latest month is well above the average of up to three earlier months.
  final bool spikeDetected;

  int extraCostIdr(double tariff) {
    final prev = previous;
    if (prev == null) return 0;
    final delta = latest.kwh - prev.kwh;
    return delta <= 0 ? 0 : (delta * tariff).round();
  }
}

EnergyInsight? buildEnergyInsight({
  required Iterable<EnergyRecord> records,
  required Iterable<Appliance> appliances,
  required Iterable<HubBooking> completedBookings,
  required double tariff,
}) {
  final months = monthlyUsage(records);
  if (months.isEmpty) return null;
  final latest = months.first;
  final previous = months.length > 1 ? months[1] : null;

  final byName = {for (final a in appliances) a.name.trim().toLowerCase(): a};
  final kindByName = {for (final e in byName.entries) e.key: e.value.kind};
  final kwhByName = <String, double>{};
  final displayName = <String, String>{};
  for (final b in completedBookings) {
    if (b.status != BookingStatus.completed ||
        !sameMonth(b.bookingDate, latest.month)) {
      continue;
    }
    void add(String name, double kwh) {
      final key = name.trim().toLowerCase();
      displayName.putIfAbsent(key, () => name.trim());
      kwhByName[key] = (kwhByName[key] ?? 0) + kwh;
    }

    // A hub session covers all of a member's registered appliances ("Oven,
    // Kulkas"); its kWh is shared out by each appliance's watts.
    final names = b.applianceName
        .split(',')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    final parts = [for (final n in names) byName[n.toLowerCase()]];
    final totalWatts = parts.fold<double>(0, (sum, a) => sum + (a?.watts ?? 0));
    if (names.length > 1 && !parts.contains(null) && totalWatts > 0) {
      for (int i = 0; i < names.length; i++) {
        add(names[i], b.estKwh * parts[i]!.watts / totalWatts);
      }
    } else {
      add(b.applianceName, b.estKwh);
    }
  }
  final usedKwh = kwhByName.values.fold<double>(0, (s, v) => s + v);
  final contributors = [
    for (final e in kwhByName.entries)
      ApplianceCost(
        name: displayName[e.key]!,
        kind: kindByName[e.key] ?? 'other',
        monthlyKwh: e.value,
        monthlyCostIdr: (e.value * tariff).round(),
        share: usedKwh <= 0 ? 0 : e.value / usedKwh,
      ),
  ]..sort((a, b) => b.monthlyKwh.compareTo(a.monthlyKwh));

  final double? change = (previous == null || previous.kwh <= 0)
      ? null
      : (latest.kwh - previous.kwh) / previous.kwh * 100;

  final earlier = months.skip(1).take(3).toList();
  final avg = earlier.isEmpty
      ? 0.0
      : earlier.fold<double>(0, (s, m) => s + m.kwh) / earlier.length;

  return EnergyInsight(
    latest: latest,
    previous: previous,
    contributors: contributors,
    changePct: change,
    spikeDetected: avg > 0 && latest.kwh > avg * 1.15,
  );
}

// ---------------------------------------------------------------------------

@immutable
class ImpactMetrics {
  const ImpactMetrics({
    required this.gridKwh,
    required this.solarKwh,
    required this.co2AvoidedKg,
    required this.thisMonthSavingIdr,
    required this.solarSharePct,
  });

  final double gridKwh;
  final double solarKwh;
  final double co2AvoidedKg;

  /// Hub energy used this month, valued at the member's tariff.
  final int thisMonthSavingIdr;
  final int solarSharePct;

  bool get hasData => gridKwh > 0 || solarKwh > 0;
}

ImpactMetrics buildImpact({
  required Iterable<EnergyRecord> records,
  required Iterable<HubBooking> completedBookings,
  required double tariff,
  required DateTime now,
}) {
  final grid = records.fold<double>(0, (s, r) => s + r.kwh);
  final done = completedBookings.where(
    (b) => b.status == BookingStatus.completed,
  );
  final solar = done.fold<double>(0, (s, b) => s + b.estKwh);
  final thisMonth = done
      .where((b) => sameMonth(b.bookingDate, now))
      .fold<double>(0, (s, b) => s + b.estKwh);
  final total = grid + solar;

  return ImpactMetrics(
    gridKwh: grid,
    solarKwh: solar,
    co2AvoidedKg: solar * kGridEmissionFactorKgPerKwh,
    thisMonthSavingIdr: (thisMonth * tariff).round(),
    solarSharePct: total <= 0 ? 0 : (solar / total * 100).round(),
  );
}

// ---------------------------------------------------------------------------

enum ObservationAction { useHub, appliances, analysis, booking, confirmBooking }

enum ObservationTone { danger, warning, success, info }

@immutable
class PowerObservation {
  const PowerObservation({
    required this.id,
    required this.tone,
    required this.title,
    required this.body,
    required this.action,
  });

  final String id;
  final ObservationTone tone;
  final String title;
  final String body;
  final ObservationAction action;
}

/// "Status Penggunaan Daya": what is worth acting on, each item traceable to a
/// recorded number.
List<PowerObservation> buildObservations({
  required EnergyInsight? insight,
  required Iterable<EnergyRecord> records,
  required Iterable<Appliance> appliances,
  required Iterable<HubBooking> myBookings,
  required double tariff,
  required DateTime now,
  required String Function(int) rupiah,
  AppLocalizations? l10n,
}) {
  final out = <PowerObservation>[];

  if (insight != null) {
    final change = insight.changePct;
    if (insight.spikeDetected && change != null && change > 0) {
      final extra = insight.extraCostIdr(tariff);
      out.add(
        PowerObservation(
          id: 'spike',
          tone: ObservationTone.danger,
          title: l10n != null
              ? l10n.obsSpikeTitle(change.round())
              : 'Lonjakan pemakaian ${change.round()}%',
          body: extra > 0
              ? (l10n != null
                    ? l10n.obsSpikeBodyExtra(rupiah(extra))
                    : 'Lebih mahal sekitar ${rupiah(extra)} dibanding bulan lalu.')
              : (l10n?.obsSpikeBodyAvg ??
                    'Pemakaian bulan ini di atas rata-rata bulan sebelumnya.'),
          action: ObservationAction.analysis,
        ),
      );
    } else if (change != null && change < -5) {
      out.add(
        PowerObservation(
          id: 'saving',
          tone: ObservationTone.success,
          title: l10n != null
              ? l10n.obsSavingTitle(change.abs().round())
              : 'Pemakaian turun ${change.abs().round()}%',
          body:
              l10n?.obsSavingBody ??
              'Lebih hemat dibanding bulan lalu. Pertahankan!',
          action: ObservationAction.analysis,
        ),
      );
    }

    if (insight.contributors.isNotEmpty &&
        insight.contributors.first.share >= 0.35) {
      final top = insight.contributors.first;
      out.add(
        PowerObservation(
          id: 'top-appliance',
          tone: ObservationTone.warning,
          title: l10n != null
              ? l10n.obsTopApplianceTitle(top.name)
              : '${top.name} paling boros',
          body: l10n != null
              ? l10n.obsTopApplianceBody(rupiah(top.monthlyCostIdr))
              : '±${rupiah(top.monthlyCostIdr)}/bulan. Pindahkan ke jam Solar Hub.',
          action: ObservationAction.booking,
        ),
      );
    }
  }

  final unconfirmed = myBookings.where(
    (b) =>
        b.status == BookingStatus.booked && dayOf(now).isAfter(b.bookingDate),
  );
  if (unconfirmed.isNotEmpty) {
    out.add(
      PowerObservation(
        id: 'confirm-booking',
        tone: ObservationTone.info,
        title: l10n?.obsConfirmBookingTitle ?? 'Konfirmasi pemakaian hub',
        body: l10n != null
            ? l10n.obsConfirmBookingBody(unconfirmed.length)
            : '${unconfirmed.length} jadwal sudah lewat. Tandai sudah dipakai agar penghematan tercatat.',
        action: ObservationAction.confirmBooking,
      ),
    );
  }

  if (!records.any((r) => sameMonth(r.periodMonth, now))) {
    out.add(
      PowerObservation(
        id: 'no-record',
        tone: ObservationTone.info,
        title: l10n?.obsUseHubTitle ?? 'Pakai Solar Hub bulan ini',
        body:
            l10n?.obsUseHubBody ??
            'Belum ada catatan listrik bulan ini — pakai hub agar tercatat otomatis.',
        action: ObservationAction.useHub,
      ),
    );
  }

  if (appliances.isEmpty) {
    out.add(
      PowerObservation(
        id: 'no-appliance',
        tone: ObservationTone.info,
        title: l10n?.obsNoApplianceTitle ?? 'Daftarkan alat usaha',
        body:
            l10n?.obsNoApplianceBody ?? 'Supaya tagihan bisa dipecah per alat.',
        action: ObservationAction.appliances,
      ),
    );
  }

  return out;
}
