import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../main.dart';
import 'result_screen.dart';
import 'scan_screen.dart';

class PlantTrackerScreen extends StatefulWidget {
  const PlantTrackerScreen({super.key});

  static const String routeName = '/plant_tracker';
  static const String profilesPrefsKey = 'plantdoc_plant_profiles';

  @override
  State<PlantTrackerScreen> createState() => _PlantTrackerScreenState();
}

class _PlantTrackerScreenState extends State<PlantTrackerScreen> {
  static const Color _creamBg = Color(0xFFF5F0E8);
  static const Color _darkGreen = Color(0xFF1B4332);
  static const Color _accentOrange = Color(0xFFF4A261);
  static const Color _healthyGreen = Color(0xFF2D6A4F);

  static const List<String> _cropTypes = <String>[
    'Tomato',
    'Potato',
    'Apple',
    'Grape',
    'Rice',
    'Corn',
    'Pepper',
    'Cherry',
    'Peach',
    'Strawberry',
  ];

  bool _loading = true;
  List<Map<String, dynamic>> _profiles = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    // No persistent controller/listener on this screen currently.
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _loading = true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(PlantTrackerScreen.profilesPrefsKey);
    final List<Map<String, dynamic>> parsed = <Map<String, dynamic>>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final dynamic item in decoded) {
            if (item is Map) {
              parsed.add(
                item.map((dynamic k, dynamic v) => MapEntry(k.toString(), v)),
              );
            }
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _profiles = parsed;
      _loading = false;
    });
  }

  Future<void> _persistProfiles() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PlantTrackerScreen.profilesPrefsKey,
      jsonEncode(_profiles),
    );
  }

  Future<void> _openCreateProfileSheet() async {
    final TextEditingController nameController = TextEditingController();
    String crop = _cropTypes.first;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, void Function(void Function()) setSheetState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Create plant profile',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _darkGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.poppins(color: _darkGreen),
                      decoration: InputDecoration(
                        labelText: 'Plant name',
                        labelStyle: GoogleFonts.poppins(color: _darkGreen.withValues(alpha: 0.7)),
                        filled: true,
                        fillColor: _creamBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: crop,
                      decoration: InputDecoration(
                        labelText: 'Crop type',
                        labelStyle: GoogleFonts.poppins(color: _darkGreen.withValues(alpha: 0.7)),
                        filled: true,
                        fillColor: _creamBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _cropTypes
                          .map(
                            (String v) => DropdownMenuItem<String>(
                              value: v,
                              child: Text(v, style: GoogleFonts.poppins()),
                            ),
                          )
                          .toList(),
                      onChanged: (String? v) {
                        if (v == null) return;
                        setSheetState(() => crop = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _darkGreen,
                              side: const BorderSide(color: _darkGreen, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final String name = nameController.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please enter a plant name', style: GoogleFonts.poppins()),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              final Map<String, dynamic> profile = <String, dynamic>{
                                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                                'name': name,
                                'crop_type': crop,
                                'createdAt': DateTime.now().toIso8601String(),
                                'reminder_days': null,
                              };

                              setState(() {
                                _profiles.insert(0, profile);
                              });
                              Navigator.pop(context);
                              await _persistProfiles();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: _accentOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Create', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: _creamBg,
        appBar: AppBar(
          backgroundColor: _darkGreen,
          foregroundColor: Colors.white,
          title: Text(
            'Plant Tracker',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: _accentOrange,
          foregroundColor: Colors.white,
          onPressed: _openCreateProfileSheet,
          child: const Icon(Icons.add_rounded),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _profiles.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.local_florist_rounded, size: 72, color: _healthyGreen.withValues(alpha: 0.75)),
                          const SizedBox(height: 14),
                          Text(
                            'No plant profiles yet.\nTap + to add your first plant.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _darkGreen.withValues(alpha: 0.75),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: _accentOrange,
                    onRefresh: _loadProfiles,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: _profiles.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> profile = _profiles[index];
                        final String name = (profile['name'] ?? 'Unnamed plant').toString();
                        final String crop = (profile['crop_type'] ?? 'Unknown crop').toString();

                        return InkWell(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PlantDetailScreen(profile: profile),
                              ),
                            );
                            await _loadProfiles();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _healthyGreen.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.eco_rounded, color: _healthyGreen.withValues(alpha: 0.9)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: _darkGreen,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        crop,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: _darkGreen.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: _darkGreen.withValues(alpha: 0.6)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      );
    } catch (e, stackTrace) {
      debugPrint('PlantTrackerScreen build failed: $e');
      debugPrint('$stackTrace');
      return Scaffold(
        backgroundColor: _creamBg,
        appBar: AppBar(
          backgroundColor: _darkGreen,
          foregroundColor: Colors.white,
          title: Text('Plant Tracker', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Something went wrong while loading Plant Tracker.\nPlease go back and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: _darkGreen.withValues(alpha: 0.8)),
            ),
          ),
        ),
      );
    }
  }
}

class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({super.key, required this.profile});

  final Map<String, dynamic> profile;

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  static const Color _creamBg = Color(0xFFF5F0E8);
  static const Color _darkGreen = Color(0xFF1B4332);
  static const Color _accentOrange = Color(0xFFF4A261);
  static const Color _healthyGreen = Color(0xFF2D6A4F);

  final FlutterLocalNotificationsPlugin _notifications = notificationsPlugin;
  final TextEditingController _remindEveryDaysController = TextEditingController();

  bool _loading = true;
  List<Map<String, dynamic>> _scans = <Map<String, dynamic>>[];

  String get _profileId => (widget.profile['id'] ?? '').toString();
  String get _plantName => (widget.profile['name'] ?? 'My plant').toString();

  @override
  void initState() {
    super.initState();
    final dynamic reminderDays = widget.profile['reminder_days'];
    if (reminderDays is int) {
      _remindEveryDaysController.text = reminderDays.toString();
    } else if (reminderDays is String && reminderDays.isNotEmpty) {
      _remindEveryDaysController.text = reminderDays;
    }
    _loadScans();
  }

  @override
  void dispose() {
    _remindEveryDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadScans() async {
    setState(() => _loading = true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(ResultScreen.historyPrefsKey);
    final List<Map<String, dynamic>> parsed = <Map<String, dynamic>>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final dynamic item in decoded) {
            if (item is Map) {
              final Map<String, dynamic> m =
                  item.map((dynamic k, dynamic v) => MapEntry(k.toString(), v));
              if ((m['plant_profile_id'] ?? '').toString() == _profileId) {
                parsed.add(m);
              }
            }
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _scans = parsed;
      _loading = false;
    });
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  String _summaryLastScanned() {
    if (_scans.isEmpty) return 'Last scanned: Never';
    final DateTime? dt = _parseDate((_scans.first['savedAt'] ?? '').toString());
    if (dt == null) return 'Last scanned: Unknown';
    final int days = DateTime.now().difference(dt).inDays;
    if (days <= 0) return 'Last scanned: Today';
    if (days == 1) return 'Last scanned: 1 day ago';
    return 'Last scanned: $days days ago';
  }

  String _summaryStatus() {
    if (_scans.isEmpty) return 'Status: Unknown';
    final bool healthy = _scans.first['is_healthy'] == true;
    return healthy ? 'Status: Healthy' : 'Status: Diseased';
  }

  double _confidenceAsPercent(dynamic rawConfidence) {
    if (rawConfidence is double) return rawConfidence <= 1.0 ? rawConfidence * 100 : rawConfidence;
    if (rawConfidence is int) return rawConfidence <= 1 ? rawConfidence * 100.0 : rawConfidence * 1.0;
    return 0;
  }

  String _formatDate(dynamic rawDate) {
    final String s = (rawDate ?? '').toString();
    final DateTime? dt = _parseDate(s);
    if (dt == null) return 'Unknown time';
    return DateFormat('MMM d, y').add_jm().format(dt.toLocal());
  }

  int _notificationBaseId() {
    final int idHash = _profileId.hashCode.abs();
    return (idHash % 200000) + 1000;
  }

  Future<void> _cancelReminderSeries() async {
    final int base = _notificationBaseId();
    for (int i = 0; i < 30; i++) {
      await _notifications.cancel(id: base + i);
    }
  }

  Future<void> _scheduleReminderSeries({required int everyDays}) async {
    await _cancelReminderSeries();
    final int base = _notificationBaseId();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'plantdoc_scan_reminders',
      'Plant scan reminders',
      channelDescription: 'Reminds you to scan your plants in PlantDoc',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    final NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Best-effort repeating: schedule the next 30 occurrences (spaced by X days).
    final DateTime now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final DateTime when = now.add(Duration(days: everyDays * (i + 1)));
      await _notifications.zonedSchedule(
        id: base + i,
        title: 'Time to check your $_plantName!',
        body: 'Open PlantDoc and scan your plant to track its health.',
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> _saveReminderDays() async {
    final String raw = _remindEveryDaysController.text.trim();
    final int? days = int.tryParse(raw);
    if (days == null || days < 1 || days > 30) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter a number between 1 and 30', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _scheduleReminderSeries(everyDays: days);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? rawProfiles = prefs.getString(PlantTrackerScreen.profilesPrefsKey);
    if (rawProfiles == null || rawProfiles.isEmpty) return;

    try {
      final dynamic decoded = jsonDecode(rawProfiles);
      if (decoded is! List) return;
      final List<Map<String, dynamic>> list = <Map<String, dynamic>>[];
      for (final dynamic item in decoded) {
        if (item is Map) {
          final Map<String, dynamic> m = item.map((dynamic k, dynamic v) => MapEntry(k.toString(), v));
          if ((m['id'] ?? '').toString() == _profileId) {
            m['reminder_days'] = days;
          }
          list.add(m);
        }
      }
      await prefs.setString(PlantTrackerScreen.profilesPrefsKey, jsonEncode(list));
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder set: every $days day(s)', style: GoogleFonts.poppins()),
        backgroundColor: _darkGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _creamBg,
      appBar: AppBar(
        backgroundColor: _darkGreen,
        foregroundColor: Colors.white,
        title: Text(_plantName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: _accentOrange,
        onRefresh: _loadScans,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    _summaryLastScanned(),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _darkGreen),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _summaryStatus(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: _scans.isNotEmpty && _scans.first['is_healthy'] == true ? _healthyGreen : _accentOrange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        ScanScreen.routeName,
                        arguments: <String, dynamic>{
                          'plant_profile_id': _profileId,
                          'plant_profile_name': _plantName,
                          'crop_type': (widget.profile['crop_type'] ?? '').toString(),
                        },
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Scan This Plant Now', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Scan Reminder',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _darkGreen),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _remindEveryDaysController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(color: _darkGreen),
                          decoration: InputDecoration(
                            hintText: '1-30',
                            hintStyle: GoogleFonts.poppins(color: _darkGreen.withValues(alpha: 0.55)),
                            filled: true,
                            fillColor: _creamBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _saveReminderDays,
                        style: FilledButton.styleFrom(
                          backgroundColor: _darkGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Save', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Remind me every X days (1-30).',
                    style: GoogleFonts.poppins(fontSize: 12, color: _darkGreen.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Timeline',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _darkGreen),
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_scans.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(Icons.timeline_rounded, size: 44, color: _darkGreen.withValues(alpha: 0.6)),
                    const SizedBox(height: 10),
                    Text(
                      'No scans linked to this plant yet.\nTap “Scan This Plant Now” to start a timeline.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: _darkGreen.withValues(alpha: 0.7), height: 1.35),
                    ),
                  ],
                ),
              )
            else
              ..._scans.asMap().entries.map((entry) {
                final int idx = entry.key;
                final Map<String, dynamic> scan = entry.value;
                final bool isHealthy = scan['is_healthy'] == true;
                final String disease = (scan['disease'] ?? 'Unknown').toString();
                final double conf = _confidenceAsPercent(scan['confidence']);
                final String date = _formatDate(scan['savedAt']);
                final String imagePath = (scan['imagePath'] ?? '').toString();
                File? image;
                if (imagePath.isNotEmpty) {
                  final File f = File(imagePath);
                  if (f.existsSync()) image = f;
                }
                final bool last = idx == _scans.length - 1;

                return _TimelineNode(
                  dateText: date,
                  disease: disease,
                  confidenceText: '${conf.round()}%',
                  isHealthy: isHealthy,
                  thumbnail: image,
                  showConnectorBelow: !last,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      ResultScreen.routeName,
                      arguments: scan,
                    );
                  },
                  darkGreen: _darkGreen,
                  accentOrange: _accentOrange,
                  healthyGreen: _healthyGreen,
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.dateText,
    required this.disease,
    required this.confidenceText,
    required this.isHealthy,
    required this.thumbnail,
    required this.showConnectorBelow,
    required this.onTap,
    required this.darkGreen,
    required this.accentOrange,
    required this.healthyGreen,
  });

  final String dateText;
  final String disease;
  final String confidenceText;
  final bool isHealthy;
  final File? thumbnail;
  final bool showConnectorBelow;
  final VoidCallback onTap;
  final Color darkGreen;
  final Color accentOrange;
  final Color healthyGreen;

  @override
  Widget build(BuildContext context) {
    final Color dotColor = isHealthy ? healthyGreen : accentOrange;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 26,
              child: Column(
                children: <Widget>[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                  ),
                  if (showConnectorBelow)
                    Container(
                      width: 2,
                      height: 90,
                      margin: const EdgeInsets.only(top: 2),
                      color: darkGreen.withValues(alpha: 0.18),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: thumbnail != null
                            ? Image.file(thumbnail!, fit: BoxFit.cover)
                            : Container(
                                color: healthyGreen.withValues(alpha: 0.16),
                                child: Icon(Icons.eco_rounded, color: healthyGreen.withValues(alpha: 0.9)),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            dateText,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: darkGreen.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            disease,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: darkGreen,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Confidence: $confidenceText',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: darkGreen.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
