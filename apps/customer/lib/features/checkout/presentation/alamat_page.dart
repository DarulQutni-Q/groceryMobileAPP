import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import '../application/checkout_provider.dart';
import 'alamat_form_page.dart';
import 'peta_picker_page.dart';

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

  Future<void> aturTitik(Alamat? address) async {
    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada alamat, tambah alamat dulu.')),
      );
      return;
    }
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PetaPickerPage(address: address)),
    );
    if (saved == true && mounted) {
      ref.invalidate(alamatProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Titik GPS tersimpan untuk ${address.label}.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFEFF4EB),
    body: Column(
      children: [
        LimeHeader(
          title: 'Alamat Pengiriman',
          centerTitle: false,
          backFilled: false,
          height: 185,
          below: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD9E6CF)),
            ),
          ),
        ),
        Expanded(
          child: ref
              .watch(alamatProvider)
              .when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        authErrorMessage(error),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(alamatProvider),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return const Center(
                      child: Text('Belum ada alamat tersimpan'),
                    );
                  }
                  final utama = entries.where((a) => a.isUtama).toList();
                  final lainnya = entries.where((a) => !a.isUtama).toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                    children: [
                      for (final address in utama)
                        _AddressCard(
                          address: address,
                          busy: busy,
                          onEdit: () => edit(address),
                          onSelect: () => select(address),
                        ),
                      if (lainnya.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 2, bottom: 10),
                          child: Text(
                            'ALAMAT LAINNYA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        for (final address in lainnya)
                          _AddressCard(
                            address: address,
                            busy: busy,
                            onEdit: () => edit(address),
                            onSelect: () => select(address),
                          ),
                      ],
                      const SizedBox(height: 10),
                      _PinpointCard(
                        onAturTitik: () => aturTitik(
                          utama.isEmpty ? null : utama.first,
                        ),
                      ),
                    ],
                  );
                },
              ),
        ),
        GreenBottomArea(
          child: DarkPillButton(
            label: 'Tambah Alamat Baru',
            icon: const Icon(Icons.add, size: 20),
            height: 48,
            fontSize: 15,
            onPressed: busy ? null : () => edit(),
          ),
        ),
      ],
    ),
  );
}

/// Kartu satu alamat: chip label, lingkaran pilih, nama + telepon sebaris,
/// alamat, strip catatan, tombol ubah dan (untuk non-utama) pilih.
class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.busy,
    required this.onEdit,
    required this.onSelect,
  });
  final Alamat address;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (address.isUtama) ...[
                const _LabelChip(label: 'Utama', dark: true),
                const SizedBox(width: 6),
              ],
              _LabelChip(label: address.label),
              const Spacer(),
              InkWell(
                onTap: busy ? null : onSelect,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: address.isUtama
                        ? const Color(0xFF75BF26)
                        : Colors.white,
                    border: address.isUtama
                        ? null
                        : Border.all(color: Colors.grey.shade400, width: 1.5),
                  ),
                  child: address.isUtama
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Wrap, bukan RichText: nama dan telepon mengalir sebaris seperti
          // referensi, tapi tetap Text terpisah supaya find.text('Nama')
          // di tes fungsional tetap cocok.
          Wrap(
            children: [
              Text(
                address.namaPenerima,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  fontFamily: 'Roboto',
                ),
              ),
              Text(
                ' (${address.noHp})',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            address.alamatLengkap,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          if (address.patokan?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.note_alt_outlined,
                    size: 14,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan: ${address.patokan}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : onEdit,
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Ubah Alamat'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: gardenInk,
                  minimumSize: const Size(0, 36),
                  side: const BorderSide(color: Color(0xFFD9E6CF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              if (!address.isUtama)
                FilledButton(
                  onPressed: busy ? null : onSelect,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD5EEC0),
                    foregroundColor: gardenInk,
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  child: const Text('Pilih Alamat'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Chip label kecil: Utama gelap, Rumah lime muda, Keluarga peach.
class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label, this.dark = false});
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = dark
        ? (gardenInk, Colors.white)
        : switch (label) {
            'Rumah' => (const Color(0xFFD5EEC0), gardenInk),
            'Keluarga' => (
              const Color(0xFFFDE8D0),
              const Color(0xFF7A4A21),
            ),
            _ => (const Color(0xFFEFF4EB), gardenInk),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

/// Kartu pinpoint GPS: ikon pin, judul, penjelasan, tautan atur titik.
/// Tautan membuka pemilih titik peta (OpenStreetMap) untuk alamat utama.
class _PinpointCard extends StatelessWidget {
  const _PinpointCard({required this.onAturTitik});
  final VoidCallback onAturTitik;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFD5EEC0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: gardenInk,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pinpoint Lokasi GPS Pengantaran',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Titik akurat mempercepat kurir menemukan gerbang rumah.',
                  style: TextStyle(fontSize: 9, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: onAturTitik,
                  child: const Text(
                    'Atur Titik Peta GPS Sekarang ›',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5A8A1F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
