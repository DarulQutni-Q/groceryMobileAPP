import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme.dart';

/// Layar Scan QR sesuai Figma: viewfinder dengan QR, bracket kuning, garis
/// scan, dan area hijau bawah dengan tombol galeri, capture, dan ganti
/// kamera.
///
/// BATAS: ini baru layout viewfinder. Feed kamera asli dan decode QR belum
/// ada (butuh paket kamera + izin kamera + tes di HP asli, tidak bisa
/// diverifikasi lewat golden test). QR yang tampil adalah QR asli yang
/// bisa dipindai (isi 'GardenMart'), bukan gambar tempelan. Tombol-tombol
/// menampilkan snackbar karena fungsinya belum ada.
class ScanQrPage extends StatelessWidget {
  const ScanQrPage({super.key});

  void _segera(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur kamera segera hadir')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F5EF),
    body: Stack(
      children: [
        Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    Material(
                      color: limeBright,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.maybePop(context),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: gardenInk,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _segera(context),
                      icon: const Icon(Icons.bolt, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    children: [
                      Center(
                        child: QrImageView(
                          data: 'GardenMart',
                          size: 230,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const Positioned(
                        top: 0,
                        left: 0,
                        child: _Corner(top: true, left: true),
                      ),
                      const Positioned(
                        top: 0,
                        right: 0,
                        child: _Corner(top: true, left: false),
                      ),
                      const Positioned(
                        bottom: 0,
                        left: 0,
                        child: _Corner(top: false, left: true),
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: _Corner(top: false, left: false),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            height: 6,
                            width: double.infinity,
                            color: scanYellow,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ClipPath(
              clipper: _ScanBottomClipper(),
              child: Container(
                height: 150,
                width: double.infinity,
                color: limeBright,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => _segera(context),
                        icon: const Icon(
                          Icons.image_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _segera(context),
                        icon: const Icon(
                          Icons.cached,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 105,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              color: gardenInk,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _segera(context),
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 34,
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

/// Satu bracket sudut kuning (bentuk L dari dua border).
class _Corner extends StatelessWidget {
  const _Corner({required this.top, required this.left});
  final bool top;
  final bool left;
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      border: Border(
        top: top
            ? const BorderSide(color: scanYellow, width: 6)
            : BorderSide.none,
        bottom: top
            ? BorderSide.none
            : const BorderSide(color: scanYellow, width: 6),
        left: left
            ? const BorderSide(color: scanYellow, width: 6)
            : BorderSide.none,
        right: left
            ? BorderSide.none
            : const BorderSide(color: scanYellow, width: 6),
      ),
    ),
  );
}

/// Lekuk atas area hijau bawah: dua bukit di kiri-kanan dan lembah di
/// tengah tempat tombol capture menonjol.
class _ScanBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final path = Path()..moveTo(0, 40);
    path.quadraticBezierTo(w * 0.25, -20, w * 0.5, 55);
    path.quadraticBezierTo(w * 0.75, -20, w, 40);
    path.lineTo(w, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
