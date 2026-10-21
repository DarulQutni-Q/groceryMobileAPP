import 'package:flutter/material.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/theme.dart';

class CheckoutSuccessPage extends StatelessWidget {
  const CheckoutSuccessPage({super.key, required this.result});
  final HasilCheckout result;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      backgroundColor: const Color(0xFFEFF4EB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF65A63A),
                  size: 112,
                ),
                const SizedBox(height: 24),
                Text(
                  result.pembayaran.metode == 'cod'
                      ? 'Pesanan Berhasil Dibuat'
                      : 'Pembayaran Berhasil',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: gardenInk,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  result.pesanan.kode,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  result.pembayaran.metode == 'cod'
                      ? 'Siapkan pembayaran tunai saat pesanan tiba.'
                      : 'Terima kasih. Belanjaanmu siap diproses oleh toko.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Detail pesanan akan tersedia di tahap B4.',
                      ),
                    ),
                  ),
                  child: const Text('Lihat Pesanan'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text('Kembali ke Beranda'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
