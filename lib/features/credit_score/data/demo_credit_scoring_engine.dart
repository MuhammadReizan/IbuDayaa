import 'package:flutter/foundation.dart';

import '../domain/credit_scoring_engine.dart';

/// IMPLEMENTATION STATUS: IMPLEMENTED — deterministic rule-based engine.
///
/// This is NOT a machine-learning or AI model. It applies transparent
/// arithmetic rules to the four normalised input signals and produces an
/// explainable score. See docs/DATA_MODEL.md §4.1 and docs/AGENTS.MD
/// (product-honesty section).
///
/// Canonical demo output (Ibu Clara seed):
///   30/35 + 24/30 + 18/20 + 10/15 = 82/100 → band: Baik Sekali
@immutable
class DemoCreditScoringEngine implements CreditScoringEngine {
  const DemoCreditScoringEngine();

  // Category maxima (docs/DATA_MODEL.md §3.11 + §4.1).
  static const Map<CreditCategory, int> _maxPoints = {
    CreditCategory.energyUsage: 35,
    CreditCategory.paymentHistory: 30,
    CreditCategory.businessActivity: 20,
    CreditCategory.communityParticipation: 15,
  };

  // Indonesian display labels per category (docs/DATA_MODEL.md §3.11).
  static const Map<CreditCategory, String> _labels = {
    CreditCategory.energyUsage: 'Konsistensi pemakaian energi',
    CreditCategory.paymentHistory: 'Riwayat pembayaran',
    CreditCategory.businessActivity: 'Aktivitas usaha',
    CreditCategory.communityParticipation: 'Partisipasi komunitas',
  };

  @override
  CreditScore compute(CreditScoreInputs inputs) {
    final signals = {
      CreditCategory.energyUsage: inputs.energyUsageConsistency,
      CreditCategory.paymentHistory: inputs.paymentHistory,
      CreditCategory.businessActivity: inputs.businessActivity,
      CreditCategory.communityParticipation: inputs.communityParticipation,
    };

    final factors = CreditCategory.values
        .map((cat) {
          final signal = (signals[cat] ?? 0.0).clamp(0.0, 1.0);
          final max = _maxPoints[cat]!;
          final pts = (signal * max).round();
          final ratio = max > 0 ? pts / max : 0.0;
          final direction = ratio >= 0.6
              ? FactorDirection.positive
              : ratio >= 0.4
              ? FactorDirection.neutral
              : FactorDirection.negative;

          return CreditFactor(
            category: cat,
            label: _labels[cat]!,
            direction: direction,
            points: pts,
            maxPoints: max,
            reason: _reason(cat, direction, pts, max),
          );
        })
        .toList(growable: false);

    final score = factors.fold(0, (sum, f) => sum + f.points);
    final band = _band(score);

    return CreditScore(
      score: score,
      band: band,
      factors: factors,
      eligibilityLabel: _eligibilityLabel(score),
      computedAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static CreditBand _band(int score) {
    if (score >= 80) return CreditBand.baikSekali;
    if (score >= 65) return CreditBand.baik;
    if (score >= 50) return CreditBand.cukup;
    return CreditBand.perluPeningkatan;
  }

  /// Short eligibility message. Does NOT mention rupiah — financing limits
  /// belong to the financing domain, not the scoring engine (correction #4).
  static String _eligibilityLabel(int score) {
    if (score >= 65) {
      return 'Layak untuk melihat simulasi pembiayaan';
    }
    return 'Skor perlu ditingkatkan untuk mengakses simulasi pembiayaan';
  }

  /// Per-category templated reason (docs/DATA_MODEL.md §3.11).
  static String _reason(
    CreditCategory cat,
    FactorDirection dir,
    int pts,
    int max,
  ) {
    return switch (cat) {
      CreditCategory.energyUsage =>
        dir == FactorDirection.positive
            ? 'Pemakaian energi Anda konsisten — menunjukkan pengelolaan daya yang baik.'
            : dir == FactorDirection.neutral
            ? 'Konsistensi pemakaian energi masih dapat ditingkatkan.'
            : 'Pemakaian energi tidak konsisten dalam periode ini.',
      CreditCategory.paymentHistory =>
        dir == FactorDirection.positive
            ? 'Riwayat pembayaran arisan tepat waktu meningkatkan skor Anda.'
            : dir == FactorDirection.neutral
            ? 'Sebagian pembayaran arisan belum tercatat tepat waktu.'
            : 'Terdapat keterlambatan pembayaran yang memengaruhi skor.',
      CreditCategory.businessActivity =>
        dir == FactorDirection.positive
            ? 'Aktivitas usaha aktif mencerminkan kemampuan pengelolaan keuangan.'
            : dir == FactorDirection.neutral
            ? 'Aktivitas usaha cukup, namun masih bisa lebih konsisten.'
            : 'Aktivitas usaha terbatas dalam periode penilaian.',
      CreditCategory.communityParticipation =>
        dir == FactorDirection.positive
            ? 'Partisipasi aktif di komunitas IbuDaya memperkuat profil Anda.'
            : dir == FactorDirection.neutral
            ? 'Partisipasi komunitas bisa ditingkatkan untuk skor lebih tinggi.'
            : 'Partisipasi komunitas masih minim dalam periode ini.',
    };
  }
}
