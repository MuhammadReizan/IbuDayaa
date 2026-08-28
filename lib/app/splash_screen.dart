import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/demo/demo_providers.dart';
import '../core/design/components/state_views.dart';
import '../core/design/tokens.dart';
import 'router.dart';

/// Bootstrap gate (SC-00). Holds here while the demo seed loads, then replaces
/// itself with Home. On a load failure it shows a retryable error state — the
/// app never proceeds with a broken scenario.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenario = ref.watch(demoScenarioProvider);

    if (scenario.hasValue) {
      // Seed ready — leave the splash on the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoute.homePath);
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: scenario.when(
            loading: () => const LoadingState(label: 'Menyiapkan Demo Mode…'),
            data: (_) => const LoadingState(),
            error: (Object error, StackTrace _) => ErrorStateView(
              message: 'Gagal memuat data demo. Coba lagi.',
              onRetry: () => ref.invalidate(demoScenarioProvider),
            ),
          ),
        ),
      ),
    );
  }
}
