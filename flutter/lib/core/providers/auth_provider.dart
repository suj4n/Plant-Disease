import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../services/local_accounts.dart';

/// Sign-in state for the whole app. Accounts live on the phone
/// ([LocalAccounts]); fingerprint checks go through the phone's own sensor.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._accounts, {LocalAuthentication? biometrics})
      : _biometrics = biometrics ?? LocalAuthentication();

  final LocalAccounts _accounts;
  final LocalAuthentication _biometrics;

  bool _isLoading = false;
  String? _errorMessage;

  /// Null for a guest.
  String? get displayName => _accounts.signedInName;
  bool get isAuthenticated => displayName != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Whose account the login screen's fingerprint button opens, if any.
  String? get biometricName => _accounts.biometricName;
  bool get biometricEnabled => _accounts.biometricIsForSignedInAccount;

  Future<bool> login(String username, String password) =>
      _run(() => _accounts.login(username, password));

  Future<bool> register({required String fullName, required String password}) =>
      _run(() => _accounts.register(fullName, password));

  /// False if the fingerprint was not confirmed. A cancelled prompt leaves
  /// [errorMessage] null so the UI stays quiet.
  Future<bool> loginWithBiometrics() => _run(() async {
        if (!await _confirmFingerprint('Log in to PlantDoc')) {
          throw const _Cancelled();
        }
        await _accounts.signInWithBiometrics();
      });

  /// Returns copy to show the user, or null on success.
  Future<String?> setBiometricEnabled(bool enabled) async {
    try {
      if (enabled) {
        final available = await _biometrics.getAvailableBiometrics();
        if (available.isEmpty) {
          return 'Add a fingerprint in your phone\'s Settings first.';
        }
        if (!await _confirmFingerprint('Confirm it\'s you to turn on fingerprint login')) {
          return null; // cancelled: leave the switch off, say nothing
        }
      }
      await _accounts.setBiometricForSignedInAccount(enabled);
      notifyListeners();
      return null;
    } on AccountException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('AuthProvider.setBiometricEnabled: $e');
      return 'Fingerprint is not available on this phone right now.';
    }
  }

  Future<void> logout() async {
    await _accounts.logout();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _confirmFingerprint(String reason) =>
      _biometrics.authenticate(localizedReason: reason, biometricOnly: true);

  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on _Cancelled {
      return false;
    } on AccountException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      debugPrint('AuthProvider: $e');
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class _Cancelled implements Exception {
  const _Cancelled();
}
