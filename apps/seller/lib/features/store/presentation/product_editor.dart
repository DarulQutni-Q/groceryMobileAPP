import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';
import 'package:image_picker/image_picker.dart';

import '../application/store_provider.dart';
import 'store_widgets.dart';

final photoPickerProvider = Provider<Future<XFile?> Function(ImageSource)>(
  (ref) =>
      (source) =>
          ImagePicker().pickImage(source: source, requestFullMetadata: false),
);

class ProductEditor extends ConsumerStatefulWidget {
  const ProductEditor({
    super.key,
    required this.userId,
    this.product,
    this.recovered,
  });
  final String userId;
  final Produk? product;
  final XFile? recovered;
  @override
  ConsumerState<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends ConsumerState<ProductEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nama, _harga, _kategori;
  late int _stok;
  late String _satuan;
  String? _savedId, _filename;
  Uint8List? _bytes;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nama = TextEditingController(text: p?.nama);
    _harga = TextEditingController(text: p?.harga.toString());
    _kategori = TextEditingController(text: p?.kategori);
    _stok = p?.stok ?? 0;
    _satuan = p?.satuan ?? 'kg';
    _savedId = p?.id;
    if (widget.recovered != null) {
      Future.microtask(() => _readPhoto(widget.recovered!));
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _harga.dispose();
    _kategori.dispose();
    super.dispose();
  }

  Future<void> _readPhoto(XFile file) async {
    try {
      final ext = file.name.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext) ||
          await file.length() > 5 * 1024 * 1024) {
        throw const FormatException('Pilih JPG, PNG, atau WebP maksimal 5 MB.');
      }
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 600);
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _filename = file.name;
        });
      }
    } catch (error) {
      if (mounted) {
        storeMessage(
          context,
          error is FormatException
              ? error.message
              : 'Foto belum dapat dibaca. Pilih foto lain.',
          error: true,
        );
      }
    }
  }

  Future<void> _pick() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final file = await ref.read(photoPickerProvider)(source);
      if (file != null && mounted) await _readPhoto(file);
    } catch (_) {
      if (mounted) {
        storeMessage(
          context,
          'Foto belum dapat dibuka. Periksa izin kamera atau galeri.',
          error: true,
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_bytes == null && widget.product?.fotoUrl == null) {
      storeMessage(context, 'Foto produk wajib dipilih', error: true);
      return;
    }
    setState(() => _saving = true);
    final notifier = ref.read(storeProvider(widget.userId).notifier);
    final api = ref.read(produkApiProvider);
    final data = {
      'nama': _nama.text.trim(),
      'harga': int.parse(_harga.text),
      'stok': _stok,
      'satuan': _satuan,
      'kategori': _kategori.text.trim(),
    };
    final ok = await notifier.mutate('editor', () async {
      if (_savedId == null) {
        _savedId = (await api.create(data)).id;
      } else {
        await api.update(_savedId!, data);
      }
      if (_bytes != null) await api.uploadFoto(_savedId!, _bytes!, _filename!);
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      storeMessage(
        context,
        ref.read(storeProvider(widget.userId)).error ??
            'Produk belum tersimpan. Coba lagi.',
        error: true,
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: const Text('Produk akan dihapus dari tokomu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    final ok = await ref
        .read(storeProvider(widget.userId).notifier)
        .mutate('editor', () => ref.read(produkApiProvider).delete(_savedId!));
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      storeMessage(
        context,
        ref.read(storeProvider(widget.userId)).error ??
            'Produk belum dapat dihapus.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: StorePage(
      title: widget.product == null ? 'Tambah Produk' : 'Ubah Produk',
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card.filled(
                      color: Colors.white,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Foto Produk Wajib',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            InkWell(
                              onTap: _saving ? null : _pick,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F9EF),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE3E6D1),
                                  ),
                                ),
                                height: 125,
                                width: double.infinity,
                                child: _bytes != null
                                    ? Image.memory(_bytes!, fit: BoxFit.contain)
                                    : widget.product?.fotoUrl != null
                                    ? ProductPhoto(
                                        product: widget.product!,
                                        size: 120,
                                      )
                                    : const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.camera_alt_outlined,
                                            size: 42,
                                          ),
                                          Text(
                                            'Foto Produk',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card.outlined(
                      color: Colors.white,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informasi Produk',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            _field(
                              'Nama Produk',
                              _nama,
                              'Masukkan Nama Produk',
                              (v) => v!.trim().isEmpty
                                  ? 'Nama produk wajib diisi'
                                  : null,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _field(
                                    'Harga Produk',
                                    _harga,
                                    'Masukkan Harga',
                                    (v) =>
                                        (int.tryParse(v ?? '') ?? 0) <= 0 ||
                                            (int.tryParse(v ?? '') ?? 0) >
                                                2147483647
                                        ? 'Harga harus lebih dari 0'
                                        : null,
                                    number: true,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Stok',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      Card.filled(
                                        color: const Color(0xFFECE5D0),
                                        margin: EdgeInsets.zero,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              tooltip: 'Kurangi stok',
                                              onPressed: _saving || _stok == 0
                                                  ? null
                                                  : () =>
                                                        setState(() => _stok--),
                                              icon: const Icon(Icons.remove),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '$_stok',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Tambah stok',
                                              onPressed:
                                                  _saving || _stok == 2147483647
                                                  ? null
                                                  : () =>
                                                        setState(() => _stok++),
                                              icon: const Icon(Icons.add),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Satuan',
                              style: TextStyle(fontSize: 21),
                            ),
                            SegmentedButton<String>(
                              showSelectedIcon: false,
                              style: SegmentedButton.styleFrom(
                                backgroundColor: const Color(0xFFECE5D0),
                                selectedBackgroundColor: const Color(
                                  0xFFE4D9BB,
                                ),
                                foregroundColor: Colors.black,
                                selectedForegroundColor: Colors.black,
                              ),
                              segments: const [
                                ButtonSegment(value: 'kg', label: Text('Kg')),
                                ButtonSegment(value: 'pcs', label: Text('pcs')),
                                ButtonSegment(
                                  value: 'liter',
                                  label: Text('Liter'),
                                ),
                              ],
                              selected: {_satuan},
                              onSelectionChanged: _saving
                                  ? null
                                  : (s) => setState(() => _satuan = s.single),
                            ),
                            const SizedBox(height: 10),
                            _field(
                              'Kategori',
                              _kategori,
                              'Contoh: Beras',
                              (v) => v!.trim().isEmpty
                                  ? 'Kategori wajib diisi'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.product != null)
                      TextButton.icon(
                        onPressed: _saving ? null : _delete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus produk'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFDC043A),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Menyimpan produk...' : 'Simpan produk'),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller,
    String hint,
    String? Function(String?) validator, {
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 3),
        TextFormField(
          key: Key('produk-${label.toLowerCase()}'),
          controller: controller,
          enabled: !_saving,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          validator: validator,
        ),
      ],
    ),
  );
}
