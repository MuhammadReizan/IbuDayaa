import 'package:flutter/material.dart';

import '../tokens.dart';
import 'app_buttons.dart';

/// Full-screen confirmation after a flow completes ("Penawaran Berhasil",
/// "Pengajuan terkirim"). Says what happened, what happens next, and offers
/// the next sensible step.
class SuccessPanel extends StatelessWidget {
  const SuccessPanel({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.child,
    this.icon = Icons.check_rounded,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Widget? child;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) (onSecondary ?? onPrimary)();
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              padding: AppSpacing.screenH,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.4, end: 1),
                          duration: AppDurations.slow,
                          curve: Curves.elasticOut,
                          builder: (_, v, child) =>
                              Transform.scale(scale: v, child: child),
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              gradient: AppGradients.brand,
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.button,
                            ),
                            child: Icon(icon, color: Colors.white, size: 52),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        title,
                        style: text.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        message,
                        style: text.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (child != null) ...[
                        const SizedBox(height: AppSpacing.xl),
                        child!,
                      ],
                      const Spacer(),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(label: primaryLabel, onPressed: onPrimary),
                      if (secondaryLabel != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        TextLinkButton(
                          label: secondaryLabel!,
                          onPressed: onSecondary,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
