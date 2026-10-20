import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../application/store_provider.dart';
import 'store_widgets.dart';

class TokoEditor extends ConsumerStatefulWidget {
  const TokoEditor({
    super.key,
    required this.userId,
    required this.toko,
    this.section = 'profil',
  });
  final String userId, section;
  final Toko toko;
  @override
  ConsumerState<TokoEditor> createState() => _TokoEditorState();
}

class _TokoEditorState extends ConsumerState<TokoEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nama,
      _alamat,
      _telepon,
      _deskripsi,
      _rekening;
  late Set<String> _kategori, _kirim;
  late double _radius;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final t = widget.toko;
    _nama = TextEditingController(text: t.nama);
    _alamat = TextEditingController(text: t.alamat);
    _telepon = TextEditingController(text: t.telepon);
    _deskripsi = TextEditingController(text: t.deskripsi);
    _rekening = TextEditingController(text: t.rekeningBank);
    _kategori = {...t.kategori};
    _kirim = {...t.metodeKirim};
    _radius = t.radiusKm.toDouble();
  }

  @override
  void dispose() {
    for (final c in [_nama, _alamat, _telepon, _deskripsi, _rekening]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final data = switch (widget.section) {
      'pengiriman' => <String, dynamic>{
        'metode_kirim': _kirim.toList(),
        'radius_km': _radius.round(),
      },
      'rekening' => <String, dynamic>{
        'rekening_bank': _rekening.text.trim().isEmpty
            ? null
            : _rekening.text.trim(),
      },
      _ => <String, dynamic>{
        'nama': _nama.text.trim(),
        'alamat': _alamat.text.trim(),
        'telepon': _telepon.text.trim(),
        'deskripsi': _deskripsi.text.trim(),
        'kategori': _kategori.toList(),
      },
    };
    setState(() => _saving = true);
    final ok = await ref.read(storeProvider(widget.userId).notifier).mutate(
      'toko',
      () async {
        await ref.read(tokoApiProvider).updateProfil(data);
      },
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      storeMessage(
        context,
        ref.read(storeProvider(widget.userId)).error ??
            'Profil belum tersimpan.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: StorePage(
      title: switch (widget.section) {
        'pengiriman' => 'Pengiriman',
        'rekening' => 'Rekening Pencairan',
        _ => 'Info Toko',
      },
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: switch (widget.section) {
                    'pengiriman' => _shipping(),
                    'rekening' => [
                      _field(
                        'Bank dan nomor rekening',
                        _rekening,
                        hint: 'Contoh: BRI 1234567890',
                      ),
                    ],
                    _ => _profile(),
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  List<Widget> _profile() => [
    const Text(
      'Data ini tampil di halaman tokomu',
      style: TextStyle(fontSize: 17),
    ),
    const SizedBox(height: 14),
    Row(
      children: [
        const Icon(Icons.storefront_outlined, size: 60),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Foto atau Logo Toko', style: TextStyle(fontSize: 18)),
              OutlinedButton.icon(
                onPressed: () => storeMessage(
                  context,
                  'Upload logo belum tersedia. Foto produk dapat diunggah lewat menu Produk.',
                ),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Ubah Foto'),
              ),
            ],
          ),
        ),
      ],
    ),
    _field('Nama Toko', _nama, required: true),
    const SizedBox(height: 12),
    const Text('Kategori', style: TextStyle(fontSize: 18)),
    Wrap(
      spacing: 10,
      children: [
        for (final value in ['Sembako', 'Sayur', 'Daging dan Ikan', 'Buah'])
          FilterChip(
            label: Text(value == 'Daging dan Ikan' ? 'Daging & Ikan' : value),
            selected: _kategori.contains(value),
            onSelected: _saving
                ? null
                : (selected) => setState(
                    () => selected
                        ? _kategori.add(value)
                        : _kategori.remove(value),
                  ),
          ),
      ],
    ),
    _field('Alamat Toko', _alamat, required: true, lines: 3),
    _field('Nomor Toko', _telepon, required: true, phone: true),
    _field('Deskripsi Singkat (Opsional)', _deskripsi, lines: 2),
  ];
  List<Widget> _shipping() => [
    for (final value in ['Instant', 'Kurir Marketplace', 'Ambil di Toko'])
      Card.outlined(
        color: const Color(0xFFECE5D0),
        child: CheckboxListTile(
          title: Text(value),
          value: _kirim.contains(value),
          onChanged: _saving
              ? null
              : (selected) => setState(
                  () => selected! ? _kirim.add(value) : _kirim.remove(value),
                ),
        ),
      ),
    const SizedBox(height: 24),
    Text(
      'Jarak antar maksimal: ${_radius.round()} km',
      style: const TextStyle(fontSize: 19),
    ),
    Slider(
      value: _radius,
      min: 1,
      max: 10,
      divisions: 9,
      label: '${_radius.round()} km',
      onChanged: _saving ? null : (value) => setState(() => _radius = value),
    ),
    const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text('1 km'), Text('10 km')],
    ),
  ];
  Widget _field(
    String label,
    TextEditingController c, {
    bool required = false,
    int lines = 1,
    bool phone = false,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        TextFormField(
          key: Key('toko-$label'),
          controller: c,
          enabled: !_saving,
          maxLines: lines,
          keyboardType: phone ? TextInputType.phone : TextInputType.text,
          decoration: InputDecoration(hintText: hint ?? 'Masukkan $label'),
          validator: (value) => required && (value?.trim().isEmpty ?? true)
              ? '$label wajib diisi'
              : null,
        ),
      ],
    ),
  );
}
