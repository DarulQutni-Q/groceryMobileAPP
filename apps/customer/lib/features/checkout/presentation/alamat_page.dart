import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/theme.dart';
import '../application/checkout_provider.dart';
import 'alamat_form_page.dart';

class AlamatPage extends ConsumerStatefulWidget {
  const AlamatPage({super.key, this.pilih = false});
  final bool pilih;
  @override
  ConsumerState<AlamatPage> createState() => _AlamatPageState();
}

class _AlamatPageState extends ConsumerState<AlamatPage> {
  bool busy = false;

  Future<void> select(Alamat address) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final updated = await ref
          .read(alamatApiProvider)
          .jadikanUtama(address.id);
      ref.invalidate(alamatProvider);
      if (!mounted) return;
      if (widget.pilih) Navigator.pop(context, updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit([Alamat? address]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AlamatFormPage(alamat: address)),
    );
    if (saved == true && mounted) ref.invalidate(alamatProvider);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFEFF4EB),
    appBar: AppBar(
      backgroundColor: const Color(0xFFA6D575),
      title: const Text('Alamat Pengiriman'),
    ),
    body: ref
        .watch(alamatProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(authErrorMessage(error), textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => ref.invalidate(alamatProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
          data: (entries) => entries.isEmpty
              ? const Center(child: Text('Belum ada alamat tersimpan'))
              : RadioGroup<String>(
                  groupValue: entries.where((a) => a.isUtama).firstOrNull?.id,
                  onChanged: (id) {
                    if (id != null && !busy) {
                      select(entries.firstWhere((a) => a.id == id));
                    }
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text('Pilih alamat untuk menerima belanjaanmu.'),
                      const SizedBox(height: 20),
                      for (final address in entries) ...[
                        if (!address.isUtama)
                          const Padding(
                            padding: EdgeInsets.only(top: 8, bottom: 12),
                            child: Text(
                              'ALAMAT LAINNYA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        Card(
                          elevation: 0,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: address.isUtama
                                  ? const Color(0xFF94C563)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (address.isUtama)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Chip(
                                          label: Text('Utama'),
                                          backgroundColor: gardenInk,
                                          labelStyle: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    Chip(label: Text(address.label)),
                                    const Spacer(),
                                    Radio<String>(
                                      value: address.id,
                                      enabled: !busy,
                                    ),
                                  ],
                                ),
                                Text(
                                  address.namaPenerima,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(address.noHp),
                                const SizedBox(height: 8),
                                Text(address.alamatLengkap),
                                if (address.patokan?.isNotEmpty == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text('Patokan: ${address.patokan}'),
                                  ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    OutlinedButton(
                                      onPressed: busy
                                          ? null
                                          : () => edit(address),
                                      child: const Text('Ubah Alamat'),
                                    ),
                                    if (widget.pilih)
                                      TextButton(
                                        onPressed: busy
                                            ? null
                                            : () => select(address),
                                        child: const Text('Pilih Alamat'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FilledButton.icon(
          onPressed: busy ? null : () => edit(),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Alamat Baru'),
        ),
      ),
    ),
  );
}
