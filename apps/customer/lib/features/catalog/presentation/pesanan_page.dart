import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import '../../auth/application/auth_provider.dart';
import '../../checkout/presentation/struk_page.dart';
import '../application/pesanan_provider.dart';
import '../application/produk_provider.dart';
import 'cart_page.dart';
import 'catalog_page.dart';
import 'catalog_widgets.dart';
import 'chat_driver_page.dart';

/// Tab Pesanan: Pesanan Saya dari backend GET /pesanan.
///
/// Pesanan dimuat dari backend, bukan contoh Figma. API pesanan tidak
/// mengembalikan nama cabang maupun data kurir, jadi label toko memakai
/// 'GardenMart' (merek saja, bukan cabang karangan) dan baris kurir hanya
/// tampil untuk pesanan yang sedang diantar dengan label generik.
class PesananPage extends ConsumerStatefulWidget {
  const PesananPage({
    super.key,
    this.onLihatStruk,
    this.onChatDriver,
    this.onBeliLagi,
    this.showBack = false,
  });

  final bool showBack;
  final ValueChanged<Pesanan>? onLihatStruk;
  final VoidCallback? onChatDriver;
  final ValueChanged<Pesanan>? onBeliLagi;

  @override
  ConsumerState<PesananPage> createState() => _PesananPageState();
}

bool _isActive(String status) =>
    const {'baru', 'diproses', 'dikemas', 'diantar'}.contains(status);
bool _isDone(String status) => status == 'selesai';
bool _isCancelled(String status) =>
    status == 'dibatalkan' || status == 'ditolak';

String _statusLabel(String status) => switch (status) {
  'baru' => 'Baru',
  'diproses' => 'Diproses',
  'dikemas' => 'Dikemas',
  'diantar' => 'Diantar',
  'selesai' => 'Selesai',
  'dibatalkan' => 'Dibatalkan',
  'ditolak' => 'Ditolak',
  _ => 'Diproses',
};

/// Judul kartu tracking per status. Bukan estimasi waktu: backend tidak
/// punya ETA, jadi judulnya status, bukan 'Tiba dalam ~8 Menit' karangan.
String _activeTitle(String status) => switch (status) {
  'baru' => 'Menunggu konfirmasi toko',
  'diproses' => 'Pesanan sedang diproses',
  'dikemas' => 'Pesanan sudah dikemas',
  'diantar' => 'Pesanan dalam perjalanan',
  _ => 'Pesanan dalam proses',
};

/// (langkah selesai, langkah aktif) untuk timeline 4 langkah
/// Dikonfirmasi / Dikemas / Dlm Perjalanan / Tiba.
/// aktif -1 berarti semua langkah selesai (pesanan selesai).
(int, int) _timeline(String status) => switch (status) {
  'baru' => (0, 0),
  'diproses' => (1, 1),
  'dikemas' => (2, 2),
  'diantar' => (2, 2),
  'selesai' => (4, -1),
  _ => (0, 0),
};

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

/// 'N Barang' memakai jumlah jenis barang (distinct), bukan total qty:
/// referensi menulis '3 Barang' untuk Indomie qty 5.
String _ringkasanBarang(Pesanan order) {
  final names = order.items.map((item) => item.namaSnapshot).join(', ');
  return '${order.items.length} Barang: $names';
}

class _PesananPageState extends ConsumerState<PesananPage> {
  var _tab = 0;
  var _searching = false;
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(pesananProvider);
    await ref.read(pesananProvider.future);
  }

  void _toggleSearch() {
    setState(() {
      if (_searching) {
        _searching = false;
        _query = '';
        _searchController.clear();
      } else {
        _searching = true;
      }
    });
  }

  void _chatDriver() {
    if (widget.onChatDriver != null) {
      widget.onChatDriver!();
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const ChatDriverPage()),
    );
  }

  void _phoneDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Telepon Kurir'),
        content: const Text(
          'Nomor telepon kurir belum tersedia untuk pesanan ini. '
          'Kamu tetap bisa menghubungi kurir lewat Chat Driver.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _chatDriver();
            },
            child: const Text('Chat Driver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _beliLagi(Pesanan order) async {
    if (widget.onBeliLagi != null) {
      widget.onBeliLagi!(order);
      return;
    }
    final user = ref.read(authProvider).user;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Masuk dulu untuk berbelanja')),
        );
      }
      return;
    }
    // Catatan: notifier keranjang bersifat autoDispose, jadi proses tambah
    // ini mengandalkan ada widget lain yang menontonnya (di aplikasi, tab
    // Beranda di shell menonton keranjang dan IndexedStack membuatnya tetap
    // terpasang saat tab Pesanan dibuka). Tanpa penonton, tambahItem gagal
    // diam-diam karena notifier dibuang di tengah proses.
    final api = ref.read(produkApiProvider);
    var added = 0;
    var skipped = 0;
    for (final item in order.items) {
      final produkId = item.produkId;
      if (produkId == null) {
        skipped++;
        continue;
      }
      try {
        final produk = await api.detail(produkId);
        if (!mounted) return;
        if (await tambahKeKeranjang(context, ref, produk, qty: item.qty)) {
          added++;
        } else {
          skipped++;
        }
      } catch (_) {
        skipped++;
      }
    }
    if (!mounted) return;
    if (skipped > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$skipped barang tidak bisa ditambahkan lagi')),
      );
    }
    if (added > 0) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => const CartPage()),
      );
    }
  }

  void _lihatStruk(Pesanan order) {
    if (widget.onLihatStruk != null) {
      widget.onLihatStruk!(order);
      return;
    }
    final data = StrukData(
      nomor: '#${order.kode}',
      waktu: _waktu(order.createdAt),
      // Kasir, kurir, metode bayar, poin, stempel, dan barcode tidak ada
      // di API pesanan: dikosongkan dan barisnya disembunyikan StrukPage.
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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pesananProvider);
    return Column(
      children: [
        LimeHeader(
          title: 'Pesanan Saya',
          showBack: widget.showBack,
          centerTitle: false,
          height: 185,
          topPadding: 38,
          actions: [
            RoundIconButton(icon: Icons.search, onPressed: _toggleSearch),
          ],
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                _ErrorState(onRetry: () => ref.invalidate(pesananProvider)),
            data: (orders) => _buildList(orders),
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<Pesanan> orders) {
    final active = orders.where((o) => _isActive(o.status)).toList();
    final done = orders.where((o) => _isDone(o.status)).toList();
    final cancelled = orders.where((o) => _isCancelled(o.status)).toList();
    final searching = _searching && _query.trim().isNotEmpty;

    final children = <Widget>[];
    if (_searching) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            key: const Key('pesanan-search-field'),
            controller: _searchController,
            autofocus: true,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Cari pesanan, barang, atau kode…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSearch,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: gardenBorder),
              ),
            ),
          ),
        ),
      );
    }
    if (searching) {
      final q = _query.trim().toLowerCase();
      final found = orders
          .where(
            (o) =>
                o.kode.toLowerCase().contains(q) ||
                _statusLabel(o.status).toLowerCase().contains(q) ||
                o.items.any(
                  (item) => item.namaSnapshot.toLowerCase().contains(q),
                ),
          )
          .toList();
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            '${found.length} hasil untuk "$_query"',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: gardenInk,
            ),
          ),
        ),
      );
      for (final order in found) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _isActive(order.status)
                ? _TrackingCard(
                    order: order,
                    onChatDriver: _chatDriver,
                    onPhone: _phoneDialog,
                  )
                : _HistoryCard(
                    order: order,
                    onBeliLagi: () => _beliLagi(order),
                    onLihatStruk: () => _lihatStruk(order),
                  ),
          ),
        );
      }
      if (found.isEmpty) {
        children.add(
          const _EmptyState(
            title: 'Tidak ada pesanan yang cocok',
            subtitle: 'Coba kata kunci lain, misalnya nama barang atau kode.',
          ),
        );
      }
    } else {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _OrderFilter(
                key: const Key('pesanan-tab-0'),
                label: 'Dalam Proses (${active.length})',
                active: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              const SizedBox(width: 8),
              _OrderFilter(
                key: const Key('pesanan-tab-1'),
                label: 'Selesai',
                active: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
              const SizedBox(width: 8),
              _OrderFilter(
                key: const Key('pesanan-tab-2'),
                label: 'Dibatalkan',
                active: _tab == 2,
                onTap: () => setState(() => _tab = 2),
              ),
            ],
          ),
        ),
      );
      final shown = _tab == 0
          ? active
          : _tab == 1
          ? done
          : cancelled;
      if (_tab == 0) {
        for (final order in shown) {
          children.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _TrackingCard(
                order: order,
                onChatDriver: _chatDriver,
                onPhone: _phoneDialog,
              ),
            ),
          );
        }
        if (shown.isEmpty) {
          children.add(
            const _EmptyState(
              title: 'Belum ada pesanan dalam proses',
              subtitle: 'Pesananmu akan tampil di sini setelah checkout.',
              showShopButton: true,
            ),
          );
        }
        children.add(
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Riwayat Pesanan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: gardenInk,
              ),
            ),
          ),
        );
        for (final order in [...done, ...cancelled]) {
          children.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _HistoryCard(
                order: order,
                onBeliLagi: () => _beliLagi(order),
                onLihatStruk: () => _lihatStruk(order),
              ),
            ),
          );
        }
      } else {
        for (final order in shown) {
          children.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _HistoryCard(
                order: order,
                onBeliLagi: () => _beliLagi(order),
                onLihatStruk: () => _lihatStruk(order),
              ),
            ),
          );
        }
        if (shown.isEmpty) {
          children.add(
            _EmptyState(
              title: _tab == 1
                  ? 'Belum ada pesanan selesai'
                  : 'Belum ada pesanan dibatalkan',
              subtitle: 'Pesananmu akan tampil di sini setelah checkout.',
              showShopButton: true,
            ),
          );
        }
      }
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: children,
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({
    required this.order,
    required this.onChatDriver,
    required this.onPhone,
  });

  final Pesanan order;
  final VoidCallback onChatDriver;
  final VoidCallback onPhone;

  @override
  Widget build(BuildContext context) {
    final timeline = _timeline(order.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 20,
                color: gardenInk,
              ),
              const SizedBox(width: 8),
              const Text(
                'GardenMart',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: gardenInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _activeTitle(order.status),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: gardenInk,
            ),
          ),
          const SizedBox(height: 14),
          _Timeline(done: timeline.$1, current: timeline.$2),
          if (order.status == 'diantar') ...[
            const SizedBox(height: 14),
            Row(
              children: [
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
                        'Kurir GardenMart',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: gardenInk,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Mengantar pesananmu',
                        style: TextStyle(fontSize: 11, color: textGrey),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: onChatDriver,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 34),
                      side: const BorderSide(color: gardenBorder),
                      foregroundColor: gardenInk,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 14),
                    label: const Text('Chat Driver'),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onPhone,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE4F3D8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone, size: 17, color: gardenInk),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 16, color: textGrey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _ringkasanBarang(order),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: textGrey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'Total Pembayaran:',
                style: TextStyle(fontSize: 12, color: textGrey),
              ),
              const Spacer(),
              Text(
                rupiah(order.total),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: gardenInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.order,
    required this.onBeliLagi,
    required this.onLihatStruk,
  });

  final Pesanan order;
  final VoidCallback onBeliLagi;
  final VoidCallback onLihatStruk;

  @override
  Widget build(BuildContext context) {
    final cancelled = _isCancelled(order.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 20,
                color: gardenInk,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GardenMart',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: gardenInk,
                      ),
                    ),
                    Text(
                      _tanggal(order.createdAt),
                      style: const TextStyle(fontSize: 11, color: textGrey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cancelled
                      ? const Color(0xFFFBE9E7)
                      : const Color(0xFFE4F3D8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(order.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cancelled
                        ? const Color(0xFFB22E32)
                        : const Color(0xFF397A24),
                  ),
                ),
              ),
            ],
          ),
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < order.items.length && i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _Thumb(index: i),
                ],
                if (order.items.length > 3) ...[
                  const SizedBox(width: 8),
                  _ThumbMore(count: order.items.length - 3),
                ],
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Spacer(),
              Text(
                '${order.items.length} Barang, ${rupiah(order.total)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: gardenInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onBeliLagi,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Beli lagi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: gardenInk,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onLihatStruk,
                  icon: const Icon(Icons.receipt_outlined, size: 16),
                  label: const Text('Lihat struk'),
                  style: FilledButton.styleFrom(
                    backgroundColor: gardenInk,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.index});

  final int index;

  static const _colors = [
    Color(0xFFE3F2FD),
    Color(0xFFFFF3E0),
    Color(0xFFFCE4EC),
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: _colors[index % _colors.length],
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(
      Icons.shopping_basket_outlined,
      size: 26,
      color: textGrey,
    ),
  );
}

class _ThumbMore extends StatelessWidget {
  const _ThumbMore({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: const Color(0xFFE8F1E2),
      borderRadius: BorderRadius.circular(12),
    ),
    alignment: Alignment.center,
    child: Text(
      '+$count',
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: gardenInk,
      ),
    ),
  );
}

/// Timeline 4 langkah dengan garis penghubung utuh, bukan putus-putus:
/// garis hijau dari langkah pertama sampai langkah aktif, sisanya hijau
/// pucat. Lingkaran: selesai = hijau + centang, aktif = gelap + ikon,
/// berikutnya = putih + outline.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.done, required this.current});

  final int done;
  final int current;

  static const _labels = ['Dikonfirmasi', 'Dikemas', 'Dlm Perjalanan', 'Tiba'];
  static const _icons = [
    Icons.check,
    Icons.inventory_2_outlined,
    Icons.local_shipping_outlined,
    Icons.location_on_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final step = width / 4;
        final firstCenter = step / 2;
        final lastCenter = width - step / 2;
        final greenEnd = current < 0
            ? lastCenter
            : done == 0
            ? firstCenter
            : firstCenter + current * step;
        return Stack(
          children: [
            Positioned(
              left: firstCenter,
              top: 15,
              child: Container(
                width: (greenEnd - firstCenter).clamp(0.0, width),
                height: 2,
                color: const Color(0xFF397A24),
              ),
            ),
            Positioned(
              left: greenEnd,
              top: 15,
              child: Container(
                width: (lastCenter - greenEnd).clamp(0.0, width),
                height: 2,
                color: const Color(0xFFD9E6CF),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < done || current < 0
                                ? const Color(0xFF397A24)
                                : i == current
                                ? gardenInk
                                : Colors.white,
                            border: i < done || current < 0 || i == current
                                ? null
                                : Border.all(
                                    color: const Color(0xFFB8C9AE),
                                    width: 1.5,
                                  ),
                          ),
                          child: Icon(
                            _icons[i],
                            size: 16,
                            color: i < done || current < 0 || i == current
                                ? Colors.white
                                : const Color(0xFF8AA07F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _labels[i],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: gardenInk,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _OrderFilter extends StatelessWidget {
  const _OrderFilter({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? gardenInk : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gardenBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: active ? Colors.white : gardenInk,
        ),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    this.showShopButton = false,
  });

  final String title;
  final String subtitle;
  final bool showShopButton;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
    child: Column(
      children: [
        const Icon(Icons.receipt_long_outlined, size: 48, color: textGrey),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: gardenInk,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: textGrey),
        ),
        if (showShopButton) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(builder: (_) => const CatalogPage()),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: gardenInk,
              foregroundColor: Colors.white,
            ),
            child: const Text('Belanja sekarang'),
          ),
        ],
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: textGrey),
        const SizedBox(height: 12),
        const Text(
          'Gagal memuat pesanan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: gardenInk,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Periksa koneksimu lalu coba lagi.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: textGrey),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onRetry,
          style: FilledButton.styleFrom(
            backgroundColor: gardenInk,
            foregroundColor: Colors.white,
          ),
          child: const Text('Coba lagi'),
        ),
      ],
    ),
  );
}
