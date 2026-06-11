import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitienda/main.dart';

void main() {
  testWidgets('loads boutique dashboard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BoutiqueApp());

    expect(find.text('Mi Tienda Boutique'), findsOneWidget);
    expect(find.text('Catálogo e inventario'), findsOneWidget);
    expect(find.text('Venta rápida'), findsOneWidget);
    expect(find.text('Cobrar QR'), findsOneWidget);
  });
}
