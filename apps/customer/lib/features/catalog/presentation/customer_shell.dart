import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../auth/application/auth_provider.dart';
import '../../checkout/presentation/alamat_page.dart';
import 'catalog_widgets.dart';
import 'home_page.dart';

class CustomerShell extends ConsumerStatefulWidget {
  const CustomerShell({super.key});
  @override
  ConsumerState<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends ConsumerState<CustomerShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(
        index: tab,
        children: [
          const HomePage(),
          const _SoonPage('Promo'),
          const _SoonPage('Scan QR'),
          const _SoonPage('Pesanan'),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 64,
                  color: gardenInk,
                ),
                const SizedBox(height: 12),
                Text(
                  ref.watch(authProvider).user!.nama,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(builder: (_) => const AlamatPage()),
                  ),
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Alamat Pengiriman'),
                ),
                FilledButton(
                  onPressed: ref.read(authProvider.notifier).logout,
                  child: const Text('Keluar'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      height: 76,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE4F2D8),
      selectedIndex: tab,
      onDestinationSelected: (value) {
        if (value == 2) {
          segera(context);
        } else {
          setState(() => tab = value);
        }
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        const NavigationDestination(
          icon: Icon(Icons.local_offer_outlined),
          label: 'Promo',
        ),
        NavigationDestination(
          icon: CircleAvatar(
            radius: 25,
            backgroundColor: gardenInk,
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 26,
            ),
          ),
          label: 'Scan QR',
        ),
        const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Pesanan',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Akun',
        ),
      ],
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
