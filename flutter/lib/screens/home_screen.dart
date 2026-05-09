import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'history_screen.dart';
import 'plant_tracker_screen.dart';
import 'result_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _creamBg = Color(0xFFF5F0E8);
  static const Color _darkGreen = Color(0xFF1B4332);
  static const Color _orange = Color(0xFFF4A261);
  static const Color _subtitleCream = Color(0xFFF5F0E8);

  int _totalScans = 0;
  int _healthyPlants = 0;
  List<String> _scanHistory = [];
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  // FIX 1: Dynamic greeting based on time
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌱';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(ResultScreen.historyPrefsKey);

    final List<Map<String, dynamic>> parsed = <Map<String, dynamic>>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final dynamic item in decoded) {
            if (item is Map) {
              parsed.add(item.map((dynamic k, dynamic v) => MapEntry(k.toString(), v)));
            }
          }
        }
      } catch (_) {
        // Ignore malformed cached history.
      }
    }

    final int total = parsed.length;
    final int healthy = parsed.where((m) => m['is_healthy'] == true).length;
    final List<String> recent = parsed
        .take(10)
        .map((m) => (m['disease'] ?? 'Unknown').toString())
        .where((s) => s.trim().isNotEmpty)
        .toList();

    if (!mounted) return;
    setState(() {
      _totalScans = total;
      _healthyPlants = healthy;
      _scanHistory = recent;
    });
  }

  Future<void> _onNavItemTapped(int index) async {
    setState(() => _navIndex = index);
    if (index == 0) return;

    String route;
    switch (index) {
      case 1:
        route = ScanScreen.routeName;
        break;
      case 2:
        route = PlantTrackerScreen.routeName;
        break;
      case 3:
        route = HistoryScreen.routeName;
        break;
      default:
        return;
    }

    await Navigator.pushNamed<void>(context, route);
    if (mounted) {
      setState(() => _navIndex = 0);
      _loadPrefs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final headerHeight = size.height * 0.35;

    return Scaffold(
      backgroundColor: _creamBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: headerHeight,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x331B4332),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FIX 1: Dynamic greeting
                      Text(
                        _getGreeting(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'PlantDoc',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _HeaderStatCard(
                                label: 'Total Scans',
                                value: _totalScans,
                                icon: Icons.document_scanner_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _HeaderStatCard(
                                label: 'Healthy Plants',
                                value: _healthyPlants,
                                icon: Icons.favorite_outline_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: _darkGreen,
                    elevation: 8,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(
                        context,
                        ScanScreen.routeName,
                      ).then((_) => _loadPrefs()),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 28,
                          horizontal: 24,
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _orange.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.eco,
                                size: 48,
                                color: _orange,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Scan a Leaf',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Take or upload a photo to detect disease',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _subtitleCream,
                                height: 1.35,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Recent Scans',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _darkGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_scanHistory.isEmpty)
                    const _RecentScansEmptyState()
                  else
                    ..._scanHistory
                        .take(5)
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: Colors.white,
                              elevation: 2,
                              shadowColor: Colors.black12,
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                leading: Icon(
                                  Icons.eco_outlined,
                                  color: _darkGreen.withValues(alpha: 0.7),
                                ),
                                title: Text(
                                  entry,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: _darkGreen,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
      // FIX 2: Orange active nav item
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: _navIndex == 0,
                  onTap: () => _onNavItemTapped(0),
                ),
                _NavItem(
                  icon: Icons.camera_alt_rounded,
                  label: 'Scan',
                  selected: _navIndex == 1,
                  onTap: () => _onNavItemTapped(1),
                ),
                _NavItem(
                  icon: Icons.local_florist_rounded,
                  label: 'Plants',
                  selected: _navIndex == 2,
                  onTap: () => _onNavItemTapped(2),
                ),
                _NavItem(
                  icon: Icons.history_rounded,
                  label: 'History',
                  selected: _navIndex == 3,
                  onTap: () => _onNavItemTapped(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// FIX 3: Better stat cards with icon
class _HeaderStatCard extends StatelessWidget {
  const _HeaderStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A4F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFF4A261), size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentScansEmptyState extends StatelessWidget {
  const _RecentScansEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1B4332).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.eco_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No scans yet. Start by scanning a leaf!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  // FIX 2: Orange when active
  static const Color _active = Color(0xFFF4A261);

  @override
  Widget build(BuildContext context) {
    final color = selected ? _active : Colors.grey.shade500;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
