import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';

class CartStorage extends SecureStorage {
  final values = <String, String>{};
  bool gagal = false;
  Completer<void>? tahan;
  Completer<void>? dibaca;
  Completer<void>? tahanSimpan;
  @override
  Future<String?> readKeranjang(String userId) async {
    final value = values[userId];
    dibaca?.complete();
    await tahan?.future;
    return value;
  }

  @override
  Future<void> saveKeranjang(String userId, String value) async {
    if (gagal) throw StateError('storage unavailable');
    await tahanSimpan?.future;
    values[userId] = value;
  }
}

Produk product(
  String id, {
  int stok = 5,
  String toko = 't1',
  int harga = 10000,
}) => Produk(
  id: id,
  tokoId: toko,
  nama: id,
  harga: harga,
  stok: stok,
  satuan: 'pcs',
  kategori: 'Beras',
  isTersedia: true,
);

void main() {
  test('qty merges, subtotal uses selected items and zero removes', () async {
    final storage = CartStorage();
    final cart = KeranjangNotifier(storage, 'u1');
    await cart.siap;
    expect(await cart.tambahItem(product('p1'), qty: 2), isTrue);
    expect(await cart.tambahItem(product('p1')), isTrue);
    await cart.tambahItem(product('p2', harga: 5000), qty: 2);
    expect(cart.state.totalItem, 5);
    expect(cart.hitungSubtotal(), 40000);
    await cart.pilihItem('p1', false);
    expect(cart.state.subtotal, 10000);
    expect(cart.state.jumlahDipilih, 2);
    await cart.pilihSemua(true);
    await cart.ubahQty('p1', 1);
    await cart.kurangItem('p1');
    expect(cart.state.items.single.produk.id, 'p2');
    await cart.hapusDipilih();
    expect(cart.state.items, isEmpty);
    expect(cart.state.subtotal, 0);
    cart.dispose();
  });

  test(
    'stock limits and changing store require explicit replacement',
    () async {
      final cart = KeranjangNotifier(CartStorage(), 'u1');
      await cart.siap;
      expect(await cart.tambahItem(product('empty', stok: 0)), isFalse);
      expect(await cart.tambahItem(product('p1'), qty: 6), isFalse);
      expect(await cart.tambahItem(product('p1'), qty: 2), isTrue);
      expect(await cart.ubahQty('p1', -1), isFalse);
      expect(await cart.ubahQty('p1', 6), isFalse);
      expect(await cart.tambahItem(product('p2', toko: 't2')), isFalse);
      expect(cart.state.items.single.produk.id, 'p1');
      expect(
        await cart.tambahItem(product('p2', toko: 't2'), gantiToko: true),
        isTrue,
      );
      expect(cart.state.tokoId, 't2');
      expect(cart.state.items.length, 1);
      await cart.hapusItem('p2');
      expect(cart.state.totalItem, 0);
      cart.dispose();
    },
  );

  test(
    'cart persists selections across restart and accounts stay separate',
    () async {
      final storage = CartStorage();
      final first = KeranjangNotifier(storage, 'u1');
      await first.tambahItem(product('p1'), qty: 3);
      await first.pilihSemua(false);
      first.dispose();
      final restored = KeranjangNotifier(storage, 'u1');
      final other = KeranjangNotifier(storage, 'u2');
      await Future.wait([restored.siap, other.siap]);
      expect(restored.state.totalItem, 3);
      expect(restored.state.subtotal, 0);
      expect(other.state.items, isEmpty);
      await restored.pilihSemua(true);
      expect(restored.state.subtotal, 30000);
      await restored.kosongkan();
      expect((jsonDecode(storage.values['u1']!) as Map)['items'], isEmpty);
      restored.dispose();
      other.dispose();
    },
  );

  test(
    'mutations await restore and serialized writes do not lose increments',
    () async {
      final storage = CartStorage()..tahan = Completer<void>();
      final cart = KeranjangNotifier(storage, 'u1');
      final first = cart.tambahItem(product('p1'));
      final second = cart.tambahItem(product('p1'));
      expect(cart.state.memuat, isTrue);
      storage.tahan!.complete();
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(cart.state.totalItem, 2);
      final restored = KeranjangNotifier(storage, 'u1');
      await restored.siap;
      expect(restored.state.totalItem, 2);
      cart.dispose();
      restored.dispose();
    },
  );

  test(
    'reload serializes with mutations and cannot restore a stale quantity',
    () async {
      final storage = CartStorage();
      final cart = KeranjangNotifier(storage, 'u1');
      await cart.tambahItem(product('p1'));
      storage.tahan = Completer<void>();
      storage.dibaca = Completer<void>();
      final reload = cart.muatUlang();
      await storage.dibaca!.future;
      final addition = cart.tambahItem(product('p1'));
      await Future<void>.delayed(Duration.zero);
      storage.tahan!.complete();
      await reload;
      expect(await addition, isTrue);
      expect(cart.state.totalItem, 2);
      expect(
        (jsonDecode(storage.values['u1']!)['items'] as List).single['qty'],
        2,
      );
      cart.dispose();
    },
  );

  test(
    'queued increments use latest qty and keep selection when saving is slow',
    () async {
      final storage = CartStorage();
      final cart = KeranjangNotifier(storage, 'u1');
      await cart.tambahItem(product('p1', stok: 3));
      await cart.pilihSemua(false);
      storage.tahanSimpan = Completer<void>();
      final first = cart.tambahQty('p1');
      await Future<void>.delayed(Duration.zero);
      final second = cart.tambahQty('p1');
      storage.tahanSimpan!.complete();
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(cart.state.totalItem, 3);
      expect(cart.state.subtotal, 0);
      expect(await cart.tambahQty('p1'), isFalse);
      expect(cart.state.totalItem, 3);
      cart.dispose();
    },
  );

  test('write failures roll back visibly and retry recovers', () async {
    final storage = CartStorage();
    final cart = KeranjangNotifier(storage, 'u1');
    await cart.tambahItem(product('p1'));
    storage.gagal = true;
    expect(await cart.ubahQty('p1', 3), isFalse);
    expect(cart.state.totalItem, 1);
    expect(cart.state.pesan, isNotNull);
    storage.gagal = false;
    expect(await cart.ubahQty('p1', 3), isTrue);
    expect(cart.state.pesan, isNull);
    expect(cart.state.totalItem, 3);
    cart.dispose();
  });

  test(
    'corrupt stored cart is reported and never silently overwritten',
    () async {
      final storage = CartStorage()..values['u1'] = '{broken';
      final cart = KeranjangNotifier(storage, 'u1');
      await cart.siap;
      expect(cart.state.pesan, isNotNull);
      expect(await cart.tambahItem(product('p1')), isFalse);
      expect(storage.values['u1'], '{broken');
      expect(await cart.kosongkan(), isTrue);
      expect(await cart.tambahItem(product('p1')), isTrue);
      cart.dispose();
    },
  );
}
