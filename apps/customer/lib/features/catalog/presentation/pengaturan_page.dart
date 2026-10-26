import 'package:flutter/material.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import '../../auth/presentation/reset_pages.dart';

/// Tab Akun: Pengaturan sesuai desain Figma.
///
/// Baris yang sudah punya tujuan nyata: Ubah Profil, Ganti kata sandi
/// (pakai alur reset yang sudah ada), dan Metode Pembayaran.
/// Baris Verifikasi KTP, Bahasa, dan Bersihkan Cache masih
/// menampilkan snackbar "Segera hadir" sampai fiturnya dibangun.
class PengaturanPage extends StatelessWidget {
  const PengaturanPage({
    super.key,
    this.onUbahProfil,
    this.onMetodeBayar,
  });
  final VoidCallback? onUbahProfil;
  final VoidCallback? onMetodeBayar;

  void _segeraHadir(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Segera hadir')),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      LimeHeader(
        title: 'Pengaturan',
        centerTitle: false,
        height: 200,
        topPadding: 38,
        actions: [
          RoundIconButton(
            icon: Icons.wb_sunny_outlined,
            onPressed: () {},
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
                    onTap: onUbahProfil ?? () {},
                  ),
                  const _RowDivider(),
                  _SettingRow(
                    icon: Icons.verified_user_outlined,
                    title: 'Verifikasi Identitas & KTP',
                    subtitle: 'Terverifikasi',
                    subtitleColor: Color(0xFF397A24),
                    onTap: () => _segeraHadir(context),
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
                    trailing: const _ToggleOn(),
                    onTap: () {},
                  ),
                  const _RowDivider(),
                  _SettingRow(
                    icon: Icons.credit_card_outlined,
                    title: 'Metode Pembayaran',
                    subtitle: 'Manage metode pembayaran',
                    showChevron: false,
                    onTap: onMetodeBayar ?? () {},
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
                    onTap: () => _segeraHadir(context),
                  ),
                  const _RowDivider(),
                  _SettingRow(
                    icon: Icons.storage_outlined,
                    title: 'Penyimpanan & Cache',
                    subtitle: 'Cache: 48,2 MB',
                    trailing: SizedBox(
                      height: 30,
                      child: FilledButton(
                        onPressed: () => _segeraHadir(context),
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
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
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
