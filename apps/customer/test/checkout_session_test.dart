import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/features/checkout/application/checkout_session.dart';
import 'package:grocery_shared/shared.dart';

import 'auth_state_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('checkout restore keeps address note amount and key isolated by account', () async {
    final fixture = AuthFixture()..installStorage();
    final body = {'alamat_id': 'a1', 'catatan': 'Pagar hijau', 'metode_bayar': 'qris'};
    const address = Alamat(id: 'a1', label: 'Rumah', namaPenerima: 'Pembeli',
      noHp: '081234567890', alamatLengkap: 'Alamat sebelum diedit', isUtama: true);
    final session = await CheckoutSession.create(fixture.storage, 'u1', body, [],
      {'subtotal': 10000, 'biaya_layanan': 1000, 'total': 11000}, address);
    body['catatan'] = 'Catatan lain';
    final restored = (await CheckoutSession.restore(fixture.storage, 'u1'))!;
    expect(restored.key, session.key);
    expect(restored.body['catatan'], 'Pagar hijau');
    expect(restored.alamat.alamatLengkap, 'Alamat sebelum diedit');
    expect(restored.costs['total'], 11000);
    expect(await CheckoutSession.restore(fixture.storage, 'u2'), isNull);
    await fixture.storage.clearCheckout('u1');
    expect(await CheckoutSession.restore(fixture.storage, 'u1'), isNull);
  });
}
