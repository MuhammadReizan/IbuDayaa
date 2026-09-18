import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../errors.dart';
import '../../l10n/l10n.dart';
import '../tokens.dart';
import '../typography.dart';

// ---------------------------------------------------------------------------
// Headers & rows
// ---------------------------------------------------------------------------

/// "Status Penggunaan Daya ········ Lihat semua"
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.md),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(title, style: text.titleMedium)),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

enum PillTone { success, warning, danger, info, neutral, solar }

({Color bg, Color fg}) pillColors(PillTone tone) => switch (tone) {
  PillTone.success => (
    bg: AppColors.successContainer,
    fg: AppColors.primaryDark,
  ),
  PillTone.warning => (
    bg: AppColors.warningContainer,
    fg: AppColors.warningText,
  ),
  PillTone.danger => (bg: AppColors.dangerContainer, fg: AppColors.dangerText),
  PillTone.info => (bg: AppColors.infoContainer, fg: AppColors.infoText),
  PillTone.neutral => (bg: AppColors.surfaceAlt, fg: AppColors.textSecondary),
  PillTone.solar => (bg: AppColors.secondaryContainer, fg: AppColors.onSolar),
};

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = PillTone.neutral,
    this.icon,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = pillColors(tone);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: c.bg, borderRadius: AppRadius.pillBr),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c.fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: c.fg,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tinted list row with a leading icon — the Figma "status" and menu rows.
class TintedRow extends StatelessWidget {
  const TintedRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.tone = PillTone.neutral,
    this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final PillTone tone;
  final VoidCallback? onTap;

  /// Fill the whole row with the tone instead of only the icon.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = pillColors(tone);
    return Material(
      color: filled ? c.bg : AppColors.surface,
      borderRadius: AppRadius.smBr,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smBr,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.smBr,
            border: filled ? null : Border.all(color: AppColors.outlineSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: filled ? AppColors.surface : c.bg,
                  borderRadius: AppRadius.xsBr,
                ),
                child: Icon(icon, size: 20, color: c.fg),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: text.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: text.bodySmall),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ] else if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: text.bodyMedium)),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: (emphasize ? text.titleMedium : text.titleSmall)?.copyWith(
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "① Estimasi Penghematan" — the numbered blocks on the roof result.
class NumberedSection extends StatelessWidget {
  const NumberedSection({
    super.key,
    required this.number,
    required this.title,
    required this.child,
  });

  final int number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: text.labelMedium?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(title, style: text.titleMedium)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero surfaces, quick actions, progress
// ---------------------------------------------------------------------------

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.child,
    this.gradient = AppGradients.brand,
    this.padding = AppSpacing.hero,
    this.onTap,
  });

  final Widget child;
  final Gradient gradient;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadius.lgBr,
        boxShadow: AppShadows.md,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: AppRadius.lgBr,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgBr,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Round icon with a label under it — the home screen shortcut row.
class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.primary,
    this.background = AppColors.primaryContainer,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color background;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smBr,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge'),
                backgroundColor: AppColors.danger,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: text.labelMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.primary,
    this.track = AppColors.primaryContainerDim,
    this.height = 8,
  });

  final double value;
  final Color color;
  final Color track;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.pillBr,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: AppDurations.slow,
        curve: kAppCurve,
        builder: (_, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          color: color,
          backgroundColor: track,
        ),
      ),
    );
  }
}

/// Half-circle gauge for the credit score.
class SemiGauge extends StatelessWidget {
  const SemiGauge({
    super.key,
    required this.value,
    this.max = 100,
    this.width = 220,
    this.caption,
  });

  final int value;
  final int max;
  final double width;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final target = (value / max).clamp(0.0, 1.0);
    return SizedBox(
      width: width,
      height: width * 0.6,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target),
        duration: AppDurations.slow * 2,
        curve: kAppCurve,
        builder: (_, v, _) => CustomPaint(
          painter: _GaugePainter(v),
          child: Align(
            alignment: const Alignment(0, 0.75),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(v * max).round()}',
                  style: AppTypography.numeric(width * 0.22),
                ),
                if (caption != null) Text(caption!, style: text.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.075;
    final radius = size.width / 2 - stroke / 2;
    final center = Offset(size.width / 2, size.width / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primaryContainerDim;
    canvas.drawArc(rect, math.pi, math.pi, false, track);

    if (value <= 0) return;
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: math.pi,
        endAngle: 2 * math.pi,
        colors: [AppColors.danger, AppColors.secondary, AppColors.primary],
        stops: [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawArc(rect, math.pi, math.pi * value, false, progress);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value;
}

// ---------------------------------------------------------------------------
// PIN entry
// ---------------------------------------------------------------------------

class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.filled,
    this.length = 6,
    this.error = false,
  });

  final int filled;
  final int length;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$filled dari $length angka PIN terisi',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < length; i++)
            AnimatedContainer(
              duration: AppDurations.fast,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled
                    ? (error ? AppColors.danger : AppColors.primary)
                    : Colors.transparent,
                border: Border.all(
                  color: error
                      ? AppColors.danger
                      : (i < filled ? AppColors.primary : AppColors.outline),
                  width: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Large numeric keypad. Bigger than the system keyboard and never covers the
/// dots, which matters for users who type slowly.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget key(String d) => _PadKey(
      label: d,
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onDigit(d);
            }
          : null,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(children: [for (final d in row) Expanded(child: key(d))]),
        Row(
          children: [
            const Expanded(child: SizedBox()),
            Expanded(child: key('0')),
            Expanded(
              child: _PadKey(
                icon: Icons.backspace_outlined,
                semantic: 'Hapus',
                onTap: enabled ? onBackspace : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({this.label, this.icon, this.semantic, required this.onTap});

  final String? label;
  final IconData? icon;
  final String? semantic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Semantics(
        button: true,
        label: semantic ?? label,
        child: Material(
          color: Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 60,
              child: Center(
                child: label != null
                    ? Text(
                        label!,
                        style: AppTypography.numeric(
                          26,
                          weight: FontWeight.w600,
                        ),
                      )
                    : Icon(icon, color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Messaging & history
// ---------------------------------------------------------------------------

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.body,
    required this.time,
    this.mine = false,
    this.system = false,
    this.senderName,
  });

  final String body;
  final String time;
  final bool mine;
  final bool system;
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: AppRadius.smBr,
            ),
            child: Column(
              children: [
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: AppColors.onSolar),
                ),
                const SizedBox(height: 2),
                Text(time, style: text.labelSmall?.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ),
      );
    }

    final bg = mine ? AppColors.primary : AppColors.surface;
    final fg = mine ? Colors.white : AppColors.textPrimary;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.sm),
              topRight: const Radius.circular(AppRadius.sm),
              bottomLeft: Radius.circular(mine ? AppRadius.sm : 4),
              bottomRight: Radius.circular(mine ? 4 : AppRadius.sm),
            ),
            boxShadow: mine ? AppShadows.none : AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (senderName != null && !mine) ...[
                Text(
                  senderName!,
                  style: text.labelMedium?.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(body, style: text.bodyMedium?.copyWith(color: fg)),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  time,
                  style: text.labelSmall?.copyWith(
                    fontSize: 10,
                    color: mine
                        ? AppColors.textOnDarkDim
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimelineItem extends StatelessWidget {
  const TimelineItem({
    super.key,
    required this.title,
    this.subtitle,
    this.time,
    this.done = true,
    this.isLast = false,
    this.tone = PillTone.success,
  });

  final String title;
  final String? subtitle;
  final String? time;
  final bool done;
  final bool isLast;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = pillColors(tone);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? c.fg : AppColors.surface,
                    border: Border.all(
                      color: done ? c.fg : AppColors.outline,
                      width: 2,
                    ),
                  ),
                  child: done
                      ? const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: done ? c.bg : AppColors.outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleSmall?.copyWith(
                      color: done
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: text.bodySmall),
                  ],
                  if (time != null) ...[
                    const SizedBox(height: 2),
                    Text(time!, style: text.labelSmall),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scanner
// ---------------------------------------------------------------------------

/// Corner brackets that tell the user where to place the bill or roof.
class ScanFramePainter extends CustomPainter {
  ScanFramePainter({required this.frame, this.progress});

  final Rect frame;

  /// 0–1 sweep line while reading; null hides it.
  final double? progress;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = AppColors.scannerDark.withValues(alpha: 0.55);
    final outer = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(frame, const Radius.circular(AppRadius.card)),
      );
    canvas.drawPath(Path.combine(PathOperation.difference, outer, hole), dim);

    final corner = Paint()
      ..color = AppColors.accentLeaf
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    final r = frame;
    for (final (p, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawLine(p, p + Offset(len * dx, 0), corner);
      canvas.drawLine(p, p + Offset(0, len * dy), corner);
    }

    final pr = progress;
    if (pr != null) {
      final y = r.top + r.height * pr;
      canvas.drawLine(
        Offset(r.left + 12, y),
        Offset(r.right - 12, y),
        Paint()
          ..color = AppColors.accentLeaf
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ScanFramePainter old) =>
      old.frame != frame || old.progress != progress;
}

// ---------------------------------------------------------------------------
// Navigation
// ---------------------------------------------------------------------------

@immutable
class NavItem {
  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
}

/// Bottom navigation with the Figma's short bar above the active tab.
///
/// Optionally raises one extra item (e.g. Solar Hub) in a floating center
/// button instead of the flat row — [items] then holds only the flat tabs,
/// split as evenly as possible around the raised [centerItem].
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
    this.centerItem,
    this.centerSelected = false,
    this.onCenterTap,
  });

  final List<NavItem> items;

  /// Index into [items] of the selected flat tab, or -1 when [centerItem] is
  /// the one selected.
  final int index;
  final ValueChanged<int> onTap;

  /// The raised center item (e.g. Solar Hub), or null for a plain flat row.
  final NavItem? centerItem;
  final bool centerSelected;
  final VoidCallback? onCenterTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hasCenter = centerItem != null && onCenterTap != null;
    final leftCount = hasCenter ? (items.length / 2).ceil() : items.length;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outlineSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  for (int i = 0; i < leftCount; i++)
                    Expanded(
                      child: _buildItem(
                        context: context,
                        item: items[i],
                        itemIndex: i,
                        text: text,
                      ),
                    ),
                  if (hasCenter) ...[
                    const Expanded(child: SizedBox()),
                    for (int i = leftCount; i < items.length; i++)
                      Expanded(
                        child: _buildItem(
                          context: context,
                          item: items[i],
                          itemIndex: i,
                          text: text,
                        ),
                      ),
                  ],
                ],
              ),
              if (hasCenter)
                Positioned(
                  top: -10,
                  child: Semantics(
                    button: true,
                    selected: centerSelected,
                    label: centerItem!.label,
                    child: GestureDetector(
                      onTap: onCenterTap,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryContainer,
                        ),
                        padding: const EdgeInsets.all(5),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x33107C41),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            centerSelected
                                ? centerItem!.activeIcon
                                : centerItem!.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required NavItem item,
    required int itemIndex,
    required TextTheme text,
  }) {
    final isSelected = itemIndex == index;
    return Semantics(
      selected: isSelected,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: () => onTap(itemIndex),
        child: Column(
          children: [
            AnimatedContainer(
              duration: AppDurations.fast,
              height: 3,
              width: isSelected ? 32 : 0,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
              ),
            ),
            const Spacer(),
            Badge(
              isLabelVisible: item.badge > 0,
              label: Text('${item.badge}'),
              backgroundColor: AppColors.danger,
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Forms & feedback
// ---------------------------------------------------------------------------

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.prefixText,
    this.suffixText,
    this.prefixIcon,
    this.maxLength,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final String? prefixText;
  final String? suffixText;
  final IconData? prefixIcon;
  final int? maxLength;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLength: maxLength,
          maxLines: maxLines,
          enabled: enabled,
          autofocus: autofocus,
          onChanged: onChanged,
          textInputAction: textInputAction,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          style: text.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperMaxLines: 3,
            counterText: '',
            prefixText: prefixText,
            suffixText: suffixText,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
          ),
        ),
      ],
    );
  }
}

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: error ? AppColors.dangerText : AppColors.primaryDarker,
        content: Text(message),
      ),
    );
}

/// Runs a mutation and turns any failure into a readable snackbar. Returns
/// whether it succeeded, so callers can navigate only on success.
Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (success != null && context.mounted) showAppSnack(context, success);
    return true;
  } on AppException catch (e) {
    if (context.mounted) showAppSnack(context, e.message, error: true);
  } catch (e, st) {
    debugPrint('Action failed: $e\n$st');
    if (context.mounted) {
      showAppSnack(
        context,
        e is Exception &&
                e.toString().isNotEmpty &&
                !e.toString().startsWith('Instance')
            ? e.toString()
            : AppLocalizations.of(context).errorGenericRetry,
        error: true,
      );
    }
  }
  return false;
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final cancelLabel = AppLocalizations.of(context).actionCancel;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  minimumSize: const Size(kMinTapTarget, kMinTapTarget),
                )
              : FilledButton.styleFrom(
                  minimumSize: const Size(kMinTapTarget, kMinTapTarget),
                ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Asks for a short text (rejection reason, note). Null when cancelled.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  bool required = true,
  bool destructive = false,
}) {
  final controller = TextEditingController();
  final cancelLabel = AppLocalizations.of(context).actionCancel;
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: destructive
                  ? AppColors.danger
                  : AppColors.primary,
              minimumSize: const Size(kMinTapTarget, kMinTapTarget),
            ),
            onPressed: required && controller.text.trim().isEmpty
                ? null
                : () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
}
