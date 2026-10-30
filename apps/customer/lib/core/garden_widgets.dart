import 'package:flutter/material.dart';

import 'theme.dart';

/// Header hijau lime dengan lekuk bawah, sesuai desain Figma.
/// Default: judul di tengah, tombol kembali bulat putih di kiri.
/// Varian layar Alamat: [centerTitle] false (judul di kiri setelah tombol
/// kembali), [backFilled] false (tombol kembali outline, bukan putih penuh),
/// [below] untuk bilah putih di bawah judul.
class LimeHeader extends StatelessWidget {
  const LimeHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.height = 150,
    this.topPadding = 10,
    this.showBack = true,
    this.centerTitle = true,
    this.backFilled = true,
    this.below,
  });
  final String title;
  final List<Widget> actions;
  final double height;
  final double topPadding;
  final bool showBack;
  final bool centerTitle;
  final bool backFilled;
  final Widget? below;

  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: GardenWaveClipper(),
    child: Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [limeBright, limeLight],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showBack)
                    RoundIconButton(
                      icon: Icons.arrow_back,
                      filled: backFilled,
                      onPressed: () => Navigator.maybePop(context),
                    )
                  else if (centerTitle)
                    const SizedBox(width: 40),
                  if (centerTitle)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: gardenInk,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: gardenInk,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (centerTitle)
                    if (actions.isEmpty)
                      const SizedBox(width: 40)
                    else
                      Row(mainAxisSize: MainAxisSize.min, children: actions)
                  else if (actions.isNotEmpty)
                    Row(mainAxisSize: MainAxisSize.min, children: actions),
                ],
              ),
              if (below != null) ...[const SizedBox(height: 12), below!],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Tombol ikon bulat: putih penuh (filled) atau outline, dipakai header
/// lime dan header keranjang.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.filled = true,
    this.color = gardenInk,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;
  final Color color;
  @override
  Widget build(BuildContext context) => Material(
    color: filled ? Colors.white : Colors.transparent,
    shape: CircleBorder(
      side: filled ? BorderSide.none : BorderSide(color: color, width: 1.5),
    ),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onPressed,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, size: 20, color: color),
      ),
    ),
  );
}

/// Area hijau bawah dengan lekuk atas (naik di tengah), untuk layar Alamat
/// dan Ubah Profil. Anaknya biasanya tombol gelap.
class GreenBottomArea extends StatelessWidget {
  const GreenBottomArea({super.key, required this.child, this.height = 150});
  final Widget child;
  final double height;
  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: _HillClipper(),
    child: Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [limeLight, limeBright],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 44, 20, 24),
        child: Align(alignment: Alignment.center, child: child),
      ),
    ),
  );
}

/// Lekuk atas area hijau bawah: naik di tengah, turun di sisi.
class _HillClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, 28);
    path.quadraticBezierTo(size.width / 2, -18, size.width, 28);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Lekuk bawah header: turun di tengah, naik di sisi.
/// Dipakai LimeHeader dan header Poinku.
class GardenWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 28);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 18,
      size.width,
      size.height - 28,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Tombol utama hijau gelap, bentuk pil penuh.
class DarkPillButton extends StatelessWidget {
  const DarkPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 56,
    this.fontSize = 16,
  });
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double height;
  final double fontSize;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: gardenInk,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(height / 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 8)],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              // Warna eksplisit: tanpa ini, di dalam _PaymentBar keranjang
              // (Material totalGreen) teks tombol mewarisi warna abu-abu
              // gelap #657168 dari DefaultTextStyle sekitar, bukan putih
              // dari foregroundColor tombol. Di layar Alamat tidak berubah,
              // karena di sana teksnya memang sudah putih.
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Kartu putih dengan radius besar dan border hijau muda.
class WhiteCard extends StatelessWidget {
  const WhiteCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  @override
  Widget build(BuildContext context) => Card(
    margin: margin,
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: gardenBorder),
    ),
    child: Padding(padding: padding, child: child),
  );
}

/// Bottom navigation sesuai Figma: 5 item, tombol Scan QR menonjol di tengah.
class GardenBottomNav extends StatelessWidget {
  const GardenBottomNav({
    super.key,
    required this.index,
    required this.onSelect,
  });
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined, Icons.home, 'Beranda'),
      (Icons.local_offer_outlined, Icons.local_offer, 'Promo'),
      (Icons.qr_code_scanner, Icons.qr_code_scanner, 'Scan QR'),
      (Icons.receipt_long_outlined, Icons.receipt_long, 'Pesanan'),
      (Icons.person_outline, Icons.person, 'Akun'),
    ];
    return SizedBox(
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: gardenBorder)),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    if (i == 2)
                      const Expanded(child: SizedBox())
                    else
                      Expanded(
                        child: _NavItem(
                          icon: index == i ? items[i].$2 : items[i].$1,
                          label: items[i].$3,
                          active: index == i,
                          onTap: () => onSelect(i),
                        ),
                      ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -22,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => onSelect(2),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: gardenInk,
                    // Lingkaran penuh sesuai referensi; sebelumnya kotak
                    // membulat (radius 16) yang bikin nav kelihatan beda.
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 28,
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            // Hijau terang sesuai referensi; sebelumnya hijau pucat.
            color: active ? const Color(0xFF96E23B) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 24,
            color: active ? gardenInk : const Color(0xFF6B7F60),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? gardenInk : const Color(0xFF6B7F60),
          ),
        ),
      ],
    ),
  );
}
