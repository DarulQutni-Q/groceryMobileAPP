import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
import '../application/produk_provider.dart';
import 'catalog_page.dart';

/// Aksi hasil pindai QR/barcode.
enum ScanAction { openUrl, searchProduct }

/// Keputusan murni dari nilai pindai, tanpa efek samping, supaya bisa
/// di-unit-test tanpa kamera.
({ScanAction action, String value})? decideScanAction(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return (action: ScanAction.openUrl, value: value);
  }
  return (action: ScanAction.searchProduct, value: value);
}

/// Layar Scan QR sesuai Figma: viewfinder kamera langsung dengan bracket
/// kuning, garis scan, dan area hijau bawah dengan tombol galeri, capture,
/// dan ganti kamera.
///
/// Tombol yang berfungsi: flash menyalakan/mematikan lampu, galeri memindai
/// gambar dari galeri, ganti kamera berpindah kamera depan/belakang,
/// tombol tengah menjeda/melanjutkan pemindaian. QR yang terdeteksi:
/// URL dibuka di browser, teks lain dipakai sebagai kata kunci pencarian
/// produk di katalog. Izin kamera ditolak menampilkan pesan + tombol coba
/// lagi di dalam viewfinder.
class ScanQrPage extends ConsumerStatefulWidget {
  const ScanQrPage({super.key});

  @override
  ConsumerState<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends ConsumerState<ScanQrPage> {
  final _controller = MobileScannerController();
  bool _torchOn = false;
  bool _running = true;
  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onBarcode(String? raw) async {
    if (_handling) return;
    final decision = decideScanAction(raw);
    if (decision == null) return;
    _handling = true;
    try {
      if (decision.action == ScanAction.openUrl) {
        await launchUrl(
          Uri.parse(decision.value),
          mode: LaunchMode.externalApplication,
        );
      } else {
        ref.read(produkProvider.notifier).cari(decision.value);
        if (!mounted) return;
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const CatalogPage()),
        );
      }
    } finally {
      _handling = false;
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    final capture = await _controller.analyzeImage(picked.path);
    if (capture == null || !mounted) return;
    await _onBarcode(
      capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue,
    );
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flash tidak tersedia di perangkat ini')),
        );
      }
    }
  }

  Future<void> _toggleRunning() async {
    try {
      if (_running) {
        await _controller.stop();
      } else {
        await _controller.start();
      }
      if (mounted) setState(() => _running = !_running);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera tidak bisa diakses')),
        );
      }
    }
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
                          onPressed: _toggleTorch,
                          tooltip: 'Flash',
                          icon: Icon(
                            Icons.bolt,
                            color: _torchOn ? gardenInk : Colors.black,
                          ),
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
                          Positioned.fill(
                            child: MobileScanner(
                              controller: _controller,
                              onDetect: (capture) => _onBarcode(
                                capture.barcodes.isEmpty
                                    ? null
                                    : capture.barcodes.first.rawValue,
                              ),
                              errorBuilder: (context, error, _) => Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.no_photography_outlined,
                                        size: 40,
                                        color: textGrey,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Kamera tidak bisa diakses. '
                                        'Izinkan akses kamera untuk memindai.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: gardenInk,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton(
                                        onPressed: _toggleRunning,
                                        child: const Text('Coba lagi'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
                            onPressed: _pickFromGallery,
                            tooltip: 'Pilih dari galeri',
                            icon: const Icon(
                              Icons.image_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _controller.switchCamera(),
                            tooltip: 'Ganti kamera',
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
                    onTap: _toggleRunning,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Icon(
                        _running
                            ? Icons.qr_code_scanner
                            : Icons.play_arrow,
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
