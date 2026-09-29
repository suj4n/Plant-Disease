import 'package:flutter_test/flutter_test.dart';
import 'package:plantdoc/core/services/local_accounts.dart';
import 'package:shared_preferences/shared_preferences.dart';

String hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('PBKDF2-HMAC-SHA256 matches the published test vectors', () {
    final salt = 'salt'.codeUnits;
    test('c = 1', () {
      expect(hex(pbkdf2Sha256('password', salt, 1)),
          '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b');
    });
    test('c = 2', () {
      expect(hex(pbkdf2Sha256('password', salt, 2)),
          'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43');
    });
    test('c = 4096', () {
      expect(hex(pbkdf2Sha256('password', salt, 4096)),
          'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a');
    });
  });

  group('LocalAccounts', () {
    late LocalAccounts accounts;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      accounts = await LocalAccounts.load();
    });

    test('sign-up signs you in, and the full name is the username', () async {
      await accounts.register('  Ram   Bahadur ', 'secret1');
      expect(accounts.signedInName, 'Ram Bahadur');
    });

    test('the password is never stored', () async {
      await accounts.register('Sita', 'hunter22');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('local_accounts'), isNot(contains('hunter22')));
    });

    test('login ignores case and extra spaces in the name', () async {
      await accounts.register('Ram Bahadur', 'secret1');
      await accounts.logout();
      expect(accounts.signedInName, isNull);
      await accounts.login('ram   BAHADUR', 'secret1');
      expect(accounts.signedInName, 'Ram Bahadur');
    });

    test('a wrong password or unknown name is refused the same way', () async {
      await accounts.register('Ram', 'secret1');
      await accounts.logout();
      expect(() => accounts.login('Ram', 'wrong!!'), throwsA(isA<AccountException>()));
      expect(() => accounts.login('Nobody', 'secret1'), throwsA(isA<AccountException>()));
      expect(accounts.signedInName, isNull);
    });

    test('a name can only be registered once', () async {
      await accounts.register('Ram', 'secret1');
      expect(() => accounts.register('RAM', 'other12'), throwsA(isA<AccountException>()));
    });

    test('rejects a short password or name', () async {
      expect(() => accounts.register('Ram', '123'), throwsA(isA<AccountException>()));
      expect(() => accounts.register('R', 'secret1'), throwsA(isA<AccountException>()));
    });

    test('fingerprint login opens the account that turned it on', () async {
      await accounts.register('Ram', 'secret1');
      await accounts.setBiometricForSignedInAccount(true);
      expect(accounts.biometricIsForSignedInAccount, isTrue);

      await accounts.logout();
      expect(accounts.biometricName, 'Ram');
      await accounts.signInWithBiometrics();
      expect(accounts.signedInName, 'Ram');

      await accounts.setBiometricForSignedInAccount(false);
      expect(accounts.biometricName, isNull);
    });

    test('a guest cannot turn on fingerprint login', () {
      expect(() => accounts.setBiometricForSignedInAccount(true),
          throwsA(isA<AccountException>()));
    });
  });
}
