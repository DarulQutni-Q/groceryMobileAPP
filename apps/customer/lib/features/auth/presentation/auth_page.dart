import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../application/auth_provider.dart';
import 'auth_artwork.dart';
import 'password_field.dart';
import 'validation.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, this.register = false});
  final bool register;
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final form = GlobalKey<FormState>();
  final identity = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool remember = true;

  @override
  void dispose() {
    for (final controller in [identity, phone, password, confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(authProvider).status == AuthStatus.loading ||
        !form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    final auth = ref.read(authProvider.notifier);
    // Referensi register hanya punya email + kata sandi + verifikasi;
    // phone opsional di backend, jadi tidak dikirim dari form ini.
    final phoneValue = phone.text.trim();
    final success = widget.register
        ? await auth.register(
            identity.text.trim(),
            password.text,
            phone: phoneValue.isEmpty ? null : phoneValue,
          )
        : await auth.login(
            identity.text.trim(),
            password.text,
            remember: remember,
          );
    if (success) TextInput.finishAutofillContext();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authProvider).status == AuthStatus.loading;
    return AuthBackdrop(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GardenLogo(),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: busy ? null : () => FocusScope.of(context).unfocus(),
              icon: const Icon(Icons.shopping_cart_outlined, size: 20),
              label: Text(widget.register ? 'Daftar Akun' : 'Masuk Akun'),
              style: FilledButton.styleFrom(
                side: const BorderSide(color: Colors.white, width: 3),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
                side: const BorderSide(color: gardenBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _card(busy),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(bool busy) => AutofillGroup(
    child: Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Masuk Akun Pembeli',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const Text(
            'Gunakan No. Handphone atau Email terdaftar',
            style: TextStyle(fontSize: 11, color: Color(0xFF657B67)),
          ),
          const SizedBox(height: 18),
          ..._fields(),
          if (!widget.register) _remember(busy) else const SizedBox(height: 18),
          FilledButton(
            onPressed: busy ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.register ? 'Daftar' : 'Masuk Sekarang'),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: Divider(color: gardenBorder)),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'atau masuk lebih cepat dengan',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Color(0xFF819681)),
                  ),
                ),
              ),
              Expanded(child: Divider(color: gardenBorder)),
            ],
          ),
          const SizedBox(height: 10),
          _social(busy),
          if (!widget.register) ...[
            const SizedBox(height: 14),
            const Divider(color: gardenBorder),
            _registerLink(busy),
          ],
        ],
      ),
    ),
  );

  List<Widget> _fields() => [
    TextFormField(
      key: Key(widget.register ? 'register-email' : 'login-identity'),
      controller: identity,
      keyboardType: TextInputType.emailAddress,
      autofillHints: widget.register
          ? const [AutofillHints.email]
          : const [AutofillHints.email, AutofillHints.telephoneNumber],
      textInputAction: TextInputAction.next,
      autocorrect: false,
      validator: widget.register
          ? emailError
          : (value) => value?.contains('@') == true
                ? emailError(value)
                : phoneError(value),
      decoration: InputDecoration(
        hintText: widget.register
            ? 'example@gmail.com'
            : 'Email atau Nomor Handphone',
        suffixIcon: widget.register
            ? null
            : const Icon(Icons.person_outline, size: 20),
      ),
    ),
    if (widget.register) ...[
      const SizedBox(height: 18),
      TextFormField(
        key: const Key('register-phone'),
        controller: phone,
        keyboardType: TextInputType.phone,
        autofillHints: const [AutofillHints.telephoneNumber],
        textInputAction: TextInputAction.next,
        autocorrect: false,
        validator: (value) =>
            value == null || value.trim().isEmpty ? null : phoneError(value),
        decoration: const InputDecoration(
          hintText: 'Nomor Handphone (opsional)',
          suffixIcon: Icon(Icons.phone_outlined, size: 20),
        ),
      ),
    ],
    const SizedBox(height: 18),
    PasswordField(
      key: Key(widget.register ? 'register-password' : 'login-password'),
      controller: password,
      hint: widget.register ? 'Kata sandi' : 'Masukkan Kata Sandi',
      validator: widget.register
          ? passwordError
          : (value) => value == null || value.isEmpty
                ? 'Kata sandi wajib diisi'
                : null,
      autofillHints: widget.register
          ? const [AutofillHints.newPassword]
          : const [AutofillHints.password],
      onSubmitted: widget.register ? null : _submit,
    ),
    if (widget.register) ...[
      const SizedBox(height: 18),
      PasswordField(
        key: const Key('register-confirm'),
        controller: confirm,
        hint: 'Verifikasi kata sandi',
        autofillHints: const [AutofillHints.newPassword],
        onSubmitted: _submit,
        validator: (value) => value != password.text
            ? 'Kata sandi harus sama'
            : passwordError(value),
      ),
    ],
  ];

  Widget _remember(bool busy) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: remember,
            onChanged: busy
                ? null
                : (value) => setState(() => remember = value ?? true),
            fillColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? gardenInk
                  : Colors.white,
            ),
            checkColor: Colors.white,
            side: const BorderSide(color: gardenInk, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          GestureDetector(
            onTap: busy ? null : () => setState(() => remember = !remember),
            child: const Text('Ingat Saya', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      TextButton(
        onPressed: busy
            ? null
            : () => Navigator.pushNamed(context, '/forgot-password'),
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: const Text('Lupa Kata Sandi?', style: TextStyle(fontSize: 12)),
      ),
    ],
  );

  Widget _social(bool busy) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: busy
              ? null
              : () => ref
                    .read(authProvider.notifier)
                    .loginWithGoogle(remember: remember),
          icon: artwork('google_icon', width: 26, height: 27),
          label: const Text('Google', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: busy
              ? null
              : () => showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Masuk dengan Apple'),
                      content: const Text(
                        'Masuk dengan Apple belum tersedia di GardenMart '
                        'karena backend belum mendukung login Apple dan '
                        'konfigurasi Apple Developer belum disiapkan.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Tutup'),
                        ),
                      ],
                    ),
                  ),
          icon: artwork('apple_icon', width: 26, height: 28),
          label: const Text('Apple ID', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _registerLink(bool busy) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('Belum punya akun?', style: TextStyle(fontSize: 12)),
        TextButton(
          onPressed: busy
              ? null
              : () => Navigator.pushReplacementNamed(context, '/register'),
          child: const Text(
            'Daftar Akun Baru',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        const Icon(Icons.chevron_right, size: 16),
      ],
    ),
  );
}
