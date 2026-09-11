/// A first estimate of what a roof could produce, from numbers the member
/// measured herself.
///
/// The app cannot see the roof. It multiplies the member's measurements by the
/// assumptions below, and the result screen lists every one of them. An
/// installer still has to inspect the roof before anything is bought.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/energy.dart';

/// ASSUMPTION: share of the measured roof usable for panels once edges and
/// walkways are left clear.
const double kUsableRoofFraction = 0.7;

/// ASSUMPTION: roof area one kilowatt-peak of panels occupies.
const double kSquareMetersPerKwp = 6.0;

/// ASSUMPTION: average peak-sun hours per day across Indonesia (3.5–4.5).
const double kPeakSunHours = 4.0;

/// ASSUMPTION: share of panel output that survives inverter, wiring and heat
/// losses.
const double kPerformanceRatio = 0.8;

double orientationFactor(RoofOrientation o) => switch (o) {
  // Most of Indonesia's population lives just south of the equator, where a
  // north-facing tilt catches the most sun.
  RoofOrientation.north => 1.0,
  RoofOrientation.flat => 0.95,
  RoofOrientation.eastWest => 0.93,
  RoofOrientation.south => 0.88,
  RoofOrientation.unknown => 0.9,
};

double shadingFactor(RoofShading s) => switch (s) {
  RoofShading.none => 1.0,
  RoofShading.partial => 0.8,
  RoofShading.heavy => 0.55,
};

@immutable
class RoofEstimate {
  const RoofEstimate({
    required this.usableAreaM2,
    required this.kwp,
    required this.monthlyKwh,
    required this.monthlySavingIdr,
    required this.systemCostIdr,
    required this.paybackYears,
    required this.band,
    required this.siteFactor,
  });

  final double usableAreaM2;
  final double kwp;
  final double monthlyKwh;
  final int monthlySavingIdr;
  final int systemCostIdr;

  /// Null when there is no saving to pay the system back with.
  final double? paybackYears;
  final String band;

  /// Orientation × shading, 0–1.
  final double siteFactor;
}

RoofEstimate estimateRoof({
  required double lengthM,
  required double widthM,
  required RoofOrientation orientation,
  required RoofShading shading,
  required double tariffIdrPerKwh,
  required int costPerKwpIdr,
  double? monthlyUsageKwh,
}) {
  final area = math.max(0.0, lengthM) * math.max(0.0, widthM);
  final usable = area * kUsableRoofFraction;
  final kwp = usable / kSquareMetersPerKwp;
  final siteFactor = orientationFactor(orientation) * shadingFactor(shading);
  final monthlyKwh = kwp * kPeakSunHours * kPerformanceRatio * siteFactor * 30;

  // Energy beyond what the business uses does not lower its bill.
  final offset = monthlyUsageKwh == null || monthlyUsageKwh <= 0
      ? monthlyKwh
      : math.min(monthlyKwh, monthlyUsageKwh);
  final saving = (offset * tariffIdrPerKwh).round();
  final cost = (kwp * costPerKwpIdr).round();
  final payback = saving <= 0 ? null : cost / (saving * 12);

  final String band;
  if (kwp >= 1 && siteFactor >= 0.85) {
    band = 'Sangat Layak';
  } else if (kwp >= 0.5 && siteFactor >= 0.7) {
    band = 'Layak';
  } else if (kwp >= 0.3 && siteFactor >= 0.5) {
    band = 'Cukup Layak';
  } else {
    band = 'Kurang Layak';
  }

  return RoofEstimate(
    usableAreaM2: usable,
    kwp: kwp,
    monthlyKwh: monthlyKwh,
    monthlySavingIdr: saving,
    systemCostIdr: cost,
    paybackYears: payback,
    band: band,
    siteFactor: siteFactor,
  );
}
