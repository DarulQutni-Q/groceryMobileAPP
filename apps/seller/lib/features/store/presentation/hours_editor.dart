import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../../core/network.dart';
import '../application/store_provider.dart';
import 'store_widgets.dart';

class HoursEditor extends ConsumerStatefulWidget {
  const HoursEditor({super.key, required this.userId});
  final String userId;
  @override
  ConsumerState<HoursEditor> createState() => _HoursEditorState();
}

class _HoursEditorState extends ConsumerState<HoursEditor> {
  List<JamBuka>? _days;
  String? _error;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final days = await ref
          .read(tokoApiProvider)
          .getJamBuka()
          .timeout(sellerLoadLimit);
      if (mounted) {
        setState(() {
          _days = days;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = authErrorMessage(error));
        storeMessage(context, _error!, error: true);
      }
    }
  }

  String _format(String? time) =>
      (time ?? '07:00').substring(0, 5).replaceAll(':', '.');
  Future<void> _pick(int index, bool open) async {
    final day = _days![index];
    final value =
        (open ? day.jamBuka : day.jamTutup) ?? (open ? '07:00' : '23:00');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(value.substring(0, 2)),
        minute: int.parse(value.substring(3, 5)),
      ),
      helpText: open ? 'Jam buka' : 'Jam tutup',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    final time =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
    setState(
      () => _days![index] = JamBuka(
        hari: day.hari,
        isTutup: false,
        jamBuka: open ? time : day.jamBuka,
        jamTutup: open ? day.jamTutup : time,
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(tokoApiProvider).updateJamBuka(_days!);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) storeMessage(context, authErrorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => StorePage(
    title: 'Jam Buka',
    child: _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Coba lagi')),
              ],
            ),
          )
        : _days == null
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    'Atur Hari dan Jam',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 7,
                  itemBuilder: (context, index) => _row(index),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Menyimpan...' : 'Simpan Jam Buka'),
                  ),
                ),
              ),
            ],
          ),
  );
  Widget _row(int index) {
    final day = _days![index];
    return Card.outlined(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 62,
              child: Text(
                '${day.hari[0].toUpperCase()}${day.hari.substring(1)}',
              ),
            ),
            Expanded(
              child: day.isTutup
                  ? const Text('Tutup', style: TextStyle(color: Colors.grey))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _time(_format(day.jamBuka), () => _pick(index, true)),
                        const Text(' - '),
                        _time(_format(day.jamTutup), () => _pick(index, false)),
                      ],
                    ),
            ),
            Switch(
              value: !day.isTutup,
              activeTrackColor: const Color(0xFF192D1E),
              onChanged: _saving
                  ? null
                  : (value) => setState(
                      () => _days![index] = JamBuka(
                        hari: day.hari,
                        isTutup: !value,
                        jamBuka: value ? day.jamBuka ?? '07:00:00' : null,
                        jamTutup: value ? day.jamTutup ?? '23:00:00' : null,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _time(String label, VoidCallback action) => OutlinedButton(
    onPressed: _saving ? null : action,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(52, 32),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      textStyle: const TextStyle(fontSize: 13),
    ),
    child: Text(label),
  );
}
