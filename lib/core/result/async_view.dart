import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/components/state_views.dart';

/// Renders an [AsyncValue] as one of the four canonical states
/// (docs/DESIGN_SYSTEM.md §7): loading spinner, error + retry, or the data
/// builder. `empty` is a screen-level concern the data builder handles.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loadingLabel,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => LoadingState(label: loadingLabel),
      error: (Object error, StackTrace _) => ErrorStateView(onRetry: onRetry),
    );
  }
}
