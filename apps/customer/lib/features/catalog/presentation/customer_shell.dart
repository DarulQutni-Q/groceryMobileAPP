import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import '../../auth/application/auth_provider.dart';
import '../application/profil_provider.dart';
import '../../checkout/presentation/alamat_page.dart';
import '../../checkout/presentation/checkout_page.dart';
import '../../checkout/application/checkout_provider.dart';
import 'chat_driver_page.dart';
import 'home_page.dart';
import 'pengaturan_page.dart';
import 'promo_page.dart';
import 'pesanan_page.dart';
import 'scan_qr_page.dart';
import 'ubah_profil_page.dart';
import '../../checkout/presentation/metode_pembayaran_page.dart';
import '../../checkout/presentation/struk_page.dart';

class CustomerShell extends ConsumerStatefulWidget {
  const CustomerShell({super.key, this.now, this.initialTab = 0});

  /// Diteruskan ke HomePage untuk countdown flash sale. Null = jam asli.
  final DateTime Function()? now;

  /// Tab awal saat shell dibuka (0 = Beranda, 3 = Pesanan).
  final int initialTab;
  @override
  ConsumerState<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends ConsumerState<CustomerShell> {
  late int tab;

  @override
  void initState() {
    super.initState();
    tab = widget.initialTab;
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(
        index: tab,
        children: [
          HomePage(
            now: widget.now,
            onGoToTab: (value) => setState(() => tab = value),
          ),
          const PromoPage(),
          const _SoonPage('Scan QR'),
          PesananPage(
            onLihatStruk: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const StrukPage()),
            ),
            onChatDriver: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const ChatDriverPage()),
            ),
            onBeliLagi: () => setState(() => tab = 0),
          ),
          const _AkunTab(),
        ],
      ),
    ),
    bottomNavigationBar: GardenBottomNav(
      index: tab,
      onSelect: (value) {
        if (value == 2) {
          Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const ScanQrPage()),
          );
        } else {
          setState(() => tab = value);
        }
      },
    ),
  );
}


/// Tab Akun sebagai layout profil: header avatar + nama + kontak, lalu
/// menu Alamat, Pengaturan, dan Keluar. Pengaturan dibuat eksplisit agar
/// mudah ditemukan (sebelumnya hanya deretan tombol di tengah layar).
class _AkunTab extends ConsumerWidget {
  const _AkunTab();

  String _initials(String nama) {
    final parts = nama.trim().split(RegExp(r'\s+'));
    final first = parts.first.isEmpty ? '' : parts.first[0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();
    // Nilai lokal dari Ubah Profil menang atas data akun, supaya hasil
    // simpan langsung tampil di sini tanpa endpoint profil backend.
    final lokal = ref.watch(profilLokalProvider);
    final displayNama = lokal.nama ?? user.nama;
    final displayEmail = lokal.email ?? user.email;
    final displayPhone = lokal.telepon ?? user.phone;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: gardenInk,
                backgroundImage: lokal.avatarPath != null
                    ? FileImage(File(lokal.avatarPath!))
                    : null,
                child: lokal.avatarPath == null
                    ? Text(
                  _initials(displayNama),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayNama,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: gardenInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayEmail,
                      style: const TextStyle(fontSize: 12, color: textGrey),
                    ),
                    if (displayPhone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        displayPhone,
                        style: const TextStyle(fontSize: 12, color: textGrey),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ref.watch(pendingCheckoutProvider).when(
          data: (pending) => pending
              ? Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckoutPage(items: []),
                          ),
                        ),
                        child: const Text('Lanjutkan Pembayaran'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => TextButton(
            onPressed: () => ref.invalidate(pendingCheckoutProvider),
            child: const Text('Periksa Pembayaran Tersimpan'),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _AkunMenuRow(
                icon: Icons.location_on_outlined,
                title: 'Alamat Pengiriman',
                subtitle: 'Kelola alamat antar pesanan',
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: (_) => const AlamatPage()),
                ),
              ),
              const Divider(height: 1, color: gardenBorder),
              _AkunMenuRow(
                icon: Icons.settings_outlined,
                title: 'Pengaturan',
                subtitle: 'Profil, kata sandi, pembayaran, preferensi',
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PengaturanPage(
                      onUbahProfil: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UbahProfilPage(),
                        ),
                      ),
                      onMetodeBayar: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MetodePembayaranPage(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: ref.read(authProvider.notifier).logout,
            child: const Text('Keluar'),
          ),
        ),
      ],
    );
  }
}

class _AkunMenuRow extends StatelessWidget {
  const _AkunMenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    key: Key('akun-$title'),
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: gardenInk),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: textGrey),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: textGrey),
        ],
      ),
    ),
  );
}

class _SoonPage extends StatelessWidget {
  const _SoonPage(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        const Text('Segera hadir'),
      ],
    ),
  );
}
