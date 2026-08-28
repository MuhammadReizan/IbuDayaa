import 'package:flutter/material.dart';

import '../tokens.dart';

/// Consistent screen frame: optional app bar with a back affordance, a
/// `SafeArea`, a scrollable body by default, and an optional pinned bottom CTA
/// bar. See docs/DESIGN_SYSTEM.md §6.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.onBack,
    this.actions,
    required this.body,
    this.bottomBar,
    this.scrollable = true,
    this.padding = AppSpacing.screenH,
  });

  final String? title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Widget body;
  final Widget? bottomBar;
  final bool scrollable;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final bool hasBar = title != null || onBack != null || actions != null;

    Widget content = Padding(
      padding: EdgeInsets.only(
        left: padding.left,
        right: padding.right,
        top: AppSpacing.lg,
        bottom: AppSpacing.xl,
      ),
      child: body,
    );
    if (scrollable) {
      content = SingleChildScrollView(child: content);
    }

    return Scaffold(
      appBar: hasBar
          ? AppBar(
              leading: onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: onBack,
                      tooltip: 'Kembali',
                    )
                  : null,
              title: title != null ? Text(title!) : null,
              actions: actions,
            )
          : null,
      body: SafeArea(child: content),
      bottomNavigationBar: bottomBar == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: bottomBar!,
            ),
    );
  }
}
