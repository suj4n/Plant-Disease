import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../backend/backend_settings.dart';
import '../backend/plant_disease_api.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  static const String routeName = '/scan';

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const Color _creamBg = Color(0xFFF5F0E8);
  static const Color _darkGreen = Color(0xFF1B4332);
  static const Color _orangeActive = Color(0xFFF4A261);
  static const Color _inactiveGrey = Color(0xFFBDBDBD);

  File? _selectedImage;
  bool _isAnalyzing = false;
  final ImagePicker _imagePicker = ImagePicker();
  final PlantDiseaseApi _api = PlantDiseaseApi();

  bool _readArgsOnce = false;
  String? _plantProfileId;
  String? _plantProfileName;
  String? _cropType;

  bool _looksHealthyLabel(String label) {
    final String s = label.toLowerCase();
    return s.contains('healthy');
  }

  Map<String, String> _genericAdviceFor(String label, bool isHealthy) {
    if (isHealthy) {
      return <String, String>{
        'description':
            'This looks healthy based on the model’s prediction. Keep monitoring for any changes.',
        'immediate_action':
            'No treatment needed right now. Ensure adequate watering and sunlight for your crop.',
        'preventive_measures':
            'Avoid overhead watering, keep leaves dry, and maintain spacing for airflow.',
      };
    }
    return <String, String>{
      'description':
          'The model detected a possible issue. Consider checking both sides of the leaves and nearby plants.',
      'immediate_action':
          'Remove severely affected leaves and isolate the plant if the issue spreads. Disinfect tools after use.',
      'preventive_measures':
          'Improve airflow, water at the base, and keep foliage dry. Consider a label-approved treatment for your crop if symptoms persist.',
    };
  }

  Future<void> _openBackendSettings() async {
    final String current = await BackendSettings.getBaseUrl();
    if (!mounted) return;

    final TextEditingController controller = TextEditingController(text: current);
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Backend URL', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Tip: Android emulator uses ${BackendSettings.defaultBaseUrl()}. '
                'On a real phone, use your PC’s LAN IP (example: http://192.168.1.10:8000).',
                style: GoogleFonts.poppins(fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'http://127.0.0.1:8000',
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            FilledButton(
              onPressed: () async {
                await BackendSettings.setBaseUrl(controller.text);
                if (context.mounted) Navigator.pop(context);
              },
              child: Text('Save', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readArgsOnce) return;
    _readArgsOnce = true;

    final raw = ModalRoute.of(context)?.settings.arguments;
    if (raw is Map) {
      final args = raw.map((k, v) => MapEntry(k.toString(), v));
      _plantProfileId = args['plant_profile_id']?.toString();
      _plantProfileName = args['plant_profile_name']?.toString();
      _cropType = args['crop_type']?.toString();
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error accessing camera: $e')));
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error accessing gallery: $e')));
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final res = await _api.predictLeafImage(imageFile: _selectedImage!, topK: 5);
      final top = res.topPrediction;
      final String label = (top?.label ?? res.topLabel ?? 'Unknown').trim().isEmpty
          ? 'Unknown'
          : (top?.label ?? res.topLabel ?? 'Unknown');
      final double confidence = top?.probability ?? 0.0;
      final bool isHealthy = _looksHealthyLabel(label);
      final bool lowConfidenceWarning = confidence < 0.6;
      final Map<String, String> advice = _genericAdviceFor(label, isHealthy);

      if (mounted) {
        Navigator.pushNamed(
          context,
          ResultScreen.routeName,
          arguments: {
            'imagePath': _selectedImage!.path,
            'disease': label,
            'confidence': confidence,
            'is_healthy': isHealthy,
            'low_confidence_warning': lowConfidenceWarning,
            'plant_profile_id': _plantProfileId,
            'plant_profile_name': _plantProfileName,
            'crop_type': _cropType,
            'description': advice['description'],
            'immediate_action': advice['immediate_action'],
            'preventive_measures': advice['preventive_measures'],
            'recommended_products': const <String>[],
            'predictions': res.predictions
                .map((p) => {'label': p.label, 'probability': p.probability})
                .toList(),
            'model_path': res.modelPath,
          },
        ).then((_) {
          // Reset state when returning
          if (mounted) {
            setState(() {
              _selectedImage = null;
              _isAnalyzing = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        final String msg = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analyze failed: $msg'),
            action: SnackBarAction(
              label: 'Backend URL',
              onPressed: _openBackendSettings,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _creamBg,
      appBar: AppBar(
        backgroundColor: _darkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan a Leaf',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        actions: <Widget>[
          IconButton(
            tooltip: 'Backend URL',
            onPressed: _openBackendSettings,
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Preview Card
                GestureDetector(
                  child: Container(
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.eco,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap below to add\na leaf photo',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                // Camera and Gallery Buttons
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: _darkGreen,
                        elevation: 4,
                        shadowColor: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _pickImageFromCamera,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Camera',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _darkGreen, width: 2),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _pickImageFromGallery,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.photo_rounded,
                                    color: _darkGreen,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Gallery',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _darkGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Analyze Button
                Material(
                  color: _selectedImage != null ? _orangeActive : _inactiveGrey,
                  elevation: _selectedImage != null ? 4 : 0,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _selectedImage != null ? _analyzeImage : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      child: Text(
                        'Analyze',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isAnalyzing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: _orangeActive,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Analyzing your plant...',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
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
