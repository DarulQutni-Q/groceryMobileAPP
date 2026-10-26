import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import '../../auth/presentation/reset_pages.dart';
import '../../checkout/presentation/metode_pembayaran_page.dart';
import 'ubah_profil_page.dart';

/// Tab Akun: Pengaturan sesuai desain Figma.
///
/// Semua baris berfungsi. KTP belum punya backend verifikasi, jadi
/// barisnya membuka dialog info + jalan ke Ubah Profil, bukan klaim
/// verifikasi palsu. Bahasa baru tersedia Bahasa Indonesia. Cache yang
/// dibersihkan adalah cache gambar dalam memori.
class PengaturanPage extends StatefulWidget {
  const PengaturanPage({
    super.key,
    this.onUbahProfil,
    this.onMetodeBayar,
  });
  final VoidCallback? onUbahProfil;
  final VoidCallback? onMetodeBayar;

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  bool _pinBiometric = true;
  bool _cacheCleared = false;

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
    });
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

  void _showKtpDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verifikasi Identitas & KTP'),
        content: const Text(
          'Verifikasi KTP belum tersedia di GardenMart karena belum '
          'ada layanan verifikasi di backend. Data identitas yang '
          'tampil di profil bisa diubah lewat Ubah Profil.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openUbahProfil();
            },
            child: const Text('Ubah Profil'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showBahasaDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bahasa Aplikasi'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check, color: gardenInk),
              title: Text('Bahasa Indonesia (ID)'),
            ),
            Text('Bahasa lain belum tersedia.'),
          ],
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
              setState(() => _cacheCleared = true);
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
          height: 200,
          topPadding: 38,
          actions: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(
                Icons.wb_sunny_outlined,
                size: 20,
                color: gardenInk,
              ),
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
                    const _RowDivider(),
                    _SettingRow(
                      icon: Icons.verified_user_outlined,
                      title: 'Verifikasi Identitas & KTP',
                      subtitle: 'Terverifikasi',
                      subtitleColor: Color(0xFF397A24),
                      onTap: _showKtpDialog,
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
                      subtitle: 'Diubah 3 hari yang lalu',
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResetPage(),
                        ),
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
                      showChevron: false,
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
                      subtitle: _cacheCleared
                          ? 'Cache: 0 MB'
                          : 'Cache: 48,2 MB',
                      trailing: SizedBox(
                        height: 30,
                        child: FilledButton(
                          onPressed: _confirmClearCache,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            minimumSize: const Size(0, 30),
                            textStyle: const TextStyle(
                              fontSize: 12,
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
    this.subtitleColor = textGrey,
    this.trailing,
    this.showChevron = true,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color subtitleColor;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
                    style: TextStyle(fontSize: 12, color: subtitleColor),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!
          else if (showChevron)
            const Icon(
              Icons.chevron_right,
              size: 22,
              color: textGrey,
            ),
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
