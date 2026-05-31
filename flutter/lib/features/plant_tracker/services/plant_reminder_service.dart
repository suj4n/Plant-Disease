import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/plant_batch.dart';
import 'plant_batch_database.dart';

/// Schedules bi-weekly scan reminders via flutter_local_notifications.
class PlantReminderService {
  PlantReminderService._();
  static final PlantReminderService instance = PlantReminderService._();

  static const _channelId = 'plant_scan_reminders';
  static const _channelName = 'Plant scan reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('PlantReminderService: timezone fallback UTC ($e)');
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Reminders to scan plants for diseases',
        importance: Importance.high,
      ),
    );

    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleForBatch(PlantBatch batch) async {
    await initialize();
    await cancelForBatch(batch);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Reminders to scan plants for diseases',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    );

    var reminder = batch.nextReminderDate;
    final end = DateTime.now().add(const Duration(days: 365));
    var scheduled = 0;

    while (reminder.isBefore(end) && scheduled < 26) {
      await _plugin.zonedSchedule(
        batch.notificationId + scheduled,
        'PlantDoc — ${batch.name}',
        PlantTrackerConstants.reminderNotificationBody,
        tz.TZDateTime.from(reminder, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: batch.id,
      );
      reminder = reminder.add(
        const Duration(days: PlantBatch.reminderIntervalDays),
      );
      scheduled++;
    }
  }

  Future<void> cancelForBatch(PlantBatch batch) async {
    await initialize();
    for (var i = 0; i < 26; i++) {
      await _plugin.cancel(batch.notificationId + i);
    }
  }

  Future<void> rescheduleAll() async {
    await initialize();
    final batches = await PlantBatchDatabase.instance.getAllBatches();
    for (final batch in batches) {
      await scheduleForBatch(batch);
    }
  }
}
