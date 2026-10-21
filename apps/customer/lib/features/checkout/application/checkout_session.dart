import 'dart:convert';
import 'dart:math';

import 'package:grocery_shared/shared.dart';

class CheckoutSession {
  CheckoutSession(this.key, this.body, this.items, this.costs, this.alamat);
  final String key;
  final Map<String, dynamic> body;
  final List<KeranjangItem> items;
  final Map<String, dynamic> costs;
  final Alamat alamat;

  static Future<CheckoutSession?> restore(
    SecureStorage storage,
    String userId,
  ) async {
    final value = await storage.readCheckout(userId);
    if (value == null) return null;
    final json = jsonDecode(value) as Map<String, dynamic>;
    return CheckoutSession(
      json['key'] as String,
      json['body'] as Map<String, dynamic>,
      (json['items'] as List)
          .map((i) => KeranjangItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      json['costs'] as Map<String, dynamic>,
      Alamat.fromJson(json['alamat'] as Map<String, dynamic>),
    );
  }

  static Future<CheckoutSession> create(
    SecureStorage storage,
    String userId,
    Map<String, dynamic> body,
    List<KeranjangItem> items,
    Map<String, dynamic> costs,
    Alamat alamat,
  ) async {
    final random = Random.secure();
    final nonce = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final key = '${DateTime.now().millisecondsSinceEpoch}-$nonce';
    final session = CheckoutSession(
      key,
      Map.unmodifiable(body),
      List.unmodifiable(items),
      Map.unmodifiable(costs),
      alamat,
    );
    await storage.saveCheckout(
      userId,
      jsonEncode({
        'key': key,
        'body': body,
        'items': items.map((i) => i.toJson()).toList(),
        'costs': costs,
        'alamat': alamat.toJson(),
      }),
    );
    return session;
  }
}
