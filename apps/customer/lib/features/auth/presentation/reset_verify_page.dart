import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/theme.dart';
import '../application/auth_provider.dart';
import 'validation.dart';

/// Halaman penyelesaian lupa kata sandi: masukkan kode 6 digit dari email,
/// lalu kata sandi baru. Tanpa halaman ini, kode email tidak ada tempat
/// untuk dimasukkan (dulu alur customer mentok di halaman "Email Sent").
class ResetVerifyPage extends ConsumerStatefulWidget {
  const ResetVerifyPage({super.key, this.email = ''});
  final String email;
  @override
  ConsumerState<ResetVerifyPage> createState() => _ResetVerifyPageState();
}

class _ResetVerifyPageState extends ConsumerState<ResetVerifyPage> {
  final kode = TextEditingController();
  final sandi = TextEditingController();
  final konfirmasi = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;

  @override
  void dispose() {
    kode.dispose();
    sandi.dispose();
    konfirmasi.dispose();
    super.dispose();
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _simpan() async {
    if (busy || !form.currentState!.validate()) return;
    if (widget.email.isEmpty) {
      _message('Email tidak ditemukan, ulangi dari halaman lupa kata sandi');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    try {
      final api = ref.read(authApiProvider);
      final token = await api.verifyOtp(widget.email, kode.text.trim());
      await api.resetPassword(
        email: widget.email,
        resetToken: token,
        password: sandi.text,
      );
      if (mounted) {
        _message('Kata sandi berhasil diperbarui');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on DioException catch (error) {
      if (mounted) _message(authErrorMessage(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 44, 28, 32),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Masukkan Kode',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'GardenSerif',
                    fontSize: 28,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.email.isEmpty
                      ? 'Masukkan kode 6 digit dari email, lalu kata sandi baru.'
                      : 'Kami mengirim kode 6 digit ke ${widget.email}. '
                          'Masukkan kode itu, lalu kata sandi baru.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 36),
                TextFormField(
                  key: const Key('reset-kode'),
                  controller: kode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      RegExp(r'^[0-9]{6}$').hasMatch(value?.trim() ?? '')
                          ? null
                          : 'Kode harus 6 digit angka',
                  decoration: const InputDecoration(
                    hintText: 'Kode 6 digit...',
                    prefixIcon: Icon(Icons.key_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('reset-sandi'),
                  controller: sandi,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: passwordError,
                  decoration: const InputDecoration(
                    hintText: 'Kata sandi baru...',
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('reset-konfirmasi'),
                  controller: konfirmasi,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _simpan(),
                  validator: (value) => value != sandi.text
                      ? 'Konfirmasi kata sandi tidak sama'
                      : null,
                  decoration: const InputDecoration(
                    hintText: 'Konfirmasi kata sandi baru...',
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 36),
                FilledButton(
                  key: const Key('reset-simpan'),
                  onPressed: busy ? null : _simpan,
                  style: FilledButton.styleFrom(
                    backgroundColor: resetGreen,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(busy ? 'Memproses...' : 'Simpan Kata Sandi Baru'),
                ),
              ],
            ),
          ),
        ),
      );
}
