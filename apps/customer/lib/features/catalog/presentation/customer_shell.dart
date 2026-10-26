import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import '../../auth/application/auth_provider.dart';
import '../../checkout/presentation/alamat_page.dart';
import '../../checkout/presentation/checkout_page.dart';
import '../../checkout/application/checkout_provider.dart';
import 'chat_driver_page.dart';
import 'home_page.dart';
import 'promo_page.dart';
import 'pesanan_page.dart';
import 'scan_qr_page.dart';
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
          HomePage(now: widget.now),
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
                ref
                    .watch(pendingCheckoutProvider)
                    .when(
                      data: (pending) => pending
                          ? FilledButton(
                              onPressed: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CheckoutPage(items: []),
                                ),
                              ),
                              child: const Text('Lanjutkan Pembayaran'),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => TextButton(
                        onPressed: () =>
                            ref.invalidate(pendingCheckoutProvider),
                        child: const Text('Periksa Pembayaran Tersimpan'),
                      ),
                    ),
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
