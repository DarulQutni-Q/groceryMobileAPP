import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../shared/auth_layout.dart';
import '../application/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.onBack,
    required this.onOtpSent,
  });
  final VoidCallback onBack;
  final void Function(String email, String? maskedPhone) onOtpSent;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final api = AuthApi(ref.read(apiClientProvider));
      final result = await api.forgotPassword(_email.text.trim());
      if (!mounted) return;
      widget.onOtpSent(
        result['email'] as String? ?? _email.text.trim(),
        result['masked_phone'] as String?,
      );
    } catch (e) {
      if (!mounted) return;
      showAuthMessage(context, authErrorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    title: 'Lupa Kata Sandi',
    onBack: widget.onBack,
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Masukkan email yang terdaftar. Kami akan mengirimkan kode verifikasi untuk mereset kata sandi Anda.',
            style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Email',
            style: TextStyle(color: Colors.black, fontSize: 14),
          ),
          const SizedBox(height: 4),
          TextFormField(
            key: const Key('forgot_email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            onFieldSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'Masukkan alamat email',
            ),
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Email wajib diisi';
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
                return 'Alamat email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Memproses...' : 'Kirim Kode Verifikasi'),
          ),
        ],
      ),
    ),
  );
}
