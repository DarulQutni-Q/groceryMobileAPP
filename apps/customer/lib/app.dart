import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import 'core/theme.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/auth/presentation/auth_page.dart';
import 'features/auth/presentation/reset_pages.dart';
import 'features/auth/presentation/reset_verify_page.dart';
import 'features/auth/presentation/splash_page.dart';
import 'features/catalog/presentation/customer_shell.dart';

class CustomerApp extends ConsumerStatefulWidget {
  const CustomerApp({super.key});
  @override
  ConsumerState<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends ConsumerState<CustomerApp> {
  final messenger = GlobalKey<ScaffoldMessengerState>();
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).checkSession());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.message != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => messenger.currentState?.showSnackBar(
            SnackBar(
              content: Text(next.message!),
              backgroundColor: Colors.red.shade700,
            ),
          ),
        );
      }
    });
    return ProviderScope(
      key: ValueKey(auth.user?.id ?? 'guest'),
      overrides: [
        keranjangStorageProvider.overrideWithValue(ref.watch(storageProvider)),
      ],
      child: MaterialApp(
        title: 'GardenMart',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: messenger,
        theme: customerTheme(),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('id'), Locale('en')],
        routes: {
          '/login': (_) => const AuthPage(),
          '/register': (_) => const AuthPage(register: true),
          '/forgot-password': (_) => const ResetPage(),
          '/email-sent': (_) => const ResetPage(sent: true),
          '/reset-verify': (context) => ResetVerifyPage(
                email:
                    ModalRoute.of(context)?.settings.arguments as String? ?? '',
              ),
        },
        home: auth.status == AuthStatus.authenticated
            ? const CustomerShell()
            : const SplashPage(),
      ),
    );
  }
}
