import 'package:flutter/material.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';

/// Ubah Profil & Identitas sesuai desain Figma.
///
/// Avatar "DG", 4 field (2 di antaranya berlabel Terverifikasi), dan
/// segmented Jenis Kelamin. Tombol Simpan di area gelombang lime bawah.
class UbahProfilPage extends StatefulWidget {
  const UbahProfilPage({super.key});

  @override
  State<UbahProfilPage> createState() => _UbahProfilPageState();
}

class _UbahProfilPageState extends State<UbahProfilPage> {
  bool _perempuan = true;

  @override
  Widget build(BuildContext context) => Scaffold(
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
        const CircleAvatar(
          radius: 34,
          backgroundColor: gardenInk,
          child: Text(
            'DG',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: limeBright,
            ),
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
              const _Field(hint: 'Full name'),
              const SizedBox(height: 12),
              const _Field(hint: 'Nomor Handphone'),
              const SizedBox(height: 12),
              const _FieldWithPill(hint: 'Tanggal Lahir'),
              const SizedBox(height: 12),
              const _FieldWithPill(hint: 'example@gmail.com'),
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
                            color: _perempuan ? gardenInk : Colors.transparent,
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
                            color: _perempuan ? Colors.transparent : gardenInk,
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
                  onPressed: () {},
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

/// Field isian: kotak abu muda, teks hint abu-abu.
class _Field extends StatelessWidget {
  const _Field({required this.hint});
  final String hint;

  @override
  Widget build(BuildContext context) => TextField(
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
  const _FieldWithPill({required this.hint});
  final String hint;

  @override
  Widget build(BuildContext context) => TextField(
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
