import 'package:flutter/material.dart';

import '../tokens.dart';
import 'qualifier_label.dart';

/// Label + prominent value + optional qualifier pill.
/// See docs/DESIGN_SYSTEM.md §6.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.qualifier,
    this.valueColor,
  });

  final String label;
  final String value;
  final QualifierKind? qualifier;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: text.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: text.titleLarge?.copyWith(color: valueColor)),
        if (qualifier != null) ...[
          const SizedBox(height: AppSpacing.xs),
          QualifierLabel(qualifier!),
        ],
      ],
    );
  }
}
