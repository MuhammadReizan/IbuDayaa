/// Models for the demo-bill payloads served by [DemoBillRepository]
/// (`lib/core/demo/demo_bill_repository.dart`).
///
/// A scanned demo barcode carries no data of its own — it is only a key
/// (the same way a real PLN meter's printed barcode is just a serial number
/// PLN looks up in its own systems). This file only shapes what a looked-up
/// entry means once found; parsing is defensive throughout so one malformed
/// dummy entry never crashes a scan, it just fails to match.
library;

import 'package:flutter/foundation.dart';

/// Marker `type` field so a differently-shaped map (a future demo dataset
/// for another feature, say) is rejected outright rather than partially
/// matched.
const String kDemoBillPayloadType = 'ibudaya_demo_bill';

@immutable
class DemoBillEntry {
  const DemoBillEntry({
    required this.month,
    required this.kwh,
    required this.totalIdr,
  });

  final DateTime month;
  final double kwh;
  final int totalIdr;
}

@immutable
class DemoApplianceEntry {
  const DemoApplianceEntry({
    required this.name,
    required this.kind,
    required this.watts,
    required this.hoursPerDay,
    required this.daysPerWeek,
  });

  final String name;

  /// One of the keys in `kApplianceKinds` (lib/features/shared/labels.dart);
  /// an unknown value just falls back to the generic icon, so this is never
  /// validated against that list here.
  final String kind;
  final double watts;
  final double hoursPerDay;
  final int daysPerWeek;
}

@immutable
class DemoContributorData {
  const DemoContributorData({
    required this.name,
    required this.monthlyCost,
    required this.percentage,
    this.kind = 'other',
  });

  final String name;
  final int monthlyCost;
  final double percentage; // 0..100
  final String kind;

  static DemoContributorData? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final cost = raw['monthly_cost'];
    final pct = raw['percentage'];
    return DemoContributorData(
      name: name.trim(),
      monthlyCost: cost is num ? cost.round() : int.tryParse('$cost') ?? 0,
      percentage: pct is num ? pct.toDouble() : double.tryParse('$pct') ?? 0.0,
      kind: raw['kind'] is String ? raw['kind'] as String : 'other',
    );
  }
}

@immutable
class DemoAnalysisData {
  const DemoAnalysisData({
    required this.status,
    required this.title,
    required this.description,
    required this.extraCost,
    required this.mainCause,
    required this.insight,
    this.contributors = const [],
  });

  /// e.g. 'energy_spike', 'normal', 'solar_recommendation'
  final String status;
  final String title;
  final String description;
  final int extraCost;
  final String mainCause;
  final String insight;
  final List<DemoContributorData> contributors;

  static DemoAnalysisData? fromMap(Object? raw) {
    if (raw is! Map) return null;
    return DemoAnalysisData(
      status: raw['status'] is String ? raw['status'] as String : 'energy_spike',
      title: raw['title'] is String ? raw['title'] as String : 'Analisis AI Energi',
      description: raw['description'] is String ? raw['description'] as String : '',
      extraCost: raw['extra_cost'] is num
          ? (raw['extra_cost'] as num).round()
          : int.tryParse('${raw['extra_cost']}') ?? 0,
      mainCause: raw['main_cause'] is String ? raw['main_cause'] as String : '',
      insight: raw['insight'] is String ? raw['insight'] as String : '',
      contributors: [
        for (final c in (raw['contributors'] as List?) ?? const [])
          if (DemoContributorData.fromMap(c) case final item?) item,
      ],
    );
  }
}

@immutable
class DemoBillPayload {
  const DemoBillPayload({
    required this.current,
    this.history = const [],
    this.appliances = const [],
    this.analysis,
  });

  /// The bill "just scanned" — prefills the editable confirm screen.
  final DemoBillEntry current;

  /// Earlier months, saved silently before landing on the confirm screen, so
  /// the real spike-detection average has something to compare against.
  final List<DemoBillEntry> history;

  /// Appliances to register (skipped if the member already has one with the
  /// same name), so the real per-appliance cost breakdown has data to show.
  final List<DemoApplianceEntry> appliances;

  /// Optional pre-computed AI analysis dataset for controlled demo scenarios.
  final DemoAnalysisData? analysis;

  /// Builds a payload from one entry of [demoPayloads]. Returns null when
  /// the entry is malformed rather than throwing, so a typo in the bundled
  /// dummy dataset fails one lookup instead of crashing the scan.
  static DemoBillPayload? fromMap(Map<String, dynamic> raw) {
    if (raw['type'] != kDemoBillPayloadType) return null;
    final current = _entry(raw['current']);
    if (current == null) return null;

    final history = <DemoBillEntry>[
      for (final h in (raw['history'] as List?) ?? const [])
        if (h is Map)
          if (_entry(h) case final e?) e,
    ];
    final appliances = <DemoApplianceEntry>[
      for (final a in (raw['appliances'] as List?) ?? const [])
        if (a is Map)
          if (_appliance(a) case final e?) e,
    ];
    final analysis = raw['analysis'] != null
        ? DemoAnalysisData.fromMap(raw['analysis'])
        : null;

    return DemoBillPayload(
      current: current,
      history: history,
      appliances: appliances,
      analysis: analysis,
    );
  }

  static DemoBillEntry? _entry(Object? raw) {
    if (raw is! Map) return null;
    final month = _month(raw['month']);
    final kwh = _num(raw['kwh']);
    final total = _num(raw['total_idr']);
    if (month == null) return null;
    if (kwh == null || kwh <= 0 || kwh > 20000) return null;
    if (total == null || total < 1000) return null;
    return DemoBillEntry(month: month, kwh: kwh, totalIdr: total.round());
  }

  static DemoApplianceEntry? _appliance(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name'];
    final watts = _num(raw['watts']);
    final hours = _num(raw['hours_per_day']);
    final days = _num(raw['days_per_week']);
    if (name is! String || name.trim().isEmpty) return null;
    if (watts == null || watts <= 0 || watts > 20000) return null;
    if (hours == null || hours <= 0 || hours > 24) return null;
    if (days == null || days < 1 || days > 7) return null;
    return DemoApplianceEntry(
      name: name.trim(),
      kind: raw['kind'] is String ? raw['kind'] as String : 'other',
      watts: watts,
      hoursPerDay: hours,
      daysPerWeek: days.round(),
    );
  }

  /// `"2026-08"` → August 2026. Rejects anything else so a typo in a demo
  /// entry fails to parse instead of landing on the wrong month.
  static DateTime? _month(Object? raw) {
    if (raw is! String) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(raw.trim());
    if (m == null) return null;
    final month = int.parse(m.group(2)!);
    if (month < 1 || month > 12) return null;
    return DateTime(int.parse(m.group(1)!), month);
  }

  static double? _num(Object? raw) => switch (raw) {
    num n => n.toDouble(),
    String s => double.tryParse(s),
    _ => null,
  };
}
