import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A sign-in problem with copy that is safe to show the user.
class AccountException implements Exception {
  const AccountException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Accounts that live entirely on this phone. Nothing is sent anywhere.
///
/// The username is the full name given at sign-up, matched ignoring case and
/// extra spaces. Passwords are never stored: only a PBKDF2-HMAC-SHA256 hash
/// with a random per-account salt.
class LocalAccounts {
  LocalAccounts(this._prefs);

  static Future<LocalAccounts> load() async =>
      LocalAccounts(await SharedPreferences.getInstance());

  static const _accountsKey = 'local_accounts';
  static const _sessionKey = 'local_session';
  static const _biometricKey = 'local_biometric_account';

  static const minNameLength = 2;
  static const maxNameLength = 40;
  static const minPasswordLength = 6;
  static const _iterations = 100000;

  final SharedPreferences _prefs;

  /// "  Ram   Bahadur " and "ram bahadur" are the same account.
  static String keyFor(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static String _tidy(String name) => name.trim().replaceAll(RegExp(r'\s+'), ' ');

  Map<String, dynamic> get _accounts =>
      jsonDecode(_prefs.getString(_accountsKey) ?? '{}') as Map<String, dynamic>;

  String? _nameOf(String? key) =>
      key == null ? null : (_accounts[key] as Map?)?['name'] as String?;

  /// Display name of the signed-in account, or null for a guest.
  String? get signedInName => _nameOf(_prefs.getString(_sessionKey));

  /// Display name of the account that fingerprint login opens, if set up.
  String? get biometricName => _nameOf(_prefs.getString(_biometricKey));

  bool get biometricIsForSignedInAccount {
    final session = _prefs.getString(_sessionKey);
    return session != null && session == _prefs.getString(_biometricKey);
  }

  Future<void> register(String fullName, String password) async {
    final name = _tidy(fullName);
    if (name.length < minNameLength || name.length > maxNameLength) {
      throw const AccountException(
          'Use a name between $minNameLength and $maxNameLength characters.');
    }
    if (password.length < minPasswordLength) {
      throw const AccountException(
          'Use a password of at least $minPasswordLength characters.');
    }
    final key = keyFor(name);
    final accounts = _accounts;
    if (accounts.containsKey(key)) {
      throw const AccountException(
          'That name is already registered on this phone. Log in instead.');
    }

    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    accounts[key] = {
      'name': name,
      'salt': base64Encode(salt),
      'hash': base64Encode(await _hash(password, salt, _iterations)),
      'iterations': _iterations,
      'created': DateTime.now().toIso8601String(),
    };
    await _prefs.setString(_accountsKey, jsonEncode(accounts));
    await _prefs.setString(_sessionKey, key);
  }

  Future<void> login(String username, String password) async {
    final key = keyFor(username);
    final account = _accounts[key] as Map<String, dynamic>?;
    const wrong = AccountException('Incorrect name or password.');
    if (account == null) throw wrong;

    final salt = base64Decode(account['salt'] as String);
    final expected = base64Decode(account['hash'] as String);
    final actual = await _hash(password, salt, account['iterations'] as int);
    if (!_sameBytes(actual, expected)) throw wrong;
    await _prefs.setString(_sessionKey, key);
  }

  /// Signs in the fingerprint-linked account. Call only after the phone has
  /// confirmed the fingerprint.
  Future<void> signInWithBiometrics() async {
    final key = _prefs.getString(_biometricKey);
    if (key == null || !_accounts.containsKey(key)) {
      throw const AccountException('Fingerprint login is not set up.');
    }
    await _prefs.setString(_sessionKey, key);
  }

  /// Links (or unlinks) fingerprint login to the signed-in account.
  Future<void> setBiometricForSignedInAccount(bool enabled) async {
    final session = _prefs.getString(_sessionKey);
    if (session == null) {
      throw const AccountException('Sign in to turn on fingerprint login.');
    }
    if (enabled) {
      await _prefs.setString(_biometricKey, session);
    } else if (biometricIsForSignedInAccount) {
      await _prefs.remove(_biometricKey);
    }
  }

  Future<void> logout() => _prefs.remove(_sessionKey);

  /// PBKDF2 is deliberately slow, so it runs off the UI thread.
  static Future<List<int>> _hash(String password, List<int> salt, int iterations) =>
      Isolate.run(() => pbkdf2Sha256(password, salt, iterations));

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// PBKDF2-HMAC-SHA256 with a 32-byte output (one block, RFC 8018).
@visibleForTesting
List<int> pbkdf2Sha256(String password, List<int> salt, int iterations) {
  final hmac = Hmac(sha256, utf8.encode(password));
  var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
  final out = List<int>.of(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < out.length; j++) {
      out[j] ^= u[j];
    }
  }
  return out;
}
