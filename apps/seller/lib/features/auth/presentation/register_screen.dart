import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/seller_theme.dart';
import '../../../shared/auth_layout.dart';
import '../application/auth_provider.dart';
import 'account_form.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onBack,
    required this.onComplete,
  });
  final VoidCallback onBack;
  final VoidCallback onComplete;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _step = 1;
  final _categories = <String>{};
  String _shipping = 'Instant';
  double _distance = 5;

  @override
  Widget build(BuildContext context) => AuthLayout(
    title: _step == 4 ? null : 'Daftar Toko',
    onBack: () => _step == 1 ? widget.onBack() : setState(() => _step--),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_step < 4) _stepTitle(),
        if (_step == 1)
          AccountForm(
            register: true,
            onRegistered: () => setState(() => _step = 2),
          ),
        if (_step == 2) _storeInfo(),
        if (_step == 3) _delivery(),
        if (_step == 4) _success(),
      ],
    ),
  );

  Widget _stepTitle() => Padding(
    padding: const EdgeInsets.only(left: 48, bottom: 18),
    child: Text(
      ['Akun', 'Info Toko', 'Pengiriman'][_step - 1],
      style: const TextStyle(fontSize: 18, color: Colors.black),
    ),
  );

  Widget _storeInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 20),
      const ReferenceArtwork(
        asset: 'store-info.png',
        rect: Rect.fromLTWH(188, 147, 164, 83),
        width: 164,
        semanticLabel: 'Maskot kardus toko',
      ),
      const SizedBox(height: 32),
      const Text(
        'Kategori Toko',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final category in [
            'Sembako',
            'Sayur',
            'Daging dan Ikan',
            'Buah',
          ])
            FilterChip(
              label: Text(category),
              selected: _categories.contains(category),
              backgroundColor: sellerInput,
              onSelected: (selected) => setState(
                () => selected
                    ? _categories.add(category)
                    : _categories.remove(category),
              ),
            ),
        ],
      ),
      const SizedBox(height: 44),
      FilledButton(
        onPressed: () => setState(() => _step = 3),
        child: const Text('Lanjut'),
      ),
    ],
  );

  Widget _delivery() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 12),
      RadioGroup<String>(
        groupValue: _shipping,
        onChanged: (value) => setState(() => _shipping = value!),
        child: Column(
          children: [
            _deliveryCard(
              'Instant',
              'Antar 1 jam setelah bayar, min. belanja Rp 25rb',
              Icons.inventory_2_outlined,
            ),
            _deliveryCard(
              'Kurir Marketplace',
              'Kurir ambil di toko',
              Icons.local_shipping_outlined,
            ),
            _deliveryCard(
              'Ambil di Toko',
              'Pembeli ambil sendiri',
              Icons.storefront_outlined,
            ),
          ],
        ),
      ),
      const SizedBox(height: 26),
      Text(
        'Jarak antar maksimal: ${_distance.round()} km',
        style: const TextStyle(fontSize: 18),
      ),
      Slider(
        value: _distance,
        min: 1,
        max: 10,
        divisions: 9,
        label: '${_distance.round()} km',
        activeColor: const Color(0xFF0B5A49),
        onChanged: (value) => setState(() => _distance = value),
      ),
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text('1 km'), Text('10 km')],
      ),
      const SizedBox(height: 32),
      FilledButton(
        onPressed: () => setState(() => _step = 4),
        child: const Text('Daftar'),
      ),
    ],
  );

  Widget _deliveryCard(String title, String subtitle, IconData icon) =>
      Card.outlined(
        color: sellerInput,
        margin: const EdgeInsets.only(bottom: 14),
        child: RadioListTile<String>(
          value: title,
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: Icon(icon, size: 36, color: Colors.black),
        ),
      );

  Widget _success() {
    final user = ref.watch(authProvider).user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 80),
        const Center(
          child: CircleAvatar(
            radius: 62,
            backgroundColor: Color(0xFF3B6D11),
            child: Icon(Icons.check, color: Colors.white, size: 88),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Toko Kamu Sudah Terdaftar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Langkah berikutnya: Tambah produk supaya pembeli bisa mulai memesan.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 30),
        Card.outlined(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Toko', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        user?.namaToko ?? 'Toko',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Pengiriman', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _shipping,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 36),
        FilledButton(
          onPressed: widget.onComplete,
          child: const Text('+ Tambah Produk'),
        ),
      ],
    );
  }
}
