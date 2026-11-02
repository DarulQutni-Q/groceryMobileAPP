import 'dart:async';

import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:grocery_shared/shared.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState(this.status, {this.user, this.message});
  final AuthStatus status;
  final User? user;
  final String? message;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this.api, this.storage, {this.googleToken, this.onAuthenticated})
    : super(const AuthState(AuthStatus.initial));
  final AuthApi api;
  final SecureStorage storage;
  final Future<String> Function()? googleToken;
  final Future<void> Function()? onAuthenticated;
  bool _fcmSynced = false;
  int _operation = 0;

  bool _current(int operation) => mounted && operation == _operation;

  Future<bool> _accept(User user, int operation) async {
    if (!_current(operation)) return false;
    if (user.role != 'customer') {
      await storage.clearSession();
      throw const AuthFailure('Gunakan akun pembeli untuk masuk ke GardenMart');
    }
    state = AuthState(AuthStatus.authenticated, user: user);
    _syncFcm();
    return true;
  }

  void _syncFcm() {
    final callback = onAuthenticated;
    if (callback == null || _fcmSynced) return;
    _fcmSynced = true;
    unawaited(callback());
  }

  void _failed(Object error, int operation) {
    if (_current(operation)) {
      state = AuthState(
        AuthStatus.error,
        message: error is AuthFailure ? error.message : authErrorMessage(error),
      );
    }
  }

  Future<bool> _authenticate(
    Future<Tokens> Function() action,
    bool remember,
  ) async {
    final operation = ++_operation;
    state = const AuthState(AuthStatus.loading);
    try {
      final tokens = await action();
      if (!_current(operation)) return false;
      await storage.setRememberSession(remember);
      if (!_current(operation)) return false;
      await storage.saveSession(tokens.accessToken, tokens.refreshToken);
      if (!_current(operation)) return false;
      return await _accept(await api.getMe(), operation);
    } catch (error) {
      _failed(error, operation);
      return false;
    }
  }

  Future<bool> login(
    String identity,
    String password, {
    bool remember = true,
  }) => _authenticate(() => api.loginCustomer(identity, password), remember);

  Future<bool> register(String email, String password, {String? phone}) =>
      _authenticate(
        () => api.registerCustomer(
          email: email,
          password: password,
          phone: phone,
        ),
        true,
      );

  Future<bool> loginWithGoogle({bool remember = true}) =>
      _authenticate(() async {
        final token = googleToken;
        if (token == null) {
          throw const AuthFailure('Login Google belum dikonfigurasi');
        }
        return api.loginWithGoogle(await token(), role: 'customer');
      }, remember);

  Future<void> checkSession() async {
    final operation = ++_operation;
    state = const AuthState(AuthStatus.loading);
    try {
      final remember = await storage.shouldRestoreSession();
      final refresh = await storage.readRefreshToken();
      if (!_current(operation)) return;
      if (!remember || refresh == null) {
        if (!remember) await storage.clearSession();
        if (_current(operation)) {
          state = const AuthState(AuthStatus.unauthenticated);
        }
        return;
      }
      await _accept(await api.getMe(), operation);
    } catch (error) {
      _failed(error, operation);
    }
  }

  void sessionExpired() {
    _operation++;
    if (mounted) state = const AuthState(AuthStatus.unauthenticated);
  }

  Future<void> logout() async {
    final operation = ++_operation;
    try {
      await storage.clearSession();
      _fcmSynced = false;
      if (_current(operation)) {
        state = const AuthState(AuthStatus.unauthenticated);
      }
    } catch (error) {
      _failed(error, operation);
    }
  }
}

final apiBaseUrlProvider = Provider<String>(
  (ref) => throw StateError('API_BASE_URL belum diisi'),
);
final googleClientIdProvider = Provider<String>((ref) => '');
final storageProvider = Provider<SecureStorage>((ref) => SecureStorage());
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    baseUrl: ref.watch(apiBaseUrlProvider),
    storage: ref.watch(storageProvider),
  );
  client.onSessionExpired = () =>
      ref.read(authProvider.notifier).sessionExpired();
  ref.onDispose(() => client.dio.close());
  return client;
});
final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider)),
);

final googleTokenProvider = Provider<Future<String> Function()>((ref) {
  final clientId = ref.watch(googleClientIdProvider);
  Future<void>? initialized;
  return () async {
    if (clientId.isEmpty) {
      throw const AuthFailure('Login Google belum dikonfigurasi');
    }
    try {
      final google = GoogleSignIn.instance;
      await (initialized ??= google.initialize(serverClientId: clientId));
      final account = await google.authenticate();
      final token = account.authentication.idToken;
      if (token == null) {
        throw const AuthFailure('Google tidak mengirim token login');
      }
      return token;
    } on GoogleSignInException {
      throw const AuthFailure(
        'Login Google dibatalkan atau belum dapat diproses',
      );
    } on PlatformException {
      throw const AuthFailure(
        'Login Google belum dikonfigurasi untuk perangkat ini',
      );
    } on UnsupportedError {
      throw const AuthFailure('Login Google belum didukung di perangkat ini');
    }
  };
});

/// Minta izin notifikasi (best-effort) lalu kirim token FCM ke backend.
/// Semua kegagalan ditelan supaya login tidak pernah gagal karena push.
Future<void> _syncFcmToken(AuthApi api) async {
  try {
    await FirebaseMessaging.instance.requestPermission();
    await syncFcmToken(
      api: api,
      register: FirebaseMessaging.instance.register,
      registeredTokens: FirebaseMessaging.instance.onRegistered,
    );
  } catch (_) {}
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) {
    final api = ref.watch(authApiProvider);
    return AuthNotifier(
      api,
      ref.watch(storageProvider),
      googleToken: ref.watch(googleTokenProvider),
      onAuthenticated: () => _syncFcmToken(api),
    );
  },
);
