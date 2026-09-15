import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/paths.dart';
import '../../../core/solar_demo/solar_panel_model.dart';
import 'solar_panel_result_screen.dart';

/// Layar loading analisis solar panel yang tampil 2–3 detik setelah QR berhasil
/// dipindai, sebelum berpindah ke [SolarPanelResultScreen].
///
/// Menampilkan:
/// - Animasi pulse + scanning ring (identik pola AiAnalysisLoadingScreen)
/// - Daftar 5 tahapan analisis yang berpindah satu-satu
/// - Progress bar linear
///
/// Jika [panelData] null (seharusnya tidak terjadi dalam flow normal),
/// layar tetap render dan menyelesaikan animasi lalu pop.
class SolarAnalysisLoadingScreen extends StatefulWidget {
  const SolarAnalysisLoadingScreen({super.key, required this.panelData});

  final SolarPanelData? panelData;

  static const List<String> steps = [
    'QR terbaca',
    'Memeriksa kondisi panel',
    'Menghitung paparan matahari',
    'Mengestimasi penghematan',
    'Menyiapkan rekomendasi',
  ];

  @override
  State<SolarAnalysisLoadingScreen> createState() =>
      _SolarAnalysisLoadingScreenState();
}

class _SolarAnalysisLoadingScreenState extends State<SolarAnalysisLoadingScreen>
    with TickerProviderStateMixin {
  static const Color _brandGreen = Color(0xFF0F4E2D);
  static const Color _lightGreen = Color(0xFFEAF6EF);
  static const Color _accentGreen = Color(0xFF2E7D32);

  late final AnimationController _pulseController;
  late final AnimationController _progressController;
  int _currentStep = 0;
  Timer? _stepTimer;

  // 500ms per step × 5 steps = 2500ms total
  static const _stepMs = 500;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: _stepMs * SolarAnalysisLoadingScreen.steps.length,
      ),
    )..forward();

    _stepTimer = Timer.periodic(Duration(milliseconds: _stepMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentStep < SolarAnalysisLoadingScreen.steps.length - 1) {
        setState(() => _currentStep++);
      } else {
        timer.cancel();
        // Jeda singkat setelah step terakhir agar terasa natural
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          final data = widget.panelData;
          if (data != null) {
            context.pushReplacement(Paths.solarQrResult, extra: data);
          } else {
            Navigator.of(context).pop();
          }
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
                // Badge "Solar Scanner" — never claim "AI" (rule-based estimate)
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.solar_power_rounded,
                        size: 16,
                        color: _brandGreen,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Solar Scanner',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _brandGreen,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Animated pulse + scanning ring
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ripple ring
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
                      // Circular progress ring
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
                      // Central icon
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
                            Icons.solar_power_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Current step label (animated fade + slide)
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
                      'Menganalisis Solar Panel...',
                      key: const ValueKey('title'),
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
                const SizedBox(height: 20),

                // Step checklist
                ...List.generate(SolarAnalysisLoadingScreen.steps.length, (i) {
                  final done = i <= _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: done
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  key: ValueKey('done'),
                                  color: _accentGreen,
                                  size: 18,
                                )
                              : Icon(
                                  Icons.radio_button_unchecked_rounded,
                                  key: const ValueKey('wait'),
                                  color: const Color(0xFFB8CAC0),
                                  size: 18,
                                ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          SolarAnalysisLoadingScreen.steps[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: done
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: done ? _brandGreen : const Color(0xFFB8CAC0),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 28),

                // Progress bar linear
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
