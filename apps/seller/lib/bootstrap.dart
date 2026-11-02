import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/auth/application/auth_provider.dart';

Future<void> bootstrap(String flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase tidak tersedia (mis. tanpa Play services): token push dilewati.
  }
  await dotenv.load(fileName: '.env.$flavor.example');
  const override = String.fromEnvironment('API_BASE_URL');
  const googleOverride = String.fromEnvironment('GOOGLE_CLIENT_ID');
  final baseUrl = override.isNotEmpty
      ? override
      : dotenv.env['API_BASE_URL'] ?? '';
  final googleId = googleOverride.isNotEmpty
      ? googleOverride
      : dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  runApp(
    ProviderScope(
      overrides: [
        apiBaseUrlProvider.overrideWithValue(baseUrl),
        googleClientIdProvider.overrideWithValue(googleId),
      ],
      child: const SellerApp(),
    ),
  );
}
