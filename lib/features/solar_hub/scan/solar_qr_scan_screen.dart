import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/solar_demo/solar_panel_model.dart';
import '../../../core/solar_demo/solar_panel_repository.dart';
import '../analysis/solar_analysis_loading_screen.dart';

/// Layar scanner QR untuk fitur Scan QR Solar Panel (Demo Mode).
///
/// Menggunakan kamera fisik perangkat. Deteksi dilakukan melalui
/// [MobileScannerController.barcodes] stream (recommended approach di
/// mobile_scanner v6) agar lebih reliable dibanding onDetect callback.
///
/// QR yang terbaca dicocokkan ke [SolarPanelRepository]; jika tidak dikenali
/// muncul snackbar tanpa crash.
class SolarQrScanScreen extends StatefulWidget {
  const SolarQrScanScreen({super.key});

  @override
  State<SolarQrScanScreen> createState() => _SolarQrScanScreenState();
}

class _SolarQrScanScreenState extends State<SolarQrScanScreen> {
  final _controller = MobileScannerController(
    // DetectionSpeed.normal: re-fires setiap detectionTimeoutMs (250ms default),
    // cocok untuk QR statis yang ditahan di depan kamera.
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 250,
    formats: const [BarcodeFormat.qrCode],
  );

  /// Subscription ke stream barcode — recommended approach di v6.
  StreamSubscription<BarcodeCapture>? _barcodeSubscription;

  bool _busy = false;

  /// Data panel yang berhasil diidentifikasi; null selama belum ada QR valid.
  SolarPanelData? _panelData;

  @override
  void initState() {
    super.initState();
    // Dengarkan stream langsung dari controller — lebih reliable daripada
    // onDetect callback di mobile_scanner v6.
    _barcodeSubscription = _controller.barcodes.listen(_handleCapture);
  }

  @override
  void dispose() {
    _barcodeSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleCapture(BarcodeCapture capture) {
    if (_busy || !mounted) return;

    for (final barcode in capture.barcodes) {
      // rawValue adalah primary field; displayValue sebagai fallback.
      final raw = barcode.rawValue ?? barcode.displayValue;
      if (raw == null || raw.trim().isEmpty) continue;

      // Log 1: raw value dari QR
      debugPrint('[SOLAR-SCAN] Raw QR: $raw');
      _processQr(raw);
      return; // proses barcode pertama yang valid saja
    }
  }

  Future<void> _processQr(String raw) async {
    if (_busy || !mounted) return;

    final data = SolarPanelRepository.findByQr(raw);

    if (data == null) {
      debugPrint('[SOLAR-SCAN] Panel ID: NOT FOUND for raw=$raw');
      if (mounted) {
        showAppSnack(context, 'QR Solar Panel tidak dikenali.', error: true);
      }
      return;
    }

    // Log 2 & 3: panel ID dan payload yang berhasil dimuat
    debugPrint('[SOLAR-SCAN] Panel ID: ${data.panelId}');
    debugPrint(
      '[SOLAR-SCAN] Payload Loaded: ${data.panelId} | ${data.location} | '
      'status=${data.status.name} | saving=${data.monthlySaving} | '
      'roi=${data.roiYears} | rec=${data.recommendation}',
    );

    // Cancel subscription sebelum stop agar tidak ada event yang masuk lagi.
    await _barcodeSubscription?.cancel();
    _barcodeSubscription = null;

    setState(() {
      _busy = true;
      _panelData = data;
    });

    await _controller.stop();
  }

  @override
  Widget build(BuildContext context) {
    // Setelah QR valid terbaca → tampilkan loading screen
    final panelData = _panelData;
    if (panelData != null) {
      return SolarAnalysisLoadingScreen(panelData: panelData);
    }

    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.scannerDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Scan QR Solar Panel',
          style: text.titleLarge?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Live camera viewfinder
            MobileScanner(
              controller: _controller,
              // onDetect juga dipasang sebagai safety-net fallback.
              onDetect: _handleCapture,
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

            // Animated corner-bracket viewfinder (persegi untuk QR)
            const IgnorePointer(child: Center(child: _ScanFrame())),

            // Petunjuk / status di bagian bawah
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
                    _busy
                        ? 'Membaca QR...'
                        : 'Arahkan kamera ke QR Code pada solar panel',
                    textAlign: TextAlign.center,
                    style: text.labelMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),

            // Loading spinner saat QR sedang diproses
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

// ---------------------------------------------------------------------------
// Animated corner-bracket frame
// ---------------------------------------------------------------------------

/// Frame dengan animasi pulse pada 4 sudut — gaya khas viewfinder IbuDaya.
class _ScanFrame extends StatefulWidget {
  const _ScanFrame();

  @override
  State<_ScanFrame> createState() => _ScanFrameState();
}

class _ScanFrameState extends State<_ScanFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.55,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: SizedBox(
          width: 260,
          height: 260,
          child: CustomPaint(
            painter: _CornerFramePainter(color: AppColors.accentLeaf),
          ),
        ),
      ),
    );
  }
}

/// Melukis 4 sudut (corner brackets) tanpa fill — viewfinder QR.
class _CornerFramePainter extends CustomPainter {
  const _CornerFramePainter({required this.color});
  final Color color;

  static const double _len = 30.0;
  static const double _strokeWidth = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, _len)
        ..lineTo(0, 0)
        ..lineTo(_len, 0),
      paint,
    );
    // top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - _len, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, _len),
      paint,
    );
    // bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - _len)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - _len, size.height),
      paint,
    );
    // bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(_len, size.height)
        ..lineTo(0, size.height)
        ..lineTo(0, size.height - _len),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerFramePainter old) => old.color != color;
}
