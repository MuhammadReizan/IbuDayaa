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
class RuleBasedCreditScoringEngine implements CreditScoringEngine {
  const RuleBasedCreditScoringEngine();

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

  static const Map<CreditCategory, String> _labelsEn = {
    CreditCategory.energyUsage: 'Energy usage consistency',
    CreditCategory.paymentHistory: 'Payment history',
    CreditCategory.businessActivity: 'Business activity',
    CreditCategory.communityParticipation: 'Community participation',
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
            labelEn: _labelsEn[cat],
            reasonEn: _reasonEn(cat, direction),
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
      eligibilityLabelEn: score >= 65
          ? 'Eligible to view the financing simulation'
          : 'The score needs to improve to access the financing simulation',
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

  /// English twin of [_reason]; keep the two in step.
  static String _reasonEn(CreditCategory cat, FactorDirection dir) {
    return switch (cat) {
      CreditCategory.energyUsage =>
        dir == FactorDirection.positive
            ? 'Your energy use is consistent — a sign of good power management.'
            : dir == FactorDirection.neutral
            ? 'The consistency of your energy use can still improve.'
            : 'Your energy use was not consistent in this period.',
      CreditCategory.paymentHistory =>
        dir == FactorDirection.positive
            ? 'On-time arisan payments raise your score.'
            : dir == FactorDirection.neutral
            ? 'Some arisan payments were not recorded on time.'
            : 'Late payments are affecting your score.',
      CreditCategory.businessActivity =>
        dir == FactorDirection.positive
            ? 'Your business appliances are used often and regularly at the Solar Hub (number of sessions, kWh and weekly regularity).'
            : dir == FactorDirection.neutral
            ? 'Solar Hub use is adequate; more frequent, regular weekly use will raise the score.'
            : 'Solar Hub use has been low over the last 8 weeks.',
      CreditCategory.communityParticipation =>
        dir == FactorDirection.positive
            ? 'Joining the digital arisan and regularly sharing quota through Quota Swap strengthens your profile.'
            : dir == FactorDirection.neutral
            ? 'Sharing quota through Quota Swap can raise your community participation.'
            : 'Community participation has been minimal in this period.',
    };
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
            ? 'Alat usaha sering dan rutin dipakai di Solar Hub (jumlah sesi, kWh, dan keteraturan mingguan).'
            : dir == FactorDirection.neutral
            ? 'Pemakaian Solar Hub cukup; lebih sering dan rutin tiap minggu akan menaikkan skor.'
            : 'Pemakaian Solar Hub masih sedikit dalam 8 minggu terakhir.',
      CreditCategory.communityParticipation =>
        dir == FactorDirection.positive
            ? 'Ikut arisan digital dan rutin berbagi kuota lewat Tukar Kuota memperkuat profil Anda.'
            : dir == FactorDirection.neutral
            ? 'Berbagi kuota lewat Tukar Kuota bisa menaikkan partisipasi komunitas Anda.'
            : 'Partisipasi komunitas masih minim dalam periode ini.',
    };
  }
}
