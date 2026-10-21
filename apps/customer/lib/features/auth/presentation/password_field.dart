import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.hint,
    required this.validator,
    this.onSubmitted,
    this.autofillHints,
  });
  final TextEditingController controller;
  final String hint;
  final String? Function(String?) validator;
  final VoidCallback? onSubmitted;
  final Iterable<String>? autofillHints;
  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool hidden = true;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: hidden,
    validator: widget.validator,
    autofillHints: widget.autofillHints,
    autocorrect: false,
    enableSuggestions: false,
    textInputAction: widget.onSubmitted == null
        ? TextInputAction.next
        : TextInputAction.done,
    onFieldSubmitted: (_) => widget.onSubmitted?.call(),
    decoration: InputDecoration(
      hintText: widget.hint,
      suffixIcon: IconButton(
        tooltip: hidden ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
        onPressed: () => setState(() => hidden = !hidden),
        icon: Icon(
          hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: const Color(0xFF515951),
        ),
      ),
    ),
  );
}
