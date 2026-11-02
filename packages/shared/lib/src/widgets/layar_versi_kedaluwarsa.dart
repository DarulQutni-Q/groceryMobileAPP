import 'package:flutter/material.dart';

/// Layar blokir force-update: tidak bisa ditutup, tidak ada tombol lanjut.
/// Satu-satunya aksi adalah "Periksa lagi" (setelah user memperbarui APK
/// dari sumber distribusinya) — tidak ada tautan toko karena aplikasi ini
/// didistribusikan sebagai APK langsung, bukan lewat Play Store.
class LayarVersiKedaluwarsa extends StatelessWidget {
  const LayarVersiKedaluwarsa({
    super.key,
    required this.versiSaatIni,
    required this.versiMinimum,
    required this.onPeriksaLagi,
  });

  final String versiSaatIni;
  final String versiMinimum;
  final VoidCallback onPeriksaLagi;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.system_update, size: 64, color: Color(0xFF75BF26)),
              const SizedBox(height: 24),
              const Text(
                'Versi aplikasi sudah kedaluwarsa',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Versi kamu $versiSaatIni, versi minimum yang didukung '
                'adalah $versiMinimum. Perbarui aplikasi untuk melanjutkan.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('versi-periksa-lagi'),
                onPressed: onPeriksaLagi,
                child: const Text('Periksa lagi'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
