import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/errors.dart';
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

  Future<void> _create(String next) async {
    setState(() => _busy = true);
    try {
      await ref.read(actionsProvider).changePin(_current!, next);
      if (!mounted) return;
      showAppSnack(context, 'PIN berhasil diganti.');
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
    return AppScaffold(
      title: 'Ganti PIN',
      onBack: () =>
          _current == null ? context.pop() : setState(() => _current = null),
      scrollable: false,
      body: _current == null
          ? PinEntryView(
              key: const ValueKey('current'),
              title: 'Masukkan PIN lama',
              onSubmit: (pin) async {
                setState(() => _current = pin);
                return null;
              },
            )
          : PinCreateView(
              key: const ValueKey('new'),
              title: 'Buat PIN baru',
              busy: _busy,
              onCreated: _create,
            ),
    );
  }
}
