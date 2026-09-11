import 'package:flutter/material.dart';

import '../tokens.dart';

/// Adds a subtle press-down scale to any button child.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (widget.enabled && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: AppDurations.micro,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Primary call-to-action. Full-width by default, with a soft coloured glow.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !loading;

    final Widget child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.onPrimary,
            ),
          )
        : (icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                )
              : Text(label, overflow: TextOverflow.ellipsis));

    final Widget button = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.buttonBr,
        boxShadow: enabled ? AppShadows.button : AppShadows.none,
      ),
      child: FilledButton(onPressed: loading ? null : onPressed, child: child),
    );

    final Widget wrapped = _PressScale(enabled: enabled, child: button);
    return expand ? SizedBox(width: double.infinity, child: wrapped) : wrapped;
  }
}

/// Secondary (outlined) action.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Widget child = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          )
        : Text(label, overflow: TextOverflow.ellipsis);

    final Widget button = OutlinedButton(onPressed: onPressed, child: child);
    final Widget wrapped = _PressScale(
      enabled: onPressed != null,
      child: button,
    );
    return expand ? SizedBox(width: double.infinity, child: wrapped) : wrapped;
  }
}

/// Low-emphasis inline text action.
class TextLinkButton extends StatelessWidget {
  const TextLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return TextButton(onPressed: onPressed, child: Text(label));
    }
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
