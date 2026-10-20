import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/seller_theme.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/auth/presentation/account_form.dart';
import 'features/auth/presentation/register_screen.dart';
import 'shared/auth_layout.dart';
import 'features/store/presentation/seller_shell.dart';

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Daclanari Grocery',
    theme: sellerTheme(),
    home: const AuthFlow(),
  );
}

class AuthFlow extends ConsumerStatefulWidget {
  const AuthFlow({super.key});

  @override
  ConsumerState<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends ConsumerState<AuthFlow> {
  String _page = 'splash';

  @override
  void initState() {
    super.initState();
    Future.microtask(_open);
  }

  Future<void> _open() async {
    try {
      final session = ref.read(authProvider.notifier).checkSession();
      final seen = ref.read(storageProvider).hasSeenOnboarding();
      final results = await Future.wait<dynamic>([
        session,
        seen,
        Future<void>.delayed(const Duration(seconds: 2)),
      ]);
      final hasSeen = results[1] as bool;
      if (!mounted) return;
      setState(
        () => _page = ref.read(authProvider).status == AuthStatus.authenticated
            ? 'home'
            : hasSeen
            ? 'login'
            : 'onboarding',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _page = 'login');
      showAuthMessage(
        context,
        'Sesi belum dapat dibaca. Silakan login kembali.',
        error: true,
      );
    }
  }

  Future<void> _continue() async {
    try {
      await ref.read(storageProvider).markOnboardingSeen();
      if (mounted) setState(() => _page = 'login');
    } catch (_) {
      if (mounted) {
        showAuthMessage(
          context,
          'Pengaturan belum tersimpan. Coba lagi.',
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.message != null) {
        showAuthMessage(context, next.message!, error: true);
      }
      if (next.status == AuthStatus.authenticated && _page == 'login') {
        setState(() => _page = 'home');
      }
      if (next.status == AuthStatus.unauthenticated && _page == 'home') {
        Navigator.of(context).popUntil((route) => route.isFirst);
        setState(() => _page = 'login');
      }
    });
    return switch (_page) {
      'splash' => _splash(),
      'onboarding' => _onboarding(context),
      'register' => RegisterScreen(
        onBack: () => setState(() => _page = 'login'),
        onComplete: () => setState(() => _page = 'home'),
      ),
      'home' => _home(),
      _ => AuthLayout(
        title: 'Login ke Toko',
        onBack: () => setState(() => _page = 'onboarding'),
        child: AccountForm(
          register: false,
          onSignUp: () => setState(() => _page = 'register'),
        ),
      ),
    };
  }

  Widget _splash() => const AuthLayout(
    child: Column(
      children: [
        SizedBox(height: 140),
        ReferenceArtwork(
          asset: 'splash.png',
          rect: Rect.fromLTWH(81, 221, 307, 308),
          width: 307,
          semanticLabel: 'daclanari GROCERY',
        ),
        SizedBox(height: 40),
        Text(
          'Belanja Mudah,\nKebutuhan Lengkap',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontFamily: 'serif',
            color: Colors.black,
          ),
        ),
      ],
    ),
  );

  Widget _onboarding(BuildContext context) => AuthLayout(
    child: Column(
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height < 750 ? 24 : 110),
        ReferenceArtwork(
          asset: 'onboarding.png',
          rect: const Rect.fromLTWH(70, 217, 307, 314),
          width: MediaQuery.sizeOf(context).height < 750 ? 220 : 300,
          semanticLabel: 'Pesanan tepung dan beras',
        ),
        const SizedBox(height: 24),
        const Text(
          'Terima Pesanan dari\nSatu Layar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        SizedBox(height: MediaQuery.sizeOf(context).height < 750 ? 24 : 65),
        SizedBox(
          width: 210,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF84A18A),
            ),
            onPressed: _continue,
            child: const Text('Lanjut'),
          ),
        ),
      ],
    ),
  );

  Widget _home() {
    final user = ref.watch(authProvider).user;
    return user == null
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : SellerShell(key: ValueKey(user.id), user: user);
  }
}
