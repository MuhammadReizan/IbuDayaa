import 'package:flutter/material.dart';

import '../../core/auth/credentials.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';

/// Title, dots, message and keypad, laid out to fit a 360 dp phone without
/// the keypad covering anything.
class _PinLayout extends StatelessWidget {
  const _PinLayout({
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.error,
    required this.busy,
    required this.onDigit,
    required this.onBackspace,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final int filled;
  final String? error;
  final bool busy;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  style: text.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    subtitle!,
                    style: text.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                PinDots(filled: filled, error: error != null),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 44,
                  child: busy
                      ? const Center(
                          child: SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        )
                      : Text(
                          error ?? '',
                          textAlign: TextAlign.center,
                          style: text.bodySmall?.copyWith(
                            color: AppColors.dangerText,
                          ),
                        ),
                ),
                const Spacer(),
                ?footer,
                PinPad(
                  onDigit: onDigit,
                  onBackspace: onBackspace,
                  enabled: !busy,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Enter an existing PIN. [onSubmit] returns an error message, or null when
/// the PIN was accepted.
class PinEntryView extends StatefulWidget {
  const PinEntryView({
    super.key,
    required this.title,
    this.subtitle,
    required this.onSubmit,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final Future<String?> Function(String pin) onSubmit;
  final Widget? footer;

  @override
  State<PinEntryView> createState() => _PinEntryViewState();
}

class _PinEntryViewState extends State<PinEntryView> {
  String _pin = '';
  String? _error;
  bool _busy = false;

  Future<void> _digit(String d) async {
    if (_busy || _pin.length >= 6) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length < 6) return;
    setState(() => _busy = true);
    final error = await widget.onSubmit(_pin);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      if (error != null) _pin = '';
    });
  }

  @override
  Widget build(BuildContext context) => _PinLayout(
    title: widget.title,
    subtitle: widget.subtitle,
    filled: _pin.length,
    error: _error,
    busy: _busy,
    footer: widget.footer,
    onDigit: _digit,
    onBackspace: () {
      if (_pin.isEmpty || _busy) return;
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    },
  );
}

/// Choose a new PIN, then type it again.
class PinCreateView extends StatefulWidget {
  const PinCreateView({
    super.key,
    required this.onCreated,
    this.title = 'Buat PIN 6 angka',
    this.busy = false,
  });

  final ValueChanged<String> onCreated;
  final String title;
  final bool busy;

  @override
  State<PinCreateView> createState() => _PinCreateViewState();
}

class _PinCreateViewState extends State<PinCreateView> {
  String _first = '';
  String _pin = '';
  bool _confirming = false;
  String? _error;

  void _digit(String d) {
    if (widget.busy || _pin.length >= 6) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length < 6) return;

    if (!_confirming) {
      if (isWeakPin(_pin)) {
        setState(() {
          _error =
              'PIN terlalu mudah ditebak. Hindari angka sama atau berurutan.';
          _pin = '';
        });
        return;
      }
      setState(() {
        _first = _pin;
        _pin = '';
        _confirming = true;
      });
      return;
    }

    if (_pin != _first) {
      setState(() {
        _error = 'PIN tidak sama. Ulangi dari awal.';
        _pin = '';
        _first = '';
        _confirming = false;
      });
      return;
    }
    widget.onCreated(_pin);
  }

  @override
  Widget build(BuildContext context) => _PinLayout(
    title: _confirming ? 'Ketik ulang PIN' : widget.title,
    subtitle: _confirming
        ? 'Pastikan sama dengan PIN tadi.'
        : 'PIN dipakai setiap kali masuk. Jangan beri tahu siapa pun.',
    filled: _pin.length,
    error: _error,
    busy: widget.busy,
    onDigit: _digit,
    onBackspace: () {
      if (_pin.isEmpty || widget.busy) return;
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    },
  );
}
