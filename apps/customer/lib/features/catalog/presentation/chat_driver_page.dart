import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Chat dengan kurir toko sesuai desain Figma.
/// Keyboard sistem tidak dirender (bukan bagian UI aplikasi).
class ChatDriverPage extends StatelessWidget {
  const ChatDriverPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: authBackground,
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                _CircleIcon(icon: Icons.arrow_back, onPressed: () {}),
                const SizedBox(width: 12),
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: gardenInk,
                  child: Icon(Icons.person, size: 24, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pak Budi (Kurir Toko)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: gardenInk,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Online • Honda Beat BK 4122 QD',
                        style: TextStyle(fontSize: 12, color: textGrey),
                      ),
                    ],
                  ),
                ),
                _CircleIcon(icon: Icons.phone, onPressed: () {}),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 22,
                    color: gardenInk,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pesanan #GM-8921',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: gardenInk,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sedang diantar (~5 mnt) • Rp 67.600',
                          style: TextStyle(fontSize: 12, color: textGrey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Lihat Detail ›',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF397A24),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: const [
                Center(
                  child: _DateChip('Hari Ini, 14:32'),
                ),
                SizedBox(height: 12),
                _SystemMessage(
                  'Pesanan telah diserahkan ke Kurir Toko',
                ),
                SizedBox(height: 12),
                _Bubble(
                  mine: false,
                  text:
                      'Halo kak Darul, pesanan GardenMart sudah jalan ya. '
                      'Sesuai titik di depan pagar hitam rumah no 42?',
                  time: '14:33',
                ),
                SizedBox(height: 10),
                _Bubble(
                  mine: true,
                  text:
                      'Iya betul pak Budi. Nanti tolong titip di meja teras '
                      'aja ya pak kalau sudah sampai. Terima kasih!',
                  time: '14:34',
                ),
                SizedBox(height: 10),
                _Bubble(
                  mine: false,
                  text:
                      'Siap kak Darul, sekitar 3 menit lagi sampai. '
                      'Nanti saya fotokan bukti serah terimanya.',
                  time: '14:35',
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: gardenBorder)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 24,
                  color: gardenInk,
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.attach_file,
                  size: 24,
                  color: gardenInk,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: gardenInk,
                  ),
                  child: const Icon(
                    Icons.send,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
    ),
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: gardenInk),
      padding: EdgeInsets.zero,
    ),
  );
}

class _DateChip extends StatelessWidget {
  const _DateChip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFDDE8D5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textGrey,
      ),
    ),
  );
}

class _SystemMessage extends StatelessWidget {
  const _SystemMessage(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(
        Icons.inventory_2_outlined,
        size: 16,
        color: gardenInk,
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE4F3D8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: gardenInk,
            ),
          ),
        ),
      ),
    ],
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.mine,
    required this.text,
    required this.time,
  });
  final bool mine;
  final String text;
  final String time;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment:
        mine ? MainAxisAlignment.end : MainAxisAlignment.start,
    children: [
      Flexible(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 290),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: mine ? gardenInk : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: mine ? Colors.white : gardenInk,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: mine
                          ? const Color(0xFFB9C4B4)
                          : textGrey,
                    ),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.done_all,
                      size: 13,
                      color: Color(0xFF7CC32E),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
