import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/demo/demo_analysis_repository.dart';
import '../../core/demo/demo_bill_repository.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/paths.dart';
import '../../core/state/actions.dart';
import 'ai_analysis_loading_screen.dart';
import 'energy_analysis_copy.dart';

/// Scans a demo barcode — a real PLN meter's printed serial, or one made up
/// for a demo — and looks it up in [DemoBillRepository]. The barcode carries
/// no data itself; it is only a key. A match seeds the same bill history and
/// appliance rows a member would type by hand, then goes straight to the
/// real Analisis Energi screen — the lookup is deterministic (unlike OCR),
/// so there is nothing to review — where the real spike check and cost
/// breakdown (`energy_insights.dart`) do the rest; nothing here bypasses
/// that engine. An unrecognised barcode never crashes and never proceeds;
/// it just says so.
class DemoBarcodeScanScreen extends ConsumerStatefulWidget {
  const DemoBarcodeScanScreen({super.key});

  @override
  ConsumerState<DemoBarcodeScanScreen> createState() =>
      _DemoBarcodeScanScreenState();
}

class _DemoBarcodeScanScreenState extends ConsumerState<DemoBarcodeScanScreen> {
  // No `formats` restriction: a real PLN meter sticker prints a linear
  // barcode (e.g. Code 128), while a barcode made for the demo could just as
  // easily be a QR code. Leaving the list empty detects every format
  // mobile_scanner supports.
  final _controller = MobileScannerController();
  bool _busy = false;
  bool _analyzing = false;
  String? _analyzingScenario;
  String? _error;
  // Completer that completes when applyDemoBillPayload finishes.
  // onComplete waits for this so navigation never races ahead of DB writes.
  Completer<void>? _payloadCompleter;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture, AppLocalizations l10n) async {
    if (_busy) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    // Debug logs as required for demo barcode auditing
    debugPrint('Scanned Barcode: $raw');
    debugPrint('[SCAN] Barcode = $raw');

    // Every new detection discards whatever analysis was left over from a
    // previous scan first — otherwise a different barcode (or a stale
    // in-memory value left by a back gesture that skipped the explicit
    // close button) could keep showing the previous scan's result.
    DemoAnalysisRepository.clear();

    final payload = DemoBillRepository.findByBarcode(raw);
    if (payload == null) {
      debugPrint('[SCAN] Barcode unrecognized: $raw');
      final errorMsg = l10n.scanDemoInvalid;
      setState(() => _error = errorMsg);
      if (mounted) {
        showAppSnack(context, errorMsg, error: true);
      }
      return;
    }

    final scenarioName = DemoBillRepository.scenarioNameOf(payload);
    debugPrint('[PAYLOAD] Scenario = $scenarioName');

    // Shown to the member on the loading screen: the localised status
    // title, never the internal English scenario name above (debug/log
    // use only) — otherwise the badge would stay in English regardless of
    // the active locale.
    final displayScenario = payload.analysis != null
        ? demoStatusTitle(payload.analysis!.status, l10n)
        : null;

    DemoAnalysisRepository.current = payload.analysis;

    // Prepare completer BEFORE showing loading screen.
    final completer = Completer<void>();
    _payloadCompleter = completer;

    setState(() {
      _busy = true;
      _analyzing = true;
      _analyzingScenario = displayScenario;
      _error = null;
    });
    await _controller.stop();
    if (!mounted) return;

    // Apply demo payload; signal completer when done so navigation waits.
    await ref.read(actionsProvider).applyDemoBillPayload(payload);
    completer.complete();
  }

  @override
  Widget build(BuildContext context) {
    if (_analyzing) {
      return AnalysisLoadingScreen(
        scenarioName: _analyzingScenario,
        onComplete: () async {
          // Wait for DB writes to finish before navigating so the analysis
          // screen always reads fresh data and never shows stale results.
          await _payloadCompleter?.future;
          if (mounted) {
            // ignore: use_build_context_synchronously
            context.pushReplacement(Paths.energyAnalysis);
          }
        },
      );
    }

    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.scannerDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          l10n.scanDemoTitle,
          style: text.titleLarge?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: (capture) => _onDetect(capture, l10n),
              errorBuilder: (context, error, child) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Text(
                    error.errorDetails?.message ?? error.errorCode.name,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
            // Wide rather than square: a real meter sticker's barcode is a
            // horizontal strip, not a QR square.
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 300,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _error != null
                          ? AppColors.danger
                          : AppColors.accentLeaf,
                      width: 3,
                    ),
                    borderRadius: AppRadius.cardBr,
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.gutter,
              right: AppSpacing.gutter,
              bottom: AppSpacing.xl,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: AppRadius.pillBr,
                  ),
                  child: Text(
                    _busy
                        ? l10n.scanDemoReading
                        : (_error ?? l10n.scanDemoInstruction),
                    textAlign: TextAlign.center,
                    style: text.labelMedium?.copyWith(
                      color: _error != null ? AppColors.danger : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            if (_busy)
              const Center(
                child: CircularProgressIndicator(color: AppColors.accentLeaf),
              ),
          ],
        ),
      ),
    );
  }
}
