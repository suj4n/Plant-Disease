import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static const String routeName = '/history';

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color _creamBg = Color(0xFFF5F0E8);
  static const Color _darkGreen = Color(0xFF1B4332);
  static const Color _accentOrange = Color(0xFFF4A261);
  static const Color _healthyGreen = Color(0xFF2D6A4F);

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allScans = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _visibleScans = <Map<String, dynamic>>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? rawJson = prefs.getString(ResultScreen.historyPrefsKey);
    final List<Map<String, dynamic>> parsed = <Map<String, dynamic>>[];

    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(rawJson);
        if (decoded is List) {
          for (final dynamic item in decoded) {
            if (item is Map) {
              parsed.add(
                item.map((dynamic k, dynamic v) => MapEntry(k.toString(), v)),
              );
            }
          }
        }
      } catch (_) {
        // Ignore invalid cached payload and show empty state.
      }
    }

    if (!mounted) return;
    setState(() {
      _allScans = parsed;
      _isLoading = false;
    });
    _applyFilter();
  }

  void _applyFilter() {
    final String query = _searchController.text.trim().toLowerCase();
    final List<Map<String, dynamic>> filtered = _allScans.where((scan) {
      final String disease = (scan['disease'] ?? '').toString().toLowerCase();
      return query.isEmpty || disease.contains(query);
    }).toList();

    if (!mounted) return;
    setState(() => _visibleScans = filtered);
  }

  Future<void> _persistHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      ResultScreen.historyPrefsKey,
      jsonEncode(_allScans),
    );
  }

  Future<void> _deleteScan(Map<String, dynamic> scan) async {
    setState(() {
      _allScans.remove(scan);
    });
    _applyFilter();
    await _persistHistory();
  }

  double _confidenceAsPercent(dynamic rawConfidence) {
    if (rawConfidence is double) {
      return rawConfidence <= 1.0 ? rawConfidence * 100 : rawConfidence;
    }
    if (rawConfidence is int) {
      return rawConfidence <= 1 ? rawConfidence * 100.0 : rawConfidence * 1.0;
    }
    return 0;
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate is! String || rawDate.isEmpty) {
      return 'Unknown time';
    }
    try {
      final DateTime dateTime = DateTime.parse(rawDate).toLocal();
      return DateFormat('MMM d, y • h:mm a').format(dateTime);
    } catch (_) {
      return 'Unknown time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _creamBg,
      appBar: AppBar(
        backgroundColor: _darkGreen,
        foregroundColor: Colors.white,
        title: Text(
          'Scan History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(color: _darkGreen),
              decoration: InputDecoration(
                hintText: 'Search disease name...',
                hintStyle: GoogleFonts.poppins(color: _darkGreen.withValues(alpha: 0.55)),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: _accentOrange,
              onRefresh: _loadHistory,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _visibleScans.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: <Widget>[
                        const SizedBox(height: 120),
                        Icon(Icons.eco_rounded, size: 72, color: _healthyGreen.withValues(alpha: 0.75)),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'No scans yet. Start by scanning a plant!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _darkGreen.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _visibleScans.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> scan = _visibleScans[index];
                        final String disease = (scan['disease'] ?? 'Unknown').toString();
                        final double confidence = _confidenceAsPercent(scan['confidence']);
                        final String dateText = _formatDate(scan['savedAt']);
                        final bool isHealthy = scan['is_healthy'] == true;
                        final String imagePath = (scan['imagePath'] ?? '').toString();
                        final File imageFile = File(imagePath);
                        final bool hasImage = imagePath.isNotEmpty && imageFile.existsSync();

                        return Dismissible(
                          key: ValueKey<String>(
                            '${scan['savedAt']}_${scan['imagePath']}_$index',
                          ),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                          ),
                          onDismissed: (_) => _deleteScan(scan),
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                ResultScreen.routeName,
                                arguments: scan,
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: <Widget>[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 68,
                                      height: 68,
                                      child: hasImage
                                          ? Image.file(imageFile, fit: BoxFit.cover)
                                          : Container(
                                              color: _healthyGreen.withValues(alpha: 0.18),
                                              child: Icon(
                                                Icons.eco_rounded,
                                                color: _healthyGreen.withValues(alpha: 0.9),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                disease,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: _darkGreen,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isHealthy ? _healthyGreen : _accentOrange,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Confidence: ${confidence.round()}%',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: _darkGreen.withValues(alpha: 0.8),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateText,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: _darkGreen.withValues(alpha: 0.65),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
