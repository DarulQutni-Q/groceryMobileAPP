import 'package:flutter/material.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';

/// Tab Pesanan: Pesanan Saya sesuai desain Figma.
///
/// Konten pesanan masih contoh dari Figma (pesanan aktif + riwayat).
/// Integrasi ke GET /pesanan (model + API sudah ada di shared package)
/// adalah tindak lanjut setelah rebuild visual ini.
class PesananPage extends StatelessWidget {
  const PesananPage({
    super.key,
    this.onLihatStruk,
    this.onChatDriver,
    this.onBeliLagi,
  });
  final VoidCallback? onLihatStruk;
  final VoidCallback? onChatDriver;
  final VoidCallback? onBeliLagi;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      LimeHeader(
        title: 'Pesanan Saya',
        showBack: false,
        centerTitle: false,
        height: 150,
        actions: [
          RoundIconButton(icon: Icons.search, onPressed: () {}),
        ],
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            Row(
              children: const [
                _OrderFilter('Dalam Proses (1)', active: true),
                SizedBox(width: 8),
                _OrderFilter('Selesai'),
                SizedBox(width: 8),
                _OrderFilter('Dibatalkan'),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 20,
                        color: gardenInk,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'GardenMart Cabang Bireuen',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: gardenInk,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tiba dalam ~8 Menit',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: gardenInk,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _Timeline(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: gardenInk,
                        child: Icon(
                          Icons.person,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pak Budi',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: gardenInk,
                              ),
                            ),
                            Text(
                              'Honda Beat • BK 4122 QD',
                              style: TextStyle(
                                fontSize: 10,
                                color: textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 34,
                        child: OutlinedButton.icon(
                          onPressed: onChatDriver ?? () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            minimumSize: const Size(0, 34),
                            side: const BorderSide(color: gardenBorder),
                            foregroundColor: gardenInk,
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 14),
                          label: const Text('Chat Driver'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE4F3D8),
                        ),
                        child: const Icon(
                          Icons.phone,
                          size: 17,
                          color: gardenInk,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '3 Barang: Bimoli 2L, Ultra Milk 1L, Indomie (5...',
                    style: TextStyle(fontSize: 12, color: textGrey),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Text(
                        'Total Pembayaran:',
                        style: TextStyle(fontSize: 12, color: textGrey),
                      ),
                      Spacer(),
                      Text(
                        'Rp 67.600',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: gardenInk,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Riwayat Pesanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: gardenInk,
              ),
            ),
            const SizedBox(height: 10),
            _HistoryCard(
              toko: 'GardenMart Cabang Lhokseumawe',
              tanggal: '2 Okt 2026',
              status: 'Selesai',
              statusColor: Color(0xFF397A24),
              statusBackground: Color(0xFFE4F3D8),
              onLihatStruk: onLihatStruk,
              onBeliLagi: onBeliLagi,
            ),
            const SizedBox(height: 12),
            _HistoryCard(
              toko: 'GardenMart Cabang Samalanga',
              tanggal: '2 Okt 2026',
              status: 'Dibatalkan',
              statusColor: Color(0xFFB22E32),
              statusBackground: Color(0xFFFBE9E7),
              onLihatStruk: onLihatStruk,
              onBeliLagi: onBeliLagi,
            ),
          ],
        ),
      ),
    ],
  );
}

class _OrderFilter extends StatelessWidget {
  const _OrderFilter(this.label, {this.active = false});
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: active ? gardenInk : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: active ? null : Border.all(color: gardenBorder),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: active ? Colors.white : gardenInk,
      ),
    ),
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline();
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      _TimelineStep(
        icon: Icons.check,
        label: 'Dikonfirmasi',
        state: _StepState.done,
      ),
      _TimelineLine(done: true),
      _TimelineStep(
        icon: Icons.check,
        label: 'Dikemas',
        state: _StepState.done,
      ),
      _TimelineLine(done: true),
      _TimelineStep(
        icon: Icons.delivery_dining,
        label: 'Dlm Perjalanan',
        state: _StepState.current,
      ),
      _TimelineLine(done: false),
      _TimelineStep(
        icon: Icons.location_on_outlined,
        label: 'Tiba',
        state: _StepState.todo,
      ),
    ],
  );
}

enum _StepState { done, current, todo }

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.label,
    required this.state,
  });
  final IconData icon;
  final String label;
  final _StepState state;
  @override
  Widget build(BuildContext context) {
    final Color circleColor;
    final Color iconColor;
    switch (state) {
      case _StepState.done:
        circleColor = const Color(0xFF397A24);
        iconColor = Colors.white;
      case _StepState.current:
        circleColor = gardenInk;
        iconColor = Colors.white;
      case _StepState.todo:
        circleColor = Colors.white;
        iconColor = textGrey;
    }
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleColor,
            border: state == _StepState.todo
                ? Border.all(color: const Color(0xFFB9C4B4), width: 1.5)
                : null,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 70,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: state == _StepState.todo
                  ? FontWeight.w400
                  : FontWeight.w600,
              color: state == _StepState.todo ? textGrey : gardenInk,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineLine extends StatelessWidget {
  const _TimelineLine({required this.done});
  final bool done;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        height: 2,
        color: done
            ? const Color(0xFF397A24)
            : const Color(0xFFD9E6CF),
      ),
    ),
  );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.toko,
    required this.tanggal,
    required this.status,
    required this.statusColor,
    required this.statusBackground,
    this.onLihatStruk,
    this.onBeliLagi,
  });
  final String toko;
  final String tanggal;
  final String status;
  final Color statusColor;
  final Color statusBackground;
  final VoidCallback? onLihatStruk;
  final VoidCallback? onBeliLagi;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: gardenInk,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    toko,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: gardenInk,
                    ),
                  ),
                  Text(
                    tanggal,
                    style: const TextStyle(fontSize: 11, color: textGrey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: statusBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            _Thumb(Color(0xFFE3F2FD)),
            SizedBox(width: 8),
            _Thumb(Color(0xFFFFF3E0)),
            SizedBox(width: 8),
            _Thumb(Color(0xFFFCE4EC)),
            SizedBox(width: 8),
            _ThumbMore(),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Spacer(),
            Text(
              '4 Barang  Rp 89.500',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: gardenInk,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              height: 34,
              child: FilledButton.icon(
                onPressed: onBeliLagi ?? () {},
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 34),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Roboto',
                  ),
                ),
                icon: const Icon(Icons.replay, size: 16),
                label: const Text('Beli lagi'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 34,
              child: FilledButton.icon(
                onPressed: onLihatStruk ?? () {},
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 34),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Roboto',
                  ),
                ),
                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                label: const Text('Lihat struk'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Thumb extends StatelessWidget {
  const _Thumb(this.color);
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(
      Icons.shopping_basket_outlined,
      size: 22,
      color: gardenInk,
    ),
  );
}

class _ThumbMore extends StatelessWidget {
  const _ThumbMore();
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFEFF4EB),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text(
      '+1',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: gardenInk,
      ),
    ),
  );
}
