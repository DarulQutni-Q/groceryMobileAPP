import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/garden_widgets.dart';
import '../../../core/theme.dart';
import 'catalog_page.dart';

/// Filter yang tersedia di chip baris atas.
enum _PromoFilter { semua, diskon, gratis, cashback }

/// Data satu voucher. Kategori dipakai chip filter.
class _VoucherData {
  const _VoucherData({
    required this.big,
    required this.small,
    required this.bigColor,
    required this.title,
    required this.subtitle,
    required this.expiry,
    required this.expiryColor,
    required this.category,
  });
  final String big;
  final String small;
  final Color bigColor;
  final String title;
  final String subtitle;
  final String expiry;
  final Color expiryColor;
  final _PromoFilter category;
}

const _vouchers = [
  _VoucherData(
    big: '30%',
    small: 'DISKON',
    bigColor: Color(0xFF397A24),
    title: 'Diskon 30% Produk Segar (Fresh Mart)',
    subtitle: 'Min. belanja Rp 75rb • Maks. Rp 25rb',
    expiry: 'Berakhir dlm 2 hari',
    expiryColor: Color(0xFFC2571B),
    category: _PromoFilter.diskon,
  ),
  _VoucherData(
    big: 'FREE',
    small: 'ONGKIR',
    bigColor: Color(0xFFE86A17),
    title: 'Gratis Ongkir Instan s/d Rp 15.000',
    subtitle: 'Khusus pengiriman toko 15 menit',
    expiry: 'Berlaku hari ini',
    expiryColor: Color(0xFF397A24),
    category: _PromoFilter.gratis,
  ),
  _VoucherData(
    big: '+15k',
    small: 'POIN',
    bigColor: Color(0xFFE86A17),
    title: 'Cashback 15.000 Poin Sembako',
    subtitle: 'Khusus beras, minyak, gula min. 100rb',
    expiry: 'Sisa 5 hari',
    expiryColor: Color(0xFFC2571B),
    category: _PromoFilter.cashback,
  ),
];

class _WeeklyData {
  const _WeeklyData({
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
}

const _weekly = [
  _WeeklyData(
    background: Color(0xFFE4F3D8),
    tag: 'JSM SPECIAL',
    title: 'Promo JSM Akhir Pekan',
    subtitle: 'Diskon s/d 40%',
    action: 'Buka Katalog >',
    badge: _CalendarBadge(),
  ),
  _WeeklyData(
    background: Color(0xFFEDE7F6),
    tag: 'SERBA 5RB',
    title: 'Tebus Murah Serba 5rb',
    subtitle: 'Camilan & biskuit',
    action: 'Lihat Produk >',
    badge: _PercentBadge(),
  ),
];

/// Halaman Promo & Kupon.
///
/// Visual dipertahankan sama persis dengan referensi; yang berubah hanya
/// interaktivitas: chip filter bisa ditekan, kartu mingguan membuka katalog,
/// tombol Klaim mengubah status jadi "Sudah Klaim", dan "Voucher saya"
/// menyaring daftar ke voucher yang sudah diklaim.
/// Klaim tersimpan lokal di SharedPreferences (belum ada backend
/// voucher/loyalty), jadi voucher yang diklaim tidak memotong harga di
/// checkout.
class PromoPage extends StatefulWidget {
  const PromoPage({super.key, this.showBack = false});

  /// True kalau halaman didorong mandiri (bukan tab): tampilkan tombol
  /// kembali di header.
  final bool showBack;

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  _PromoFilter _filter = _PromoFilter.semua;
  bool _claimedOnly = false;

  /// Kunci penyimpanan klaim lokal.
  static const _klaimKey = 'promo_klaim';

  /// Judul voucher yang sudah diklaim di tampilan awal referensi.
  static const _freeTitle = 'Gratis Ongkir Instan s/d Rp 15.000';

  /// Judul voucher yang sudah diklaim. FREE ongkir sudah diklaim sesuai
  /// tampilan referensi (pill "Sudah Klaim").
  final _claimed = <String>{_freeTitle};

  @override
  void initState() {
    super.initState();
    _muatKlaim();
  }

  /// Muat klaim tersimpan; kalau belum ada simpanan sama sekali, pakai
  /// dan simpan set awal referensi (FREE ongkir sudah diklaim).
  Future<void> _muatKlaim() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_klaimKey);
      if (!mounted) return;
      if (stored == null) {
        await prefs.setStringList(_klaimKey, _claimed.toList());
      } else {
        setState(
          () => _claimed
            ..clear()
            ..addAll(stored),
        );
      }
    } catch (_) {
      // Tanpa prefs (mis. lingkungan tes tanpa mock): pakai set awal
      // di memori saja, jangan sampai halaman gagal tampil.
    }
  }

  Future<void> _klaim(String title) async {
    setState(() => _claimed.add(title));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_klaimKey, _claimed.toList());
    } catch (_) {
      // Klaim tetap tampil di sesi ini walau penyimpanan gagal.
    }
  }

  void _openCatalog() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CatalogPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shownVouchers = _vouchers
        .where(
          (v) =>
              (_filter == _PromoFilter.semua || v.category == _filter) &&
              (!_claimedOnly || _claimed.contains(v.title)),
        )
        .toList();
    // Kedua kartu mingguan adalah promo diskon.
    final showWeekly =
        !_claimedOnly &&
        (_filter == _PromoFilter.semua || _filter == _PromoFilter.diskon);
    return Column(
      children: [
        LimeHeader(
          title: 'Promo & Kupon',
          showBack: widget.showBack,
          height: 200,
          topPadding: 38,
          titleSize: 24,
          actions: [
            SizedBox(
              height: 32,
              child: FilledButton(
                onPressed: () => setState(() => _claimedOnly = !_claimedOnly),
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
                  children: [
                    _FilterChip(
                      'Semua Promo',
                      active: _filter == _PromoFilter.semua,
                      onTap: () => setState(() => _filter = _PromoFilter.semua),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      'Diskon Belanja',
                      active: _filter == _PromoFilter.diskon,
                      onTap: () =>
                          setState(() => _filter = _PromoFilter.diskon),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      'Gratis Ongkir',
                      active: _filter == _PromoFilter.gratis,
                      onTap: () =>
                          setState(() => _filter = _PromoFilter.gratis),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      'Cashback',
                      active: _filter == _PromoFilter.cashback,
                      onTap: () =>
                          setState(() => _filter = _PromoFilter.cashback),
                    ),
                  ],
                ),
              ),
              if (showWeekly) ...[
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
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _openCatalog,
                        borderRadius: BorderRadius.circular(16),
                        child: _WeeklyCard(
                          background: _weekly[0].background,
                          tag: _weekly[0].tag,
                          title: _weekly[0].title,
                          subtitle: _weekly[0].subtitle,
                          action: _weekly[0].action,
                          badge: _weekly[0].badge,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _openCatalog,
                        borderRadius: BorderRadius.circular(16),
                        child: _WeeklyCard(
                          background: _weekly[1].background,
                          tag: _weekly[1].tag,
                          title: _weekly[1].title,
                          subtitle: _weekly[1].subtitle,
                          action: _weekly[1].action,
                          badge: _weekly[1].badge,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _claimedOnly
                          ? 'Voucher Saya (${shownVouchers.length})'
                          : 'Voucher',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: gardenInk,
                      ),
                    ),
                  ),
                  if (_claimedOnly)
                    TextButton(
                      onPressed: () => setState(() => _claimedOnly = false),
                      child: const Text('Tampilkan Semua'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (shownVouchers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Belum ada voucher yang diklaim.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: textGrey),
                  ),
                )
              else
                for (var i = 0; i < shownVouchers.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _VoucherCard(
                    big: shownVouchers[i].big,
                    small: shownVouchers[i].small,
                    bigColor: shownVouchers[i].bigColor,
                    title: shownVouchers[i].title,
                    subtitle: shownVouchers[i].subtitle,
                    expiry: shownVouchers[i].expiry,
                    expiryColor: shownVouchers[i].expiryColor,
                    claimed: _claimed.contains(shownVouchers[i].title),
                    onClaim: () => _klaim(shownVouchers[i].title),
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(this.label, {this.active = false, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: active ? gardenInk : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: active ? null : Border.all(color: gardenBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: active ? Colors.white : gardenInk,
        ),
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
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: gardenInk,
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: textGrey)),
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
    required this.onClaim,
  });
  final String big;
  final String small;
  final Color bigColor;
  final String title;
  final String subtitle;
  final String expiry;
  final Color expiryColor;
  final bool claimed;
  final VoidCallback onClaim;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 46,
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
                  fontSize: 10.5,
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
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
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF397A24),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.check, size: 11, color: Color(0xFF397A24)),
                  ],
                ),
              )
            : SizedBox(
                height: 32,
                child: FilledButton(
                  onPressed: onClaim,
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
