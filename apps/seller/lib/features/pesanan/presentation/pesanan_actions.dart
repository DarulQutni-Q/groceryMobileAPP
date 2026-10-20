import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../store/presentation/store_widgets.dart';
import '../application/pesanan_provider.dart';

Future<void> terimaPesanan(
  BuildContext context,
  WidgetRef ref,
  String userId,
  Pesanan order,
) async {
  final elapsed = Stopwatch()..start();
  final updated = await ref
      .read(pesananProvider(userId).notifier)
      .change(order.id, () => ref.read(pesananApiProvider).terima(order.id));
  if (!context.mounted) return;
  if (updated == null) {
    storeMessage(
      context,
      ref.read(pesananProvider(userId)).error ?? 'Pesanan belum diterima.',
      error: true,
    );
    return;
  }
  ref.invalidate(pesananDetailProvider((userId: userId, id: order.id)));
  final window =
      updated.undoUntil?.difference(updated.serverTime ?? updated.undoUntil!) ??
      Duration.zero;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF3B6341),
    showDragHandle: true,
    builder: (_) => _TerimaSheet(
      kode: order.kode,
      remaining: window - elapsed.elapsed,
      onUndo: () async {
        final undone = await ref
            .read(pesananProvider(userId).notifier)
            .change(
              order.id,
              () => ref.read(pesananApiProvider).urungkan(order.id),
            );
        if (!context.mounted) return null;
        if (undone == null) {
          return ref.read(pesananProvider(userId)).error ??
              'Pesanan belum dapat diurungkan.';
        }
        ref.invalidate(pesananDetailProvider((userId: userId, id: order.id)));
        return null;
      },
    ),
  );
}

Future<void> tolakPesanan(BuildContext context, String userId, String id) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFDFFF4),
      builder: (_) => StoreBackground(
        child: _TolakSheet(userId: userId, id: id),
      ),
    );

class _TerimaSheet extends StatefulWidget {
  const _TerimaSheet({
    required this.kode,
    required this.remaining,
    required this.onUndo,
  });
  final String kode;
  final Duration remaining;
  final Future<String?> Function() onUndo;
  @override
  State<_TerimaSheet> createState() => _TerimaSheetState();
}

class _TerimaSheetState extends State<_TerimaSheet> {
  final _elapsed = Stopwatch();
  Timer? _timer;
  bool _busy = false;
  String? _error;
  int get seconds =>
      (widget.remaining - _elapsed.elapsed).inMilliseconds.clamp(0, 10000) ~/
      1000;
  @override
  void initState() {
    super.initState();
    _elapsed.start();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {});
      if (seconds == 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsed.stop();
    super.dispose();
  }

  Future<void> _undo() async {
    setState(() => _busy = true);
    final error = await widget.onUndo();
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(
            'Pesanan ${widget.kode} diterima',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            seconds > 0
                ? 'Dapat diurungkan dalam $seconds detik.'
                : 'Waktu untuk mengurungkan sudah habis.',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            onPressed: _busy || seconds == 0 ? null : _undo,
            child: Text(_busy ? 'Mengurungkan...' : 'Urungkan'),
          ),
        ],
      ),
    ),
  );
}

class _TolakSheet extends ConsumerStatefulWidget {
  const _TolakSheet({required this.userId, required this.id});
  final String userId, id;
  @override
  ConsumerState<_TolakSheet> createState() => _TolakSheetState();
}

class _TolakSheetState extends ConsumerState<_TolakSheet> {
  String? _reason, _error;
  final _other = TextEditingController();
  bool _saving = false;
  String get reason =>
      _reason == 'Lainnya' ? _other.text.trim() : _reason ?? '';
  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (reason.isEmpty) return;
    setState(() => _saving = true);
    final result = await ref
        .read(pesananProvider(widget.userId).notifier)
        .change(
          widget.id,
          () => ref.read(pesananApiProvider).tolak(widget.id, reason),
        );
    if (!mounted) return;
    if (result != null) {
      ref.invalidate(
        pesananDetailProvider((userId: widget.userId, id: widget.id)),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = ref.read(pesananProvider(widget.userId)).error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Kenapa pesanan ditolak?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pembeli akan diberi tahu alasannya.',
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),
              RadioGroup<String>(
                groupValue: _reason,
                onChanged: (value) {
                  if (!_saving) setState(() => _reason = value);
                },
                child: Column(
                  children: [
                    for (final value in [
                      'Stok Habis',
                      'Toko akan ditutup',
                      'Alamat di luar jangkauan',
                      'Lainnya',
                    ])
                      Card.filled(
                        color: const Color(0xFFECE5D0),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: RadioListTile<String>(
                          title: Text(
                            value,
                            style: const TextStyle(color: Colors.black),
                          ),
                          value: value,
                        ),
                      ),
                  ],
                ),
              ),
              if (_reason == 'Lainnya')
                TextField(
                  key: const Key('pesanan-reject-reason'),
                  controller: _other,
                  style: const TextStyle(color: Colors.black),
                  enabled: !_saving,
                  maxLength: 1000,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Tulis alasan penolakan',
                  ),
                ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Color(0xFFDC043A))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const Key('pesanan-reject-confirm'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC043A),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 15),
                      ),
                      onPressed: _saving || reason.isEmpty ? null : _submit,
                      child: Text(_saving ? 'Menolak...' : 'Tolak Pesanan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
