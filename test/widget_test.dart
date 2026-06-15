import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitienda/main.dart';

void main() {
  testWidgets('loads boutique dashboard with role access', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BoutiqueApp(useAuth: false));

    expect(find.text('Mi Tienda Boutique'), findsOneWidget);
    expect(find.text('Cuenta de prueba'), findsOneWidget);
    expect(find.text('Catalogo e inventario'), findsOneWidget);
    expect(find.text('Venta rapida'), findsOneWidget);
    expect(find.text('Matriz de acceso'), findsOneWidget);
    expect(find.text('admin@mitienda.bo'), findsOneWidget);
  });
}
