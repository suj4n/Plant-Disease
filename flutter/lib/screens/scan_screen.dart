import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/services/api_error.dart';
import '../core/services/api_service.dart';
import '../core/services/scan_storage.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/scan_frame_overlay.dart';

enum _ScanStage {
  /// Camera starting up.
  initializing,

  /// Live viewfinder.
  framing,

  /// A photo is captured and awaiting confirmation.
  reviewing,

  /// Uploading and running the model.
  analysing,

  /// Camera unusable — gallery still works.
  cameraUnavailable,
}

/// The scanning experience: viewfinder, confirm, analyse.
///
/// A photo is never uploaded without the user confirming it, and every failure
/// path ends in a readable message rather than a dead end.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();

  CameraController? _camera;
  _ScanStage _stage = _ScanStage.initializing;
  File? _captured;
  String? _cameraMessage;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  /// Release the camera in the background and rebuild it on resume, so the app
  /// does not hold the hardware (or crash) across lifecycle changes.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _camera;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed &&
        _stage == _ScanStage.framing) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _failCamera('No camera was found on this device.');
        return;
      }

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _stage = _ScanStage.framing;
        _cameraMessage = null;
      });
    } on CameraException catch (e) {
      _failCamera(
        e.code == 'CameraAccessDenied'
            ? 'PlantDoc needs camera access to scan a leaf. You can still '
                'choose a photo from your gallery.'
            : 'The camera is unavailable right now. You can still choose a '
                'photo from your gallery.',
      );
    } catch (_) {
      _failCamera(
        'The camera could not be started. You can still choose a photo from '
        'your gallery.',
      );
    }
  }

  void _failCamera(String message) {
    if (!mounted) return;
    setState(() {
      _stage = _ScanStage.cameraUnavailable;
      _cameraMessage = message;
    });
  }

  Future<void> _capture() async {
    final controller = _camera;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isTakingPicture) return;

    try {
      await HapticFeedback.mediumImpact();
      final shot = await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _captured = File(shot.path);
        _stage = _ScanStage.reviewing;
      });
    } catch (_) {
      _showMessage("We couldn't take that photo. Please try again.");
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _captured = File(picked.path);
        _stage = _ScanStage.reviewing;
      });
    } catch (_) {
      _showMessage("We couldn't open your gallery. Please try again.");
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _camera;
    if (controller == null || !controller.value.isInitialized) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await controller.setFlashMode(next);
      if (mounted) setState(() => _flashMode = next);
    } catch (_) {
      _showMessage('This device does not support the flash.');
    }
  }

  void _retake() {
    setState(() {
      _captured = null;
      _stage = _camera != null ? _ScanStage.framing : _ScanStage.cameraUnavailable;
    });
  }

  Future<void> _analyse() async {
    final image = _captured;
    if (image == null || _stage == _ScanStage.analysing) return;

    setState(() => _stage = _ScanStage.analysing);

    try {
      final result = await ApiService.detect(image);
      // Save locally first — a scan is never lost to a cloud failure. An
      // unidentifiable photo is not a diagnosis, so it is not stored.
      if (result.isIdentifiable) {
        await ScanStorage.saveResult(result);
      }
      if (!mounted) return;
      await Navigator.pushReplacementNamed(
        context,
        '/result',
        arguments: result,
      );
    } catch (e) {
      if (!mounted) return;
      final error = ApiError.from(e);
      setState(() => _stage = _ScanStage.reviewing);
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => Navigator.maybePop(context),
              busy: _stage == _ScanStage.analysing,
            ),
            Expanded(child: _buildViewfinder()),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildViewfinder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ClipRRect(
        borderRadius: AppRadius.hero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: AppColors.foreground, child: _viewfinderContent()),
            if (_stage == _ScanStage.framing ||
                _stage == _ScanStage.reviewing ||
                _stage == _ScanStage.analysing)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: ScanFrameOverlay(),
              ),
            if (_stage == _ScanStage.analysing) const _AnalysingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _viewfinderContent() {
    switch (_stage) {
      case _ScanStage.initializing:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.onPrimary),
        );

      case _ScanStage.cameraUnavailable:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.no_photography_outlined,
                  size: 44,
                  color: AppColors.onPrimary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _cameraMessage ?? 'The camera is unavailable.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _initCamera,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try the camera again'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(220, 46),
                  ),
                ),
              ],
            ),
          ),
        );

      case _ScanStage.reviewing:
      case _ScanStage.analysing:
        final image = _captured;
        if (image == null) return const SizedBox.shrink();
        return Image.file(image, fit: BoxFit.cover);

      case _ScanStage.framing:
        final controller = _camera;
        if (controller == null || !controller.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.onPrimary),
          );
        }
        // Fill the rounded frame without distorting the sensor aspect ratio.
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? 1080,
            height: controller.value.previewSize?.width ?? 1920,
            child: CameraPreview(controller),
          ),
        );
    }
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: switch (_stage) {
        _ScanStage.analysing => Text(
            'This usually takes a few seconds.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        _ScanStage.reviewing => Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retake,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retake'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _analyse,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 19),
                  label: const Text('Use this photo'),
                ),
              ),
            ],
          ),
        _ => _CaptureRow(
            canCapture: _stage == _ScanStage.framing,
            flashOn: _flashMode != FlashMode.off,
            onGallery: _pickFromGallery,
            onCapture: _capture,
            onFlash: _stage == _ScanStage.framing ? _toggleFlash : null,
          ),
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.busy});

  final VoidCallback onBack;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
            iconSize: 22,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  busy ? 'Analysing' : 'Scan your plant',
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  busy
                      ? 'Hold on while PlantDoc AI reads the leaf.'
                      : 'Place a clear photo of the affected leaf inside the frame.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Replaces the capture UI while the model runs — informative, and it keeps
/// the screen interactive rather than freezing behind a modal spinner.
class _AnalysingOverlay extends StatelessWidget {
  const _AnalysingOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: AppColors.foreground.withValues(alpha: 0.55)),
        const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: ScanSweepLine(),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.onPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Analysing your plant...',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PlantDoc AI is examining the leaf',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CaptureRow extends StatelessWidget {
  const _CaptureRow({
    required this.canCapture,
    required this.flashOn,
    required this.onGallery,
    required this.onCapture,
    required this.onFlash,
  });

  final bool canCapture;
  final bool flashOn;
  final VoidCallback onGallery;
  final VoidCallback onCapture;
  final VoidCallback? onFlash;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundAction(
          icon: Icons.photo_library_outlined,
          label: 'Choose from gallery',
          onTap: onGallery,
        ),
        Semantics(
          button: true,
          label: 'Capture photo',
          child: Tooltip(
            message: 'Capture photo',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canCapture ? onCapture : null,
                customBorder: const CircleBorder(),
                child: Ink(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: canCapture ? AppColors.primary : AppColors.cardElevated,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 4),
                    boxShadow: canCapture ? AppShadows.lifted : null,
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 30,
                    color: canCapture
                        ? AppColors.onPrimary
                        : AppColors.mutedForeground,
                  ),
                ),
              ),
            ),
          ),
        ),
        _RoundAction(
          icon: flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          label: flashOn ? 'Turn flash off' : 'Turn flash on',
          onTap: onFlash,
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Ink(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                icon,
                size: 22,
                color: enabled ? AppColors.foreground : AppColors.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
