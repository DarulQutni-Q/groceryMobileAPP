import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';
import 'package:image_picker/image_picker.dart';

import '../application/store_provider.dart';
import 'home_screen.dart';
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

class _SellerShellState extends ConsumerState<SellerShell> {
  int _tab = 0;
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
    Future.microtask(_recoverPhoto);
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
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      if (state.error != null) _error(state.error!),
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
            onPressed: () =>
                ref.read(storeProvider(widget.user.id).notifier).load(),
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
