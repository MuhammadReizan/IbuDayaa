/// A member's "Laporan Kredit Energi": the score, why it is what it is, and
/// the energy and community record behind it, in a form she can hand to a
/// lender she chooses. It restates data the app already holds — it adds no new
/// judgement, and says plainly that it is neither AI nor a loan decision.
library;

import 'package:flutter/foundation.dart';

import '../../features/credit_score/domain/credit_scoring_engine.dart';
import '../db/row.dart';
import '../format/format.dart';
import '../models/models.dart';
import 'credit_signals.dart';
import 'energy_insights.dart';

@immutable
class CreditReport {
  const CreditReport({
    required this.memberName,
    required this.businessName,
    required this.cooperativeName,
    required this.generatedAt,
    required this.score,
    required this.minScore,
    required this.months,
    required this.sessions8w,
    required this.kwh8w,
    required this.appliances,
    required this.quotaGiven,
    required this.quotaReceived,
    required this.duesConfirmed,
    required this.installmentsDue,
    required this.installmentsOnTime,
  });

  final String memberName;
  final String businessName;
  final String cooperativeName;
  final DateTime generatedAt;
  final CreditScore score;
  final int minScore;

  /// Newest first, at most six.
  final List<MonthlyUsage> months;
  final int sessions8w;
  final double kwh8w;
  final int appliances;
  final int quotaGiven;
  final int quotaReceived;
  final int duesConfirmed;
  final int installmentsDue;
  final int installmentsOnTime;

  bool get loanReady => score.score >= minScore;

  /// Plain text a member can paste into a message to a lender.
  String toPlainText() {
    final b = StringBuffer()
      ..writeln('LAPORAN KREDIT ENERGI - IbuDaya')
      ..writeln('Nama: $memberName')
      ..writeln('Usaha: $businessName')
      ..writeln('Koperasi: $cooperativeName')
      ..writeln('Dibuat: ${formatShortDate(generatedAt)} ${generatedAt.year}')
      ..writeln()
      ..writeln(
        'Skor: ${score.score}/100 (${score.band.label})'
        '${loanReady ? ' - memenuhi batas pinjam koperasi ($minScore)' : ' - belum memenuhi batas pinjam koperasi ($minScore)'}',
      )
      ..writeln('Rincian skor:');
    for (final f in score.factors) {
      b.writeln('- ${f.label}: ${f.points}/${f.maxPoints}');
    }
    b
      ..writeln()
      ..writeln('Pemakaian Solar Hub per bulan:');
    if (months.isEmpty) {
      b.writeln('- (belum ada)');
    }
    for (final m in months) {
      b.writeln('- ${monthYearLabel(m.month)}: ${formatKwh(m.kwh)}');
    }
    b
      ..writeln(
        'Aktivitas 8 minggu terakhir: $sessions8w sesi, ${formatKwh(kwh8w)}; '
        'alat usaha terdaftar: $appliances',
      )
      ..writeln(
        'Berbagi kuota: dibagikan $quotaGiven kali, diterima $quotaReceived kali',
      )
      ..writeln('Iuran arisan terkonfirmasi: $duesConfirmed')
      ..writeln(
        installmentsDue == 0
            ? 'Cicilan pinjaman: belum ada yang jatuh tempo'
            : 'Cicilan tepat waktu: $installmentsOnTime dari $installmentsDue yang jatuh tempo',
      )
      ..writeln()
      ..writeln(
        'Catatan: skor dihitung dengan aturan tetap yang dapat diperiksa '
        '(bukan model AI). Angka kWh adalah estimasi perangkat lunak '
        '(daya alat x jam slot), bukan pembacaan sensor. Laporan ini bukan '
        'keputusan pinjaman; keputusan ada pada pemberi pinjaman.',
      );
    return b.toString();
  }
}

/// Builds the report from what the score itself was computed from, so the
/// numbers can never disagree with the score screen.
CreditReport buildCreditReport({
  required Profile member,
  required String cooperativeName,
  required CreditContext context,
  required CreditScore score,
  required int minScore,
}) {
  final c = context;
  final cutoff = c.now.subtract(const Duration(days: 56));
  final recent = c.bookings.where(
    (b) =>
        b.userId == c.userId &&
        b.status == BookingStatus.completed &&
        b.bookingDate.isAfter(cutoff),
  );
  final today = dayOf(c.now);
  final due = c.installments.where((i) => !i.dueDate.isAfter(today)).toList();
  final quotaDone = c.offers.where((o) => o.status == QuotaStatus.completed);
  return CreditReport(
    memberName: member.fullName,
    businessName: member.businessName,
    cooperativeName: cooperativeName,
    generatedAt: c.now,
    score: score,
    minScore: minScore,
    months: monthlyUsage(c.records).take(6).toList(),
    sessions8w: recent.length,
    kwh8w: recent.fold<double>(0, (s, b) => s + b.estKwh),
    appliances: c.appliances.length,
    quotaGiven: quotaDone.where((o) => o.giverId == c.userId).length,
    quotaReceived: quotaDone.where((o) => o.receiverId == c.userId).length,
    duesConfirmed: c.payments
        .where(
          (p) =>
              p.type == PaymentType.contribution &&
              p.status == PaymentStatus.confirmed,
        )
        .length,
    installmentsDue: due.length,
    installmentsOnTime: due.where((i) => i.paidOnTime).length,
  );
}
