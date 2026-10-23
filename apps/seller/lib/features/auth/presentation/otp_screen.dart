import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../shared/auth_layout.dart';
import '../application/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    required this.email,
    required this.maskedPhone,
    required this.onBack,
    required this.onVerified,
  });
  final String email;
  final String? maskedPhone;
  final VoidCallback onBack;
  final void Function(String email, String resetToken) onVerified;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const _length = 6;
  static const _resendSeconds = 40;

  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _focuses = List.generate(_length, (_) => FocusNode());
  bool _busy = false;
  int _seconds = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focuses[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focuses) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _seconds--;
        if (_seconds <= 0) t.cancel();
      });
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _resend() async {
    try {
      final api = AuthApi(ref.read(apiClientProvider));
      await api.forgotPassword(widget.email);
      if (!mounted) return;
      _startTimer();
      for (final c in _controllers) {
        c.clear();
      }
      _focuses[0].requestFocus();
    } catch (e) {
      if (!mounted) return;
      showAuthMessage(context, authErrorMessage(e), error: true);
    }
  }

  Future<void> _submit() async {
    final otp = _otp;
    if (otp.length < _length) {
      showAuthMessage(context, 'Masukkan 6 digit kode OTP', error: true);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final api = AuthApi(ref.read(apiClientProvider));
      final token = await api.verifyOtp(widget.email, otp);
      if (!mounted) return;
      widget.onVerified(widget.email, token);
    } catch (e) {
      if (!mounted) return;
      showAuthMessage(context, authErrorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _timerLabel() {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.maskedPhone ?? widget.email;
    return AuthLayout(
      title: 'Verifikasi OTP',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Color(0xFF555555)),
              children: [
                const TextSpan(text: 'Kode verifikasi dikirim ke '),
                TextSpan(
                  text: target,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_length, (i) => _OtpBox(
              key: Key('otp_$i'),
              controller: _controllers[i],
              focusNode: _focuses[i],
              onInput: (digit) {
                if (digit.isNotEmpty && i < _length - 1) {
                  _focuses[i + 1].requestFocus();
                }
              },
              onBackspace: () {
                if (i > 0) {
                  _controllers[i - 1].clear();
                  _focuses[i - 1].requestFocus();
                }
              },
            )),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Kirim ulang dalam ',
                style: TextStyle(
                  fontSize: 13,
                  color: _seconds > 0 ? const Color(0xFF888888) : Colors.transparent,
                ),
              ),
              if (_seconds > 0)
                Text(
                  _timerLabel(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF192D1E),
                  ),
                )
              else
                TextButton(
                  onPressed: _resend,
                  child: const Text(
                    'Kirim Ulang',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF192D1E),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Memverifikasi...' : 'Lanjut'),
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onInput,
    required this.onBackspace,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String digit) onInput;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 46,
    height: 54,
    child: KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            controller.text.isEmpty) {
          onBackspace();
        }
      },
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFECE5D0),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDCCCAC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDCCCAC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF192D1E),
              width: 2,
            ),
          ),
        ),
        onChanged: (v) {
          if (v.length > 1) {
            controller.text = v[v.length - 1];
            controller.selection = TextSelection.collapsed(
              offset: controller.text.length,
            );
          }
          onInput(controller.text);
        },
      ),
    ),
  );
}
