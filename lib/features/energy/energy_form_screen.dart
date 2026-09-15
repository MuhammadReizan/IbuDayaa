import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/row.dart';
import '../../core/demo/demo_analysis_repository.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logic/energy_insights.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../shared/inputs.dart';
import '../shared/labels.dart';
import 'energy_analysis_copy.dart';

class EnergyFormScreen extends ConsumerStatefulWidget {
  const EnergyFormScreen({super.key, this.draft});

  final EnergyDraft? draft;

  @override
  ConsumerState<EnergyFormScreen> createState() => _EnergyFormScreenState();
}

class _EnergyFormScreenState extends ConsumerState<EnergyFormScreen> {
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

  final _form = GlobalKey<FormState>();
  late EnergyKind _kind = widget.draft?.kind ?? EnergyKind.postpaid;
  late DateTime _month;
  late final _kwh = TextEditingController(
    text: widget.draft?.kwh == null ? '' : decimalText(widget.draft!.kwh!),
  );
  late final _total = TextEditingController(
    text: widget.draft?.totalIdr == null
        ? ''
        : thousands(widget.draft!.totalIdr!),
  );
  late final _customer = TextEditingController(
    text: widget.draft?.customerId ?? '',
  );
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    final m = widget.draft?.periodMonth;
    final earliest = DateTime(now.year, now.month - 11);
    _month = m == null || m.isBefore(earliest) || m.isAfter(monthOf(now))
        ? monthOf(now)
        : monthOf(m);
  }

  @override
  void dispose() {
    _kwh.dispose();
    _total.dispose();
    _customer.dispose();
    super.dispose();
  }

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

  Future<void> _save() async {
    final fromScan = widget.draft?.source == RecordSource.scan;
    if (!fromScan && !_form.currentState!.validate()) {
      return;
    }
    setState(() => _busy = true);
    final s = ref.read(appStateProvider);
    final tariff = s.me?.tariffIdrPerKwh ?? 1444.7;
    final kwhVal = fromScan
        ? (widget.draft?.kwh ?? parseDecimal(_kwh.text) ?? 150.0)
        : (parseDecimal(_kwh.text) ?? 0.0);
    final totalVal = fromScan
        ? (widget.draft?.totalIdr ??
              parseDigits(_total.text) ??
              (kwhVal * tariff).round())
        : (parseDigits(_total.text) ?? 0);

    final ok = await runAction(
      context,
      () => ref
          .read(actionsProvider)
          .saveRecord(
            kind: widget.draft?.kind ?? _kind,
            periodMonth: widget.draft?.periodMonth ?? _month,
            kwh: kwhVal,
            totalIdr: totalVal,
            customerId:
                widget.draft?.customerId ??
                (_customer.text.trim().isEmpty ? null : _customer.text.trim()),
            photoPath: widget.draft?.photoPath,
            source: widget.draft?.source ?? RecordSource.manual,
          ),
      success: AppLocalizations.of(context).energySaveSuccess,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) context.pushReplacement(Paths.energyAnalysis);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final draft = widget.draft;
    final now = ref.read(clockProvider)();
    final fromScan = draft?.source == RecordSource.scan;
    final tariff = me.tariffIdrPerKwh;

    final kwh = parseDecimal(_kwh.text);
    final total = parseDigits(_total.text);
    final perKwh = kwh != null && kwh > 0 && total != null ? total / kwh : null;
    final suspicious =
        perKwh != null &&
        (perKwh < me.tariffIdrPerKwh * 0.6 ||
            perKwh > me.tariffIdrPerKwh * 1.6);
    final replacing =
        _kind == EnergyKind.postpaid &&
        s.data.energyRecords.any(
          (r) =>
              r.userId == me.id &&
              r.kind == EnergyKind.postpaid &&
              sameMonth(r.periodMonth, _month),
        );

    // Dynamic analysis calculations based on scanned kwh & member history
    final userRecords = s.data.recordsOf(me.id);
    final userMonths = monthlyUsage(userRecords);
    final avgKwh = userMonths.isEmpty
        ? 0.0
        : userMonths.take(3).fold<double>(0, (sum, m) => sum + m.kwh) /
              math.min(userMonths.length, 3);

    final currentKwh = kwh ?? draft?.kwh ?? 0.0;
    final currentTotal = total ?? draft?.totalIdr ?? 0;

    final demo = DemoAnalysisRepository.current;

    final String statusTitle;
    final String statusSubtitle;
    final String statusLabel;
    final int displayCost;
    final String causeTitle;
    final String causeText;
    final String insightText;
    final bool isSpike;

    String spikeApplianceNames() {
      final owned = s.data.appliancesOf(me.id);
      final names = owned.isNotEmpty
          ? owned
                .take(3)
                .map(
                  (a) => a.name.isNotEmpty
                      ? a.name.toLowerCase()
                      : applianceKindLabel(a.kind, l10n).toLowerCase(),
                )
                .join(', ')
          : defaultSpikeApplianceNames(l10n);
      return '${names[0].toUpperCase()}${names.substring(1)}';
    }

    if (demo != null) {
      statusTitle = demoStatusTitle(demo.status, l10n);
      statusSubtitle = demoStatusDescription(demo.status, l10n);
      statusLabel = demoStatusLabel(demo.status, l10n);
      displayCost = demo.extraCost;
      causeTitle = demoCauseTitle(demo.status, l10n);
      causeText = demoCauseText(demo.status, l10n);
      insightText = demoInsightText(demo.status, l10n);
      isSpike = demo.status == 'energy_spike';
    } else if (avgKwh > 0 && currentKwh > avgKwh * 1.12) {
      statusTitle = heuristicTitle(UsageHeuristic.spike, l10n);
      statusSubtitle = heuristicSubtitle(UsageHeuristic.spike, l10n);
      statusLabel = heuristicLabel(UsageHeuristic.spike, l10n);
      final diff = ((currentKwh - avgKwh) * tariff).round();
      displayCost = diff > 0 ? diff : 45200;
      causeTitle = heuristicCauseTitle(UsageHeuristic.spike, l10n);
      causeText = heuristicCauseText(
        UsageHeuristic.spike,
        l10n,
        applianceNames: spikeApplianceNames(),
      );
      insightText = heuristicInsightText(UsageHeuristic.spike, l10n);
      isSpike = true;
    } else if (avgKwh > 0 && currentKwh < avgKwh * 0.90) {
      statusTitle = heuristicTitle(UsageHeuristic.savings, l10n);
      statusSubtitle = heuristicSubtitle(UsageHeuristic.savings, l10n);
      statusLabel = heuristicLabel(UsageHeuristic.savings, l10n);
      final diff = ((avgKwh - currentKwh) * tariff).round();
      displayCost = diff > 0 ? diff : 32000;
      causeTitle = heuristicCauseTitle(UsageHeuristic.savings, l10n);
      causeText = heuristicCauseText(UsageHeuristic.savings, l10n);
      insightText = heuristicInsightText(UsageHeuristic.savings, l10n);
      isSpike = false;
    } else if (avgKwh > 0) {
      statusTitle = heuristicTitle(UsageHeuristic.normal, l10n);
      statusSubtitle = heuristicSubtitle(UsageHeuristic.normal, l10n);
      statusLabel = heuristicLabel(UsageHeuristic.normal, l10n);
      displayCost = currentTotal > 0
          ? currentTotal
          : (currentKwh * tariff).round();
      causeTitle = heuristicCauseTitle(UsageHeuristic.normal, l10n);
      causeText = heuristicCauseText(UsageHeuristic.normal, l10n);
      insightText = heuristicInsightText(UsageHeuristic.normal, l10n);
      isSpike = false;
    } else {
      statusTitle = heuristicTitle(UsageHeuristic.spike, l10n);
      statusSubtitle = heuristicSubtitle(UsageHeuristic.spike, l10n);
      statusLabel = heuristicLabel(UsageHeuristic.spike, l10n);
      displayCost = currentTotal > 0
          ? (currentTotal * 0.215).round()
          : (currentKwh > 0 ? (currentKwh * 0.25 * tariff).round() : 45200);
      causeTitle = heuristicCauseTitle(UsageHeuristic.spike, l10n);
      causeText = heuristicCauseText(
        UsageHeuristic.spike,
        l10n,
        applianceNames: spikeApplianceNames(),
      );
      insightText = heuristicInsightText(UsageHeuristic.spike, l10n);
      isSpike = true;
    }

    final appliances = s.data.appliancesOf(me.id);
    final List<_ApplianceDisplayItem> displayAppliances;
    if (demo != null) {
      displayAppliances = [
        for (final c in demo.contributors)
          _ApplianceDisplayItem(
            name: applianceKindLabel(c.kind, l10n),
            kind: c.kind,
            costIdr: c.monthlyCost,
            progress: (c.percentage / 100.0).clamp(0.05, 1.0),
          ),
      ];
    } else if (appliances.isNotEmpty) {
      final maxCost = appliances
          .map((a) => a.monthlyCostIdr(tariff))
          .fold<int>(0, math.max);
      displayAppliances = [
        for (final a in appliances)
          _ApplianceDisplayItem(
            name: a.name.isNotEmpty ? a.name : applianceKindLabel(a.kind, l10n),
            kind: a.kind,
            costIdr: a.monthlyCostIdr(tariff),
            progress: maxCost > 0
                ? (a.monthlyCostIdr(tariff) / maxCost).clamp(0.1, 1.0)
                : 0.5,
          ),
      ]..sort((a, b) => b.costIdr.compareTo(a.costIdr));
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
          fromScan ? l10n.energyAnalysisTitle : l10n.energyFormTitle,
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: PrimaryButton(
            label: l10n.actionSave,
            loading: _busy,
            onPressed: _save,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Form(
            key: _form,
            onChanged: () => setState(() {}),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (fromScan) ...[
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

                  // SECTION 1: ANALYSIS SUMMARY
                  _buildAlertCard(
                    statusTitle: statusTitle,
                    statusSubtitle: statusSubtitle,
                    statusLabel: statusLabel,
                    amountIdr: displayCost,
                    isSpike: isSpike,
                    perMonthSuffix: l10n.scanAnalysisPerMonthSuffix,
                  ),
                  const SizedBox(height: 14),

                  // SECTION 2: PENYEBAB UTAMA
                  _buildCauseCard(causeText, causeTitle),
                  const SizedBox(height: 14),

                  // SECTION 3: ALAT PENYUMBANG BIAYA
                  _buildAppliancesSection(
                    displayAppliances,
                    l10n.scanAnalysisAppliancesSectionTitle,
                    l10n.scanAnalysisPerMonthSuffix,
                  ),
                  const SizedBox(height: 14),

                  // SECTION 4: INSIGHT UTAMA
                  _buildInsightCard(insightText, l10n.scanAnalysisInsightTitle),
                  // No Solar Hub CTA here: this screen is the result of
                  // Scan Tagihan, which is only about the analysis.
                  const SizedBox(height: 18),
                ],

                if (!fromScan) ...[
                  _buildRawFormFields(
                    context: context,
                    now: now,
                    text: text,
                    replacing: replacing,
                    perKwh: perKwh,
                    suspicious: suspicious,
                    tariff: tariff,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required String statusTitle,
    required String statusSubtitle,
    required String statusLabel,
    required int amountIdr,
    required String perMonthSuffix,
    bool isSpike = true,
  }) {
    final bg = isSpike ? _alertBg : const Color(0xFFEAF6EF);
    final border = isSpike ? _alertBorder : const Color(0xFFC8E6D3);
    final textTitleColor = isSpike ? _alertText : _brandGreen;
    final amountColor = isSpike ? _alertRed : _brandGreen;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1.0),
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
                      Icons.check_circle_rounded,
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
                      statusTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textTitleColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusSubtitle,
                      style: const TextStyle(fontSize: 13, color: _textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: border, thickness: 1, height: 1),
          const SizedBox(height: 14),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: amountColor,
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
                  formatRupiah(amountIdr),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: amountColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  perMonthSuffix,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCauseCard(
    String causeText, [
    String causeTitle = 'Penyebab Lonjakan',
  ]) {
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '+${formatRupiah(item.costIdr)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _brandGreen,
                      ),
                    ),
                    Text(
                      perMonthSuffix,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
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

  Widget _buildRawFormFields({
    required BuildContext context,
    required DateTime now,
    required TextTheme text,
    required bool replacing,
    required double? perKwh,
    required bool suspicious,
    required double tariff,
  }) {
    final l10n = AppLocalizations.of(context);
    final isPostpaid = _kind == EnergyKind.postpaid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<EnergyKind>(
          segments: [
            ButtonSegment(
              value: EnergyKind.postpaid,
              label: Text(l10n.energyFormKindBill),
              icon: const Icon(Icons.receipt_long_rounded),
            ),
            ButtonSegment(
              value: EnergyKind.token,
              label: Text(l10n.energyFormKindToken),
              icon: const Icon(Icons.bolt_rounded),
            ),
          ],
          selected: {_kind},
          showSelectedIcon: false,
          onSelectionChanged: (v) => setState(() => _kind = v.first),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isPostpaid
              ? l10n.energyFormKindHelpBill
              : l10n.energyFormKindHelpToken,
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          isPostpaid ? l10n.energyFormMonth : l10n.energyFormMonthToken,
          style: text.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<DateTime>(
          value: _month,
          items: [
            for (int i = 0; i < 12; i++)
              DropdownMenuItem(
                value: DateTime(now.year, now.month - i),
                child: Text(monthYearLabel(DateTime(now.year, now.month - i))),
              ),
          ],
          onChanged: (v) => setState(() => _month = v ?? _month),
        ),
        if (replacing) ...[
          const SizedBox(height: AppSpacing.sm),
          InfoBanner(
            tone: InfoTone.warning,
            message: l10n.energyFormReplaceWarning,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: isPostpaid
              ? l10n.energyFormKwhLabelBill
              : l10n.energyFormKwhLabelToken,
          controller: _kwh,
          hint: l10n.energyFormKwhHint,
          suffixText: 'kWh',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [decimalInput, LengthLimitingTextInputFormatter(8)],
          helper: isPostpaid
              ? l10n.energyFormKwhHelpBill
              : l10n.energyFormKwhHelpToken,
          validator: (v) {
            final x = parseDecimal(v ?? '');
            if (x == null || x <= 0) return l10n.energyFormKwhValidatorEmpty;
            if (x > 20000) return l10n.energyFormKwhValidatorTooLarge;
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: isPostpaid
              ? l10n.energyFormBillLabelBill
              : l10n.energyFormBillLabelToken,
          controller: _total,
          hint: l10n.energyFormBillHint,
          prefixText: 'Rp ',
          keyboardType: TextInputType.number,
          inputFormatters: [
            ThousandsFormatter(),
            LengthLimitingTextInputFormatter(13),
          ],
          validator: (v) {
            final x = parseDigits(v ?? '');
            if (x == null || x < 1000) return l10n.energyFormBillValidator;
            return null;
          },
        ),
        if (isPostpaid) ...[
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: l10n.energyFormCustomerIdLabel,
            controller: _customer,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
          ),
        ],
        if (perKwh != null) ...[
          const SizedBox(height: AppSpacing.lg),
          InfoBanner(
            tone: suspicious ? InfoTone.warning : InfoTone.success,
            title: l10n.energyFormPerKwhTitle(formatRupiah(perKwh)),
            message: suspicious
                ? l10n.energyFormPerKwhSuspicious(formatRupiah(tariff))
                : l10n.energyFormPerKwhOk(formatRupiah(tariff)),
          ),
        ],
      ],
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

    final rayPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = w * 0.5;
    final cy = h * 0.58;

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

    final triPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    final top = Offset(cx, h * 0.26);
    final bottomLeft = Offset(w * 0.18, h * 0.88);
    final bottomRight = Offset(w * 0.82, h * 0.88);

    final path = Path();
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

    final exclPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(cx, h * 0.46), Offset(cx, h * 0.66), exclPaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, h * 0.77), 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
