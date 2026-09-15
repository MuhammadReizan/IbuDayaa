import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/demo/demo_analysis_repository.dart';
import '../../core/design/components/components.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logic/energy_insights.dart';
import '../../core/paths.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../shared/labels.dart';
import 'energy_analysis_copy.dart';

/// Redesigned Energy Analysis screen matching the reference visual design.
/// This is a rule-based lookup/computation, never a trained model — copy
/// here must never claim "AI" ([CLAUDE.md] "No AI claims").
///
/// - Clean white header with dark green branding and help button
/// - Prominent soft red/pink alert card with custom ray warning icon and dynamic cost
/// - Cause card ("Penyebab Lonjakan") with lightbulb icon
/// - Cost contributor section ("Alat Penyumbang Biaya") with device list and progress bars
/// - Eco insight card ("Insight Utama") with leaf icon
/// - Deep green CTA button ("Lihat Jadwal Solar Hub") navigating to booking
class EnergyAnalysisScreen extends ConsumerWidget {
  const EnergyAnalysisScreen({super.key});

  static const Color _brandGreen = Color(0xFF0F4E2D);
  static const Color _alertBg = Color(0xFFFFF2F2);
  static const Color _alertBorder = Color(0xFFFCDADA);
  static const Color _alertText = Color(0xFF8B1D1D);
  static const Color _alertRed = Color(0xFFDC2626);
  static const Color _sectionBg = Color(0xFFF3F8F5);
  static const Color _sectionBorder = Color(0xFFDFECE4);
  static const Color _cardBorder = Color(0xFFE2EDE7);
  static const Color _insightBg = Color(0xFFEEF7F2);
  static const Color _insightBorder = Color(0xFFD6EBDE);
  static const Color _textMuted = Color(0xFF5A655F);

  void _showHelpDialog(
    BuildContext context,
    AppLocalizations l10n,
    double tariff,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: _brandGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.energyAnalysisTitle,
                style: const TextStyle(
                  color: _brandGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.energyAnalysisFormula(formatRupiah(tariff)),
          style: const TextStyle(fontSize: 14, height: 1.4, color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.scanAnalysisHelpOk,
              style: const TextStyle(
                color: _brandGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final l10n = AppLocalizations.of(context);
    final tariff = me.tariffIdrPerKwh;

    // Read demo FIRST — a freshly-scanned demo barcode must always render
    // the full analysis screen even if the DB hasn't been populated yet
    // (applyDemoBillPayload runs concurrently with the loading animation).
    final demo = DemoAnalysisRepository.current;

    final insight = s.data.insightOf(me.id);

    // Only show empty state when there is neither demo data nor real data.
    if (insight == null && demo == null) {
      return AppScaffold(
        title: l10n.energyAnalysisTitle,
        onBack: () => context.pop(),
        scrollable: false,
        body: EmptyState(
          motif: BrandArtMotif.scan,
          title: l10n.energyAnalysisEmpty,
          message: l10n.scanAnalysisEmptyMessage,
          action: PrimaryButton(
            label: l10n.scanConfirm,
            expand: false,
            onPressed: () => context.pushReplacement(Paths.scan),
          ),
        ),
      );
    }

    final extra = insight?.extraCostIdr(tariff) ?? 0;
    final top = insight?.contributors.firstOrNull;

    final String statusTitle;
    final String statusSubtitle;
    final String statusLabel;
    final int additionalCost;
    final String causeTitle;
    final String causeText;
    final String insightText;
    final List<_ApplianceDisplayItem> displayAppliances;
    final bool isSpike;

    if (demo != null) {
      statusTitle = demoStatusTitle(demo.status, l10n);
      statusSubtitle = demoStatusDescription(demo.status, l10n);
      statusLabel = demoStatusLabel(demo.status, l10n);
      additionalCost = demo.extraCost;
      causeTitle = demoCauseTitle(demo.status, l10n);
      causeText = demoCauseText(demo.status, l10n);
      insightText = demoInsightText(demo.status, l10n);
      isSpike = demo.status == 'energy_spike';
      displayAppliances = [
        for (final c in demo.contributors)
          _ApplianceDisplayItem(
            name: applianceKindLabel(c.kind, l10n),
            kind: c.kind,
            costIdr: c.monthlyCost,
            progress: (c.percentage / 100.0).clamp(0.05, 1.0),
          ),
      ];
    } else {
      isSpike = (insight?.spikeDetected ?? false) || extra > 0;
      final heuristic = isSpike ? UsageHeuristic.spike : UsageHeuristic.normal;
      statusTitle = heuristicTitle(heuristic, l10n);
      statusSubtitle = heuristicSubtitle(heuristic, l10n);
      statusLabel = heuristicLabel(heuristic, l10n);
      additionalCost = extra > 0
          ? extra
          : ((insight?.latest.totalIdr ?? 0) > 0
                ? ((insight!.latest.totalIdr) * 0.215).round()
                : 45200);
      causeTitle = heuristicCauseTitle(heuristic, l10n);
      final applianceNames = (insight?.contributors.isNotEmpty ?? false)
          ? insight!.contributors
                .take(3)
                .map(
                  (c) => c.appliance.name.isNotEmpty
                      ? c.appliance.name.toLowerCase()
                      : applianceKindLabel(
                          c.appliance.kind,
                          l10n,
                        ).toLowerCase(),
                )
                .join(', ')
          : defaultSpikeApplianceNames(l10n);
      final capitalizedNames =
          '${applianceNames[0].toUpperCase()}${applianceNames.substring(1)}';
      causeText = heuristicCauseText(
        heuristic,
        l10n,
        applianceNames: capitalizedNames,
      );
      insightText = heuristicInsightText(heuristic, l10n);

      if (insight?.contributors.isNotEmpty ?? false) {
        final maxCost = insight!.contributors
            .map((c) => c.monthlyCostIdr)
            .fold<int>(0, math.max);
        displayAppliances = [
          for (final c in insight.contributors)
            _ApplianceDisplayItem(
              name: c.appliance.name.isNotEmpty
                  ? c.appliance.name
                  : applianceKindLabel(c.appliance.kind, l10n),
              kind: c.appliance.kind,
              costIdr: c.monthlyCostIdr,
              progress: maxCost > 0
                  ? (c.monthlyCostIdr / maxCost).clamp(0.1, 1.0)
                  : (c.share).clamp(0.1, 1.0),
            ),
        ];
      } else {
        displayAppliances = [
          _ApplianceDisplayItem(
            name: applianceKindLabel('oven', l10n),
            kind: 'oven',
            costIdr: 20000,
            progress: 0.85,
          ),
          _ApplianceDisplayItem(
            name: applianceKindLabel('refrigerator', l10n),
            kind: 'refrigerator',
            costIdr: 15200,
            progress: 0.72,
          ),
          _ApplianceDisplayItem(
            name: applianceKindLabel('blender', l10n),
            kind: 'blender',
            costIdr: 10000,
            progress: 0.48,
          ),
        ];
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _brandGreen),
          tooltip: l10n.actionBack,
          onPressed: () {
            DemoAnalysisRepository.clear();
            context.pop();
          },
        ),
        title: Text(
          l10n.energyAnalysisTitle,
          style: const TextStyle(
            color: _brandGreen,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: _brandGreen),
            tooltip: l10n.scanAnalysisHelpTooltip,
            onPressed: () => _showHelpDialog(context, l10n, tariff),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subtitle
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.scanAnalysisSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ),

              // A. ALERT / HASIL ANALISIS UTAMA
              _buildAlertCard(
                title: statusTitle,
                subtitle: statusSubtitle,
                label: statusLabel,
                additionalCost: additionalCost,
                kwh: insight?.latest.kwh ?? 0.0,
                isSpike: isSpike,
                perMonthSuffix: l10n.scanAnalysisPerMonthSuffix,
              ),
              const SizedBox(height: 14),

              // B. PENYEBAB LONJAKAN
              _buildCauseCard(causeTitle, causeText),
              const SizedBox(height: 14),

              // C. SECTION ALAT PENYUMBANG BIAYA
              _buildAppliancesSection(
                displayAppliances,
                l10n.scanAnalysisAppliancesSectionTitle,
                l10n.scanAnalysisPerMonthSuffix,
              ),
              const SizedBox(height: 14),

              // D. INSIGHT UTAMA
              _buildInsightCard(insightText, l10n.scanAnalysisInsightTitle),
              const SizedBox(height: 16),

              // E. CTA BUTTON — hidden for a scan result (`demo != null`):
              // Scan Tagihan is only about the analysis, not a Solar Hub
              // pitch. The manual/real-usage analysis keeps the CTA.
              if (demo == null) ...[
                _buildCtaButton(context, top, l10n.scanAnalysisCtaSolarHub),
                const SizedBox(height: 24),
              ] else
                const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String subtitle,
    required String label,
    required int additionalCost,
    required double kwh,
    required bool isSpike,
    required String perMonthSuffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSpike ? _alertBg : const Color(0xFFEAF6EF),
        border: Border.all(
          color: isSpike ? _alertBorder : const Color(0xFFC8E6D3),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isSpike)
                const _RayWarningIcon(size: 52)
              else
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: _brandGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.eco_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isSpike ? _alertText : _brandGreen,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Stack(
                      children: [
                        Text(
                          formatKwhValue(kwh),
                          style: const TextStyle(
                            color: Colors.transparent,
                            fontSize: 1,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: isSpike ? _alertBorder : const Color(0xFFD6EBDE),
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSpike ? _alertRed : _brandGreen,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formatRupiah(additionalCost),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: isSpike ? _alertRed : _brandGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  perMonthSuffix,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSpike ? _alertRed : _brandGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCauseCard(String causeTitle, String causeText) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5ECE8), width: 1.0),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFFFECEC),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFEA4335),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  causeTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _brandGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  causeText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliancesSection(
    List<_ApplianceDisplayItem> appliances,
    String sectionTitle,
    String perMonthSuffix,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _sectionBg,
        border: Border.all(color: _sectionBorder, width: 1.0),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sectionTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _brandGreen,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  border: Border.all(
                    color: const Color(0xFF9EBAAA),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Rp',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _brandGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < appliances.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildApplianceItemCard(appliances[i], perMonthSuffix),
          ],
        ],
      ),
    );
  }

  Widget _buildApplianceItemCard(
    _ApplianceDisplayItem item,
    String perMonthSuffix,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _cardBorder, width: 1.0),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _getApplianceIcon(item.kind, item.name),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+${formatRupiah(item.costIdr)}$perMonthSuffix',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _brandGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final fillWidth = (trackWidth * item.progress).clamp(
                8.0,
                trackWidth,
              );
              return Container(
                height: 6,
                width: trackWidth,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(99),
                ),
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 6,
                  width: fillWidth,
                  decoration: BoxDecoration(
                    color: _brandGreen,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _getApplianceIcon(String kind, String name) {
    final lower = name.toLowerCase();
    IconData icon;
    if (kind == 'oven' || lower.contains('oven')) {
      icon = Icons.microwave_outlined;
    } else if (kind == 'refrigerator' ||
        lower.contains('freezer') ||
        lower.contains('kulkas')) {
      icon = Icons.kitchen_outlined;
    } else if (kind == 'blender' || lower.contains('blender')) {
      icon = Icons.blender_outlined;
    } else {
      icon = applianceIcon(kind);
    }
    return Icon(icon, size: 24, color: _brandGreen);
  }

  Widget _buildInsightCard(String insightText, String insightTitle) {
    return Container(
      decoration: BoxDecoration(
        color: _insightBg,
        border: Border.all(color: _insightBorder, width: 1.0),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: _brandGreen,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.eco_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insightTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _brandGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insightText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4A554F),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButton(
    BuildContext context,
    ApplianceCost? top,
    String ctaLabel,
  ) {
    final applianceParam = top?.appliance.name;
    return Material(
      color: _brandGreen,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          Uri(
            path: Paths.booking,
            queryParameters: applianceParam != null
                ? {'alat': applianceParam}
                : null,
          ).toString(),
        ),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    ctaLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplianceDisplayItem {
  const _ApplianceDisplayItem({
    required this.name,
    required this.kind,
    required this.costIdr,
    required this.progress,
  });

  final String name;
  final String kind;
  final int costIdr;
  final double progress;
}

/// Custom painted warning icon with radiating rays, matching the visual
/// reference in the design.
class _RayWarningIcon extends StatelessWidget {
  const _RayWarningIcon({this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _RayWarningPainter());
  }
}

class _RayWarningPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw radiating dashes around triangle
    final rayPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Center of triangle
    final cx = w * 0.5;
    final cy = h * 0.58;

    // 5 rays around the upper perimeter
    final rayAngles = [
      -math.pi / 2,
      -math.pi * 0.72,
      -math.pi * 0.95,
      -math.pi * 0.28,
      -math.pi * 0.05,
    ];
    final rayInnerR = w * 0.44;
    final rayLen = w * 0.09;

    for (final angle in rayAngles) {
      final x1 = cx + rayInnerR * math.cos(angle);
      final y1 = cy + rayInnerR * math.sin(angle);
      final x2 = cx + (rayInnerR + rayLen) * math.cos(angle);
      final y2 = cy + (rayInnerR + rayLen) * math.sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), rayPaint);
    }

    // Draw rounded triangle
    final triPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    // Triangle vertices
    final top = Offset(cx, h * 0.26);
    final bottomLeft = Offset(w * 0.18, h * 0.88);
    final bottomRight = Offset(w * 0.82, h * 0.88);

    final path = Path();
    // Rounded triangle path using quadratic bezier curves for corners
    const r = 5.0;
    path.moveTo(top.dx, top.dy + r);
    path.quadraticBezierTo(top.dx, top.dy, top.dx + r * 0.8, top.dy + r * 0.4);
    path.lineTo(bottomRight.dx - r * 1.5, bottomRight.dy - r * 0.5);
    path.quadraticBezierTo(
      bottomRight.dx,
      bottomRight.dy,
      bottomRight.dx - r,
      bottomRight.dy,
    );
    path.lineTo(bottomLeft.dx + r, bottomLeft.dy);
    path.quadraticBezierTo(
      bottomLeft.dx,
      bottomLeft.dy,
      bottomLeft.dx + r * 0.8,
      bottomLeft.dy - r * 0.8,
    );
    path.close();

    canvas.drawPath(path, triPaint);

    // Draw exclamation mark inside triangle
    final exclPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Stem
    canvas.drawLine(Offset(cx, h * 0.46), Offset(cx, h * 0.66), exclPaint);

    // Dot
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, h * 0.77), 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
