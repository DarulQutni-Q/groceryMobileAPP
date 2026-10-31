import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:grocery_shared/shared.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../checkout/presentation/struk_page.dart';
import '../../../core/theme.dart';
import 'catalog_widgets.dart' show rupiah;

/// Chat dengan kurir toko.
///
/// Halaman ini SIMULASI LOKAL: tidak ada backend chat kurir, jadi tidak
/// ada balasan kurir sungguhan. Yang berfungsi beneran: pesan yang dikirim
/// pengguna (teks dan foto) tampil sebagai bubble sendiri dan tersimpan
/// lokal per pesanan lewat SharedPreferences.
///
/// Data yang tampil berasal dari [order] yang dioper dari halaman Pesanan:
/// nomor, status, dan total pesanan adalah data backend asli. Identitas
/// kurir tampil generik ("Kurir Toko") karena API pesanan tidak
/// mengembalikan nama, kendaraan, plat, maupun nomor telepon kurir.
/// Percakapan referensi Figma (nama, plat, isi chat) TIDAK dipakai sebagai
/// data: chat baru mulai kosong, bukan dari percakapan referensi.
///
/// Keyboard sistem tidak dirender (bukan bagian UI aplikasi).
class ChatDriverPage extends StatefulWidget {
  const ChatDriverPage({super.key, this.order});

  /// Pesanan yang sedang dibahas. Boleh null (pemakaian langsung tanpa
  /// konteks pesanan): kartu pesanan dan pesan sistem disembunyikan.
  final Pesanan? order;

  @override
  State<ChatDriverPage> createState() => _ChatDriverPageState();
}

class _ChatMessage {
  const _ChatMessage({
    required this.mine,
    this.text,
    this.imagePath,
    required this.sentAt,
  });

  final bool mine;
  final String? text;
  final String? imagePath;
  final DateTime sentAt;

  String get time =>
      '${sentAt.hour}:${sentAt.minute.toString().padLeft(2, '0')}';

  Map<String, Object?> toJson() => {
    'mine': mine,
    'text': text,
    'imagePath': imagePath,
    'sentAt': sentAt.toIso8601String(),
  };

  static _ChatMessage? fromJson(Object? value) {
    if (value is! Map<String, Object?>) return null;
    final sentAt = DateTime.tryParse('${value['sentAt']}');
    if (sentAt == null) return null;
    return _ChatMessage(
      mine: value['mine'] == true,
      text: value['text'] as String?,
      imagePath: value['imagePath'] as String?,
      sentAt: sentAt,
    );
  }
}

const _bulan = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Judul status pesanan. Bukan estimasi waktu: backend tidak punya ETA,
/// jadi judulnya status, bukan "Tiba dalam ~8 Menit" karangan.
/// Pemetaan ini sama dengan judul kartu tracking di halaman Pesanan.
String _statusTitle(String status) => switch (status) {
  'baru' => 'Menunggu konfirmasi toko',
  'diproses' => 'Pesanan sedang diproses',
  'dikemas' => 'Pesanan sudah dikemas',
  'diantar' => 'Pesanan dalam perjalanan',
  'selesai' => 'Pesanan selesai',
  'dibatalkan' => 'Pesanan dibatalkan',
  'ditolak' => 'Pesanan dibatalkan',
  _ => 'Pesanan dalam proses',
};

class _ChatDriverPageState extends State<ChatDriverPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  var _messages = const <_ChatMessage>[];

  String get _prefsKey => 'chat_kurir_${widget.order?.kode ?? 'tanpa_kode'}';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void didUpdateWidget(ChatDriverPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Halaman yang sama dipakai untuk pesanan berbeda (mis. rebuild dari
    // parent): muat ulang riwayat sesuai kode pesanan baru, jangan tampilkan
    // riwayat pesanan lama.
    if (oldWidget.order?.kode != widget.order?.kode) {
      _messages = const [];
      _loadMessages();
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final loaded = decoded
          .map(_ChatMessage.fromJson)
          .whereType<_ChatMessage>()
          // Foto picker tersimpan di cache yang bisa dibersihkan sistem:
          // pesan foto yang filenya sudah tidak ada tidak ditampilkan
          // daripada bubble rusak.
          .where((m) => m.imagePath == null || File(m.imagePath!).existsSync())
          .toList();
      if (!mounted) return;
      setState(() => _messages = loaded);
      _scrollToBottom();
    } catch (_) {
      // Data lokal rusak: mulai dari chat kosong daripada crash.
    }
  }

  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(_messages.map((m) => m.toJson()).toList()),
      );
    } catch (_) {
      // Penyimpanan lokal gagal: pesan tetap tampil di sesi ini.
    }
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
      _messages = [
        ..._messages,
        _ChatMessage(mine: true, text: text, sentAt: DateTime.now()),
      ];
      _input.clear();
    });
    _saveMessages();
    _scrollToBottom();
  }

  Future<void> _sendImage(ImageSource source) async {
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: source);
    } catch (_) {
      return;
    }
    if (picked == null || !mounted) return;
    setState(() {
      _messages = [
        ..._messages,
        _ChatMessage(
          mine: true,
          imagePath: picked!.path,
          sentAt: DateTime.now(),
        ),
      ];
    });
    _saveMessages();
    _scrollToBottom();
  }

  void _showPhoneDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        // Teks sama dengan dialog telepon di halaman Pesanan: tidak ada
        // nomor telepon kurir di data manapun, jadi tidak dikarang.
        // Tombol "Chat Driver" tidak ada di sini karena pengguna sudah
        // berada di halaman chat.
        title: const Text('Telepon Kurir'),
        content: const Text(
          'Nomor telepon kurir belum tersedia untuk pesanan ini. '
          'Kamu tetap bisa menghubungi kurir lewat Chat Driver.',
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

  void _lihatDetail() {
    final order = widget.order;
    if (order == null) return;
    // Pemetaan sama dengan _lihatStruk di halaman Pesanan: Kasir, kurir,
    // metode bayar, poin, stempel, dan barcode tidak ada di API pesanan,
    // jadi dikosongkan dan barisnya disembunyikan StrukPage.
    final data = StrukData(
      nomor: '#${order.kode}',
      waktu: _waktu(order.createdAt),
      kasir: '',
      kurir: '',
      items: order.items
          .map(
            (item) => StrukItem(
              nama: item.namaSnapshot,
              qty: '${item.qty}x @ ${rupiah(item.hargaSnapshot)}',
              hargaSatuan: rupiah(item.hargaSnapshot),
              total: rupiah(item.hargaSnapshot * item.qty),
            ),
          )
          .toList(),
      totalBelanja: rupiah(order.subtotal),
      jumlahBarang: '${order.items.length} Barang',
      diskonPromo: order.diskon > 0 ? '-${rupiah(order.diskon)}' : '',
      diskonVoucher: '',
      biayaLayanan: rupiah(order.biayaLayanan),
      totalBayar: rupiah(order.total),
      metodeBayar: '',
      metodeId: '',
      poin: '',
      stempel: '',
      kodeBarcode: '',
    );
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => StrukPage(data: data)),
    );
  }

  String _headerStatus() {
    final order = widget.order;
    if (order == null) return 'Kurir GardenMart';
    if (order.status == 'diantar') return 'Sedang mengantar pesananmu';
    return _statusTitle(order.status);
  }

  String _dayLabel() {
    if (_messages.isEmpty) return 'Hari Ini';
    final latest = _messages.last.sentAt;
    final now = DateTime.now();
    if (latest.year == now.year &&
        latest.month == now.month &&
        latest.day == now.day) {
      return 'Hari Ini';
    }
    return '${latest.day} ${_bulan[latest.month - 1]} ${latest.year}';
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      backgroundColor: authBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 12),
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: gardenInk,
                    child: Icon(Icons.person, size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kurir Toko',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: gardenInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _headerStatus(),
                          style: const TextStyle(fontSize: 11, color: textGrey),
                        ),
                      ],
                    ),
                  ),
                  _CircleButton(icon: Icons.phone, onTap: _showPhoneDialog),
                ],
              ),
            ),
            if (order != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F3D8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 22,
                        color: gardenInk,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pesanan #${order.kode}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: gardenInk,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_statusTitle(order.status)} • ${rupiah(order.total)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: _lihatDetail,
                        child: const Text(
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
                  Center(child: _DateChip(_dayLabel())),
                  const SizedBox(height: 12),
                  // Pesan sistem hanya kalau pesanan benar-benar sedang
                  // diantar (sudah diserahkan ke kurir).
                  if (order != null && order.status == 'diantar') ...[
                    const _SystemMessage(
                      'Pesanan telah diserahkan ke Kurir Toko',
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_messages.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text(
                        'Belum ada pesan untuk pesanan ini.\n'
                        'Pesan yang kamu kirim tersimpan di perangkat ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: textGrey),
                      ),
                    ),
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
}

String _tanggal(DateTime value) {
  final local = value.toLocal();
  return '${local.day} ${_bulan[local.month - 1]} ${local.year}';
}

String _waktu(DateTime value) {
  final local = value.toLocal();
  return '${_tanggal(local)}, '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')} WIB';
}

/// Tombol lingkaran putih di header, sesuai referensi (panah kembali dan
/// telepon masing-masing di dalam lingkaran putih).
class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    customBorder: const CircleBorder(),
    child: Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 22, color: gardenInk),
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
      const Icon(Icons.inventory_2_outlined, size: 16, color: gardenInk),
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
    mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                      color: mine ? const Color(0xFFB9C4B4) : textGrey,
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
