import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import 'metode_bayar_page.dart';

/// Kelola metode pembayaran (layar Pengaturan > Metode Pembayaran).
/// Beda dengan [MetodeBayarPage] yang dipakai sebagai picker saat checkout:
/// halaman ini memilih preferensi metode dari metode yang benar-benar
/// didukung backend, bukan dompet/kartu tersimpan (tidak ada yang
/// terhubung).
class MetodePembayaranPage extends StatefulWidget {
  const MetodePembayaranPage({super.key});

  @override
  State<MetodePembayaranPage> createState() =>
      _MetodePembayaranPageState();
}

/// Metode yang benar-benar didukung checkout (sama dengan kunci
/// [metodeBayar] di picker checkout).
class _Metode {
  const _Metode(this.key, this.label, this.deskripsi);
  final String key, label, deskripsi;
}

const _metode = [
  _Metode('qris', 'QRIS', 'Scan QR saat checkout'),
  _Metode('gopay', 'GoPay', 'E-wallet saat checkout'),
  _Metode('shopeepay', 'ShopeePay', 'E-wallet saat checkout'),
  _Metode('va_bca', 'VA BCA', 'Transfer bank saat checkout'),
  _Metode('va_bri', 'VA BRI', 'Transfer bank saat checkout'),
  _Metode('va_mandiri', 'VA Mandiri', 'Transfer bank saat checkout'),
  _Metode('cod', 'COD (Bayar di Tempat)', 'Bayar tunai saat pesanan sampai'),
];

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
    final preferensi = _selected >= 0 && _selected < _metode.length
        ? _metode[_selected].key
        : null;
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
              const _SectionLabel('METODE YANG DIDUKUNG'),
              const SizedBox(height: 6),
              const Text(
                'Belum ada dompet atau kartu yang terhubung. Metode di '
                'bawah ini adalah yang benar-benar didukung saat checkout; '
                'pilihan di sini hanya menjadi preferensi awal.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < _metode.length; i++)
                _Card(
                  child: InkWell(
                    key: Key('metode-${_metode[i].key}'),
                    onTap: () => setState(() => _selected = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            ikonBayar(_metode[i].key),
                            color: gardenInk,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _metode[i].label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: gardenInk,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _metode[i].deskripsi,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (_selected == i)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF397A24),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
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
