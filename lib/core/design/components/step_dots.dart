import 'package:flutter/material.dart';

import '../tokens.dart';

/// A compact numbered step header ("1 Kuota · 2 Jadwal · 3 Konfirmasi").
/// Used at the top of the stepped flows (Arisan sharing, financing).
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.labels, required this.current});

  /// Ordered step labels.
  final List<String> labels;

  /// Zero-based index of the active step.
  final int current;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<Widget> children = [];

    for (int i = 0; i < labels.length; i++) {
      final bool done = i < current;
      final bool active = i == current;
      final Color circleColor = done || active
          ? AppColors.primary
          : AppColors.surface;
      final Color numberColor = done || active
          ? Colors.white
          : AppColors.textTertiary;

      children.add(
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppDurations.fast,
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done || active
                        ? AppColors.primary
                        : AppColors.outline,
                    width: 1.4,
                  ),
                ),
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : Text(
                        '${i + 1}',
                        style: text.labelSmall?.copyWith(
                          color: numberColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(
                    color: active
                        ? AppColors.primaryDark
                        : AppColors.textTertiary,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      if (i != labels.length - 1) {
        children.add(
          Container(
            width: 14,
            height: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: AppColors.outline,
          ),
        );
      }
    }

    return Row(children: children);
  }
}
