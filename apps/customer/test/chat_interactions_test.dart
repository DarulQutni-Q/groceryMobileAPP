import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/core/theme.dart';
import 'package:gardenmart_customer/features/catalog/presentation/chat_driver_page.dart';
import 'package:gardenmart_customer/features/checkout/presentation/struk_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'golden_test.dart' show loadTestFonts;
import 'pesanan_fixture.dart';

void main() {
  setUpAll(loadTestFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget wrap(Widget child) => MaterialApp(
    theme: customerTheme(),
    debugShowCheckedModeBanner: false,
    home: child,
  );

  testWidgets('header generik + kartu pesanan asli, bukan data referensi', (
    tester,
  ) async {
    final order = pesananFixture().first; // GM-1001, diantar, Rp 67.600
    await tester.pumpWidget(wrap(ChatDriverPage(order: order)));
    await tester.pump();

    expect(find.text('Kurir Toko'), findsOneWidget);
    expect(find.text('Sedang mengantar pesananmu'), findsOneWidget);
    expect(find.text('Pesanan #GM-1001'), findsOneWidget);
    expect(
      find.text('Pesanan dalam perjalanan • Rp 67.600'),
      findsOneWidget,
    );
    // Data referensi Figma tidak boleh muncul sebagai data.
    expect(find.textContaining('Pak Budi'), findsNothing);
    expect(find.textContaining('BK 4122'), findsNothing);
    expect(find.textContaining('GM-8921'), findsNothing);
    // Pesan sistem hanya untuk pesanan yang sedang diantar.
    expect(
      find.text('Pesanan telah diserahkan ke Kurir Toko'),
      findsOneWidget,
    );
    expect(find.text('Hari Ini'), findsOneWidget);
  });

  testWidgets('pesan sistem tidak tampil kalau pesanan belum diantar', (
    tester,
  ) async {
    final order = pesananFixture()[1]; // GM-0998, selesai
    await tester.pumpWidget(wrap(ChatDriverPage(order: order)));
    await tester.pump();

    expect(find.text('Pesanan #GM-0998'), findsOneWidget);
    expect(
      find.text('Pesanan telah diserahkan ke Kurir Toko'),
      findsNothing,
    );
  });

  testWidgets('tanpa pesanan: kartu disembunyikan, chat tetap jalan', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const ChatDriverPage()));
    await tester.pump();

    expect(find.text('Kurir Toko'), findsOneWidget);
    expect(find.text('Kurir GardenMart'), findsOneWidget);
    expect(find.textContaining('Pesanan #'), findsNothing);
    expect(find.textContaining('Belum ada pesan'), findsOneWidget);
  });

  testWidgets('tombol kembali kembali ke layar sebelumnya', (tester) async {
    final order = pesananFixture().first;
    await tester.pumpWidget(
      MaterialApp(
        theme: customerTheme(),
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ChatDriverPage(order: order),
                  ),
                ),
                child: const Text('Buka Chat'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Kurir Toko'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Buka Chat'), findsOneWidget);
    expect(find.text('Kurir Toko'), findsNothing);
  });

  testWidgets('ikon telepon menampilkan dialog jujur tanpa nomor', (
    tester,
  ) async {
    final order = pesananFixture().first;
    await tester.pumpWidget(wrap(ChatDriverPage(order: order)));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.phone));
    await tester.pumpAndSettle();
    expect(find.text('Telepon Kurir'), findsOneWidget);
    expect(
      find.textContaining('Nomor telepon kurir belum tersedia'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('Telepon Kurir'), findsNothing);
  });

  testWidgets('Lihat Detail membuka struk pesanan yang sama', (
    tester,
  ) async {
    final order = pesananFixture().first;
    await tester.pumpWidget(wrap(ChatDriverPage(order: order)));
    await tester.pump();

    await tester.tap(find.text('Lihat Detail ›'));
    await tester.pumpAndSettle();
    expect(find.byType(StrukPage), findsOneWidget);
    expect(find.textContaining('GM-1001'), findsWidgets);
  });

  testWidgets('kirim pesan menambah bubble + centang, field dibersihkan', (
    tester,
  ) async {
    final order = pesananFixture().first;
    await tester.pumpWidget(wrap(ChatDriverPage(order: order)));
    await tester.pump();

    await tester.enterText(
      find.byType(TextField),
      'Tolong titip di teras ya',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(find.text('Tolong titip di teras ya'), findsOneWidget);
    expect(find.byIcon(Icons.done_all), findsOneWidget);
    expect(find.text('Tolong titip di teras ya'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(find.textContaining('Belum ada pesan'), findsNothing);
  });

  testWidgets('kirim kosong diblokir', (tester) async {
    final order = pesananFixture().first;
    await tester.pumpWidget(wrap(ChatDriverPage(order: order)));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(find.textContaining('Belum ada pesan'), findsOneWidget);
  });

  testWidgets('pesan terkirim tersimpan lokal per pesanan', (tester) async {
    final order = pesananFixture().first;
    await tester.pumpWidget(wrap(ChatDriverPage(order: order)));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Sudah sampai mana?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    expect(find.text('Sudah sampai mana?'), findsOneWidget);

    // Buka ulang halaman dengan pesanan yang sama: pesan harus tetap ada.
    await tester.pumpWidget(wrap(ChatDriverPage(order: order)));
    await tester.pumpAndSettle();
    expect(find.text('Sudah sampai mana?'), findsOneWidget);

    // Pesanan lain tidak ikut menampilkan pesan ini.
    final other = pesananFixture()[1];
    await tester.pumpWidget(wrap(ChatDriverPage(order: other)));
    await tester.pumpAndSettle();
    expect(find.text('Sudah sampai mana?'), findsNothing);
  });

  testWidgets('tombol kamera dan lampiran tidak crash tanpa picker', (
    tester,
  ) async {
    final order = pesananFixture().first;
    await tester.pumpWidget(wrap(ChatDriverPage(order: order)));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.camera_alt_outlined));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.attach_file));
    await tester.pump();

    // Di lingkungan tes tidak ada picker asli: tidak ada bubble baru dan
    // halaman tetap tampil (picker gagal ditangani, bukan crash).
    expect(find.text('Kurir Toko'), findsOneWidget);
    expect(find.textContaining('Belum ada pesan'), findsOneWidget);
  });
}
