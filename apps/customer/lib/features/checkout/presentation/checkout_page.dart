import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../auth/application/auth_provider.dart';
import '../../catalog/presentation/catalog_widgets.dart';
import '../application/checkout_provider.dart';
import '../application/checkout_session.dart';
import 'alamat_page.dart';
import 'checkout_success_page.dart';
import 'metode_bayar_page.dart';
import 'payment_page.dart';

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

  Widget section(String title, Widget child) => Card(
    color: Colors.white,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );

  Widget costRow(String label, int amount, {bool bold = false}) => Padding(
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
        Text(
          rupiah(amount),
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      backgroundColor: const Color(0xFFEFF4EB),
      appBar: AppBar(title: const Text('Konfirmasi Pesanan')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
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
                        style: const TextStyle(color: Color(0xFFA52A20)),
                      ),
                    ),
                  if (error != null && session == null)
                    TextButton(
                      onPressed: busy ? null : load,
                      child: const Text('Perbarui Rincian'),
                    ),
                  section(
                    'Alamat Pengiriman',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (address == null)
                          const Text(
                            'Tambahkan alamat pengiriman terlebih dahulu.',
                          )
                        else ...[
                          Text(
                            '${address!.namaPenerima} • ${address!.noHp}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            address!.alamatLengkap,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: busy || session != null
                                ? null
                                : chooseAddress,
                            child: const Text('Ubah'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  section(
                    'Metode Pengiriman',
                    RadioGroup<String>(
                      groupValue: shipping,
                      onChanged: busy || session != null
                          ? (_) {}
                          : (value) {
                              if (value != null) {
                                setState(() => shipping = value);
                              }
                            },
                      child: Column(
                        children: [
                          for (final value in [
                            'Instant',
                            'Kurir Marketplace',
                            'Ambil di Toko',
                          ])
                            RadioListTile<String>(
                              value: value,
                              title: Text(
                                value,
                                style: const TextStyle(fontSize: 13),
                              ),
                              secondary: const Text('Rp 0'),
                              enabled: !busy && session == null,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                        ],
                      ),
                    ),
                  ),
                  section(
                    'Ringkasan Belanja (${items.fold<int>(0, (n, i) => n + i.qty)} Barang)',
                    Column(
                      children: [
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
                      ],
                    ),
                  ),
                  section(
                    'Metode Pembayaran',
                    ListTile(
                      key: const Key('choose-payment'),
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(ikonBayar(method)),
                      title: Text(metodeBayar[method]!),
                      subtitle: method == 'qris'
                          ? const Text(
                              'RECOMMENDED',
                              style: TextStyle(fontSize: 10),
                            )
                          : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: busy || session != null
                          ? null
                          : () async {
                              final value = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MetodeBayarPage(selected: method),
                                ),
                              );
                              if (mounted && value != null) {
                                setState(() => method = value);
                              }
                            },
                    ),
                  ),
                  TextField(
                    controller: note,
                    enabled: !busy && session == null,
                    maxLength: 3000,
                    decoration: const InputDecoration(
                      labelText: 'Catatan pesanan (opsional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (costs != null)
                    section(
                      'Rincian Biaya',
                      Column(
                        children: [
                          costRow('Subtotal Produk', costs!['subtotal'] as int),
                          costRow(
                            'Total Diskon Voucher',
                            costs!['diskon'] as int,
                          ),
                          costRow('Ongkos Kirim Toko', costs!['ongkir'] as int),
                          costRow(
                            'Biaya Layanan Aplikasi',
                            costs!['biaya_layanan'] as int,
                          ),
                          const Divider(),
                          costRow(
                            'Total Tagihan Belanja',
                            costs!['total'] as int,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            key: const Key('checkout-pay'),
            onPressed:
                busy ||
                    loading ||
                    costs == null ||
                    (address == null && session == null)
                ? null
                : pay,
            child: Text(
              busy
                  ? 'Memproses...'
                  : '${session != null
                        ? 'Lanjutkan Pembayaran'
                        : method == 'cod'
                        ? 'Buat Pesanan'
                        : 'Bayar Sekarang'}${costs == null ? '' : ' • ${rupiah(costs!['total'] as int)}'}',
            ),
          ),
        ),
      ),
    ),
  );
}
