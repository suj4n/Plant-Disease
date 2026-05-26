import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/services/api_service.dart';
import '../core/widgets/page_background.dart';

/// Camera / gallery leaf capture and disease detection API call.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) _showError('Could not open camera: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) _showError('Could not open gallery: $e');
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

      await Navigator.pushNamed(
        context,
        '/result',
        arguments: data,
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('SocketException')
          ? 'No internet connection'
          : 'Something went wrong. Try again.';
      _showError(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.coral,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _selectedImage != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text('Scan Your Plant', style: AppTextStyles.headlineSmall),
      ),
      body: Stack(
        children: [
          const PageBackground(
            imagePath: AppAssets.bg,
            overlayOpacity: 0.7,
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _buildImagePreview(hasImage),
                _buildSourceButtons(),
                _buildAnalyzeButton(hasImage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(bool hasImage) {
    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.file(
              _selectedImage!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.eco,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select a leaf image',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Good lighting = better results 📸',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSourceButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : _pickFromCamera,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text('Camera', style: AppTextStyles.titleSmall),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : _pickFromGallery,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.photo_library,
                      color: AppColors.indigo,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text('Gallery', style: AppTextStyles.titleSmall),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton(bool hasImage) {
    final canAnalyze = hasImage && !_isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: GestureDetector(
        onTap: canAnalyze ? _analyzeImage : null,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: hasImage
                ? const LinearGradient(
                    colors: [Color(0xFF2D7A2D), AppColors.primary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: hasImage ? null : AppColors.cardElevated,
            borderRadius: BorderRadius.circular(16),
            boxShadow: hasImage
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else ...[
                Icon(
                  Icons.biotech,
                  color: hasImage ? Colors.white : AppColors.muted,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Analyze Leaf',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: hasImage ? Colors.white : AppColors.muted,
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
