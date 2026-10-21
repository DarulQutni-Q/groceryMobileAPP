import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../application/checkout_provider.dart';

class AlamatFormPage extends ConsumerStatefulWidget {
  const AlamatFormPage({super.key, this.alamat});
  final Alamat? alamat;
  @override
  ConsumerState<AlamatFormPage> createState() => _AlamatFormPageState();
}

class _AlamatFormPageState extends ConsumerState<AlamatFormPage> {
  final form = GlobalKey<FormState>();
  late final nama = TextEditingController(text: widget.alamat?.namaPenerima);
  late final hp = TextEditingController(text: widget.alamat?.noHp);
  late final lengkap = TextEditingController(
    text: widget.alamat?.alamatLengkap,
  );
  late final patokan = TextEditingController(text: widget.alamat?.patokan);
  late String label = widget.alamat?.label ?? 'Rumah';
  bool busy = false;

  @override
  void dispose() {
    nama.dispose();
    hp.dispose();
    lengkap.dispose();
    patokan.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    final payload = {
      'label': label,
      'nama_penerima': nama.text.trim(),
      'no_hp': hp.text.trim(),
      'alamat_lengkap': lengkap.text.trim(),
      'patokan': patokan.text.trim(),
      'is_utama': widget.alamat?.isUtama ?? false,
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

  Widget field(
    String name,
    TextEditingController controller,
    int limit, {
    int lines = 1,
    bool optional = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: Key(
        'alamat-${name == 'Nama penerima'
            ? 'nama'
            : name == 'Nomor HP'
            ? 'hp'
            : name == 'Alamat lengkap'
            ? 'lengkap'
            : 'patokan'}',
      ),
      controller: controller,
      enabled: !busy,
      maxLength: limit,
      minLines: lines,
      maxLines: lines,
      keyboardType: name == 'Nomor HP'
          ? TextInputType.phone
          : lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: name,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      validator: (text) {
        if (!optional && (text == null || text.trim().isEmpty)) {
          return '$name wajib diisi';
        }
        if (name == 'Nomor HP' &&
            !RegExp(r'^\+?[0-9][0-9 ()-]{4,30}[0-9]$')
                .hasMatch(text?.trim() ?? '')) {
          return 'Nomor HP tidak valid';
        }
        return null;
      },
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
                'Label alamat',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [
                  for (final value in ['Rumah', 'Kantor', 'Lainnya'])
                    ChoiceChip(
                      label: Text(value),
                      selected: label == value,
                      onSelected: busy
                          ? null
                          : (_) => setState(() => label = value),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              field('Nama penerima', nama, 120),
              field('Nomor HP', hp, 32),
              field('Alamat lengkap', lengkap, 2000, lines: 4),
              field('Patokan (opsional)', patokan, 500, optional: true),
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
