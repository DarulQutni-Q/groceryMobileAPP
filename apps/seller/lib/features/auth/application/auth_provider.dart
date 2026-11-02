import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/network.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState(this.status, {this.user, this.message});
  final AuthStatus status;
  final User? user;
  final String? message;
}

class AuthCancelledException implements Exception {
  const AuthCancelledException();
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

  void _syncFcm() {
    final callback = onAuthenticated;
    if (callback == null || _fcmSynced) return;
    _fcmSynced = true;
    unawaited(callback());
  }

  Future<bool> _authenticate(Future<Tokens> Function() action) async {
    final operation = ++_operation;
    state = const AuthState(AuthStatus.loading);
    try {
      final tokens = await action();
      if (!_current(operation)) return false;
      await storage.saveSession(tokens.accessToken, tokens.refreshToken);
      final user = await api.getMe();
      if (!_current(operation)) return false;
      state = AuthState(AuthStatus.authenticated, user: user);
      _syncFcm();
      return true;
    } catch (error) {
      if (!_current(operation)) return false;
      if (error is AuthCancelledException) {
        state = const AuthState(AuthStatus.unauthenticated);
        return false;
      }
      state = AuthState(
        AuthStatus.error,
        message: error is AuthFailure ? error.message : authErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> login(String email, String password) =>
      _authenticate(() => api.login(email, password));

  Future<bool> register({
    required String namaPemilik,
    required String namaToko,
    required String email,
    required String password,
  }) => _authenticate(
    () => api.registerSeller(
      namaPemilik: namaPemilik,
      namaToko: namaToko,
      email: email,
      password: password,
    ),
  );

  Future<bool> loginWithGoogle() => _authenticate(() async {
    final getToken = googleToken;
    if (getToken == null) {
      throw const AuthFailure('Login Google belum dikonfigurasi');
    }
    return api.loginWithGoogle(await getToken());
  });

  Future<void> checkSession() async {
    final operation = ++_operation;
    state = const AuthState(AuthStatus.loading);
    try {
      final access = await storage.readAccessToken();
      final refresh = await storage.readRefreshToken();
      if (!_current(operation)) return;
      if (access == null && refresh == null) {
        state = const AuthState(AuthStatus.unauthenticated);
        return;
      }
      final user = await api.getMe();
      if (_current(operation)) {
        state = AuthState(AuthStatus.authenticated, user: user);
        _syncFcm();
      }
    } catch (error) {
      if (!_current(operation)) return;
      state = error is DioException && error.response?.statusCode == 401
          ? const AuthState(AuthStatus.unauthenticated)
          : AuthState(AuthStatus.error, message: authErrorMessage(error));
    }
  }

  void sessionExpired() {
    _operation++;
    if (mounted) state = const AuthState(AuthStatus.unauthenticated);
  }

  Future<void> logout() async {
    final operation = ++_operation;
    final user = state.user;
    try {
      await storage.clearSession();
      _fcmSynced = false;
      if (_current(operation)) {
        state = const AuthState(AuthStatus.unauthenticated);
      }
    } catch (_) {
      if (_current(operation)) {
        state = AuthState(
          AuthStatus.error,
          user: user,
          message: 'Sesi belum dapat dihapus. Silakan coba lagi.',
        );
      }
    }
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
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
  configureSellerNetwork(client, ref.watch(connectionCheckProvider));
  client.onSessionExpired = () =>
      ref.read(authProvider.notifier).sessionExpired();
  ref.onDispose(() => client.dio.close());
  return client;
});

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
    } on GoogleSignInException catch (e, stack) {
      debugPrint('GoogleSignInException: code=${e.code}, description=${e.description}, details=${e.details}\n$stack');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelledException();
      }
      throw const AuthFailure(
        'Login Google gagal. Periksa konfigurasi atau coba lagi.',
      );
    } on PlatformException catch (e, stack) {
      debugPrint('PlatformException on Google Sign-In: code=${e.code}, message=${e.message}, details=${e.details}\n$stack');
      throw const AuthFailure(
        'Login Google belum dikonfigurasi untuk perangkat ini',
      );
    } on UnsupportedError catch (e, stack) {
      debugPrint('UnsupportedError on Google Sign-In: $e\n$stack');
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
    final api = AuthApi(ref.watch(apiClientProvider));
    return AuthNotifier(
      api,
      ref.watch(storageProvider),
      googleToken: ref.watch(googleTokenProvider),
      onAuthenticated: () => _syncFcmToken(api),
    );
  },
);
