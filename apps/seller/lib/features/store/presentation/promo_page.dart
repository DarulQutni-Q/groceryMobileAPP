import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/promo_provider.dart';
import '../application/store_provider.dart';

/// Kelola promo harga toko (tebus murah + kilat murah): daftar, tambah,
/// aktif/nonaktif, hapus. Potongan dihitung server saat checkout.
class PromoPage extends ConsumerWidget {
  const PromoPage({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(promoHargaListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Promo Harga')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gagal memuat promo.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(promoHargaListProvider),
                child: const Text('Muat ulang'),
              ),
            ],
          ),
        ),
        data: (promos) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              key: const Key('promo-tambah'),
              onPressed: () => _tambahPromo(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Tambah promo'),
            ),
            const SizedBox(height: 16),
            if (promos.isEmpty)
              const Text(
                'Belum ada promo. Promo aktif tampil di halaman Tebus '
                'Murah dan Kilat Murah customer, dan memotong tagihan '
                'saat checkout.',
                style: TextStyle(color: Colors.black54),
              ),
            for (final promo in promos) ...[
              Card.outlined(
                margin: EdgeInsets.zero,
                child: ListTile(
                  title: Text('${promo.judul} • ${promo.jenis}'),
                  subtitle: Text(
                    '${promo.produk?.nama ?? 'Produk'}: '
                    'Rp ${promo.produk?.harga} → Rp ${promo.hargaPromo}'
                    '${promo.minBelanja > 0 ? ' • Min. belanja Rp ${promo.minBelanja}' : ''}'
                    '${promo.berakhirAt == null ? '' : ' • Sampai ${promo.berakhirAt!.toLocal()}'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        key: Key('promo-aktif-${promo.id}'),
                        value: promo.aktif,
                        onChanged: (value) async {
                          await ref
                              .read(promoHargaApiProvider)
                              .setAktif(promo.id, value);
                          ref.invalidate(promoHargaListProvider);
                        },
                      ),
                      IconButton(
                        key: Key('promo-hapus-${promo.id}'),
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final hapus = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Hapus promo?'),
                              content: Text(
                                'Promo ${promo.judul} tidak memotong '
                                'tagihan lagi setelah dihapus.',
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
                                .read(promoHargaApiProvider)
                                .delete(promo.id);
                            ref.invalidate(promoHargaListProvider);
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

  Future<void> _tambahPromo(BuildContext context, WidgetRef ref) async {
    final toko = ref.read(storeProvider(userId)).toko;
    if (toko == null) return;
    final halaman = await ref
        .read(produkApiProvider)
        .listHalaman(tokoId: toko.id, perPage: 100);
    final produkList = halaman.data;
    if (!context.mounted) return;
    if (produkList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambah produk dulu sebelum buat promo.')),
      );
      return;
    }
    final judul = TextEditingController();
    final hargaPromo = TextEditingController();
    final minBelanja = TextEditingController();
    var jenis = 'tebus';
    var produkId = produkList.first.id;
    DateTime? berakhir;
    var error = '';
    final simpan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Tambah promo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('promo-judul'),
                  controller: judul,
                  decoration: const InputDecoration(labelText: 'Judul'),
                ),
                DropdownButtonFormField<String>(
                  key: const Key('promo-jenis'),
                  initialValue: jenis,
                  items: const [
                    DropdownMenuItem(value: 'tebus', child: Text('Tebus murah')),
                    DropdownMenuItem(value: 'kilat', child: Text('Kilat murah')),
                  ],
                  onChanged: (value) =>
                      setState(() => jenis = value ?? 'tebus'),
                ),
                DropdownButtonFormField<String>(
                  key: const Key('promo-produk'),
                  initialValue: produkId,
                  items: [
                    for (final produk in produkList)
                      DropdownMenuItem(
                        value: produk.id,
                        child: Text('${produk.nama} (Rp ${produk.harga})'),
                      ),
                  ],
                  onChanged: (value) => setState(
                    () => produkId = value ?? produkList.first.id,
                  ),
                ),
                TextField(
                  key: const Key('promo-harga'),
                  controller: hargaPromo,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Harga promo'),
                ),
                TextField(
                  key: const Key('promo-min'),
                  controller: minBelanja,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Min. belanja (0 = tanpa syarat)',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('promo-berakhir'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(
                        () => berakhir = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          23,
                          59,
                        ),
                      );
                    }
                  },
                  child: Text(
                    berakhir == null
                        ? 'Tanggal berakhir (opsional)'
                        : 'Berakhir ${berakhir!.day}/${berakhir!.month}/${berakhir!.year}',
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
                if (judul.text.trim().isEmpty ||
                    hargaPromo.text.trim().isEmpty) {
                  setState(() => error = 'Judul dan harga promo wajib diisi.');
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
      await ref.read(promoHargaApiProvider).create({
        'judul': judul.text.trim(),
        'jenis': jenis,
        'produk_id': produkId,
        'harga_promo': int.tryParse(hargaPromo.text) ?? 0,
        'min_belanja': int.tryParse(minBelanja.text) ?? 0,
        'berakhir_at': berakhir?.toIso8601String(),
      });
      ref.invalidate(promoHargaListProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan promo.')),
        );
      }
    }
  }
}
