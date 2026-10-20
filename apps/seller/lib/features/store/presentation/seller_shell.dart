import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network.dart';
import '../../laporan/presentation/laporan_screen.dart';
import '../application/store_provider.dart';
import 'home_screen.dart';
import 'offline_home.dart';
import 'product_screen.dart';
import 'product_editor.dart';
import 'toko_screen.dart';
import 'store_widgets.dart';
import '../../pesanan/presentation/pesanan_screen.dart';

class SellerShell extends ConsumerStatefulWidget {
  const SellerShell({super.key, required this.user});
  final User user;
  @override
  ConsumerState<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends ConsumerState<SellerShell>
    with WidgetsBindingObserver {
  int _tab = 0;
  bool _showOffline = false;
  static const labels = ['Beranda', 'Laporan', 'Produk', 'Pesanan', 'Toko'];
  static const icons = [
    Icons.home_outlined,
    Icons.show_chart,
    Icons.inventory_2_outlined,
    Icons.receipt_long_outlined,
    Icons.storefront_outlined,
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_recoverPhoto);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(connectionStateProvider);
    }
  }

  Future<void> _retry() async {
    ref.invalidate(connectionStateProvider);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await ref.read(storeProvider(widget.user.id).notifier).load();
    if (!mounted) return;
    if (ref.read(storeProvider(widget.user.id)).error == null ||
        ref.read(connectionStateProvider).asData?.value == true) {
      setState(() => _showOffline = false);
    }
  }

  Future<void> _recoverPhoto() async {
    if (!Platform.isAndroid) return;
    try {
      final lost = await ImagePicker().retrieveLostData();
      if (!mounted) return;
      if (lost.exception != null) {
        storeMessage(
          context,
          'Foto belum dapat dipulihkan. Silakan pilih ulang.',
          error: true,
        );
      } else if (lost.files?.isNotEmpty ?? false) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ProductEditor(
              userId: widget.user.id,
              recovered: lost.files!.first,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        storeMessage(
          context,
          'Foto belum dapat dipulihkan. Silakan pilih ulang.',
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeProvider(widget.user.id));
    final connection = ref.watch(connectionStateProvider);
    ref.listen(connectionStateProvider, (previous, next) {
      if (next.asData?.value == false) setState(() => _showOffline = true);
      if (next.asData?.value == true && previous?.asData?.value == false) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
    ref.listen(storeProvider(widget.user.id), (previous, next) {
      if (next.error != null &&
          next.error != previous?.error &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        storeMessage(context, 'Permintaan gagal: ${next.error!}', error: true);
      }
    });
    final offline =
        _tab == 0 && (_showOffline || connection.asData?.value == false);
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: Colors.black,
          ),
        ),
      ),
      child: Scaffold(
        body: StoreBackground(
          child: SafeArea(
            bottom: false,
            child: offline
                ? OfflineHome(
                    namaToko: state.toko?.nama ?? widget.user.namaToko ?? '',
                    retry: _retry,
                    loading: state.loading,
                  )
                : state.loading && state.toko == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      if (state.error != null)
                        _error(state.error!)
                      else if (state.loading)
                        const LinearProgressIndicator()
                      else
                        const SizedBox.shrink(),
                      Expanded(child: _page(state)),
                    ],
                  ),
          ),
        ),
        bottomNavigationBar: _navigation(),
      ),
    );
  }

  Widget _error(String message) => Material(
    color: const Color(0xFFF86361),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: _retry,
            child: const Text(
              'Coba lagi',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _page(StoreState state) {
    if (state.toko == null) {
      return const Center(child: Text('Profil toko belum dapat dimuat.'));
    }
    return switch (_tab) {
      0 => HomeScreen(
        user: widget.user,
        state: state,
        openOrders: () => setState(() => _tab = 3),
      ),
      1 => LaporanScreen(
        userId: widget.user.id,
        namaToko: state.toko!.nama,
        openOrders: () => setState(() => _tab = 3),
      ),
      2 => ProductScreen(userId: widget.user.id, state: state),
      3 => PesananScreen(userId: widget.user.id, namaToko: state.toko!.nama),
      4 => TokoScreen(userId: widget.user.id, toko: state.toko!),
      _ => Center(
        child: Text(
          '${labels[_tab]}\nTahap A4',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    };
  }

  Widget _navigation() => NavigationBarTheme(
    data: NavigationBarThemeData(
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 13,
          color: states.contains(WidgetState.selected)
              ? Colors.black
              : Colors.white,
        ),
      ),
    ),
    child: NavigationBar(
      height: 80,
      elevation: 0,
      backgroundColor: const Color(0xFF7AA491),
      indicatorColor: Colors.white,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      selectedIndex: _tab,
      onDestinationSelected: (index) => setState(() => _tab = index),
      destinations: [
        for (var i = 0; i < labels.length; i++)
          NavigationDestination(
            icon: Icon(
              icons[i],
              key: Key('nav-${labels[i].toLowerCase()}'),
              color: Colors.white,
              size: 34,
            ),
            selectedIcon: Icon(
              icons[i],
              key: Key('nav-${labels[i].toLowerCase()}'),
              color: Colors.black,
              size: 34,
            ),
            label: labels[i],
          ),
      ],
    ),
  );
}
