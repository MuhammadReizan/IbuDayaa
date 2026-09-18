import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/db/row.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/hub_qr.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/paths.dart';
import '../../../core/state/actions.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/selectors.dart';

/// Scans the Solar Hub's QR code and sends an admin a request to verify the
/// member is using the hub now. Approval, not the scan, is what lets the
/// session count — the app never claims the connection is live on its own,
/// matching the "people decide" honesty rule the app already applies to loans.
///
/// There is no appliance picker: the hub supplies whatever the member has
/// registered (Alat Usaha), each within her own capacity allocation, so the
/// request covers all of them. While waiting the member can leave and use the
/// rest of the app; reopening this screen shows the request's live status.
class HubConnectScanScreen extends ConsumerStatefulWidget {
  const HubConnectScanScreen({super.key});

  @override
  ConsumerState<HubConnectScanScreen> createState() =>
      _HubConnectScanScreenState();
}

class _HubConnectScanScreenState extends ConsumerState<HubConnectScanScreen> {
  MobileScannerController? _controller;
  StreamSubscription<BarcodeCapture>? _subscription;
  bool _sending = false;

  /// After a finished request the member can start a new one; until then the
  /// latest recent request is shown instead of the scanner, so its status
  /// survives leaving the screen or signing out and back in.
  bool _scanAgain = false;

  @override
  void initState() {
    super.initState();
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 250,
      formats: const [BarcodeFormat.qrCode],
    );
    _controller = controller;
    _subscription = controller.barcodes.listen(_handleCapture);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _handleCapture(BarcodeCapture capture) {
    if (_sending || !mounted) return;
    final s = ref.read(appStateProvider);
    final open = s.data.latestHubRequestOf(s.me!.id, ref.read(clockProvider)());
    if (open != null && !_scanAgain) return;

    for (final barcode in capture.barcodes) {
      final raw = (barcode.rawValue ?? barcode.displayValue)?.trim();
      if (raw == null || raw.isEmpty) continue;
      if (raw.toUpperCase() != kSolarHubQr.toUpperCase()) {
        showAppSnack(
          context,
          AppLocalizations.of(context).hubConnectWrongCode,
          error: true,
        );
        continue;
      }
      _send(raw);
      return;
    }
  }

  Future<void> _send(String scannedCode) async {
    final s = ref.read(appStateProvider);
    final appliances = s.data.appliancesOf(s.me!.id);
    if (appliances.isEmpty) return;
    final now = ref.read(clockProvider)();
    final slot = s.data
        .availabilityOn(dayOf(now))
        .where((a) => now.hour >= a.slot.startHour && now.hour < a.slot.endHour)
        .firstOrNull;
    // Off hours: the repository explains the hub's opening hours.
    final hours = slot?.slot.hours ?? 1;
    final estKwh =
        appliances.fold<double>(0, (sum, a) => sum + a.watts) / 1000 * hours;

    setState(() => _sending = true);
    final ok = await runAction(
      context,
      () => ref
          .read(actionsProvider)
          .requestConnection(
            scannedCode: scannedCode,
            applianceName: appliances.map((a) => a.name).join(', '),
            estKwh: estKwh,
            loadKw:
                appliances.fold<double>(0, (sum, a) => sum + a.watts) / 1000,
          ),
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) _scanAgain = false;
    });
    if (ok) _controller?.stop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();

    if (s.data.appliancesOf(me.id).isEmpty) {
      return AppScaffold(
        title: l10n.hubConnectTitle,
        onBack: () => context.pop(),
        scrollable: false,
        body: EmptyState(
          motif: BrandArtMotif.solar,
          title: l10n.appliancesEmpty,
          message: l10n.appliancesEmptyMessage,
          action: PrimaryButton(
            label: l10n.appliancesAdd,
            expand: false,
            onPressed: () => context.push(Paths.applianceEdit),
          ),
        ),
      );
    }

    final request = _scanAgain
        ? null
        : s.data.latestHubRequestOf(me.id, ref.read(clockProvider)());
    if (request != null) return _status(l10n, request);
    return _scanner(l10n);
  }

  Widget _status(AppLocalizations l10n, HubBooking request) {
    final (title, message, icon) = switch (request.status) {
      BookingStatus.booked => (
        l10n.hubConnectApprovedTitle,
        l10n.hubConnectApprovedMessage,
        Icons.check_rounded,
      ),
      BookingStatus.completed => (
        l10n.hubConnectDoneTitle,
        l10n.hubConnectDoneMessage,
        Icons.bolt_rounded,
      ),
      BookingStatus.cancelled => (
        l10n.hubConnectRejectedTitle,
        l10n.hubConnectRejectedMessage,
        Icons.close_rounded,
      ),
      BookingStatus.pendingVerification => (
        l10n.hubConnectSentTitle,
        l10n.hubConnectSentMessage,
        Icons.hourglass_top_rounded,
      ),
    };
    final finished = request.status != BookingStatus.pendingVerification;
    return SuccessPanel(
      title: title,
      message: message,
      icon: icon,
      primaryLabel: l10n.hubConnectBrowse,
      onPrimary: () => context.pop(),
      secondaryLabel: finished
          ? l10n.hubConnectScanAgain
          : l10n.solarMyBookings,
      onSecondary: finished
          ? () {
              setState(() => _scanAgain = true);
              _controller?.start();
            }
          : () => context.pushReplacement(Paths.bookings),
    );
  }

  Widget _scanner(AppLocalizations l10n) {
    final controller = _controller;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.scannerDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          l10n.hubConnectTitle,
          style: text.titleLarge?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          tooltip: l10n.actionBack,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (controller != null)
              MobileScanner(controller: controller, onDetect: _handleCapture),
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
                    color: Colors.black.withValues(alpha: 0.50),
                    borderRadius: AppRadius.pillBr,
                  ),
                  child: Text(
                    _sending
                        ? l10n.hubConnectSending
                        : l10n.hubConnectInstruction,
                    textAlign: TextAlign.center,
                    style: text.labelMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
