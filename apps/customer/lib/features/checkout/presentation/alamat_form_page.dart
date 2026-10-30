import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';
import 'package:latlong2/latlong.dart';

import '../application/checkout_provider.dart';
import 'peta_alamat.dart';

/// Formulir tambah/ubah alamat: peta titik GPS di atas, lalu label,
/// field teks (masing-masing dengan placeholder contoh), dan tombol simpan.
/// Alamat teks + titik GPS dikirim ke backend yang sama (endpoint
/// /alamat sudah punya kolom latitude/longitude), bukan simpan lokal.
class AlamatFormPage extends ConsumerStatefulWidget {
  const AlamatFormPage({super.key, this.alamat});
  final Alamat? alamat;
  @override
  ConsumerState<AlamatFormPage> createState() => _AlamatFormPageState();
}

class _AlamatFormPageState extends ConsumerState<AlamatFormPage> {
  static const _labelChoices = ['Rumah', 'Kantor', 'Keluarga', 'Lainnya'];

  final form = GlobalKey<FormState>();
  late final nama = TextEditingController(text: widget.alamat?.namaPenerima);
  late final hp = TextEditingController(text: widget.alamat?.noHp);
  late final jalan = TextEditingController(
    text: _parseAlamat(widget.alamat?.alamatLengkap ?? '').jalan,
  );
  late final kecKota = TextEditingController(
    text: _parseAlamat(widget.alamat?.alamatLengkap ?? '').kecKota,
  );
  late final kodePos = TextEditingController(
    text: _parseAlamat(widget.alamat?.alamatLengkap ?? '').kodePos,
  );
  late final patokan = TextEditingController(text: widget.alamat?.patokan);
  late String label = _labelChoices.contains(widget.alamat?.label)
      ? widget.alamat!.label
      : (widget.alamat == null ? 'Rumah' : 'Lainnya');
  late final labelBebas = TextEditingController(
    text: label == 'Lainnya' ? (widget.alamat?.label ?? '') : '',
  );
  LatLng? pickedPoint;
  bool pinTouched = false;
  bool busy = false;

  /// Pecah alamat lengkap jadi jalan + kecamatan/kota + kode pos.
  /// Aturan: 5 digit di ujung = kode pos; segmen "Kec./Kota/Kab." dan
  /// semua segmen setelahnya = kecamatan/kota; sisanya = jalan.
  /// Disusun ulang dengan [_composeAlamat] hasilnya identik untuk
  /// format alamat Indonesia yang umum.
  static ({String jalan, String kecKota, String kodePos}) _parseAlamat(
    String raw,
  ) {
    var rest = raw.trim();
    var kodePos = '';
    final zip = RegExp(r'(\d{5})\s*$').firstMatch(rest);
    if (zip != null) {
      kodePos = zip.group(1)!;
      rest = rest.substring(0, zip.start).trim();
    }
    final parts = rest
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final jalanParts = <String>[];
    final kecParts = <String>[];
    var seenArea = false;
    for (final part in parts) {
      if (!seenArea &&
          (part.startsWith('Kec.') ||
              part.startsWith('Kota ') ||
              part.startsWith('Kab.') ||
              part.startsWith('Kecamatan '))) {
        seenArea = true;
      }
      if (seenArea) {
        kecParts.add(part);
      } else {
        jalanParts.add(part);
      }
    }
    return (
      jalan: jalanParts.join(', '),
      kecKota: kecParts.join(', '),
      kodePos: kodePos,
    );
  }

  static String _composeAlamat(String jalan, String kecKota, String kodePos) {
    var out = jalan.trim();
    if (kecKota.trim().isNotEmpty) {
      out = out.isEmpty ? kecKota.trim() : '$out, ${kecKota.trim()}';
    }
    if (kodePos.trim().isNotEmpty) {
      out = out.isEmpty ? kodePos.trim() : '$out ${kodePos.trim()}';
    }
    return out;
  }

  LatLng get _initialPoint {
    final address = widget.alamat;
    if (address?.latitude != null && address?.longitude != null) {
      return LatLng(address!.latitude!, address.longitude!);
    }
    return jakartaDefault;
  }

  @override
  void dispose() {
    nama.dispose();
    hp.dispose();
    jalan.dispose();
    kecKota.dispose();
    kodePos.dispose();
    patokan.dispose();
    labelBebas.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    final effectiveLabel = label == 'Lainnya'
        ? (labelBebas.text.trim().isEmpty ? 'Lainnya' : labelBebas.text.trim())
        : label;
    // Titik GPS: pakai titik baru kalau user menggeser peta / memakai GPS,
    // kalau tidak, pertahankan titik lama (edit) atau kosong (baru).
    // Backend mewajibkan lat dan lng diisi bersama, jadi keduanya selalu
    // dari sumber yang sama: tidak pernah setengah-setengah.
    var lat = widget.alamat?.latitude;
    var lng = widget.alamat?.longitude;
    if (pinTouched && pickedPoint != null) {
      lat = pickedPoint!.latitude;
      lng = pickedPoint!.longitude;
    }
    final payload = {
      'label': effectiveLabel,
      'nama_penerima': nama.text.trim(),
      'no_hp': hp.text.trim(),
      'alamat_lengkap': _composeAlamat(jalan.text, kecKota.text, kodePos.text),
      'patokan': patokan.text.trim(),
      'is_utama': widget.alamat?.isUtama ?? false,
      'latitude': lat,
      'longitude': lng,
    };
    try {
      final api = ref.read(alamatApiProvider);
      if (widget.alamat == null) {
        await api.create(payload);
      } else {
        await api.update(widget.alamat!.id, payload);
      }
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

  Widget field({
    required String label,
    required String hint,
    required Key key,
    required TextEditingController controller,
    required int limit,
    int lines = 1,
    bool optional = false,
    TextInputType? keyboard,
    String? Function(String?)? extraValidator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextFormField(
          key: key,
          controller: controller,
          enabled: !busy,
          maxLength: limit,
          minLines: lines,
          maxLines: lines,
          keyboardType:
              keyboard ??
              (lines > 1 ? TextInputType.multiline : TextInputType.text),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          validator: (text) {
            if (!optional && (text == null || text.trim().isEmpty)) {
              return '$label wajib diisi';
            }
            if (extraValidator != null) return extraValidator(text);
            return null;
          },
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      backgroundColor: const Color(0xFFEFF4EB),
      appBar: AppBar(
        title: Text(
          widget.alamat == null ? 'Tambah Alamat Baru' : 'Ubah Alamat',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Titik Peta GPS (opsional)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              PetaAlamat(
                initial: _initialPoint,
                onPointChanged: (point, byUser) {
                  pickedPoint = point;
                  if (byUser) pinTouched = true;
                },
              ),
              const Text(
                'Geser peta untuk memindah pin, atau pakai tombol '
                'Gunakan Lokasi Saya. Titik hanya tersimpan kalau kamu '
                'menggeser peta atau memakai GPS.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              const Text(
                'Label alamat',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [
                  for (final value in _labelChoices)
                    ChoiceChip(
                      label: Text(value),
                      selected: label == value,
                      onSelected: busy
                          ? null
                          : (_) => setState(() => label = value),
                    ),
                ],
              ),
              if (label == 'Lainnya') ...[
                const SizedBox(height: 16),
                field(
                  label: 'Label bebas',
                  hint: 'cth: Kos, Apartemen, Toko',
                  key: const Key('alamat-label-bebas'),
                  controller: labelBebas,
                  limit: 40,
                  optional: true,
                ),
              ],
              const SizedBox(height: 8),
              field(
                label: 'Nama penerima',
                hint: 'cth: Budi Santoso',
                key: const Key('alamat-nama'),
                controller: nama,
                limit: 120,
              ),
              field(
                label: 'Nomor HP',
                hint: 'cth: 081234567890',
                key: const Key('alamat-hp'),
                controller: hp,
                limit: 32,
                keyboard: TextInputType.phone,
                extraValidator: (text) {
                  if (!RegExp(
                    r'^\+?[0-9][0-9 ()-]{4,30}[0-9]$',
                  ).hasMatch(text?.trim() ?? '')) {
                    return 'Nomor HP tidak valid';
                  }
                  return null;
                },
              ),
              field(
                label: 'Alamat jalan',
                hint: 'cth: Jl. Melati No. 10, RT 01/RW 02',
                key: const Key('alamat-lengkap'),
                controller: jalan,
                limit: 2000,
                lines: 3,
              ),
              field(
                label: 'Kecamatan / Kota',
                hint: 'cth: Kec. Sukajadi, Kota Bandung',
                key: const Key('alamat-keckota'),
                controller: kecKota,
                limit: 200,
                optional: true,
              ),
              field(
                label: 'Kode pos',
                hint: 'cth: 40162',
                key: const Key('alamat-kodepos'),
                controller: kodePos,
                limit: 5,
                keyboard: TextInputType.number,
                optional: true,
                extraValidator: (text) {
                  final value = text?.trim() ?? '';
                  if (value.isNotEmpty && !RegExp(r'^\d{5}$').hasMatch(value)) {
                    return 'Kode pos harus 5 digit angka';
                  }
                  return null;
                },
              ),
              field(
                label: 'Patokan (opsional)',
                hint: 'cth: Rumah cat hijau, gerbang samping',
                key: const Key('alamat-patokan'),
                controller: patokan,
                limit: 500,
                optional: true,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Menyimpan...' : 'Simpan Alamat'),
          ),
        ),
      ),
    ),
  );
}
