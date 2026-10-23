import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../shared/auth_layout.dart';
import '../application/auth_provider.dart';

class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.resetToken,
    required this.onBack,
    required this.onSuccess,
  });
  final String email;
  final String resetToken;
  final VoidCallback onBack;
  final VoidCallback onSuccess;

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _busy = false;
  String _pw = '';
  String _cf = '';

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _hasLength => _pw.runes.length >= 8 && _pw.runes.length <= 20;
  bool get _hasLetterAndNumber =>
      RegExp(r'[a-zA-Z]').hasMatch(_pw) && RegExp(r'[0-9]').hasMatch(_pw);
  bool get _hasSpecial => RegExp(r'[^a-zA-Z0-9\s]').hasMatch(_pw);
  bool get _matches => _pw.isNotEmpty && _pw == _cf;

  Future<void> _submit() async {
    if (_busy) return;
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final api = AuthApi(ref.read(apiClientProvider));
      await api.resetPassword(
        email: widget.email,
        resetToken: widget.resetToken,
        password: _password.text,
      );
      if (!mounted) return;
      showAuthMessage(
        context,
        'Kata sandi berhasil diperbarui. Silakan login kembali.',
      );
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      showAuthMessage(context, authErrorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _check(bool ok, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(
          ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 16,
          color: ok ? const Color(0xFF2E7D32) : const Color(0xFFAAAAAA),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: ok ? const Color(0xFF2E7D32) : const Color(0xFF888888),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _passwordField({
    required Key fieldKey,
    required String label,
    required TextEditingController controller,
    required bool hidden,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    bool isLast = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
            const SizedBox(height: 4),
            TextFormField(
              key: fieldKey,
              controller: controller,
              obscureText: hidden,
              textInputAction:
                  isLast ? TextInputAction.done : TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (v) => setState(() {
                if (controller == _password) {
                  _pw = v;
                } else {
                  _cf = v;
                }
              }),
              onFieldSubmitted: isLast ? (_) => _submit() : null,
              validator: validator,
              decoration: InputDecoration(
                hintText: label,
                suffixIcon: IconButton(
                  tooltip: hidden ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                  onPressed: onToggle,
                  icon: Icon(
                    hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => AuthLayout(
    title: 'Buat Sandi Baru',
    onBack: widget.onBack,
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _passwordField(
            fieldKey: const Key('new_password'),
            label: 'Sandi Baru',
            controller: _password,
            hidden: _hidePassword,
            onToggle: () => setState(() => _hidePassword = !_hidePassword),
            validator: (v) {
              final val = v ?? '';
              if (val.isEmpty) return 'Sandi Baru wajib diisi';
              if (val.runes.length < 8 || val.runes.length > 20) {
                return 'Kata sandi harus 8-20 karakter';
              }
              if (!RegExp(r'[a-zA-Z]').hasMatch(val) ||
                  !RegExp(r'[0-9]').hasMatch(val)) {
                return 'Gunakan huruf dan angka';
              }
              if (!RegExp(r'[^a-zA-Z0-9\s]').hasMatch(val)) {
                return 'Tambahkan karakter khusus (!@#\$...)';
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _check(_hasLength, '8–20 karakter'),
                _check(_hasLetterAndNumber, 'Memuat huruf dan angka'),
                _check(_hasSpecial, 'Memuat karakter khusus (!@#\$...)'),
              ],
            ),
          ),
          _passwordField(
            fieldKey: const Key('confirm_password'),
            label: 'Konfirmasi Sandi Baru',
            controller: _confirm,
            hidden: _hideConfirm,
            onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
            isLast: true,
            validator: (v) {
              if ((v ?? '').isEmpty) return 'Konfirmasi Sandi wajib diisi';
              if (v != _password.text) return 'Kata sandi tidak cocok';
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _check(_matches, 'Konfirmasi cocok'),
          ),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Menyimpan...' : 'Simpan Sandi Baru'),
          ),
        ],
      ),
    ),
  );
}
