import 'dart:async';
import 'package:flutter/material.dart';

/// Full-screen AI Energy Analysis Loading screen displayed after scanning
/// a demo barcode.
///
/// Cycles smoothly through the 5 diagnostic steps over ~2 seconds before
/// completing and invoking [onComplete].
class AiAnalysisLoadingScreen extends StatefulWidget {
  const AiAnalysisLoadingScreen({
    super.key,
    required this.onComplete,
    this.scenarioName,
  });

  final VoidCallback onComplete;
  final String? scenarioName;

  static const List<String> steps = [
    'Membaca data tagihan...',
    'Menganalisis pola penggunaan energi...',
    'Mengidentifikasi sumber biaya terbesar...',
    'Menyusun rekomendasi penghematan...',
    'Analisis selesai',
  ];

  @override
  State<AiAnalysisLoadingScreen> createState() =>
      _AiAnalysisLoadingScreenState();
}

class _AiAnalysisLoadingScreenState extends State<AiAnalysisLoadingScreen>
    with TickerProviderStateMixin {
  static const Color _brandGreen = Color(0xFF0F4E2D);
  static const Color _lightGreen = Color(0xFFEAF6EF);
  static const Color _accentGreen = Color(0xFF2E7D32);

  late final AnimationController _pulseController;
  late final AnimationController _progressController;
  int _currentStep = 0;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..forward();

    // Step duration: 420ms each * 5 steps = 2100ms
    _stepTimer = Timer.periodic(const Duration(milliseconds: 420), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentStep < AiAnalysisLoadingScreen.steps.length - 1) {
        setState(() => _currentStep++);
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) widget.onComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Tag / Scenario (if provided)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _lightGreen,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC8E6D3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: _brandGreen,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.scenarioName != null
                              ? 'AI Engine • ${widget.scenarioName}'
                              : 'AI Energy Engine',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _brandGreen,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Animated Energy Pulse & Scanning Indicator
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outermost ripple ring
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = 1.0 + (_pulseController.value * 0.22);
                          final opacity = (1.0 - (_pulseController.value * 0.7))
                              .clamp(0.0, 1.0);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _brandGreen.withValues(
                                  alpha: 0.12 * opacity,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Inner pulse ring
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = 0.95 + (_pulseController.value * 0.12);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _lightGreen,
                                border: Border.all(
                                  color: const Color(0xFFBFE0CB),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Circular scanning progress ring
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return SizedBox(
                            width: 106,
                            height: 106,
                            child: CircularProgressIndicator(
                              value: _progressController.value,
                              strokeWidth: 3,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                _brandGreen,
                              ),
                              backgroundColor: const Color(0xFFE2EDE6),
                            ),
                          );
                        },
                      ),
                      // Central Core Node with icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _brandGreen,
                          boxShadow: [
                            BoxShadow(
                              color: _brandGreen.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Animated step texts with smooth fade transition
                SizedBox(
                  height: 32,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.25),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      AiAnalysisLoadingScreen.steps[_currentStep],
                      key: ValueKey<int>(_currentStep),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _brandGreen,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  'Mohon tunggu sebentar, AI sedang memproses data tagihan...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5A655F),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // Progress Bar
                Container(
                  width: 220,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5EBE7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  alignment: Alignment.centerLeft,
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        widthFactor: _progressController.value.clamp(0.05, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _accentGreen,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
