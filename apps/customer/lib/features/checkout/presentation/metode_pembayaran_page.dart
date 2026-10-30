import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import '../application/placeholder_metode.dart';

/// Kelola metode pembayaran (layar Pengaturan > Metode Pembayaran).
/// Beda dengan [MetodeBayarPage] yang dipakai sebagai picker saat checkout:
/// halaman ini menampilkan dompet dan kartu yang sudah tersimpan.
class MetodePembayaranPage extends StatefulWidget {
  const MetodePembayaranPage({super.key});

  @override
  State<MetodePembayaranPage> createState() =>
      _MetodePembayaranPageState();
}

class _MetodePembayaranPageState extends State<MetodePembayaranPage> {
  int _selected = -1;
  bool _biometric = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selected = prefs.getInt('metode_utama') ?? -1;
      _biometric = prefs.getBool('metode_biometrik') ?? true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('metode_utama', _selected);
    await prefs.setBool('metode_biometrik', _biometric);
    final preferensi = metodeBayarDariKartu(_selected);
    if (preferensi != null) {
      await prefs.setString('metode_bayar_preferensi', preferensi);
    } else {
      await prefs.remove('metode_bayar_preferensi');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Metode pembayaran tersimpan')),
    );
    Navigator.maybePop(context);
  }

  void _honestDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: authBackground,
    body: Column(
      children: [
        const LimeHeader(
          title: 'Metode Pembayaran',
          centerTitle: false,
          height: 200,
          topPadding: 38,
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                placeholderDompet[0].nama,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: gardenInk,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                placeholderDompet[0].status,
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
                            _Pill(
                              text: placeholderDompet[0].terhubung ? 'Terhubung' : 'Belum Terhubung',
                              background: Color(0xFFE4F3D8),
                              foreground: Color(0xFF397A24),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 30,
                              child: FilledButton(
                                onPressed: () => _honestDialog(
                                  'Top Up GoPay',
                                  'Top Up GoPay belum tersedia di GardenMart '
                                  'karena belum ada integrasi e-wallet di backend.',
                                ),
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
                                child: Text(placeholderDompet[0].tombol),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                placeholderDompet[1].nama,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: gardenInk,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                placeholderDompet[1].status,
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
                            onPressed: () => _honestDialog(
                              'Hubungkan ShopeePay',
                              'Menghubungkan ShopeePay belum tersedia di GardenMart '
                              'karena belum ada integrasi e-wallet di backend.',
                            ),
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
                            child: Text(placeholderDompet[1].tombol),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    placeholderKartu[0].judul,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: gardenInk,
                                    ),
                                  ),
                                  if (placeholderKartu[0].utama) ...[
                                    const SizedBox(width: 8),
                                    _Pill(
                                      text: 'Utama',
                                      background: gardenInk,
                                      foreground: Colors.white,
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 2),
                              Text(
                                placeholderKartu[0].tersamar,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _NetworkMark(placeholderKartu[0].network),
                        const SizedBox(width: 10),
                        _RadioDot(
                          key: const Key('metode-bca'),
                          selected: _selected == 0,
                          onTap: () => setState(() => _selected = 0),
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
                          color: Color(0xFF003A70),
                          label: 'mandiri',
                          labelColor: Color(0xFFF7C948),
                          italic: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                placeholderKartu[1].judul,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: gardenInk,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                placeholderKartu[1].tersamar,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _NetworkMark(placeholderKartu[1].network),
                        const SizedBox(width: 10),
                        _RadioDot(
                          key: const Key('metode-mandiri'),
                          selected: _selected == 1,
                          onTap: () => setState(() => _selected = 1),
                        ),
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
                    _ToggleOn(
                      key: const Key('toggle-biometrik'),
                      value: _biometric,
                      onChanged: (value) =>
                          setState(() => _biometric = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 56),
              Center(
                child: SizedBox(
                  width: 260,
                  child: FilledButton(
                    key: const Key('simpan-metode'),
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
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
    width: 44,
    height: 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  const _RadioDot({super.key, required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFB9C4B4), width: 2),
            color: Colors.white,
          ),
          child: selected
              ? Container(
                  width: 11,
                  height: 11,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: gardenInk,
                  ),
                )
              : null,
        ),
      );
}

class _MastercardMark extends StatelessWidget {
  const _MastercardMark();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 30,
    height: 18,
    child: Stack(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFEB001B),
          ),
        ),
        Positioned(
          left: 12,
          child: Container(
            width: 18,
            height: 18,
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

class _NetworkMark extends StatelessWidget {
  const _NetworkMark(this.network);
  final String network;
  @override
  Widget build(BuildContext context) => network == 'visa'
      ? const Text(
          'VISA',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            color: Color(0xFF1A1F71),
          ),
        )
      : const _MastercardMark();
}

class _ToggleOn extends StatelessWidget {
  const _ToggleOn({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          width: 52,
          height: 32,
          padding: const EdgeInsets.all(3),
          alignment:
              value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? gardenInk : const Color(0xFFB9C4B4),
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
            child: value
                ? const Icon(Icons.check, size: 16, color: gardenInk)
                : null,
          ),
        ),
      );
}
