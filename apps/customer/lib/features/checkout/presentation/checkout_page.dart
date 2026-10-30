import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import '../../auth/application/auth_provider.dart';
import '../../catalog/presentation/catalog_widgets.dart';
import '../application/checkout_provider.dart';
import '../application/checkout_session.dart';
import 'alamat_page.dart';
import 'checkout_success_page.dart';
import 'metode_bayar_page.dart';
import 'payment_page.dart';
import 'voucher_picker_page.dart';

/// Tarif normal pengiriman Instant menurut referensi.
///
/// Backend saat ini selalu mengembalikan ongkir 0 (promo gratis ongkir),
/// jadi nilai coret ini dari referensi sampai backend punya tarif asli.
const ongkirNormal = 10000;

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key, required this.items});
  final List<KeranjangItem> items;
  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  Alamat? address;
  Map<String, dynamic>? costs;
  CheckoutSession? session;
  bool loading = true, busy = false;
  String shipping = 'Instant', method = 'qris';
  String? error;
  VoucherLocal? voucher;
  final note = TextEditingController();
  String get userId => ref.read(authProvider).user!.id;
  SecureStorage get storage => ref.read(storageProvider);
  List<KeranjangItem> get items => session?.items ?? widget.items;

  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Map<String, dynamic> payload() => {
    'alamat_id': address!.id,
    'metode_kirim': shipping,
    'metode_bayar': method,
    'catatan': note.text.trim(),
    'items': [
      for (final item in items) {'produk_id': item.produk.id, 'qty': item.qty},
    ],
  };

  Future<void> load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
      costs = null;
    });
    try {
      session ??= await CheckoutSession.restore(storage, userId);
      if (!mounted) return;
      if (session != null) {
        costs = session!.costs;
        shipping = session!.body['metode_kirim'] as String;
        method = session!.body['metode_bayar'] as String;
        address = session!.alamat;
        note.text = session!.body['catatan'] as String? ?? '';
        return;
      }
      final addresses = await ref.read(alamatApiProvider).list();
      if (!mounted) return;
      address =
          addresses.where((a) => a.id == address?.id).firstOrNull ??
          addresses.where((a) => a.isUtama).firstOrNull ??
          addresses.firstOrNull;
      if (session == null && address != null) {
        costs = await ref.read(checkoutApiProvider).preview(payload());
      }
    } catch (err) {
      if (mounted) error = authErrorMessage(err);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> chooseAddress() async {
    final chosen = await Navigator.push<Alamat>(
      context,
      MaterialPageRoute(builder: (_) => const AlamatPage(pilih: true)),
    );
    if (!mounted) return;
    if (chosen != null) address = chosen;
    await load();
  }

  Future<void> complete(HasilCheckout result) async {
    final current = session!;
    final owner = userId;
    final secure = storage;
    final removed = await ref
        .read(keranjangProvider(owner).notifier)
        .selesaikanCheckout(current.key, current.items);
    if (!removed) {
      throw StateError(
        'Pesanan berhasil, keranjang belum dapat diperbarui. Periksa lagi.',
      );
    }
    await secure.clearCheckout(owner);
    if (mounted) ref.invalidate(pendingCheckoutProvider);
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => CheckoutSuccessPage(result: result)),
        (route) => route.isFirst,
      );
    }
  }

  Future<void> pay() async {
    if (busy || costs == null) return;
    // Penagihan toko belum mendukung voucher: total yang dikirim ke
    // backend harus sama dengan total preview backend, kalau tidak
    // backend menolak (409). Kalau voucher membuat total tampil beda
    // dari total toko, beri tahu dulu sebelum menagih.
    if (voucher != null && _total != (costs!['total'] as int)) {
      final lanjut = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Voucher belum didukung penagihan toko'),
          content: Text(
            'Potongan voucher tampil di aplikasi, tapi penagihan toko '
            'belum mendukung voucher. Total yang ditagih adalah '
            '${rupiah(costs!['total'] as int)}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Lanjut Bayar'),
            ),
          ],
        ),
      );
      if (lanjut != true || !mounted) return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      session ??= await CheckoutSession.create(
        storage,
        userId,
        {...payload(), 'total_dikonfirmasi': costs!['total']},
        items,
        costs!,
        address!,
      );
      if (!mounted) return;
      ref.invalidate(pendingCheckoutProvider);
      final result = await ref
          .read(checkoutApiProvider)
          .checkout(session!.body, requestKey: session!.key);
      if (!mounted) return;
      if (result.pembayaran.perluRekonsiliasi) {
        throw StateError(
          'Pembayaran perlu diperiksa oleh toko sebelum melanjutkan.',
        );
      }
      if (result.pembayaran.status == 'expired' ||
          result.pembayaran.status == 'failed') {
        await reset();
        return;
      }
      if (result.pembayaran.metode == 'cod' ||
          result.pembayaran.status == 'paid') {
        await complete(result);
      } else {
        final outcome = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PaymentPage(result: result, onPaid: () => complete(result)),
          ),
        );
        if (mounted && (outcome == 'expired' || outcome == 'failed')) {
          await reset();
        }
      }
    } catch (err) {
      if (!mounted) return;
      if (err is DioException &&
          (err.response?.headers.value('x-checkout-started') == 'false' ||
              err.response?.statusCode == 422)) {
        try {
          await storage.clearCheckout(userId);
          session = null;
          ref.invalidate(pendingCheckoutProvider);
        } catch (_) {
          error = 'Checkout belum dapat diperbarui. Coba lagi.';
        }
      }
      if (mounted) {
        setState(
          () => error ??= err is StateError
              ? err.message.toString()
              : authErrorMessage(err),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> reset() async {
    await storage.clearCheckout(userId);
    if (!mounted) return;
    session = null;
    ref.invalidate(pendingCheckoutProvider);
    await load();
  }


  bool _showAll = false;

  String get _shippingLabel => switch (shipping) {
    'Instant' => 'Pengantaran Kilat Toko (15-20 Menit)',
    'Kurir Marketplace' => 'Kurir Marketplace',
    'Ambil di Toko' => 'Ambil di Toko',
    _ => shipping,
  };

  int get _totalQty => items.fold<int>(0, (n, i) => n + i.qty);
  int get _subtotal => costs == null ? 0 : costs!['subtotal'] as int;
  int get _backendDiskon => costs == null ? 0 : costs!['diskon'] as int;
  int get _backendOngkir => costs == null ? 0 : costs!['ongkir'] as int;
  int get _biayaLayanan =>
      costs == null ? 0 : costs!['biaya_layanan'] as int;

  /// Potongan dari voucher lokal yang dipilih. Potongan produk (harga
  /// coret placeholder di keranjang) sudah tercermin di harga jual, jadi
  /// tidak dihitung lagi di sini; baris voucher hanya berisi voucher.
  int get _voucherDiskon =>
      voucher == null ? 0 : voucher!.potonganTagihan(_subtotal);
  int get _voucherOngkirDiskon =>
      voucher == null ? 0 : voucher!.potonganOngkir(_backendOngkir);
  int get _diskon => _backendDiskon + _voucherDiskon;
  int get _ongkir => _backendOngkir - _voucherOngkirDiskon;
  int get _total => _subtotal - _diskon + _ongkir + _biayaLayanan;

  /// Promo gratis ongkir toko berlaku kalau backend mengembalikan
  /// ongkir 0 (bukan karena voucher).
  bool get _gratisOngkirPromo => costs != null && _backendOngkir == 0;

  Future<void> _chooseShipping() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<String>(
          groupValue: shipping,
          onChanged: (selected) => Navigator.pop(sheetContext, selected),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in [
                'Instant',
                'Kurir Marketplace',
                'Ambil di Toko',
              ])
                RadioListTile<String>(
                  value: option,
                  title: Text(option, style: const TextStyle(fontSize: 13)),
                  secondary: const Text('Rp 0'),
                  enabled: !busy && session == null,
                  dense: true,
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    if (value != null && mounted) setState(() => shipping = value);
  }

  Future<void> _chooseVoucher() async {
    if (busy || session != null) return;
    final result = await Navigator.push<VoucherLocal>(
      context,
      MaterialPageRoute(
        builder: (_) => VoucherPickerPage(
          subtotal: _subtotal,
          ongkir: _backendOngkir,
          selected: voucher,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => voucher = result.isTanpa ? null : result);
  }

  Future<void> _editNote() async {
    final controller = TextEditingController(text: note.text);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Catatan pesanan'),
        content: TextField(
          controller: controller,
          maxLength: 3000,
          decoration: const InputDecoration(
            hintText: 'Catatan untuk pesanan ini (opsional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) setState(() => note.text = controller.text);
  }

  Widget _card({Key? key, required Widget child, VoidCallback? onTap}) {
    final card = Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
    if (onTap == null) return card;
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }

  Widget _iconCircle(IconData icon) => Container(
    width: 40,
    height: 40,
    decoration: const BoxDecoration(
      color: Color(0xFFE9F4DD),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 20, color: gardenInk),
  );

  Widget _chevron() => const Icon(
    Icons.chevron_right,
    size: 20,
    color: Colors.black45,
  );

  Widget _costRow(
    String label,
    String amount, {
    bool bold = false,
    String? coret,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
                ),
              ),
            ),
            if (coret != null) ...[
              Text(
                coret,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black38,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              amount,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );

  Widget _addressCard() {
    final a = address;
    return _card(
      onTap: busy || session != null ? null : chooseAddress,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconCircle(Icons.location_on_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Alamat Pengiriman',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    if (a != null)
                      Text(
                        a.isUtama ? 'Utama • ${a.label}' : a.label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    const SizedBox(width: 2),
                    _chevron(),
                  ],
                ),
                if (a == null) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Tambahkan alamat pengiriman terlebih dahulu.',
                    style: TextStyle(fontSize: 12),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    '${a.namaPenerima} (${a.noHp})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(a.alamatLengkap, style: const TextStyle(fontSize: 12)),
                  if (a.patokan?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Catatan: ${a.patokan}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF5E872F),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shippingCard() => _card(
    onTap: busy || session != null ? null : _chooseShipping,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconCircle(Icons.motorcycle_outlined),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _shippingLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    rupiah(_ongkir),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5E872F),
                    ),
                  ),
                  if (_gratisOngkirPromo) ...[
                    const SizedBox(width: 8),
                    Text(
                      rupiah(ongkirNormal),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: limePale,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Promo Gratis Ongkir',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: gardenInk,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        _chevron(),
      ],
    ),
  );

  Widget _summaryCard() {
    final shown = _showAll ? items : items.take(3).toList();
    final stripText = note.text.isNotEmpty
        ? note.text
        : (address?.patokan?.isNotEmpty == true ? address!.patokan! : '');
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Ringkasan Belanja ($_totalQty Barang)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => setState(() => _showAll = !_showAll),
                child: Text(
                  _showAll ? 'Sembunyikan >' : 'Lihat Semua >',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5E872F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!_showAll) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: shown.length * 52.0 + (shown.length - 1) * 8.0,
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      final item = shown[index];
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: FotoProduk(item.produk),
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                color: gardenInk,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${item.qty}x',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items.map((i) => i.produk.nama).join(', '),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ] else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.produk.nama,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${item.qty} ${item.produk.satuan}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  key: const Key('checkout-note-strip'),
                  onTap: busy || session != null ? null : _editNote,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.note_alt_outlined,
                          size: 14,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            stripText.isEmpty
                                ? 'Tambah catatan pesanan'
                                : 'Catatan: $stripText',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                key: const Key('summary-ubah'),
                onTap: busy
                    ? null
                    : () => Navigator.maybePop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  child: Text(
                    'Ubah',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5E872F),
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

  Widget _voucherCard() {
    final dipilih = voucher;
    final hematVoucher = _voucherDiskon + _voucherOngkirDiskon;
    return _card(
      key: const Key('choose-voucher'),
      onTap: busy || session != null ? null : _chooseVoucher,
      child: Row(
        children: [
          const Icon(
            Icons.confirmation_number_outlined,
            color: Color(0xFF7A9B52),
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gunakan / Masukkan Voucher',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  dipilih == null
                      ? 'Ada 2 voucher aktif hemat belanja'
                      : 'Terpilih: ${dipilih.title}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF73876B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            dipilih == null
                ? 'Hemat s/d Rp 25rb >'
                : (hematVoucher > 0
                      ? 'Hemat ${rupiah(hematVoucher)} >'
                      : 'Ganti >'),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5E872F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentCard() => _card(
    onTap: busy || session != null
        ? null
        : () async {
            final value = await Navigator.push<String>(
              context,
              MaterialPageRoute(
                builder: (_) => MetodeBayarPage(selected: method),
              ),
            );
            if (mounted && value != null) setState(() => method = value);
          },
    child: Row(
      key: const Key('choose-payment'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconCircle(Icons.account_balance_wallet_outlined),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: limePale,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Utama',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: gardenInk,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                metodeBayar[method] ?? method,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'GoPay, ShopeePay, Virtual Account BCA, Kasir COD',
                style: TextStyle(fontSize: 11, color: Color(0xFF73876B)),
              ),
            ],
          ),
        ),
        _chevron(),
      ],
    ),
  );

  Widget _costCard() {
    if (costs == null) return const SizedBox.shrink();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Pembayaran',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _costRow(
            'Subtotal Produk ($_totalQty Barang)',
            rupiah(costs!['subtotal'] as int),
          ),
          _costRow(
            'Total Diskon Voucher',
            _diskon > 0 ? '-${rupiah(_diskon)}' : rupiah(0),
          ),
          _costRow(
            'Ongkos Kirim Toko',
            rupiah(_ongkir),
            coret: _gratisOngkirPromo ? rupiah(ongkirNormal) : null,
          ),
          _costRow(
            'Biaya Layanan Aplikasi',
            rupiah(costs!['biaya_layanan'] as int),
          ),
          const Divider(),
          _costRow('Total Tagihan Belanja', rupiah(_total), bold: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      backgroundColor: const Color(0xFFEFF4EB),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.arrow_back,
                          background: limePale,
                          onPressed: busy
                              ? () {}
                              : () => Navigator.maybePop(context),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Konfirmasi Pesanan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      children: [
                        if (session != null)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Checkout sebelumnya tersimpan. Periksa atau lanjutkan pembayaran yang sama.',
                            ),
                          ),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              error!,
                              style: const TextStyle(
                                color: Color(0xFFA52A20),
                              ),
                            ),
                          ),
                        if (error != null && session == null)
                          TextButton(
                            onPressed: busy ? null : load,
                            child: const Text('Perbarui Rincian'),
                          ),
                        _addressCard(),
                        _shippingCard(),
                        _summaryCard(),
                        _voucherCard(),
                        _paymentCard(),
                        _costCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: loading
          ? null
          : SafeArea(top: false, child: _payBar()),
    ),
  );

  Widget _payBar() => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: gardenBorder)),
    ),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              Text(
                rupiah(_total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_diskon > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: limePale,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Hemat ${rupiah(_diskon)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: gardenInk,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: FilledButton(
            key: const Key('checkout-pay'),
            onPressed: busy || loading || costs == null || address == null
                ? null
                : pay,
            style: FilledButton.styleFrom(
              backgroundColor: gardenInk,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  busy
                      ? 'Memproses...'
                      : session != null
                      ? 'Lanjutkan Pembayaran'
                      : method == 'cod'
                      ? 'Buat Pesanan'
                      : 'Bayar Sekarang',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: limeBright,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
