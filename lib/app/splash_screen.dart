import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/brand/brand.dart';
import '../core/data/app_data_controller.dart';
import '../core/design/components/state_views.dart';
import '../core/design/tokens.dart';
import 'router.dart';

/// Bootstrap gate. Holds the branded splash while the user's records are read
/// from disk, then goes to onboarding (first run) or Home. A read failure shows
/// a retryable error rather than starting on an unknown state.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);

    final loaded = data.value;
    if (loaded != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(
          loaded.isOnboarded ? AppRoute.homePath : AppRoute.onboardingPath,
        );
      });
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.forest),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                const Spacer(flex: 3),
                _AnimatedMark(),
                const SizedBox(height: AppSpacing.xl),
                const IbuDayaLogo(height: 34, variant: BrandVariant.onDark),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Energi Bersih, Ekonomi Tumbuh.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textOnDarkDim,
                  ),
                ),
                const Spacer(flex: 4),
                data.when(
                  loading: () => const _Dots(),
                  data: (_) => const _Dots(),
                  error: (Object error, StackTrace _) => Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.cardBr,
                    ),
                    child: ErrorStateView(
                      message: 'Gagal membuka data Anda. Coba lagi.',
                      onRetry: () => ref.invalidate(appDataProvider),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedMark extends StatefulWidget {
  @override
  State<_AnimatedMark> createState() => _AnimatedMarkState();
}

class _AnimatedMarkState extends State<_AnimatedMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
      child: Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: const Center(child: IbuDayaMark(size: 68)),
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final double t = (_c.value * 3 - i).clamp(0.0, 1.0);
            final double o = 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: o.clamp(0.0, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
