import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../application/voucher_provider.dart';

/// Kelola voucher toko: daftar, tambah, aktif/nonaktif, hapus.
class VoucherPage extends ConsumerWidget {
  const VoucherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(voucherListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Voucher')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gagal memuat voucher.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(voucherListProvider),
                child: const Text('Muat ulang'),
              ),
            ],
          ),
        ),
        data: (vouchers) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              key: const Key('voucher-tambah'),
              onPressed: () => _tambahVoucher(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Tambah voucher'),
            ),
            const SizedBox(height: 16),
            if (vouchers.isEmpty)
              const Text(
                'Belum ada voucher. Voucher yang aktif tampil di '
                'pemilih voucher customer saat checkout.',
                style: TextStyle(color: Colors.black54),
              ),
            for (final voucher in vouchers) ...[
              Card.outlined(
                margin: EdgeInsets.zero,
                child: ListTile(
                  title: Text('${voucher.kode} • ${voucher.judul}'),
                  subtitle: Text(_ringkas(voucher)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        key: Key('voucher-aktif-${voucher.id}'),
                        value: voucher.aktif,
                        onChanged: (value) async {
                          await ref
                              .read(voucherApiProvider)
                              .setAktif(voucher.id, value);
                          ref.invalidate(voucherListProvider);
                        },
                      ),
                      IconButton(
                        key: Key('voucher-hapus-${voucher.id}'),
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final hapus = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Hapus voucher?'),
                              content: Text(
                                'Voucher ${voucher.kode} tidak bisa dipakai '
                                'lagi setelah dihapus.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Batal'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                          if (hapus == true) {
                            await ref
                                .read(voucherApiProvider)
                                .delete(voucher.id);
                            ref.invalidate(voucherListProvider);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  String _ringkas(Voucher voucher) {
    if (voucher.jenis == 'persen') {
      final syarat = <String>['${voucher.persen}%'];
      if (voucher.cap > 0) syarat.add('maks. Rp ${voucher.cap}');
      if (voucher.minBelanja > 0) {
        syarat.add('min. belanja Rp ${voucher.minBelanja}');
      }
      return syarat.join(' • ');
    }
    return 'Gratis ongkir s/d Rp ${voucher.maxOngkir}';
  }

  Future<void> _tambahVoucher(BuildContext context, WidgetRef ref) async {
    final kode = TextEditingController();
    final judul = TextEditingController();
    final persen = TextEditingController();
    final cap = TextEditingController();
    final minBelanja = TextEditingController();
    final maxOngkir = TextEditingController();
    var jenis = 'persen';
    var error = '';
    final simpan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Tambah voucher'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('voucher-kode'),
                  controller: kode,
                  decoration: const InputDecoration(labelText: 'Kode'),
                ),
                TextField(
                  key: const Key('voucher-judul'),
                  controller: judul,
                  decoration: const InputDecoration(labelText: 'Judul'),
                ),
                DropdownButtonFormField<String>(
                  key: const Key('voucher-jenis'),
                  initialValue: jenis,
                  items: const [
                    DropdownMenuItem(
                      value: 'persen',
                      child: Text('Persen'),
                    ),
                    DropdownMenuItem(
                      value: 'gratis_ongkir',
                      child: Text('Gratis ongkir'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => jenis = value ?? 'persen'),
                ),
                if (jenis == 'persen') ...[
                  TextField(
                    key: const Key('voucher-persen'),
                    controller: persen,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Persen (0-100)'),
                  ),
                  TextField(
                    key: const Key('voucher-cap'),
                    controller: cap,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Maks. potongan (0 = tanpa batas)',
                    ),
                  ),
                  TextField(
                    key: const Key('voucher-min'),
                    controller: minBelanja,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Min. belanja (0 = tanpa syarat)',
                    ),
                  ),
                ] else
                  TextField(
                    key: const Key('voucher-max-ongkir'),
                    controller: maxOngkir,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Maks. ongkir ditanggung',
                    ),
                  ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(error, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (kode.text.trim().isEmpty || judul.text.trim().isEmpty) {
                  setState(() => error = 'Kode dan judul wajib diisi.');
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (simpan != true || !context.mounted) return;
    try {
      await ref.read(voucherApiProvider).create({
        'kode': kode.text.trim(),
        'judul': judul.text.trim(),
        'jenis': jenis,
        'persen': int.tryParse(persen.text) ?? 0,
        'cap': int.tryParse(cap.text) ?? 0,
        'min_belanja': int.tryParse(minBelanja.text) ?? 0,
        'max_ongkir': int.tryParse(maxOngkir.text) ?? 0,
      });
      ref.invalidate(voucherListProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan voucher.')),
        );
      }
    }
  }
}
