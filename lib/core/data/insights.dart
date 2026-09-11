/// Everything the dashboard shows, derived from what the user actually
/// recorded. No bundled figures, no model — plain arithmetic over their own
/// bills, appliances and sessions.
///
/// Each result carries how much data it stands on, so a screen can say
/// "belum cukup data" instead of showing a confident number built on one entry.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'app_data.dart';
import 'models.dart';

/// Grid emission factor used to turn hub kWh into avoided CO₂.
///
/// ASSUMPTION: 0.87 kg CO₂e per kWh, the commonly cited figure for Indonesia's
/// Jawa–Bali grid. It is not measured by this app and is shown as an estimate
/// everywhere it appears. Adjust here if the cooperative adopts an official
/// factor.
const double kGridEmissionFactorKgPerKwh = 0.87;

// ---------------------------------------------------------------------------
// Appliance cost attribution
// ---------------------------------------------------------------------------

@immutable
class ApplianceCost {
  const ApplianceCost({
    required this.appliance,
    required this.monthlyKwh,
    required this.monthlyCostIdr,
    required this.share,
  });

  final Appliance appliance;
  final double monthlyKwh;
  final int monthlyCostIdr;

  /// Fraction of the declared total, 0–1.
  final double share;
}

// ---------------------------------------------------------------------------
// Energy insight
// ---------------------------------------------------------------------------

@immutable
class EnergyInsight {
  const EnergyInsight({
    required this.latest,
    required this.previous,
    required this.contributors,
    required this.declaredKwh,
    required this.unaccountedKwh,
    required this.changePct,
    required this.spikeDetected,
    required this.declaredExceedsBill,
  });

  /// Most recent recorded bill.
  final Bill latest;

  /// The bill before it, when there is one.
  final Bill? previous;

  /// Declared appliances ranked by cost, biggest first.
  final List<ApplianceCost> contributors;

  /// Total energy the declared appliances account for.
  final double declaredKwh;

  /// Bill energy the appliance list does not explain (never negative).
  final double unaccountedKwh;

  /// Change in kWh vs the previous bill, in percent. Null without a previous.
  final double? changePct;

  /// Latest bill is meaningfully above the recent average.
  final bool spikeDetected;

  /// The declared appliances add up to more than the bill — the user's hours
  /// or wattage need correcting, so the breakdown is not trustworthy yet.
  final bool declaredExceedsBill;

  int extraCostIdr(double tariff) {
    final prev = previous;
    if (prev == null) return 0;
    final delta = latest.kwh - prev.kwh;
    return delta <= 0 ? 0 : (delta * tariff).round();
  }
}

/// Builds the insight for the most recent bill, or null when no bill exists.
EnergyInsight? buildEnergyInsight(AppData data) {
  if (data.bills.isEmpty) return null;

  final bills = [...data.bills]
    ..sort((a, b) => b.periodMonth.compareTo(a.periodMonth));
  final latest = bills.first;
  final previous = bills.length > 1 ? bills[1] : null;

  final tariff = data.profile?.tariffIdrPerKwh ?? latest.idrPerKwh;

  final declaredKwh = data.appliances.fold<double>(
    0,
    (sum, a) => sum + a.monthlyKwh,
  );
  final contributors = <ApplianceCost>[
    for (final a in data.appliances)
      ApplianceCost(
        appliance: a,
        monthlyKwh: a.monthlyKwh,
        monthlyCostIdr: a.monthlyCostIdr(tariff),
        share: declaredKwh <= 0 ? 0 : a.monthlyKwh / declaredKwh,
      ),
  ]..sort((a, b) => b.monthlyKwh.compareTo(a.monthlyKwh));

  final double? changePct = (previous == null || previous.kwh <= 0)
      ? null
      : (latest.kwh - previous.kwh) / previous.kwh * 100;

  // A spike is measured against the average of up to three earlier bills, so
  // one unusual month does not permanently define "normal".
  final earlier = bills.skip(1).take(3).toList();
  bool spike = false;
  if (earlier.isNotEmpty) {
    final avg = earlier.fold<double>(0, (s, b) => s + b.kwh) / earlier.length;
    spike = avg > 0 && latest.kwh > avg * 1.15;
  }

  return EnergyInsight(
    latest: latest,
    previous: previous,
    contributors: contributors,
    declaredKwh: declaredKwh,
    unaccountedKwh: math.max(0, latest.kwh - declaredKwh),
    changePct: changePct,
    spikeDetected: spike,
    declaredExceedsBill: declaredKwh > latest.kwh * 1.05,
  );
}

// ---------------------------------------------------------------------------
// Impact
// ---------------------------------------------------------------------------

@immutable
class ImpactMetrics {
  const ImpactMetrics({
    required this.gridKwh,
    required this.solarKwh,
    required this.sharedKwh,
    required this.co2AvoidedKg,
    required this.monthlySavingIdr,
    required this.solarSharePct,
    required this.groupSize,
    required this.hasData,
  });

  /// Total billed energy across every recorded bill.
  final double gridKwh;

  /// Total energy taken from the hub across every logged session.
  final double solarKwh;

  /// Energy the user published to other members.
  final double sharedKwh;
  final double co2AvoidedKg;

  /// Value of hub energy used this calendar month, at the user's tariff.
  final int monthlySavingIdr;

  /// Hub share of total energy, 0–100.
  final int solarSharePct;
  final int groupSize;

  /// False when nothing has been recorded — show an empty state, not zeros.
  final bool hasData;

  static const ImpactMetrics none = ImpactMetrics(
    gridKwh: 0,
    solarKwh: 0,
    sharedKwh: 0,
    co2AvoidedKg: 0,
    monthlySavingIdr: 0,
    solarSharePct: 0,
    groupSize: 0,
    hasData: false,
  );
}

ImpactMetrics buildImpact(AppData data) {
  final gridKwh = data.bills.fold<double>(0, (s, b) => s + b.kwh);
  final solarKwh = data.sessions.fold<double>(0, (s, x) => s + x.kwh);
  final sharedKwh = data.offers
      .where((o) => o.status != 'cancelled')
      .fold<double>(0, (s, o) => s + o.amountKwh);

  final now = DateTime.now();
  final thisMonthSolarKwh = data.sessions
      .where((s) => s.date.year == now.year && s.date.month == now.month)
      .fold<double>(0, (s, x) => s + x.kwh);

  final tariff = data.profile?.tariffIdrPerKwh ?? 0;
  final total = gridKwh + solarKwh;

  return ImpactMetrics(
    gridKwh: gridKwh,
    solarKwh: solarKwh,
    sharedKwh: sharedKwh,
    co2AvoidedKg: solarKwh * kGridEmissionFactorKgPerKwh,
    monthlySavingIdr: (thisMonthSolarKwh * tariff).round(),
    solarSharePct: total <= 0 ? 0 : (solarKwh / total * 100).round(),
    groupSize: data.arisan?.members.length ?? 0,
    hasData: data.bills.isNotEmpty || data.sessions.isNotEmpty,
  );
}

// ---------------------------------------------------------------------------
// Power-usage observations (Home "Status Penggunaan Daya")
// ---------------------------------------------------------------------------

@immutable
class PowerObservation {
  const PowerObservation({
    required this.id,
    required this.severity,
    required this.title,
    required this.body,
    this.route,
  });

  final String id;

  /// 'danger' | 'warning' | 'schedule' | 'info'.
  final String severity;
  final String title;
  final String body;
  final String? route;
}

/// Observations worth acting on, each one traceable to a recorded number.
List<PowerObservation> buildObservations(AppData data) {
  final out = <PowerObservation>[];
  final insight = buildEnergyInsight(data);
  final tariff = data.profile?.tariffIdrPerKwh ?? 0;

  if (insight != null) {
    if (insight.declaredExceedsBill) {
      out.add(
        const PowerObservation(
          id: 'obs-mismatch',
          severity: 'warning',
          title: 'Data alat perlu dikoreksi',
          body:
              'Total pemakaian alat yang Anda catat melebihi tagihan. Periksa '
              'lagi daya (watt) atau jam pemakaiannya.',
          route: '/appliances',
        ),
      );
    }

    final change = insight.changePct;
    if (insight.spikeDetected && change != null && change > 0) {
      final extra = insight.extraCostIdr(tariff);
      out.add(
        PowerObservation(
          id: 'obs-spike',
          severity: 'danger',
          title: 'Pemakaian naik ${change.round()}%',
          body: extra > 0
              ? 'Tagihan terakhir naik dibanding bulan sebelumnya, sekitar '
                    'Rp ${_thousands(extra)} lebih mahal.'
              : 'Tagihan terakhir lebih tinggi dari rata-rata bulan sebelumnya.',
          route: '/energy-analysis',
        ),
      );
    } else if (change != null && change < -5) {
      out.add(
        PowerObservation(
          id: 'obs-down',
          severity: 'info',
          title: 'Pemakaian turun ${change.abs().round()}%',
          body: 'Tagihan terakhir lebih hemat dari bulan sebelumnya. Bagus!',
          route: '/energy-analysis',
        ),
      );
    }

    if (insight.contributors.isNotEmpty) {
      final top = insight.contributors.first;
      if (top.share >= 0.35) {
        out.add(
          PowerObservation(
            id: 'obs-top',
            severity: 'warning',
            title: '${top.appliance.name} paling boros',
            body:
                'Sekitar ${(top.share * 100).round()}% dari pemakaian alat yang '
                'Anda catat — kira-kira Rp ${_thousands(top.monthlyCostIdr)} '
                'per bulan. Coba jadwalkan di Solar Hub.',
            route: '/solar-booking',
          ),
        );
      }
    }
  }

  // Housekeeping nudges — these are the difference between a dashboard and a
  // tool people keep using.
  final now = DateTime.now();
  final hasThisMonthBill = data.bills.any(
    (b) => b.periodMonth.year == now.year && b.periodMonth.month == now.month,
  );
  if (!hasThisMonthBill) {
    out.add(
      PowerObservation(
        id: 'obs-nobill',
        severity: 'info',
        title: 'Catat tagihan bulan ini',
        body:
            'Tagihan bulan ini belum dicatat. Semakin rutin dicatat, semakin '
            'akurat analisis dan skor Anda.',
        route: '/scan-tagihan',
      ),
    );
  }

  if (data.appliances.isEmpty) {
    out.add(
      const PowerObservation(
        id: 'obs-noappliance',
        severity: 'info',
        title: 'Daftarkan alat usaha Anda',
        body:
            'Tambahkan alat dan jam pakainya supaya IbuDaya bisa memecah '
            'tagihan Anda per alat.',
        route: '/appliances',
      ),
    );
  }

  return out;
}

String _thousands(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}$b';
}
