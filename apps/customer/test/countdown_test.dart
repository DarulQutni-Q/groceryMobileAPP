import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardenmart_customer/features/catalog/presentation/catalog_widgets.dart';

void main() {
  testWidgets('countdown ticks toward local 23:59 and stops at zero', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 21, 23, 58, 57);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SaleCountdown(now: () => now)),
      ),
    );
    expect(find.text('BERAKHIR: 00:00:03'), findsOneWidget);
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('BERAKHIR: 00:00:02'), findsOneWidget);
    now = now.add(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('BERAKHIR: 00:00:00'), findsOneWidget);
    now = DateTime(2026, 10, 22);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('BERAKHIR: 23:59:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
