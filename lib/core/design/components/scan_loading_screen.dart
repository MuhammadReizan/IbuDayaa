import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens.dart';

/// Shared full-screen "processing" animation shown right after a scan
/// (energy bill, solar-panel QR, ...) while the on-device rule-based
/// computation runs, before the result screen appears.
///
/// This is a fixed-duration UI animation, not a progress callback from real
/// work — the computation itself is instant. Copy passed in here must never
/// claim "AI"; see the honesty rules in CLAUDE.md.
class ScanLoadingScreen extends StatefulWidget {
  const ScanLoadingScreen({
    super.key,
    required this.badgeIcon,
    required this.badgeLabel,
    required this.centerIcon,
    required this.title,
    required this.steps,
    required this.onComplete,
    this.stepDuration = const Duration(milliseconds: 420),
    this.completionDelay = const Duration(milliseconds: 200),
  });

  final IconData badgeIcon;
  final String badgeLabel;
  final IconData centerIcon;

  /// Headline shown above the step checklist while it runs.
  final String title;

  /// Steps ticked off one by one; the last one marks completion.
  final List<String> steps;

  final VoidCallback onComplete;
  final Duration stepDuration;
  final Duration completionDelay;

  @override
  State<ScanLoadingScreen> createState() => _ScanLoadingScreenState();
}

class _ScanLoadingScreenState extends State<ScanLoadingScreen>
    with TickerProviderStateMixin {
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
      duration: widget.stepDuration * widget.steps.length,
    )..forward();

    _stepTimer = Timer.periodic(widget.stepDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentStep < widget.steps.length - 1) {
        setState(() => _currentStep++);
      } else {
        timer.cancel();
        Future.delayed(widget.completionDelay, () {
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
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Badge(icon: widget.badgeIcon, label: widget.badgeLabel),
                const SizedBox(height: AppSpacing.xxxl),
                _PulseRing(
                  pulseController: _pulseController,
                  progressController: _progressController,
                  centerIcon: widget.centerIcon,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...List.generate(widget.steps.length, (i) {
                  final done = i <= _currentStep;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxs,
                    ),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: AppDurations.normal,
                          child: done
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  key: ValueKey('done'),
                                  color: AppColors.success,
                                  size: AppIconSize.md,
                                )
                              : const Icon(
                                  Icons.radio_button_unchecked_rounded,
                                  key: ValueKey('wait'),
                                  color: AppColors.textTertiary,
                                  size: AppIconSize.md,
                                ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            widget.steps[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: done
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: done
                                  ? AppColors.primaryDark
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: 220,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: AppRadius.pillBr,
                  ),
                  alignment: Alignment.centerLeft,
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        widthFactor: _progressController.value.clamp(0.05, 1.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: AppRadius.pillBr,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: AppRadius.pillBr,
        border: Border.all(color: AppColors.primaryContainerDim),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.sm, color: AppColors.primaryDark),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({
    required this.pulseController,
    required this.progressController,
    required this.centerIcon,
  });

  final AnimationController pulseController;
  final AnimationController progressController;
  final IconData centerIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final scale = 1.0 + (pulseController.value * 0.22);
              final opacity = (1.0 - (pulseController.value * 0.7)).clamp(
                0.0,
                1.0,
              );
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryDark.withValues(
                      alpha: 0.12 * opacity,
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final scale = 0.95 + (pulseController.value * 0.12);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryContainer,
                    border: Border.all(color: AppColors.primaryContainerDim),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: progressController,
            builder: (context, child) {
              return SizedBox(
                width: 106,
                height: 106,
                child: CircularProgressIndicator(
                  value: progressController.value,
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryDark,
                  ),
                  backgroundColor: AppColors.outline,
                ),
              );
            },
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryDark,
              boxShadow: AppShadows.button,
            ),
            child: Center(
              child: Icon(
                centerIcon,
                color: AppColors.onPrimary,
                size: AppIconSize.xl,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
