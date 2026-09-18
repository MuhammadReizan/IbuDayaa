import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/l10n.dart';
import '../tokens.dart';
import 'ui_kit.dart';

const Duration _cameraTimeout = Duration(seconds: 8);

/// Live viewfinder with a guide frame, shutter, gallery and flash. Falls back
/// to the gallery when there is no camera or permission was refused. Shared by
/// every photo-capture flow (roof check, appliance photos, etc.).
class CaptureView extends StatefulWidget {
  const CaptureView({
    super.key,
    required this.title,
    required this.hint,
    required this.onCaptured,
    this.frameAspect = 0.75,
    this.busy = false,
    this.busyLabel,
    this.tips = const [],
    this.secondaryAction,
    this.extraActions = const [],
  });

  final String title;
  final String hint;
  final Future<void> Function(String path) onCaptured;

  /// Frame width ÷ height.
  final double frameAspect;
  final bool busy;

  /// Falls back to [AppLocalizations.captureDefaultBusyLabel] when omitted.
  final String? busyLabel;
  final List<String> tips;
  final Widget? secondaryAction;

  /// App-bar actions in front of the flash toggle. Empty by default.
  final List<Widget> extraActions;

  @override
  State<CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<CaptureView>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  String? _error;
  bool _torch = false;
  bool _shooting = false;
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didUpdateWidget(covariant CaptureView old) {
    super.didUpdateWidget(old);
    if (widget.busy && !_sweep.isAnimating) {
      _sweep.repeat(reverse: true);
    } else if (!widget.busy && _sweep.isAnimating) {
      _sweep.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sweep.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      c?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && c == null) {
      _init();
    }
  }

  Future<void> _init() async {
    try {
      // Some devices never answer when the camera service is busy; fall back
      // to the gallery instead of spinning forever.
      final cams = await availableCameras().timeout(_cameraTimeout);
      if (cams.isEmpty) {
        if (mounted) {
          setState(
            () => _error = AppLocalizations.of(context).captureCameraNotFound,
          );
        }
        return;
      }
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      try {
        await controller.initialize().timeout(_cameraTimeout);
      } catch (_) {
        await controller.dispose();
        rethrow;
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(
        () => _error = e.code.contains('Denied')
            ? l10n.captureCameraDenied
            : l10n.captureCameraUnavailable,
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).captureCameraUnavailable,
        );
      }
    }
  }

  Future<void> _shoot() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _shooting || widget.busy) return;
    setState(() => _shooting = true);
    try {
      final file = await c.takePicture();
      if (_torch) {
        await c.setFlashMode(FlashMode.off);
        _torch = false;
      }
      await widget.onCaptured(file.path);
    } catch (e) {
      if (mounted) {
        showAppSnack(
          context,
          AppLocalizations.of(context).captureShootFailed,
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _shooting = false);
    }
  }

  Future<void> _gallery() async {
    if (widget.busy) return;
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (file != null) await widget.onCaptured(file.path);
    } catch (_) {
      if (mounted) {
        showAppSnack(
          context,
          AppLocalizations.of(context).captureGalleryFailed,
          error: true,
        );
      }
    }
  }

  Future<void> _toggleTorch() async {
    final c = _controller;
    if (c == null) return;
    try {
      await c.setFlashMode(_torch ? FlashMode.off : FlashMode.torch);
      setState(() => _torch = !_torch);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = _controller;
    final busyLabel = widget.busyLabel ?? l10n.captureDefaultBusyLabel;

    return Scaffold(
      backgroundColor: AppColors.scannerDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          widget.title,
          style: text.titleLarge?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          tooltip: l10n.actionBack,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          ...widget.extraActions,
          if (c != null)
            IconButton(
              tooltip: _torch ? l10n.captureTorchOff : l10n.captureTorchOn,
              onPressed: _toggleTorch,
              icon: Icon(
                _torch ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final maxW = box.maxWidth * 0.84;
                  final maxH = box.maxHeight * 0.82;
                  var w = maxW;
                  var h = w / widget.frameAspect;
                  if (h > maxH) {
                    h = maxH;
                    w = h * widget.frameAspect;
                  }
                  final frame = Rect.fromCenter(
                    center: Offset(box.maxWidth / 2, box.maxHeight / 2),
                    width: w,
                    height: h,
                  );
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      if (c != null && c.value.isInitialized)
                        ClipRect(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width:
                                  c.value.previewSize?.height ?? box.maxWidth,
                              height:
                                  c.value.previewSize?.width ?? box.maxHeight,
                              child: CameraPreview(c),
                            ),
                          ),
                        )
                      else if (_error != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.no_photography_outlined,
                                  color: AppColors.textOnDarkDim,
                                  size: 48,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: text.bodyMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentLeaf,
                          ),
                        ),
                      if (_error == null)
                        AnimatedBuilder(
                          animation: _sweep,
                          builder: (_, _) => CustomPaint(
                            painter: ScanFramePainter(
                              frame: frame,
                              progress: widget.busy ? _sweep.value : null,
                            ),
                          ),
                        ),
                      Positioned(
                        left: AppSpacing.gutter,
                        right: AppSpacing.gutter,
                        top: AppSpacing.sm,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: AppRadius.pillBr,
                            ),
                            child: Text(
                              widget.busy ? busyLabel : widget.hint,
                              textAlign: TextAlign.center,
                              style: text.labelMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (widget.tips.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sm,
                  AppSpacing.gutter,
                  0,
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final t in widget.tips)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppColors.accentLeaf,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            t,
                            style: text.labelSmall?.copyWith(
                              color: AppColors.textOnDarkDim,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RoundButton(
                  icon: Icons.photo_library_rounded,
                  label: l10n.captureGalleryLabel,
                  onTap: widget.busy ? null : _gallery,
                ),
                Semantics(
                  button: true,
                  label: l10n.captureShootSemanticLabel,
                  child: GestureDetector(
                    onTap: _shoot,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c == null || widget.busy
                              ? Colors.white.withValues(alpha: 0.3)
                              : AppColors.accentLeaf,
                        ),
                        child: widget.busy || _shooting
                            ? const Padding(
                                padding: EdgeInsets.all(AppSpacing.lg),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 64),
              ],
            ),
            ?widget.secondaryAction,
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.14),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox.square(
                dimension: 52,
                child: Icon(icon, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
