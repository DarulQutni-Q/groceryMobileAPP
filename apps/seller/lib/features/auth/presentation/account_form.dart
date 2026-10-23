import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/seller_theme.dart';
import '../../../shared/auth_layout.dart';
import '../application/auth_provider.dart';

class AccountForm extends ConsumerStatefulWidget {
  const AccountForm({
    super.key,
    required this.register,
    this.onRegistered,
    this.onSignUp,
    this.onForgotPassword,
  });
  final bool register;
  final VoidCallback? onRegistered;
  final VoidCallback? onSignUp;
  final VoidCallback? onForgotPassword;

  @override
  ConsumerState<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<AccountForm> {
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _toko = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;

  @override
  void dispose() {
    for (final controller in [_nama, _toko, _email, _password]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(authProvider).status == AuthStatus.loading) return;
    if (!_form.currentState!.validate()) return;
    final auth = ref.read(authProvider.notifier);
    final success = widget.register
        ? await auth.register(
            namaPemilik: _nama.text.trim(),
            namaToko: _toko.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          )
        : await auth.login(_email.text.trim(), _password.text);
    if (success && mounted && widget.register) widget.onRegistered?.call();
  }

  Widget _field(
    String label,
    String hint,
    TextEditingController controller, {
    bool required = false,
    bool password = false,
    bool email = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black, fontSize: 14)),
        const SizedBox(height: 4),
        TextFormField(
          key: Key(email ? 'email' : label),
          controller: controller,
          keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
          textInputAction: password
              ? TextInputAction.done
              : TextInputAction.next,
          obscureText: password && _hidden,
          autocorrect: !password && !email,
          enableSuggestions: !password,
          onFieldSubmitted: password ? (_) => _submit() : null,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: password
                ? IconButton(
                    tooltip: _hidden
                        ? 'Tampilkan kata sandi'
                        : 'Sembunyikan kata sandi',
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  )
                : null,
          ),
          validator: (value) =>
              _validate(value ?? '', label, required, password, email),
        ),
      ],
    ),
  );

  String? _validate(
    String value,
    String label,
    bool required,
    bool password,
    bool email,
  ) {
    if ((required || password || email) && value.trim().isEmpty) {
      return '$label wajib diisi';
    }
    if (email &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
      return 'Alamat email tidak valid';
    }
    if (password && widget.register) {
      if (value.runes.length < 8 || value.runes.length > 20) {
        return 'Kata sandi harus 8-20 karakter';
      }
      if (!RegExp(r'[a-zA-Z]').hasMatch(value) ||
          !RegExp(r'[0-9]').hasMatch(value) ||
          !RegExp(r'[^a-zA-Z0-9\s]').hasMatch(value)) {
        return 'Gunakan huruf, angka, dan karakter khusus';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authProvider).status == AuthStatus.loading;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ReferenceArtwork(
            asset: 'login.png',
            rect: Rect.fromLTWH(108, 145, 267, 124),
            width: 265,
            semanticLabel: 'Ilustrasi toko grocery',
          ),
          const SizedBox(height: 16),
          _field(
            'Nama Pemilik',
            'Masukkan Nama Pemilik',
            _nama,
            required: widget.register,
          ),
          _field(
            'Nama Toko',
            'Masukkan Nama Toko',
            _toko,
            required: widget.register,
          ),
          _field('Email', 'Masukkan alamat email', _email, email: true),
          _field(
            'Kata Sandi',
            'Masukkan Kata Sandi',
            _password,
            password: true,
          ),
          if (!widget.register)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onForgotPassword,
                child: const Text(
                  'Lupa kata sandi?',
                  style: TextStyle(color: Color(0xFF1B5E20)),
                ),
              ),
            ),
          FilledButton(
            onPressed: busy ? null : _submit,
            child: Text(
              busy
                  ? 'Memproses...'
                  : widget.register
                  ? 'Daftar'
                  : 'Login',
            ),
          ),
          if (!widget.register) ..._socialButtons(busy),
        ],
      ),
    );
  }

  List<Widget> _socialButtons(bool busy) => [
    const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.black)),
          Text('Atau'),
          Expanded(child: Divider(color: Colors.black)),
        ],
      ),
    ),
    OutlinedButton.icon(
      onPressed: busy
          ? null
          : () => ref.read(authProvider.notifier).loginWithGoogle(),
      icon: const ReferenceArtwork(
        asset: 'login.png',
        rect: Rect.fromLTWH(111, 679, 25, 27),
        width: 25,
        semanticLabel: 'Google',
      ),
      label: const Text('Login Dengan Google'),
    ),
    const SizedBox(height: 14),
    FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: sellerInk),
      onPressed: () => showAuthMessage(context, 'Segera hadir'),
      icon: const Icon(Icons.apple),
      label: const Text('Apple'),
    ),
    const SizedBox(height: 12),
    Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('Belum punya akun?'),
        TextButton(
          onPressed: busy ? null : widget.onSignUp,
          child: const Text(
            'Daftar',
            style: TextStyle(color: Color(0xFF0B5A49)),
          ),
        ),
      ],
    ),
  ];
}
