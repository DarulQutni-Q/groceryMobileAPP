import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../checkout/presentation/struk_page.dart';

import '../../../core/theme.dart';

/// Chat dengan kurir toko sesuai desain Figma.
/// Keyboard sistem tidak dirender (bukan bagian UI aplikasi).
class ChatDriverPage extends StatefulWidget {
  const ChatDriverPage({super.key});

  @override
  State<ChatDriverPage> createState() => _ChatDriverPageState();
}

class _ChatMessage {
  const _ChatMessage({required this.mine, this.text, this.imagePath, required this.time});
  final bool mine;
  final String? text;
  final String? imagePath;
  final String time;
}

class _ChatDriverPageState extends State<ChatDriverPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      mine: false,
      text: 'Halo kak Darul, pesanan GardenMart sudah jalan ya. '
          'Sesuai titik di depan pagar hitam rumah no 42?',
      time: '14:33',
    ),
    const _ChatMessage(
      mine: true,
      text: 'Iya betul pak Budi. Nanti tolong titip di meja teras '
          'aja ya pak kalau sudah sampai. Terima kasih!',
      time: '14:34',
    ),
    const _ChatMessage(
      mine: false,
      text: 'Siap kak Darul, sekitar 3 menit lagi sampai. '
          'Nanti saya fotokan bukti serah terimanya.',
      time: '14:35',
    ),
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _now() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _sendText() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(mine: true, text: text, time: _now()));
      _input.clear();
    });
    _scrollToBottom();
  }

  Future<void> _sendImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null || !mounted) return;
    setState(() {
      _messages.add(
        _ChatMessage(mine: true, imagePath: picked.path, time: _now()),
      );
    });
    _scrollToBottom();
  }

  void _showDriverDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pak Budi'),
        content: const Text(
          'Honda Beat • BK 4122 QD\nKurir GardenMart\n\n'
          'Nomor telepon kurir tidak tersedia di data pesanan, '
          'jadi panggilan belum bisa dilakukan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

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
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 22,
                    color: gardenInk,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: gardenInk,
                  child: Icon(Icons.person, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pak Budi (Kurir Toko)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: gardenInk,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Online • Honda Beat BK 4122 QD',
                        style: TextStyle(fontSize: 11, color: textGrey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showDriverDialog,
                  icon: const Icon(
                    Icons.phone,
                    size: 22,
                    color: gardenInk,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
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
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: gardenInk,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sedang diantar (~5 mnt) • Rp 67.600',
                          style: TextStyle(fontSize: 11, color: textGrey),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(builder: (_) => const StrukPage()),
                    ),
                    child: Text(
                      'Lihat Detail ›',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF397A24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                const Center(
                  child: _DateChip('Hari Ini, 14:32'),
                ),
                const SizedBox(height: 12),
                const _SystemMessage(
                  'Pesanan telah diserahkan ke Kurir Toko',
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < _messages.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _Bubble(
                    mine: _messages[i].mine,
                    text: _messages[i].text,
                    imagePath: _messages[i].imagePath,
                    time: _messages[i].time,
                  ),
                ],
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
                InkWell(
                  onTap: () => _sendImage(ImageSource.camera),
                  customBorder: const CircleBorder(),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 24,
                    color: gardenInk,
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _sendImage(ImageSource.gallery),
                  customBorder: const CircleBorder(),
                  child: const Icon(
                    Icons.attach_file,
                    size: 24,
                    color: gardenInk,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _input,
                    onSubmitted: (_) => _sendText(),
                    decoration: const InputDecoration(
                      hintText: 'Ketik pesan...',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _sendText,
                  customBorder: const CircleBorder(),
                  child: Container(
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
                ),
              ],
            ),
          ),
        ],
      ),
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
    this.text,
    this.imagePath,
    required this.time,
  });
  final bool mine;
  final String? text;
  final String? imagePath;
  final String time;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisAlignment:
        mine ? MainAxisAlignment.end : MainAxisAlignment.start,
    children: [
      if (!mine) ...[
        const CircleAvatar(
          radius: 12,
          backgroundColor: gardenInk,
          child: Icon(Icons.person, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
      Flexible(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
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
              if (imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(imagePath!),
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              if (text != null)
                Text(
                  text!,
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
