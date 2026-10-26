import 'package:flutter/material.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';

/// Tab Promo: Promo & Kupon sesuai desain Figma.
class PromoPage extends StatelessWidget {
  const PromoPage({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      LimeHeader(
        title: 'Promo & Kupon',
        showBack: false,
        height: 150,
        actions: [
          SizedBox(
            height: 32,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 32),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Roboto',
                ),
              ),
              child: const Text('Voucher saya'),
            ),
          ),
        ],
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  _FilterChip('Semua Promo', active: true),
                  SizedBox(width: 8),
                  _FilterChip('Diskon Belanja'),
                  SizedBox(width: 8),
                  _FilterChip('Gratis Ongkir'),
                  SizedBox(width: 8),
                  _FilterChip('Cashback'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Promo Mingguan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: gardenInk,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(
                  child: _WeeklyCard(
                    background: Color(0xFFE4F3D8),
                    tag: 'JSM SPECIAL',
                    title: 'Promo JSM Akhir Pekan',
                    subtitle: 'Diskon s/d 40%',
                    action: 'Buka Katalog ›',
                    badge: _CalendarBadge(),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _WeeklyCard(
                    background: Color(0xFFEDE7F6),
                    tag: 'SERBA 5RB',
                    title: 'Tebus Murah Serba 5rb',
                    subtitle: 'Camilan & biskuit',
                    action: 'Lihat Produk ›',
                    badge: _PercentBadge(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Voucher',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: gardenInk,
              ),
            ),
            const SizedBox(height: 10),
            const _VoucherCard(
              big: '30%',
              small: 'DISKON',
              bigColor: Color(0xFF397A24),
              title: 'Diskon 30% Produk Segar (Fresh Mart)',
              subtitle: 'Min. belanja Rp 75rb • Maks. Rp 25rb',
              expiry: 'Berakhir dlm 2 hari',
              expiryColor: Color(0xFFC2571B),
              claimed: false,
            ),
            const SizedBox(height: 10),
            const _VoucherCard(
              big: 'FREE',
              small: 'ONGKIR',
              bigColor: Color(0xFFE86A17),
              title: 'Gratis Ongkir Instan s/d Rp 15.000',
              subtitle: 'Khusus pengiriman toko 15 menit',
              expiry: 'Berlaku hari ini',
              expiryColor: Color(0xFF397A24),
              claimed: true,
            ),
            const SizedBox(height: 10),
            const _VoucherCard(
              big: '+15k',
              small: 'POIN',
              bigColor: Color(0xFFE86A17),
              title: 'Cashback 15.000 Poin Sembako',
              subtitle: 'Khusus beras, minyak, gula min. 100rb',
              expiry: 'Sisa 5 hari',
              expiryColor: Color(0xFFC2571B),
              claimed: false,
            ),
          ],
        ),
      ),
    ],
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(this.label, {this.active = false});
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: active ? gardenInk : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: active
          ? null
          : Border.all(color: gardenBorder),
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

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({
    required this.background,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.badge,
  });
  final Color background;
  final String tag;
  final String title;
  final String subtitle;
  final String action;
  final Widget badge;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                tag,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: textGrey,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            badge,
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: gardenInk,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: textGrey),
        ),
        const SizedBox(height: 8),
        Text(
          action,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF397A24),
          ),
        ),
      ],
    ),
  );
}

class _CalendarBadge extends StatelessWidget {
  const _CalendarBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today_outlined, size: 12, color: gardenInk),
        SizedBox(width: 3),
        Text(
          '15 Okt',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: gardenInk,
          ),
        ),
      ],
    ),
  );
}

class _PercentBadge extends StatelessWidget {
  const _PercentBadge();
  @override
  Widget build(BuildContext context) => Container(
    width: 26,
    height: 26,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color(0xFFD1C4E9),
    ),
    child: const Text(
      '%',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF5E35B1),
      ),
    ),
  );
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.big,
    required this.small,
    required this.bigColor,
    required this.title,
    required this.subtitle,
    required this.expiry,
    required this.expiryColor,
    required this.claimed,
  });
  final String big;
  final String small;
  final Color bigColor;
  final String title;
  final String subtitle;
  final String expiry;
  final Color expiryColor;
  final bool claimed;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Column(
            children: [
              Text(
                big,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: bigColor,
                ),
              ),
              Text(
                small,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: bigColor,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: gardenInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: textGrey),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: expiryColor),
                  const SizedBox(width: 3),
                  Text(
                    expiry,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: expiryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        claimed
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F3D8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sudah Klaim',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF397A24),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.check,
                      size: 12,
                      color: Color(0xFF397A24),
                    ),
                  ],
                ),
              )
            : SizedBox(
                height: 32,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 32),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  child: const Text('Klaim'),
                ),
              ),
      ],
    ),
  );
}
