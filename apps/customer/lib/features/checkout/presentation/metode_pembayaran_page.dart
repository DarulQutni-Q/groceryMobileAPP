import 'package:flutter/material.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';

/// Kelola metode pembayaran (layar Pengaturan > Metode Pembayaran).
/// Beda dengan [MetodeBayarPage] yang dipakai sebagai picker saat checkout:
/// halaman ini menampilkan dompet dan kartu yang sudah tersimpan.
class MetodePembayaranPage extends StatelessWidget {
  const MetodePembayaranPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: authBackground,
    body: Column(
      children: [
        const LimeHeader(
          title: 'Metode Pembayaran',
          centerTitle: false,
          height: 150,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const _SectionLabel('DOMPET DIGITAL TERHUBUNG'),
              const SizedBox(height: 10),
              _Card(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _BrandBox(
                          color: Color(0xFFE31E24),
                          label: 'GoPay',
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saldo GoPay',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: gardenInk,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Rp 445.200',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: gardenInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const _Pill(
                              text: 'Terhubung',
                              background: Color(0xFFE4F3D8),
                              foreground: Color(0xFF397A24),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 30,
                              child: FilledButton(
                                onPressed: () {},
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  minimumSize: const Size(0, 30),
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                                child: const Text('Top Up'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, color: gardenBorder),
                    ),
                    Row(
                      children: [
                        const _BrandBox(
                          color: Color(0xFFEE4D2D),
                          label: 'S Pay',
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ShopeePay',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: gardenInk,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Belum Terhubung',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 30,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              minimumSize: const Size(0, 30),
                              side: const BorderSide(color: gardenInk),
                              foregroundColor: gardenInk,
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            child: const Text('Hubungkan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _SectionLabel('KARTU DEBIT & KREDIT'),
              const SizedBox(height: 10),
              _Card(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const _BrandBox(
                          color: Color(0xFF0060AF),
                          label: 'BCA',
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'BCA Mastercard Debit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: gardenInk,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _Pill(
                                    text: 'Utama',
                                    background: gardenInk,
                                    foreground: Colors.white,
                                  ),
                                ],
                              ),
                              SizedBox(height: 2),
                              Text(
                                '•••• 4122 • Exp 08/28',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _MastercardMark(),
                        const SizedBox(width: 10),
                        const _RadioDot(),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, color: gardenBorder),
                    ),
                    Row(
                      children: [
                        const _BrandBox(
                          color: Color(0xFF003A70),
                          label: 'mandiri',
                          labelColor: Color(0xFFF7C948),
                          italic: true,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mandiri Visa Debit',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: gardenInk,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '•••• 8921 • Exp 11/27',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'VISA',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF1A1F71),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const _RadioDot(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Card(
                child: Row(
                  children: [
                    const Icon(
                      Icons.fingerprint,
                      size: 30,
                      color: gardenInk,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PIN Transaksi & Biometrik',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: gardenInk,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Gunakan Face ID / Sidik Jari untuk konfirmasi bayar',
                            style: TextStyle(fontSize: 9, color: textGrey),
                          ),
                        ],
                      ),
                    ),
                    const _ToggleOn(),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: SizedBox(
                  width: 220,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    child: const Text('Simpan'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: textGrey,
      letterSpacing: 0.4,
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );
}

class _BrandBox extends StatelessWidget {
  const _BrandBox({
    required this.color,
    required this.label,
    this.labelColor = Colors.white,
    this.italic = false,
  });
  final Color color;
  final String label;
  final Color labelColor;
  final bool italic;
  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: labelColor,
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.background,
    required this.foreground,
  });
  final String text;
  final Color background;
  final Color foreground;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
    ),
  );
}

class _RadioDot extends StatelessWidget {
  const _RadioDot();
  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFB9C4B4), width: 2),
      color: Colors.white,
    ),
  );
}

class _MastercardMark extends StatelessWidget {
  const _MastercardMark();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 34,
    height: 20,
    child: Stack(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFEB001B),
          ),
        ),
        Positioned(
          left: 14,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF79E1B),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ToggleOn extends StatelessWidget {
  const _ToggleOn();
  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 32,
    padding: const EdgeInsets.all(3),
    alignment: Alignment.centerRight,
    decoration: BoxDecoration(
      color: gardenInk,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: const Icon(Icons.check, size: 16, color: gardenInk),
    ),
  );
}
