import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../core/services/supabase_service.dart';
import '../models/plant_batch.dart';

/// Plant batches: SQLite for guests, Supabase for signed-in users.
class PlantBatchDatabase {
  PlantBatchDatabase._();
  static final PlantBatchDatabase instance = PlantBatchDatabase._();

  static const _dbName = 'plant_tracker.db';
  static const _dbVersion = 1;

  Database? _db;

  bool get _useCloud => SupabaseService.isAuthenticated;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE plant_batches (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            plant_type TEXT NOT NULL,
            planted_date TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE batch_scan_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            batch_id TEXT NOT NULL,
            occurred_at TEXT NOT NULL,
            note TEXT,
            FOREIGN KEY (batch_id) REFERENCES plant_batches (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<List<PlantBatch>> getAllBatches() async {
    if (_useCloud) {
      final rows = await SupabaseService.getPlantBatches();
      return rows.map(PlantBatch.fromMap).toList();
    }
    final db = await database;
    final rows = await db.query(
      'plant_batches',
      orderBy: 'planted_date DESC',
    );
    return rows.map(PlantBatch.fromMap).toList();
  }

  Future<PlantBatch?> getBatch(String id) async {
    if (_useCloud) {
      final row = await SupabaseService.getPlantBatch(id);
      if (row == null) return null;
      return PlantBatch.fromMap(row);
    }
    final db = await database;
    final rows = await db.query(
      'plant_batches',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PlantBatch.fromMap(rows.first);
  }

  Future<void> insertBatch(PlantBatch batch) async {
    if (_useCloud) {
      await SupabaseService.insertPlantBatch(batch.toMap());
      return;
    }
    final db = await database;
    await db.insert('plant_batches', batch.toMap());
  }

  Future<void> updateBatch(PlantBatch batch) async {
    if (_useCloud) {
      await SupabaseService.updatePlantBatch(batch.toMap());
      return;
    }
    final db = await database;
    await db.update(
      'plant_batches',
      batch.toMap(),
      where: 'id = ?',
      whereArgs: [batch.id],
    );
  }

  Future<void> deleteBatch(String id) async {
    if (_useCloud) {
      await SupabaseService.deletePlantBatch(id);
      return;
    }
    final db = await database;
    await db.delete('batch_scan_events', where: 'batch_id = ?', whereArgs: [id]);
    await db.delete('plant_batches', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addScanEvent({
    required String batchId,
    required DateTime occurredAt,
    String? note,
  }) async {
    if (_useCloud) {
      await SupabaseService.addBatchScanEvent(
        batchId: batchId,
        occurredAt: occurredAt,
        note: note,
      );
      return;
    }
    final db = await database;
    await db.insert('batch_scan_events', {
      'batch_id': batchId,
      'occurred_at': occurredAt.toIso8601String(),
      'note': note,
    });
  }

  Future<List<BatchTimelineEvent>> getTimelineEvents(PlantBatch batch) async {
    final List<Map<String, dynamic>> scanRows;
    if (_useCloud) {
      scanRows = await SupabaseService.getBatchScanEvents(batch.id);
    } else {
      final db = await database;
      scanRows = await db.query(
        'batch_scan_events',
        where: 'batch_id = ?',
        whereArgs: [batch.id],
        orderBy: 'occurred_at DESC',
      );
    }

    final events = <BatchTimelineEvent>[
      BatchTimelineEvent(
        type: BatchTimelineType.planted,
        occurredAt: batch.plantedDate,
        title: 'Batch planted',
        subtitle: batch.name,
      ),
      ...scanRows.map(
        (row) => BatchTimelineEvent(
          type: BatchTimelineType.scan,
          occurredAt: DateTime.parse(row['occurred_at'] as String),
          title: row['note'] as String? ?? 'Manual scan',
          subtitle: 'Disease check recorded',
        ),
      ),
    ];

    final reminders = _reminderTimelineEvents(batch);
    events.addAll(reminders);
    events.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return events;
  }

  /// Copies guest SQLite batches to Supabase after sign-in.
  static Future<void> migrateGuestBatchesToCloud() async {
    if (!SupabaseService.isAuthenticated) return;

    final db = await instance.database;
    final rows = await db.query('plant_batches', orderBy: 'planted_date DESC');
    if (rows.isEmpty) return;

    for (final row in rows) {
      final batch = PlantBatch.fromMap(row);
      try {
        final existing = await SupabaseService.getPlantBatch(batch.id);
        if (existing == null) {
          await SupabaseService.insertPlantBatch(batch.toMap());
        }

        final eventRows = await db.query(
          'batch_scan_events',
          where: 'batch_id = ?',
          whereArgs: [batch.id],
        );
        for (final event in eventRows) {
          await SupabaseService.addBatchScanEvent(
            batchId: batch.id,
            occurredAt: DateTime.parse(event['occurred_at'] as String),
            note: event['note'] as String?,
          );
        }
      } catch (_) {}
    }

    await db.delete('batch_scan_events');
    await db.delete('plant_batches');
  }

  List<BatchTimelineEvent> _reminderTimelineEvents(PlantBatch batch) {
    final events = <BatchTimelineEvent>[];
    var reminder = batch.firstReminderDate;
    final horizon = DateTime.now().add(const Duration(days: 365));

    while (reminder.isBefore(horizon)) {
      final isPast = reminder.isBefore(DateTime.now());
      events.add(
        BatchTimelineEvent(
          type: BatchTimelineType.reminder,
          occurredAt: reminder,
          title: isPast ? 'Reminder sent' : 'Upcoming reminder',
          subtitle: PlantTrackerConstants.reminderNotificationBody,
        ),
      );
      reminder = reminder.add(
        const Duration(days: PlantBatch.reminderIntervalDays),
      );
    }
    return events;
  }
}
