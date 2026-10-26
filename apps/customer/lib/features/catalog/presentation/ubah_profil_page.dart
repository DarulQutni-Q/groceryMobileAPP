import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import '../../auth/application/auth_provider.dart';
import '../application/profil_provider.dart';

/// Ubah Profil & Identitas sesuai desain Figma.
///
/// Avatar "DG", 4 field (2 di antaranya berlabel Terverifikasi), dan
/// segmented Jenis Kelamin. Tombol Simpan di area gelombang lime bawah.
///
/// Field diisi dari profil lokal tersimpan (kalau ada) atau akun login.
/// Simpan bersifat lokal di perangkat (belum ada endpoint ubah profil di
/// backend), dan tab Akun langsung menampilkan nilai baru lewat
/// [profilLokalProvider].
class UbahProfilPage extends ConsumerStatefulWidget {
  const UbahProfilPage({super.key});

  @override
  ConsumerState<UbahProfilPage> createState() => _UbahProfilPageState();
}

class _UbahProfilPageState extends ConsumerState<UbahProfilPage> {
  final _nama = TextEditingController();
  final _telepon = TextEditingController();
  final _lahir = TextEditingController();
  final _email = TextEditingController();
  bool _perempuan = true;
  String? _avatarPath;
  bool _prefilled = false;

  @override
  void dispose() {
    _nama.dispose();
    _telepon.dispose();
    _lahir.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() => _avatarPath = picked.path);
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'DG';
    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _simpan() async {
    final nama = _nama.text.trim();
    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong')),
      );
      return;
    }
    await ref
        .read(profilLokalProvider.notifier)
        .simpan(
          nama: nama,
          telepon: _telepon.text.trim(),
          email: _email.text.trim(),
          gender: _perempuan ? 'perempuan' : 'laki-laki',
          tanggalLahir: _lahir.text.trim(),
          avatarPath: _avatarPath,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil tersimpan')),
    );
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final lokal = ref.watch(profilLokalProvider);
    final user = ref.watch(authProvider).user;
    if (!_prefilled && (lokal.nama != null || user != null)) {
      _nama.text = lokal.nama ?? user?.nama ?? '';
      _telepon.text = lokal.telepon ?? user?.phone ?? '';
      _email.text = lokal.email ?? user?.email ?? '';
      _lahir.text = lokal.tanggalLahir ?? '';
      _perempuan = lokal.gender == null
          ? true
          : lokal.gender == 'perempuan';
      _avatarPath = lokal.avatarPath;
      _prefilled = true;
    }
    final avatarLabel = _initials(_nama.text);
    return Scaffold(
      backgroundColor: authBackground,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Ubah Profil & Identitas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: gardenInk,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _pickAvatar,
            child: CircleAvatar(
              radius: 34,
              backgroundColor: gardenInk,
              backgroundImage: _avatarPath != null
                  ? FileImage(File(_avatarPath!))
                  : null,
              child: _avatarPath == null
                  ? Text(
                      avatarLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: limeBright,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ketuk untuk mengganti foto profil',
            style: TextStyle(fontSize: 12, color: textGrey),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Field(hint: 'Full name', controller: _nama),
                const SizedBox(height: 12),
                _Field(hint: 'Nomor Handphone', controller: _telepon),
                const SizedBox(height: 12),
                _FieldWithPill(hint: 'Tanggal Lahir', controller: _lahir),
                const SizedBox(height: 12),
                _FieldWithPill(hint: 'example@gmail.com', controller: _email),
                const SizedBox(height: 16),
                const Text(
                  'Jenis Kelamin',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: gardenInk,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 46,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(color: gardenBorder),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _perempuan = true),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _perempuan
                                  ? gardenInk
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_perempuan)
                                  const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: limeBright,
                                  ),
                                if (_perempuan) const SizedBox(width: 4),
                                Text(
                                  'Perempuan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        _perempuan ? Colors.white : textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _perempuan = false),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _perempuan
                                  ? Colors.transparent
                                  : gardenInk,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!_perempuan)
                                  const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: limeBright,
                                  ),
                                if (!_perempuan) const SizedBox(width: 4),
                                Text(
                                  'Laki-laki',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        _perempuan ? textGrey : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          ClipPath(
            clipper: _BottomWaveClipper(),
            child: Container(
              height: 186,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [limeLight, limeBright],
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 52,
                  child: FilledButton(
                    onPressed: _simpan,
                    style: FilledButton.styleFrom(
                      backgroundColor: gardenInk,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Simpan',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Field isian: kotak abu muda, teks hint abu-abu.
class _Field extends StatelessWidget {
  const _Field({required this.hint, required this.controller});
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: textHint),
          filled: true,
          fillColor: inputBg,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );
}

/// Field isian dengan pill "Terverifikasi" di kanan (pakai Icon, bukan
/// glyph centang, karena font test tidak punya glyph itu).
class _FieldWithPill extends StatelessWidget {
  const _FieldWithPill({required this.hint, required this.controller});
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: textHint),
          filled: true,
          fillColor: inputBg,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: limePale,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Terverifikasi',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF397A24),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.check, size: 11, color: Color(0xFF397A24)),
                ],
              ),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(minHeight: 0),
        ),
      );
}

/// Gelombang bawah: cerminan GardenWaveClipper (melengkung naik di tengah).
class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, 28);
    path.quadraticBezierTo(size.width / 2, -28, size.width, 28);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
