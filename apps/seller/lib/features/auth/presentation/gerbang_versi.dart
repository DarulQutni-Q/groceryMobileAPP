import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../application/auth_provider.dart';

/// Gerbang force-update: sekali jalan saat aplikasi dibuka, cek
/// /versi-minimum. Kalau server bilang wajib update, tampilkan layar blokir
/// (tidak bisa ditutup) sampai user memperbarui APK. Galat apa pun
/// (offline, server mati) = fail-open, aplikasi jalan seperti biasa.
class GerbangVersi extends ConsumerStatefulWidget {
  const GerbangVersi({
    super.key,
    required this.aplikasi,
    required this.versiSaatIni,
    required this.child,
    this.api,
  });

  final String aplikasi;
  final String versiSaatIni;
  final Widget child;

  /// Diisi hanya di tes (stub VersiApi); produksi memakai apiClientProvider.
  final VersiApi? api;

  @override
  ConsumerState<GerbangVersi> createState() => _GerbangVersiState();
}

class _GerbangVersiState extends ConsumerState<GerbangVersi> {
  bool _wajib = false;
  String _minimum = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_cek);
  }

  Future<void> _cek() async {
    final api = widget.api ?? VersiApi(ref.read(apiClientProvider));
    CekVersi? hasil;
    try {
      hasil = await api.cek(widget.aplikasi, widget.versiSaatIni);
    } catch (_) {
      hasil = null;
    }
    if (!mounted) return;
    setState(() {
      _wajib = hasil?.wajibUpdate ?? false;
      _minimum = hasil?.versiMinimum ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_wajib) return widget.child;
    return LayarVersiKedaluwarsa(
      versiSaatIni: widget.versiSaatIni,
      versiMinimum: _minimum,
      onPeriksaLagi: _cek,
    );
  }
}
