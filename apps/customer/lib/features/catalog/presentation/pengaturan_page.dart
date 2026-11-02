import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import '../../auth/presentation/reset_pages.dart';
import '../../checkout/presentation/metode_pembayaran_page.dart';
import 'ubah_profil_page.dart';

/// Tab Akun: Pengaturan sesuai desain Figma.
///
/// Semua baris berfungsi. Kata sandi
/// diubah lewat email terdaftar (backend hanya punya endpoint reset
/// lewat email), jadi subtitlenya menjelaskan jalurnya, bukan tanggal
/// karangan. Bahasa baru tersedia Bahasa Indonesia dan pilihannya
/// tersimpan lokal. Cache yang tampil adalah ukuran cache gambar dalam
/// memori yang terukur, dan yang dibersihkan adalah cache itu juga.
/// Ikon gerigi membuka dialog Tentang yang jujur (info versi belum
/// tersedia di aplikasi ini).
class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key, this.onUbahProfil, this.onMetodeBayar});
  final VoidCallback? onUbahProfil;
  final VoidCallback? onMetodeBayar;

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  bool _pinBiometric = true;
  int _cacheBytes = 0;
  String _bahasa = 'id';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pinBiometric = prefs.getBool('metode_biometrik') ?? true;
      _cacheBytes = imageCache.currentSizeBytes;
      _bahasa = prefs.getString('bahasa_aplikasi') ?? 'id';
    });
  }

  /// Format ukuran cache gaya Indonesia: "48,2 MB", nol jadi "0 MB".
  String _formatCache(int bytes) {
    if (bytes <= 0) return 'Cache: 0 MB';
    final mb = bytes / 1048576;
    return 'Cache: ${mb.toStringAsFixed(1).replaceAll('.', ',')} MB';
  }

  Future<void> _setPinBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('metode_biometrik', value);
    if (!mounted) return;
    setState(() => _pinBiometric = value);
  }

  void _openUbahProfil() {
    final callback = widget.onUbahProfil;
    if (callback != null) {
      callback();
    } else {
      Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const UbahProfilPage()),
      );
    }
  }

  void _openMetodeBayar() {
    final callback = widget.onMetodeBayar;
    if (callback != null) {
      callback();
    } else {
      Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const MetodePembayaranPage()),
      );
    }
  }

  void _showBahasaDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bahasa Aplikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: _bahasa == 'id'
                  ? const Icon(Icons.check, color: gardenInk)
                  : const SizedBox(width: 24),
              title: const Text('Bahasa Indonesia (ID)'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('bahasa_aplikasi', 'id');
                if (!mounted) return;
                setState(() => _bahasa = 'id');
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
            ),
            const Text('Bahasa lain belum tersedia.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showTentangDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tentang GardenMart'),
        content: const Text(
          'GardenMart — aplikasi belanja kebutuhan harian.\n\n'
          'Info versi belum tersedia di aplikasi ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCache() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bersihkan Cache'),
        content: const Text('Hapus cache gambar dalam memori?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              imageCache.clear();
              imageCache.clearLiveImages();
              setState(() => _cacheBytes = imageCache.currentSizeBytes);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache dibersihkan')),
              );
            },
            child: const Text('Bersihkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        LimeHeader(
          title: 'Pengaturan',
          centerTitle: false,
          // Tinggi 120 + padding 8: baris judul berakhir jauh di atas
          // gelombang (92px), jadi tidak tertimpa di HP apa pun.
          height: 120,
          topPadding: 8,
          titleSize: 22,
          actions: [
            RoundIconButton(
              icon: Icons.settings_outlined,
              onPressed: _showTentangDialog,
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              const _SectionLabel('AKUN & PERAN PENGGUNA'),
              const SizedBox(height: 8),
              _Card(
                child: Column(
                  children: [
                    _SettingRow(
                      icon: Icons.person_outline,
                      title: 'Ubah Profil & Identitas',
                      subtitle: 'Nama, No. HP, Email',
                      onTap: _openUbahProfil,
                    ),

                  ],
                ),
              ),
              const SizedBox(height: 12),
              const _SectionLabel('KEAMANAN'),
              const SizedBox(height: 8),
              _Card(
                child: Column(
                  children: [
                    _SettingRow(
                      icon: Icons.key_outlined,
                      title: 'Ganti kata sandi',
                      subtitle: 'Lewat email terdaftar',
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(builder: (_) => const ResetPage()),
                      ),
                    ),
                    const _RowDivider(),
                    _SettingRow(
                      icon: Icons.fingerprint,
                      title: 'PIN Transaksi & Biometrik',
                      trailing: _ToggleOn(
                        value: _pinBiometric,
                        onChanged: _setPinBiometric,
                      ),
                      onTap: () => _setPinBiometric(!_pinBiometric),
                    ),
                    const _RowDivider(),
                    _SettingRow(
                      icon: Icons.credit_card_outlined,
                      title: 'Metode Pembayaran',
                      subtitle: 'Manage metode pembayaran',
                      onTap: _openMetodeBayar,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const _SectionLabel('PREFERENSI APLIKASI'),
              const SizedBox(height: 8),
              _Card(
                child: Column(
                  children: [
                    _SettingRow(
                      icon: Icons.language_outlined,
                      title: 'Bahasa Aplikasi',
                      subtitle: 'Bahasa Indonesia (ID)',
                      onTap: _showBahasaDialog,
                    ),
                    const _RowDivider(),
                    _SettingRow(
                      icon: Icons.storage_outlined,
                      title: 'Penyimpanan & Cache',
                      subtitle: _formatCache(_cacheBytes),
                      trailing: SizedBox(
                        height: 26,
                        child: FilledButton(
                          onPressed: _confirmClearCache,
                          style: FilledButton.styleFrom(
                            foregroundColor: limeBright,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: const Size(0, 26),
                            textStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          child: const Text('Bersihkan'),
                        ),
                      ),
                      onTap: _confirmClearCache,
                    ),
                  ],
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
      fontSize: 11,
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
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 38),
    child: Divider(height: 1, color: gardenBorder),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 26, color: gardenInk),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: gardenInk,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 12, color: textGrey),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else
            const Icon(Icons.chevron_right, size: 22, color: textGrey),
        ],
      ),
    ),
  );
}

class _ToggleOn extends StatelessWidget {
  const _ToggleOn({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: Container(
      width: 40,
      height: 28,
      padding: const EdgeInsets.all(3),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: value ? gardenInk : const Color(0xFFB9C4B4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: value
            ? const Icon(Icons.check, size: 13, color: gardenInk)
            : null,
      ),
    ),
  );
}
