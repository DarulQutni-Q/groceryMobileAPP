import 'auth_api.dart';

/// Daftarkan perangkat ke FCM lalu kirim setiap Firebase Installation ID
/// (FID) yang diterbitkan ke backend.
///
/// API FCM modern tidak lagi memakai registration token: [register]
/// mendaftarkan instance aplikasi, dan [registeredTokens] mengalirkan FID
/// saat ini (observer LiveData native mengirim nilai saat ini begitu
/// di-listen) plus setiap perubahan berikutnya. Stream-nya broadcast,
/// jadi sync boleh dipanggil ulang tiap login.
///
/// Fungsi ini tidak pernah selesai (await-for atas stream tak berujung)
/// dan memang dipanggil tanpa await; semua kegagalan ditelan supaya login
/// tidak pernah gagal karena push.
Future<void> syncFcmToken({
  required AuthApi api,
  required Future<void> Function() register,
  required Stream<String> registeredTokens,
}) async {
  try {
    await register();
    await for (final token in registeredTokens) {
      if (token.isEmpty) continue;
      try {
        await api.updateFcmToken(token);
      } catch (_) {
        // Best-effort: FID berikutnya dikirim saat login berikutnya.
      }
    }
  } catch (_) {
    // Firebase belum siap / tidak ada Play services: lewati diam-diam.
  }
}
