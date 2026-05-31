import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Authentication service for PlantDoc
/// Handles login, registration, and auth state management
class AuthService {
  static const String _tokenKey = 'plantdoc_auth_token';
  
  /// Listen to authentication state changes
  static Stream<AuthState> get onAuthStateChanged {
    return SupabaseService.client.auth.onAuthStateChange;
  }

  /// Register new user
  static Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
      throw Exception('Email, password, and name are required');
    }

    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters');
    }

    if (!email.contains('@')) {
      throw Exception('Please enter a valid email');
    }

    try {
      await SupabaseService.register(
        email: email,
        password: password,
        fullName: fullName,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Login user
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }

    try {
      await SupabaseService.login(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Logout user
  static Future<void> logout() async {
    try {
      await SupabaseService.logout();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    return SupabaseService.isAuthenticated;
  }

  /// Get current user
  static User? getCurrentUser() {
    return SupabaseService.currentUser;
  }

  /// Get access token
  static String? getAccessToken() {
    return SupabaseService.getAccessToken();
  }

  /// Verify email (check if user exists)
  static Future<bool> emailExists(String email) async {
    try {
      // Try to sign in - if it fails with "Invalid login credentials", email doesn't exist
      // This is a bit of a hack, but Supabase doesn't provide a direct way to check
      final response = await SupabaseService.client.from('user_profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Send password reset email
  static Future<void> resetPassword(String email) async {
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  /// Update password
  static Future<void> updatePassword(String newPassword) async {
    if (newPassword.length < 8) {
      throw Exception('Password must be at least 8 characters');
    }

    try {
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Password update failed: $e');
    }
  }

  /// Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isAuthenticated()) {
      throw Exception('Not authenticated');
    }
    
    try {
      return await SupabaseService.getUserProfile();
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  /// Update user profile
  static Future<void> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    if (!isAuthenticated()) {
      throw Exception('Not authenticated');
    }

    if (fullName.isEmpty) {
      throw Exception('Name cannot be empty');
    }

    try {
      await SupabaseService.updateProfile(
        fullName: fullName,
        avatarUrl: avatarUrl,
      );
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}
