import 'package:flutter/material.dart';

import '../tokens.dart';

/// Consistent screen frame: a flat app bar with a back affordance, a `SafeArea`,
/// a scrollable body by default, and an optional pinned bottom CTA bar that
/// floats above the content with a soft shadow.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.titleWidget,
    this.onBack,
    this.actions,
    required this.body,
    this.bottomBar,
    this.scrollable = true,
    this.padding = AppSpacing.screenH,
    this.backgroundColor,
  });

  final String? title;
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Widget body;
  final Widget? bottomBar;
  final bool scrollable;
  final EdgeInsets padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bool hasBar =
        title != null ||
        titleWidget != null ||
        onBack != null ||
        actions != null;

    Widget content = Padding(
      padding: EdgeInsets.only(
        left: padding.left,
        right: padding.right,
        top: AppSpacing.md,
        bottom: bottomBar == null ? AppSpacing.xl : AppSpacing.xxl,
      ),
      child: body,
    );
    if (scrollable) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: hasBar
          ? AppBar(
              centerTitle: true,
              automaticallyImplyLeading: false,
              titleSpacing: AppSpacing.sm,
              leadingWidth: 52,
              leading: onBack != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: _RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Kembali',
                        onPressed: onBack!,
                      ),
                    )
                  : null,
              title: titleWidget ?? (title != null ? Text(title!) : null),
              actions: actions == null
                  ? null
                  : [...actions!, const SizedBox(width: AppSpacing.sm)],
            )
          : null,
      body: SafeArea(bottom: bottomBar == null, child: content),
      bottomNavigationBar: bottomBar == null
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: bottomBar!,
              ),
            ),
    );
  }
}

/// Small circular icon button used for the app-bar back affordance.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(side: BorderSide(color: AppColors.outline)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
