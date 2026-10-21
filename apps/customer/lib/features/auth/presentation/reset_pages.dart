import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
import '../application/auth_provider.dart';
import 'auth_artwork.dart';
import 'validation.dart';

final openEmailProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

class ResetPage extends ConsumerStatefulWidget {
  const ResetPage({super.key, this.sent = false});
  final bool sent;
  @override
  ConsumerState<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends ConsumerState<ResetPage> {
  final email = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;
  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _send() async {
    if (busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    try {
      await ref.read(authApiProvider).requestPasswordReset(email.text.trim());
      if (mounted) Navigator.pushReplacementNamed(context, '/email-sent');
    } on DioException catch (error) {
      if (mounted) {
        _message(
          error.response?.statusCode == 404
              ? 'Segera hadir'
              : authErrorMessage(error),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _openEmail({bool contact = false}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: contact ? 'darulqutni512@gmail.com' : '',
    );
    try {
      final opened = await ref.read(openEmailProvider)(uri);
      if (mounted && !opened) _message('Aplikasi email belum tersedia');
    } catch (_) {
      if (mounted) _message('Aplikasi email belum dapat dibuka');
    }
  }

  @override
  Widget build(BuildContext context) => AuthBackdrop(
    reset: true,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 44, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.sent ? 'Email Reset Sent!' : 'Forget Password',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'GardenSerif',
              fontSize: 28,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 44),
          widget.sent
              ? _mailbox()
              : artwork('forgot_lock', width: 286, height: 285),
          const SizedBox(height: 40),
          if (widget.sent)
            const Text(
              'Please check your email in a few minutes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            )
          else
            Form(
              key: form,
              child: TextFormField(
                key: const Key('reset-email'),
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: emailError,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Enter your email address...',
                ),
              ),
            ),
          const SizedBox(height: 36),
          FilledButton(
            onPressed: busy
                ? null
                : widget.sent
                ? _openEmail
                : _send,
            style: FilledButton.styleFrom(backgroundColor: resetGreen),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  busy
                      ? 'Mengirim...'
                      : widget.sent
                      ? 'Open My Email'
                      : 'Send Email',
                ),
                if (!widget.sent) ...[
                  const SizedBox(width: 18),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          _help(),
        ],
      ),
    ),
  );

  Widget _mailbox() => const SizedBox(
    height: 285,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.mark_email_read_rounded,
          size: 200,
          color: Color(0xFF4F9CDF),
        ),
        Positioned(
          bottom: 25,
          right: 20,
          child: Icon(Icons.key_rounded, size: 98, color: Color(0xFFEA8E25)),
        ),
      ],
    ),
  );

  Widget _help() => Column(
    children: [
      Text(
        widget.sent
            ? 'Didn’t receive the email?'
            : 'Don’t remember your email?',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'GardenSerif',
          fontSize: 16,
          color: Colors.black,
        ),
      ),
      TextButton(
        onPressed: () => _openEmail(contact: true),
        child: Text(
          widget.sent ? 'Contact us.' : 'Contact us at darulqutni512@gmail.com',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'GardenSerif',
            fontSize: 16,
            color: Color(0xFF518D20),
          ),
        ),
      ),
    ],
  );
}
