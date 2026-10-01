import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../l10n/l10n.dart';

/// Replacement for Flutter's default red/grey error box
/// (installed as `ErrorWidget.builder` in bootstrap).
///
/// In debug it still surfaces the message so mistakes are visible; in release it
/// shows a calm, generic placeholder instead of a scary crash rectangle.
class AppErrorBox extends StatelessWidget {
  const AppErrorBox({super.key, this.details});

  final FlutterErrorDetails? details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.danger,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.sm),
              // No BuildContext ancestry is guaranteed for an error widget, so
              // use the language in use rather than looking it up.
              Text(
                AppLocalizations.current.errorViewBroken,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              if (kDebugMode && details != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${details!.exception}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
