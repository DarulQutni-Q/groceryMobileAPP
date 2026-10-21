import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  int revision = 0;
  int generation = 0;
  Future<void> _writes = Future.value();

  Future<Map<String, dynamic>> _session() async {
    await _writes;
    final value = await _storage.read(key: 'auth_session');
    return value == null ? {} : jsonDecode(value) as Map<String, dynamic>;
  }

  Future<String?> readAccessToken() async => (await _session())['access_token'];
  Future<String?> readRefreshToken() async =>
      (await _session())['refresh_token'];

  Future<void> _write(Future<void> Function() operation) {
    final result = _writes.then((_) => operation());
    _writes = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  Future<void> saveSession(
    String accessToken,
    String refreshToken, {
    bool refreshed = false,
  }) {
    revision++;
    if (!refreshed) generation++;
    return _write(
      () => _storage.write(
        key: 'auth_session',
        value: jsonEncode({
          'access_token': accessToken,
          'refresh_token': refreshToken,
        }),
      ),
    );
  }

  Future<void> clearSession() {
    revision++;
    generation++;
    return _write(() => _storage.delete(key: 'auth_session'));
  }

  Future<bool> hasSeenOnboarding() async =>
      await _storage.read(key: 'seller_onboarding_seen') == 'true';

  Future<void> markOnboardingSeen() =>
      _storage.write(key: 'seller_onboarding_seen', value: 'true');

  Future<bool> shouldRestoreSession() async =>
      await _storage.read(key: 'remember_session') != 'false';

  Future<void> setRememberSession(bool value) => _write(
    () => _storage.write(key: 'remember_session', value: value.toString()),
  );

  Future<String?> readKeranjang(String userId) async {
    await _writes;
    return _storage.read(key: 'customer_cart_$userId');
  }

  Future<void> saveKeranjang(String userId, String value) =>
      _write(() => _storage.write(key: 'customer_cart_$userId', value: value));
  Future<String?> readCheckout(String userId) async {
    await _writes;
    return _storage.read(key: 'customer_checkout_$userId');
  }

  Future<void> saveCheckout(String userId, String value) => _write(
    () => _storage.write(key: 'customer_checkout_$userId', value: value),
  );
  Future<void> clearCheckout(String userId) =>
      _write(() => _storage.delete(key: 'customer_checkout_$userId'));
}
