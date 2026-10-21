import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/secure_storage.dart';
import '../models/keranjang.dart';
import '../models/produk.dart';

final keranjangStorageProvider = Provider<SecureStorage>(
  (ref) => SecureStorage(),
);
final keranjangProvider = StateNotifierProvider.autoDispose
    .family<KeranjangNotifier, Keranjang, String>(
      (ref, userId) =>
          KeranjangNotifier(ref.watch(keranjangStorageProvider), userId),
      dependencies: [keranjangStorageProvider],
    );

class KeranjangNotifier extends StateNotifier<Keranjang> {
  KeranjangNotifier(this.storage, this.userId)
    : super(Keranjang(memuat: true)) {
    siap = _restore();
  }
  final SecureStorage storage;
  final String userId;
  late final Future<void> siap;
  Future<void> _operations = Future.value();
  bool _restoreGagal = false;
  List<String> _selesai = [];

  Future<void> _restore() async {
    try {
      final value = await storage.readKeranjang(userId);
      final items = <KeranjangItem>[];
      if (value != null) {
        final json = jsonDecode(value) as Map<String, dynamic>;
        if (json['version'] != 1) {
          throw const FormatException('Versi keranjang tidak didukung');
        }
        _selesai = List<String>.from(json['checkout_selesai'] as List? ?? []);
        items.addAll(
          (json['items'] as List).map(
            (item) => KeranjangItem.fromJson(item as Map<String, dynamic>),
          ),
        );
        final ids = <String>{};
        for (final item in items) {
          if (item.qty < 1 ||
              item.qty > item.produk.stok ||
              !item.produk.isTersedia ||
              item.produk.harga < 1 ||
              item.produk.id.isEmpty ||
              !ids.add(item.produk.id) ||
              item.produk.tokoId != items.first.produk.tokoId) {
            throw const FormatException('Isi keranjang tidak valid');
          }
        }
      }
      _restoreGagal = false;
      if (mounted) state = Keranjang(items: items);
    } catch (_) {
      _restoreGagal = true;
      if (mounted) {
        state = Keranjang(
          pesan: 'Keranjang belum dapat dibaca. Coba lagi atau kosongkan keranjang.',
        );
      }
    }
  }

  Future<void> muatUlang() {
    return _operations = _operations.then((_) async {
      await siap;
      if (!mounted) return;
      state = Keranjang(items: state.items, memuat: true);
      await _restore();
    });
  }

  Future<bool> _change(
    List<KeranjangItem> Function(List<KeranjangItem>) change, {
    bool reset = false,
    String? checkoutKey,
  }) {
    final result = _operations.then((_) async {
      await siap;
      if (!mounted || (_restoreGagal && !reset)) return false;
      if (checkoutKey != null && _selesai.contains(checkoutKey)) return true;
      final before = state.items;
      try {
        final next = change(before);
        final completed = [..._selesai, ?checkoutKey];
        if (completed.length > 30) {
          completed.removeRange(0, completed.length - 30);
        }
        state = Keranjang(items: next);
        await storage.saveKeranjang(
          userId,
          jsonEncode({
            'version': 1,
            'items': next.map((item) => item.toJson()).toList(),
            if (completed.isNotEmpty) 'checkout_selesai': completed,
          }),
        );
        _selesai = completed;
        if (reset) _restoreGagal = false;
        return true;
      } on ArgumentError catch (error) {
        if (mounted) {
          state = Keranjang(items: before, pesan: error.message as String);
        }
        return false;
      } catch (_) {
        if (mounted) {
          state = Keranjang(
            items: before,
            pesan: 'Keranjang belum dapat disimpan. Silakan coba lagi.',
          );
        }
        return false;
      }
    });
    _operations = result.then((_) {});
    return result;
  }

  Future<bool> tambahItem(
    Produk produk, {
    int qty = 1,
    bool gantiToko = false,
  }) => _change((items) {
    if (!produk.isTersedia || qty < 1 || produk.harga < 1) {
      throw ArgumentError('Produk tidak tersedia');
    }
    final bedaToko =
        items.isNotEmpty && items.first.produk.tokoId != produk.tokoId;
    if (bedaToko && !gantiToko) {
      throw ArgumentError('Konfirmasi penggantian toko terlebih dahulu');
    }
    final next = bedaToko ? <KeranjangItem>[] : [...items];
    final index = next.indexWhere((item) => item.produk.id == produk.id);
    final jumlah = qty + (index < 0 ? 0 : next[index].qty);
    if (jumlah > produk.stok) {
      throw ArgumentError('Jumlah melebihi stok tersedia');
    }
    final item = KeranjangItem(produk: produk, qty: jumlah);
    if (index < 0) {
      next.add(item);
    } else {
      next[index] = item;
    }
    return next;
  });

  Future<bool> ubahQty(String id, int qty) => _change((items) {
    final item = items.where((item) => item.produk.id == id).firstOrNull;
    if (item == null) return items;
    if (qty < 0 || qty > item.produk.stok) {
      throw ArgumentError('Jumlah harus antara 0 dan stok tersedia');
    }
    return [
      for (final item in items)
        if (item.produk.id != id)
          item
        else if (qty > 0)
          item.copyWith(qty: qty),
    ];
  });

  Future<bool> tambahQty(String id) => _change((items) {
    final item = items.where((item) => item.produk.id == id).firstOrNull;
    if (item == null) return items;
    if (item.qty >= item.produk.stok) {
      throw ArgumentError('Jumlah melebihi stok tersedia');
    }
    return [
      for (final item in items)
        item.produk.id == id ? item.copyWith(qty: item.qty + 1) : item,
    ];
  });

  Future<bool> kurangItem(String id) => _change(
    (items) => [
      for (final item in items)
        if (item.produk.id != id)
          item
        else if (item.qty > 1)
          item.copyWith(qty: item.qty - 1),
    ],
  );
  Future<bool> hapusItem(String id) =>
      _change((items) => items.where((item) => item.produk.id != id).toList());
  Future<bool> kosongkan() => _change((_) => [], reset: true);
  Future<bool> pilihItem(String id, bool value) => _change(
    (items) => [
      for (final item in items)
        item.produk.id == id ? item.copyWith(dipilih: value) : item,
    ],
  );
  Future<bool> pilihSemua(bool value) => _change(
    (items) => [for (final item in items) item.copyWith(dipilih: value)],
  );
  Future<bool> hapusDipilih() =>
      _change((items) => items.where((item) => !item.dipilih).toList());
  int hitungSubtotal() => state.subtotal;
  Future<bool> selesaikanCheckout(String key, List<KeranjangItem> purchased) =>
      _change((items) {
        final quantities = {
          for (final item in purchased) item.produk.id: item.qty,
        };
        return [
          for (final item in items)
            if (!quantities.containsKey(item.produk.id))
              item
            else if (item.qty > quantities[item.produk.id]!)
              item.copyWith(qty: item.qty - quantities[item.produk.id]!),
        ];
      }, checkoutKey: key);
}
