import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/auth/presentation/gerbang_versi.dart';
import 'features/auth/application/auth_provider.dart';

Future<void> bootstrap(String flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase tidak tersedia (mis. tanpa Play services): token push dilewati.
  }
  await dotenv.load(fileName: '.env.$flavor.example');
  const apiOverride = String.fromEnvironment('API_BASE_URL');
  const googleOverride = String.fromEnvironment('GOOGLE_CLIENT_ID');
  final url = apiOverride.isNotEmpty
      ? apiOverride
      : dotenv.env['API_BASE_URL'] ?? '';
  final uri = Uri.tryParse(url);
  if (uri == null ||
      uri.host.isEmpty ||
      !['http', 'https'].contains(uri.scheme) ||
      (flavor != 'dev' && uri.scheme != 'https')) {
    throw StateError('Isi API_BASE_URL valid dengan HTTPS untuk staging/prod');
  }
  runApp(
    ProviderScope(
      overrides: [
        apiBaseUrlProvider.overrideWithValue(url),
        googleClientIdProvider.overrideWithValue(
          googleOverride.isNotEmpty
              ? googleOverride
              : dotenv.env['GOOGLE_CLIENT_ID'] ?? '',
        ),
      ],
      child: const GerbangVersi(
        aplikasi: 'customer',
        // Samakan dengan pubspec.yaml (tanpa sufiks +build).
        versiSaatIni: '0.1.0',
        child: CustomerApp(),
      ),
    ),
  );
}
