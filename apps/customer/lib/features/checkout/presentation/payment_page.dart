import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../catalog/presentation/catalog_widgets.dart';
import '../application/checkout_provider.dart';

final paymentLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (url) => launchUrl(url, mode: LaunchMode.externalApplication),
);

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key, required this.result, required this.onPaid});
  final HasilCheckout result;
  final Future<void> Function() onPaid;
  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage>
    with WidgetsBindingObserver {
  Timer? timer, deadlineTimer;
  DateTime? deadline;
  bool checking = false, finished = false, opening = false;
  bool paidConfirmed = false, finalizing = false;
  String? terminalFailure;
  String message = 'Selesaikan pembayaran di halaman Xendit.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      open();
      start();
    });
  }

  @override
  void dispose() {
    stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void stop() {
    timer?.cancel();
    deadlineTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      start(ulang: true);
    } else {
      stop();
    }
  }

  void start({bool ulang = false}) {
    if (!mounted || finished) return;
    stop();
    if (ulang || deadline == null) {
      deadline = DateTime.now().add(const Duration(minutes: 2));
    }
    final remaining = deadline!.difference(DateTime.now());
    if (remaining.isNegative) {
      timeout();
      return;
    }
    check();
    timer = Timer.periodic(const Duration(seconds: 3), (_) => check());
    deadlineTimer = Timer(remaining, timeout);
  }

  void timeout() {
    stop();
    if (mounted && !finished) {
      setState(
        () => message = 'Pembayaran belum terkonfirmasi. Periksa status lagi sebelum membuat pesanan baru.',
      );
    }
  }

  Future<void> open() async {
    if (opening) return;
    setState(() => opening = true);
    try {
      final url = Uri.tryParse(widget.result.pembayaran.paymentUrl ?? '');
      if (url == null ||
          url.scheme != 'https' ||
          url.userInfo.isNotEmpty ||
          !(url.host == 'xendit.co' || url.host.endsWith('.xendit.co'))) {
        throw const FormatException('Tautan pembayaran tidak valid');
      }
      final opened = await ref.read(paymentLauncherProvider)(url);
      if (!opened) throw StateError('Browser belum dapat dibuka');
    } catch (error) {
      if (mounted) {
        setState(
          () => message =
              'Halaman pembayaran belum dapat dibuka. Coba buka kembali.',
        );
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  Future<void> check() async {
    if (!mounted || finished || checking) return;
    checking = true;
    try {
      final payment = await ref
          .read(checkoutApiProvider)
          .cekStatusBayar(widget.result.pembayaran.id);
      if (!mounted || finished) return;
      if (payment.perluRekonsiliasi) {
        finished = true;
        stop();
        setState(
          () => message = 'Dana diterima setelah pesanan dibatalkan. Hubungi toko untuk memeriksa pembayaran.',
        );
      } else if (payment.status == 'paid') {
        finished = true;
        paidConfirmed = true;
        stop();
        await finalize();
      } else if (payment.status == 'expired' || payment.status == 'failed') {
        finished = true;
        terminalFailure = payment.status;
        stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pembayaran berakhir. Silakan coba lagi.'),
            action: SnackBarAction(
              label: 'Coba Lagi',
              onPressed: () => Navigator.pop(context, payment.status),
            ),
          ),
        );
        setState(
          () => message =
              'Pembayaran ${payment.status == 'expired' ? 'kedaluwarsa' : 'gagal'}.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => message = authErrorMessage(error));
    } finally {
      checking = false;
    }
  }

  Future<void> finalize() async {
    if (finalizing || !paidConfirmed) return;
    setState(() => finalizing = true);
    try {
      await widget.onPaid();
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Pembayaran sudah berhasil. Keranjang belum dapat diperbarui. Coba perbarui keranjang.',
        );
      }
    } finally {
      if (mounted) setState(() => finalizing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pembayaran Xendit')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.qr_code_2, size: 88, color: Color(0xFF4F8C2E)),
              const SizedBox(height: 20),
              Text(
                rupiah(widget.result.pembayaran.jumlah),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(widget.result.pesanan.kode),
              const SizedBox(height: 24),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (!finished) ...[
                FilledButton(
                  onPressed: opening ? null : open,
                  child: const Text('Buka Halaman Pembayaran'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: checking ? null : () => start(ulang: true),
                  child: const Text('Periksa Status Pembayaran'),
                ),
              ],
              if (paidConfirmed)
                FilledButton(
                  onPressed: finalizing ? null : finalize,
                  child: const Text('Perbarui Keranjang'),
                ),
              if (terminalFailure != null)
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, terminalFailure),
                  child: const Text('Coba Lagi'),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
