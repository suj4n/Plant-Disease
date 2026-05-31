import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Main Supabase service for PlantDoc Flutter app
/// Handles database operations and authentication
class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static SupabaseClient get client => _client;
  static Session? get currentSession => _client.auth.currentSession;
  static User? get currentUser => _client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  // ==================== AUTH ====================

  static Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    if (response.user != null) {
      await _client.from('user_profiles').insert({
        'id': response.user!.id,
        'email': email,
        'full_name': fullName,
      }).catchError((_) => null);
    }

    return response;
  }

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> logout() async {
    await _client.auth.signOut();
  }

  static String? getAccessToken() {
    return _client.auth.currentSession?.accessToken;
  }

  // ==================== USER PROFILE ====================

  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isAuthenticated) return null;

    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();

      return response;
    } catch (_) {
      return null;
    }
  }

  static Future<void> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    if (!isAuthenticated) throw Exception('Not authenticated');

    await _client.from('user_profiles').update({
      'full_name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', currentUser!.id);
  }

  // ==================== SCANS ====================

  static Future<Map<String, dynamic>> saveScan({
    required String diseaseName,
    required double confidence,
    required bool isHealthy,
    required String recommendations,
    String? imageUrl,
  }) async {
    if (!isAuthenticated) throw Exception('Not authenticated');

    final data = {
      'user_id': currentUser!.id,
      'disease_name': diseaseName,
      'confidence': confidence.clamp(0, 1),
      'is_healthy': isHealthy,
      'recommendations': recommendations,
      'image_url': imageUrl,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response =
        await _client.from('scans').insert(data).select();

    return response.first;
  }

  static Future<List<Map<String, dynamic>>> getScanHistory({
    int limit = 50,
  }) async {
    if (!isAuthenticated) return [];

    try {
      final response = await _client
          .from('scans')
          .select()
          .eq('user_id', currentUser!.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getScanById(String scanId) async {
    if (!isAuthenticated) return null;

    try {
      final response = await _client
          .from('scans')
          .select()
          .eq('id', scanId)
          .eq('user_id', currentUser!.id)
          .single();

      return response;
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteScan(String scanId) async {
    if (!isAuthenticated) throw Exception('Not authenticated');

    await _client
        .from('scans')
        .delete()
        .eq('id', scanId)
        .eq('user_id', currentUser!.id);
  }

  // ==================== DISEASE INFO ====================

  static Future<List<Map<String, dynamic>>> getAllDiseases() async {
    try {
      final response = await _client
          .from('disease_info')
          .select()
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getDiseaseInfo(
      String diseaseName) async {
    try {
      final response = await _client
          .from('disease_info')
          .select()
          .eq('name', diseaseName)
          .single();

      return response;
    } catch (_) {
      return null;
    }
  }

  // ==================== FAVORITES ====================

  static Future<void> addFavorite(int diseaseId) async {
    if (!isAuthenticated) throw Exception('Not authenticated');

    try {
      await _client.from('favorites').insert({
        'user_id': currentUser!.id,
        'disease_id': diseaseId,
      });
    } catch (_) {}
  }

  static Future<void> removeFavorite(int diseaseId) async {
    if (!isAuthenticated) throw Exception('Not authenticated');

    await _client
        .from('favorites')
        .delete()
        .eq('user_id', currentUser!.id)
        .eq('disease_id', diseaseId);
  }

  static Future<List<Map<String, dynamic>>> getFavorites() async {
    if (!isAuthenticated) return [];

    try {
      final response = await _client
          .from('favorites')
          .select('disease_info(*)')
          .eq('user_id', currentUser!.id);

      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isFavorited(int diseaseId) async {
    if (!isAuthenticated) return false;

    try {
      final response = await _client
          .from('favorites')
          .select('id')
          .eq('user_id', currentUser!.id)
          .eq('disease_id', diseaseId);

      return response.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ==================== STORAGE (FIXED) ====================

  /// FIXED: Now uses Uint8List instead of List<int>
  static Future<String?> uploadScanImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    if (!isAuthenticated) return null;

    try {
      final userId = currentUser!.id;
      final path = '$userId/$fileName';

      await _client.storage.from('scan-images').uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(upsert: false),
          );

      return _client.storage.from('scan-images').getPublicUrl(path);
    } catch (e) {
      print('Image upload failed: $e');
      return null;
    }
  }

  // ==================== REALTIME ====================

  static RealtimeChannel subscribeToScans({
    required Function(List<Map<String, dynamic>>) onUpdate,
  }) {
    if (!isAuthenticated) throw Exception('Not authenticated');

    final channel = _client
        .channel('scans:user')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'scans',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUser!.id,
          ),
          callback: (_) async {
            final scans = await getScanHistory();
            onUpdate(scans);
          },
        )
        .subscribe();

    return channel;
  }

  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}