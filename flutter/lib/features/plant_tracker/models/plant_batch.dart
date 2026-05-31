import 'package:intl/intl.dart';

/// A locally tracked planting batch with reminder scheduling metadata.
class PlantBatch {
  const PlantBatch({
    required this.id,
    required this.name,
    required this.plantType,
    required this.plantedDate,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String plantType;
  final DateTime plantedDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  static const int reminderIntervalDays = 14;

  /// First scan reminder is 2 weeks after planting; then every 2 weeks.
  DateTime get firstReminderDate =>
      plantedDate.add(const Duration(days: reminderIntervalDays));

  DateTime get nextReminderDate => _computeNextReminder(DateTime.now());

  int get daysSincePlanted {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final planted =
        DateTime(plantedDate.year, plantedDate.month, plantedDate.day);
    return today.difference(planted).inDays;
  }

  int get daysUntilNextReminder {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next = DateTime(
      nextReminderDate.year,
      nextReminderDate.month,
      nextReminderDate.day,
    );
    return next.difference(today).inDays;
  }

  bool get isReminderDueToday => daysUntilNextReminder == 0;

  bool get isReminderDueSoon =>
      daysUntilNextReminder >= 0 && daysUntilNextReminder <= 3;

  String get nextReminderSummary {
    if (isReminderDueToday) return 'Scan due today';
    if (daysUntilNextReminder == 1) return 'Scan due tomorrow';
    if (daysUntilNextReminder < 0) return 'Scan overdue';
    return 'Scan in $daysUntilNextReminder days';
  }

  DateTime _computeNextReminder(DateTime reference) {
    var candidate = firstReminderDate;
    if (candidate.isAfter(reference)) return candidate;
    while (!candidate.isAfter(reference)) {
      candidate = candidate.add(const Duration(days: reminderIntervalDays));
    }
    return candidate;
  }

  /// Stable notification id derived from batch uuid (fits 32-bit int).
  int get notificationId => id.hashCode.abs() % 2147483647;

  PlantBatch copyWith({
    String? name,
    String? plantType,
    DateTime? plantedDate,
    DateTime? updatedAt,
  }) {
    return PlantBatch(
      id: id,
      name: name ?? this.name,
      plantType: plantType ?? this.plantType,
      plantedDate: plantedDate ?? this.plantedDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'plant_type': plantType,
        'planted_date': plantedDate.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': (updatedAt ?? createdAt).toIso8601String(),
      };

  factory PlantBatch.fromMap(Map<String, dynamic> map) {
    return PlantBatch(
      id: map['id'] as String,
      name: map['name'] as String,
      plantType: map['plant_type'] as String,
      plantedDate: DateTime.parse(map['planted_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  String get plantedDateLabel => DateFormat.yMMMd().format(plantedDate);

  String get nextReminderLabel => DateFormat.yMMMd().format(nextReminderDate);
}

abstract final class PlantTrackerConstants {
  static const reminderNotificationBody =
      'Time to scan your plants for possible diseases';
}

/// Timeline entry for batch detail (planted, scan, reminder).
enum BatchTimelineType { planted, scan, reminder }

class BatchTimelineEvent {
  const BatchTimelineEvent({
    required this.type,
    required this.occurredAt,
    this.title,
    this.subtitle,
  });

  final BatchTimelineType type;
  final DateTime occurredAt;
  final String? title;
  final String? subtitle;

  String get typeLabel => switch (type) {
        BatchTimelineType.planted => 'Planted',
        BatchTimelineType.scan => 'Disease scan',
        BatchTimelineType.reminder => 'Scan reminder',
      };
}
