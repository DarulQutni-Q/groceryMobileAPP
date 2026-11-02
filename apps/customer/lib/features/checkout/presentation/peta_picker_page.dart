import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';
import 'package:latlong2/latlong.dart';

import '../application/checkout_provider.dart';
import 'peta_alamat.dart';

/// Pemilih titik GPS layar penuh untuk satu alamat. Dibuka dari tautan
/// "Atur Titik Peta GPS Sekarang" di layar Alamat Pengiriman. Titik yang
/// disimpan dikirim ke backend bersama field alamat yang sudah ada
/// (bukan endpoint baru), jadi sinkron ke server seperti alamat teks.
class PetaPickerPage extends ConsumerStatefulWidget {
  const PetaPickerPage({super.key, required this.address});
  final Alamat address;

  @override
  ConsumerState<PetaPickerPage> createState() => _PetaPickerPageState();
}

class _PetaPickerPageState extends ConsumerState<PetaPickerPage> {
  LatLng? picked;
  bool touched = false;
  bool busy = false;

  LatLng get _initial {
    final address = widget.address;
    if (address.latitude != null && address.longitude != null) {
      return LatLng(address.latitude!, address.longitude!);
    }
    return dewantaraDefault;
  }

  bool get _hasStored =>
      widget.address.latitude != null && widget.address.longitude != null;

  Future<void> _save() async {
    if (busy) return;
    if (!touched && !_hasStored) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Titik belum dipilih'),
          content: const Text(
            'Geser peta atau pakai tombol Gunakan Lokasi Saya dulu, '
            'baru tekan Simpan Titik Ini.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }
    final point = picked ?? _initial;
    setState(() => busy = true);
    try {
      final address = widget.address;
      await ref.read(alamatApiProvider).update(address.id, {
        'label': address.label,
        'nama_penerima': address.namaPenerima,
        'no_hp': address.noHp,
        'alamat_lengkap': address.alamatLengkap,
        'patokan': address.patokan ?? '',
        'is_utama': address.isUtama,
        'latitude': point.latitude,
        'longitude': point.longitude,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFEFF4EB),
    appBar: AppBar(title: const Text('Atur Titik Peta GPS')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Titik pengantaran untuk alamat "${widget.address.label}".',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Geser peta untuk memindah pin, atau pakai tombol '
            'Gunakan Lokasi Saya.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          PetaAlamat(
            initial: _initial,
            height: 420,
            onPointChanged: (point, byUser) {
              picked = point;
              if (byUser) touched = true;
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy ? null : _save,
            child: Text(busy ? 'Menyimpan...' : 'Simpan Titik Ini'),
          ),
        ],
      ),
    ),
  );
}
