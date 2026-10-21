import 'package:flutter/material.dart';

const metodeBayar = <String, String>{
  'qris': 'QRIS',
  'gopay': 'GoPay',
  'shopeepay': 'ShopeePay',
  'va_bca': 'VA BCA',
  'va_bri': 'VA BRI',
  'va_mandiri': 'VA Mandiri',
  'cod': 'COD',
};
IconData ikonBayar(String value) => value == 'qris'
    ? Icons.qr_code_2
    : value.startsWith('va_')
    ? Icons.account_balance_outlined
    : value == 'cod'
    ? Icons.payments_outlined
    : Icons.account_balance_wallet_outlined;

class MetodeBayarPage extends StatelessWidget {
  const MetodeBayarPage({super.key, required this.selected});
  final String selected;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFEFF4EB),
    appBar: AppBar(
      backgroundColor: const Color(0xFFB5E27E),
      title: const Text('Metode Pembayaran'),
    ),
    body: SafeArea(
      child: RadioGroup<String>(
        groupValue: selected,
        onChanged: (value) {
          if (value != null) Navigator.pop(context, value);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Pilih cara bayar',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bayar aman melalui Xendit atau tunai saat pesanan tiba.',
            ),
            const SizedBox(height: 20),
            for (final entry in metodeBayar.entries)
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: RadioListTile<String>(
                  key: Key('bayar-${entry.key}'),
                  value: entry.key,
                  secondary: Icon(ikonBayar(entry.key)),
                  title: Text(entry.value),
                  subtitle: entry.key == 'qris'
                      ? const Text(
                          'RECOMMENDED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF397A24),
                          ),
                        )
                      : entry.key == 'cod'
                      ? const Text('Bayar saat diterima')
                      : null,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
