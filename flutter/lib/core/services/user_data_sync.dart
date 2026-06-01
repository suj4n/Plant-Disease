import '../../features/plant_tracker/services/plant_batch_database.dart';
import 'scan_storage.dart';

/// Moves guest-only local data to Supabase after sign-in.
class UserDataSync {
  UserDataSync._();

  static Future<void> migrateGuestDataToCloud() async {
    await ScanStorage.migrateGuestDataToCloud();
    await PlantBatchDatabase.migrateGuestBatchesToCloud();
  }
}
