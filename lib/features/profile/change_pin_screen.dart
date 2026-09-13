import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/errors.dart';
import '../../core/l10n/l10n.dart';
import '../../core/state/actions.dart';
import '../auth/pin_views.dart';

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  String? _current;
  bool _busy = false;

  Future<void> _create(String next, AppLocalizations l10n) async {
    setState(() => _busy = true);
    try {
      await ref.read(actionsProvider).changePin(_current!, next);
      if (!mounted) return;
      showAppSnack(context, l10n.changePinSuccess);
      context.pop();
    } on AppException catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.message, error: true);
      setState(() {
        _busy = false;
        _current = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n.scaffoldChangePin,
      onBack: () =>
          _current == null ? context.pop() : setState(() => _current = null),
      scrollable: false,
      body: _current == null
          ? PinEntryView(
              key: const ValueKey('current'),
              title: l10n.changePinCurrentPin,
              onSubmit: (pin) async {
                setState(() => _current = pin);
                return null;
              },
            )
          : PinCreateView(
              key: const ValueKey('new'),
              title: l10n.changePinNewPin,
              busy: _busy,
              onCreated: (pin) => _create(pin, l10n),
            ),
    );
  }
}
