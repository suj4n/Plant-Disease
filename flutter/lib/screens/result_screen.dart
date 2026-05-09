import 'dart:convert';
import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  static const String routeName = '/result';

  static const String historyPrefsKey = 'plantdoc_scan_history';

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const Color _creamBg = Color(0xFFF5F0E8);
  static const Color _darkGreen = Color(0xFF1B4332);
  static const Color _accentOrange = Color(0xFFF4A261);

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = _argsOf(context);
      final isHealthy = _boolArg(args, 'is_healthy');
      if (isHealthy) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _argsOf(BuildContext context) {
    final raw = ModalRoute.of(context)?.settings.arguments;
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  bool _boolArg(Map<String, dynamic> args, String key, {bool fallback = false}) {
    final v = args[key];
    if (v is bool) return v;
    return fallback;
  }

  double _confidenceArg(Map<String, dynamic> args) {
    final v = args['confidence'];
    if (v is double) {
      final double percent = v > 1.0 ? (v / 100.0) : v;
      return percent.clamp(0.0, 1.0);
    }
    if (v is int) {
      final double percent = v > 1 ? (v / 100.0) : v.toDouble();
      return percent.clamp(0.0, 1.0);
    }
    return 0.0;
  }

  String _stringArg(Map<String, dynamic> args, String key, {String fallback = ''}) {
    final v = args[key];
    if (v == null) return fallback;
    return v.toString();
  }

  List<String> _productsArg(Map<String, dynamic> args) {
    final v = args['recommended_products'];
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    return const [];
  }

  List<Map<String, dynamic>> _predictionsArg(Map<String, dynamic> args) {
    final v = args['predictions'];
    if (v is! List) return const <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    for (final item in v) {
      if (item is Map) {
        out.add(item.map((k, val) => MapEntry(k.toString(), val)));
      }
    }
    return out;
  }

  String _formatProb(dynamic v) {
    if (v is num) {
      final double p = v.toDouble();
      return '${(p.clamp(0.0, 1.0) * 100).round()}%';
    }
    return '';
  }

  Future<void> _saveToHistory(Map<String, dynamic> args) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(ResultScreen.historyPrefsKey);
    List<dynamic> list = [];
    if (existing != null && existing.isNotEmpty) {
      try {
        final decoded = jsonDecode(existing);
        if (decoded is List) list = List<dynamic>.from(decoded);
      } catch (_) {}
    }
    final entry = <String, dynamic>{
      'savedAt': DateTime.now().toIso8601String(),
      'imagePath': _stringArg(args, 'imagePath'),
      'disease': _stringArg(args, 'disease', fallback: 'Unknown'),
      'confidence': _confidenceArg(args),
      'is_healthy': _boolArg(args, 'is_healthy'),
      'low_confidence_warning': _boolArg(args, 'low_confidence_warning'),
      'plant_profile_id': _stringArg(args, 'plant_profile_id'),
      'plant_profile_name': _stringArg(args, 'plant_profile_name'),
      'crop_type': _stringArg(args, 'crop_type'),
      'description': _stringArg(args, 'description'),
      'immediate_action': _stringArg(args, 'immediate_action'),
      'preventive_measures': _stringArg(args, 'preventive_measures'),
      'recommended_products': _productsArg(args),
    };
    list.insert(0, entry);
    await prefs.setString(ResultScreen.historyPrefsKey, jsonEncode(list));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Saved to history',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: _darkGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareResult(Map<String, dynamic> args) async {
    final disease = _stringArg(args, 'disease', fallback: 'Unknown');
    final confidence = _confidenceArg(args);
    final immediate = _stringArg(args, 'immediate_action');
    final percent = confidence > 1.0 ? confidence / 100 : confidence;
    final safePercent = percent.clamp(0.0, 1.0);
    final text =
        'PlantDoc result\n\n'
        'Condition: $disease\n'
        'Confidence: ${(safePercent * 100).round()}%\n\n'
        'Immediate action:\n$immediate';
    await SharePlus.instance.share(
      ShareParams(text: text, subject: 'Plant scan: $disease'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = _argsOf(context);
    final imagePath = _stringArg(args, 'imagePath');
    final disease = _stringArg(args, 'disease', fallback: 'Unknown');
    final confidence = _confidenceArg(args);
    final percent = confidence > 1.0 ? confidence / 100 : confidence;
    final safePercent = percent.clamp(0.0, 1.0);
    final isHealthy = _boolArg(args, 'is_healthy');
    final lowConfidence = _boolArg(args, 'low_confidence_warning');
    final description = _stringArg(
      args,
      'description',
      fallback: 'No description available.',
    );
    final immediateAction = _stringArg(
      args,
      'immediate_action',
      fallback: 'No immediate action listed.',
    );
    final preventive = _stringArg(
      args,
      'preventive_measures',
      fallback: 'No preventive measures listed.',
    );
    final products = _productsArg(args);
    final productsBody = products.isEmpty
        ? 'No specific products listed.'
        : products.map((p) => '• $p').join('\n');
    final predictions = _predictionsArg(args);

    File? displayImage;
    if (imagePath.isNotEmpty) {
      final f = File(imagePath);
      if (f.existsSync()) displayImage = f;
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _creamBg,
          appBar: AppBar(
            backgroundColor: _darkGreen,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Scan result',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Leaf image card
                Container(
                  height: 220,
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: displayImage != null
                        ? Image.file(
                            displayImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 220,
                          )
                        : Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Disease name + badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        disease,
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _darkGreen,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _HealthBadge(isHealthy: isHealthy),
                  ],
                ),
                const SizedBox(height: 16),

                if (lowConfidence) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFC107).withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Colors.amber.shade800,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Low confidence detection — retake in better lighting',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.brown.shade800,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Center(
                  child: CircularPercentIndicator(
                    radius: 72,
                    lineWidth: 12,
                    percent: safePercent,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(safePercent * 100).round()}%',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _darkGreen,
                          ),
                        ),
                        Text(
                          'confidence',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _darkGreen.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    progressColor: _accentOrange,
                    backgroundColor: _darkGreen.withValues(alpha: 0.12),
                    circularStrokeCap: CircularStrokeCap.round,
                    animation: true,
                    animationDuration: 1200,
                    animateFromLastPercent: true,
                  ),
                ),
                const SizedBox(height: 28),

                if (predictions.isNotEmpty) ...[
                  _ExpandableInfoCard(
                    title: 'Top Predictions',
                    body: predictions
                        .take(5)
                        .map((m) {
                          final String label = (m['label'] ?? '').toString();
                          final String prob = _formatProb(m['probability']);
                          return prob.isEmpty ? label : '$label — $prob';
                        })
                        .where((s) => s.trim().isNotEmpty)
                        .map((s) => '• $s')
                        .join('\n'),
                    darkGreen: _darkGreen,
                  ),
                ],

                _ExpandableInfoCard(
                  title: 'Description',
                  body: description,
                  darkGreen: _darkGreen,
                ),
                _ExpandableInfoCard(
                  title: 'Immediate Action',
                  body: immediateAction,
                  darkGreen: _darkGreen,
                ),
                _ExpandableInfoCard(
                  title: 'Preventive Measures',
                  body: preventive,
                  darkGreen: _darkGreen,
                ),
                _ExpandableInfoCard(
                  title: 'Recommended Products',
                  body: productsBody,
                  darkGreen: _darkGreen,
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _saveToHistory(args),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _darkGreen,
                          side: const BorderSide(color: _darkGreen, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save to History',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _shareResult(args),
                        style: FilledButton.styleFrom(
                          backgroundColor: _accentOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Share Result',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.06,
                numberOfParticles: 28,
                maxBlastForce: 18,
                minBlastForce: 7,
                gravity: 0.12,
                shouldLoop: false,
                colors: const [
                  Color(0xFF2D6A4F),
                  Color(0xFFF4A261),
                  Color(0xFF95D5B2),
                  Color(0xFFFFFFFF),
                  Color(0xFFFFD166),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.isHealthy});

  final bool isHealthy;

  static const Color _healthyGreen = Color(0xFF2D6A4F);
  static const Color _accentOrange = Color(0xFFF4A261);

  @override
  Widget build(BuildContext context) {
    if (isHealthy) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _healthyGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _healthyGreen.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: _healthyGreen, size: 20),
            const SizedBox(width: 4),
            Text(
              'Healthy',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _healthyGreen,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _accentOrange.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC97C3A).withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: _accentOrange, size: 20),
          const SizedBox(width: 4),
          Text(
            'Issue',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFC97C3A),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableInfoCard extends StatefulWidget {
  const _ExpandableInfoCard({
    required this.title,
    required this.body,
    required this.darkGreen,
  });

  final String title;
  final String body;
  final Color darkGreen;

  @override
  State<_ExpandableInfoCard> createState() => _ExpandableInfoCardState();
}

class _ExpandableInfoCardState extends State<_ExpandableInfoCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: widget.darkGreen,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: widget.darkGreen,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      widget.body,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.45,
                        color: widget.darkGreen.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
