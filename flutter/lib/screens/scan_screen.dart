import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_assets.dart';
import '../core/services/api_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/page_background.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromCamera() => _pick(ImageSource.camera);
  Future<void> _pickFromGallery() => _pick(ImageSource.gallery);

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) _showError('Could not open ${source.name}: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null || _isLoading) return;

    await HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.analyzePlant(_selectedImage!);
      if (!mounted) return;
      data['imagePath'] = _selectedImage!.path;
      data['timestamp'] = DateTime.now().toIso8601String();
      await Navigator.pushNamed(context, '/result', arguments: data);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('SocketException')
          ? 'Cannot reach backend at ${ApiService.baseUrl}. Check Wi‑Fi IP or run: adb reverse tcp:8000 tcp:8000'
          : e.toString().replaceFirst('HttpException: ', '');
      _showError(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _selectedImage != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Scan plant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          const PageBackground(imagePath: AppAssets.scanBg, overlayOpacity: 0.5),
          SafeArea(
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ImagePreview(
                    hasImage: hasImage,
                    image: _selectedImage,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SourceButtons(
                    enabled: !_isLoading,
                    onCamera: _pickFromCamera,
                    onGallery: _pickFromGallery,
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: hasImage && !_isLoading ? _analyzeImage : null,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.biotech_outlined),
                    label: Text(_isLoading ? 'Analyzing…' : 'Analyze leaf'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.hasImage, required this.image});

  final bool hasImage;
  final File? image;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: SizedBox(
          height: 280,
          width: double.infinity,
          child: hasImage && image != null
              ? Image.file(image!, fit: BoxFit.cover)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.eco_outlined, size: 64, color: AppColors.primary),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Select a leaf image', style: AppTextStyles.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Use good lighting for best results',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SourceButtons extends StatelessWidget {
  const _SourceButtons({
    required this.enabled,
    required this.onCamera,
    required this.onGallery,
  });

  final bool enabled;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled ? onCamera : null,
            icon: const Icon(Icons.camera_alt_outlined, size: 20),
            label: const Text('Camera'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled ? onGallery : null,
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: const Text('Gallery'),
          ),
        ),
      ],
    );
  }
}
