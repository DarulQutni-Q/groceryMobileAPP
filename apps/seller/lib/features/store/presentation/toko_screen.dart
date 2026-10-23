import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../../auth/application/auth_provider.dart';
import '../../../shared/auth_layout.dart';
import '../application/store_provider.dart';
import 'toko_editor.dart';
import 'hours_editor.dart';

class TokoScreen extends ConsumerWidget {
  const TokoScreen({super.key, required this.userId, required this.toko});
  final String userId;
  final Toko toko;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeProvider(userId));
    final toko = state.toko ?? this.toko;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Toko',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        Text('Toko ${toko.nama}', style: const TextStyle(fontSize: 17)),
        const SizedBox(height: 20),
        Row(
          children: [
            const SizedBox(
              width: 76,
              height: 76,
              child: ReferenceArtwork(
                asset: 'splash.png',
                rect: Rect.fromLTWH(81, 221, 307, 308),
                width: 76,
                semanticLabel: 'Logo toko',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    toko.nama,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    toko.alamat.isEmpty ? 'Alamat belum diisi' : toko.alamat,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Card.filled(
          color: const Color(0xFFE4D9BB),
          margin: EdgeInsets.zero,
          child: ListTile(
            title: const Text('Status toko'),
            subtitle: Text(
              toko.status == 'buka' ? 'Toko sedang buka' : 'Toko sedang tutup',
            ),
            trailing: ActionChip(
              key: const Key('toko-status-action'),
              label: Text(toko.status == 'buka' ? 'Buka' : 'Tutup'),
              backgroundColor: toko.status == 'buka'
                  ? const Color(0xFF3B6341)
                  : null,
              labelStyle: TextStyle(
                color: toko.status == 'buka' ? Colors.white : Colors.black,
              ),
              onPressed: state.busy.contains('status')
                  ? null
                  : () => ref.read(storeProvider(userId).notifier).mutate(
                      'status',
                      () async {
                        await ref
                            .read(tokoApiProvider)
                            .updateStatus(
                              toko.status == 'buka' ? 'tutup' : 'buka',
                            );
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _menu(
          'Info Toko',
          Icons.home_outlined,
          () => _open(context, TokoEditor(userId: userId, toko: toko)),
        ),
        _menu(
          'Jam buka',
          Icons.schedule,
          () => _open(context, HoursEditor(userId: userId)),
        ),
        _menu(
          'Pengiriman',
          Icons.delivery_dining,
          () => _open(
            context,
            TokoEditor(userId: userId, toko: toko, section: 'pengiriman'),
          ),
        ),
        _menu(
          'Rekening Pencairan',
          Icons.account_balance_outlined,
          () => _open(
            context,
            TokoEditor(userId: userId, toko: toko, section: 'rekening'),
          ),
          subtitle: toko.rekeningBank,
        ),
        _menu(
          'Lihat Panduan Awal',
          Icons.folder_outlined,
          () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Panduan Awal'),
              content: const Text(
                'Lengkapi info toko dan jam buka, pilih pengiriman, lalu tambahkan produk. Buka toko saat kamu siap menerima pesanan.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Mengerti'),
                ),
              ],
            ),
          ),
        ),
        _menu(
          'Keluar',
          Icons.logout,
          () => _confirmLogout(context, ref),
          logout: true,
        ),
      ],
    );
  }

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) {
    var saving = false;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            title: const Text('Keluar dari toko?'),
            content: const Text(
              'Kamu perlu login kembali untuk mengelola toko.',
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(100, 48),
                  backgroundColor: const Color(0xFFDC043A),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: saving
                    ? null
                    : () async {
                        setState(() => saving = true);
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted &&
                            (ModalRoute.of(context)?.isCurrent ?? false)) {
                          Navigator.pop(context);
                        }
                      },
                child: Text(saving ? 'Keluar...' : 'Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menu(
    String label,
    IconData icon,
    VoidCallback action, {
    String? subtitle,
    bool logout = false,
  }) => Card.outlined(
    color: const Color(0xFFECE5D0),
    margin: EdgeInsets.zero,
    child: ListTile(
      leading: Icon(icon, color: const Color(0xFF1F634D), size: 36),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 20,
          color: logout ? const Color(0xFFDC043A) : Colors.black,
        ),
      ),
      subtitle: subtitle == null || subtitle.isEmpty ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF1F634D)),
      onTap: action,
    ),
  );
}
