import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/plant_batch.dart';
import '../services/plant_batch_database.dart';
import '../services/plant_reminder_service.dart';

class PlantBatchProvider extends ChangeNotifier {
  PlantBatchProvider({
    PlantBatchDatabase? database,
    PlantReminderService? reminderService,
  })  : _database = database ?? PlantBatchDatabase.instance,
        _reminderService = reminderService ?? PlantReminderService.instance;

  final PlantBatchDatabase _database;
  final PlantReminderService _reminderService;
  final _uuid = const Uuid();

  List<PlantBatch> _batches = [];
  bool _loading = true;
  String? _error;

  List<PlantBatch> get batches => List.unmodifiable(_batches);
  bool get loading => _loading;
  bool get isEmpty => _batches.isEmpty;
  String? get error => _error;

  Future<void> loadBatches() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _batches = await _database.getAllBatches();
    } catch (e) {
      _error = 'Could not load plant batches';
      debugPrint('PlantBatchProvider.loadBatches: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<PlantBatch?> getBatch(String id) => _database.getBatch(id);

  Future<List<BatchTimelineEvent>> getTimeline(String batchId) async {
    final batch = await _database.getBatch(batchId);
    if (batch == null) return [];
    return _database.getTimelineEvents(batch);
  }

  Future<PlantBatch?> createBatch({
    required String name,
    required String plantType,
    required DateTime plantedDate,
  }) async {
    final now = DateTime.now();
    final batch = PlantBatch(
      id: _uuid.v4(),
      name: name.trim(),
      plantType: plantType.trim(),
      plantedDate: plantedDate,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _database.insertBatch(batch);
      await _reminderService.scheduleForBatch(batch);
      _batches = await _database.getAllBatches();
      notifyListeners();
      return batch;
    } catch (e) {
      debugPrint('PlantBatchProvider.createBatch: $e');
      _error = 'Could not save batch';
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateBatch({
    required String id,
    required String name,
    required String plantType,
    required DateTime plantedDate,
  }) async {
    final existing = await _database.getBatch(id);
    if (existing == null) return false;

    final updated = existing.copyWith(
      name: name.trim(),
      plantType: plantType.trim(),
      plantedDate: plantedDate,
      updatedAt: DateTime.now(),
    );

    try {
      await _database.updateBatch(updated);
      await _reminderService.scheduleForBatch(updated);
      _batches = await _database.getAllBatches();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('PlantBatchProvider.updateBatch: $e');
      return false;
    }
  }

  Future<bool> deleteBatch(String id) async {
    final existing = await _database.getBatch(id);
    if (existing == null) return false;

    try {
      await _reminderService.cancelForBatch(existing);
      await _database.deleteBatch(id);
      _batches = await _database.getAllBatches();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('PlantBatchProvider.deleteBatch: $e');
      return false;
    }
  }

  Future<void> recordScan(String batchId, {String? note}) async {
    await _database.addScanEvent(
      batchId: batchId,
      occurredAt: DateTime.now(),
      note: note ?? 'Manual scan started',
    );
    notifyListeners();
  }
}
