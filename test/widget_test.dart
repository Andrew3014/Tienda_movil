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

  testWidgets('customer sees shopping experience instead of point of sale', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BoutiqueApp(useAuth: false));

    await tester.tap(find.text('Admin General - Administrador'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cliente Demo - Cliente').last);
    await tester.pumpAndSettle();

    expect(find.text('Mi carrito'), findsWidgets);
    expect(find.text('Mis pedidos'), findsWidgets);
    expect(find.text('Venta rapida'), findsNothing);
    expect(find.text('cliente@mitienda.bo'), findsOneWidget);
  });

  test('database roles map to the three supported account roles', () {
    expect(AccountRoleParser.fromDatabase('admin'), AccountRole.admin);
    expect(AccountRoleParser.fromDatabase('seller'), AccountRole.seller);
    expect(AccountRoleParser.fromDatabase('customer'), AccountRole.customer);
  });

  test('product maps Supabase catalog data with image and variants', () {
    final product = Product.fromMap({
      'id': 'product-1',
      'name': 'Vestido demo',
      'brand': 'Marca',
      'model': 'Modelo',
      'base_price': 250,
      'image_url': 'https://example.com/vestido.png',
      'categories': {'name': 'Vestidos'},
      'product_variants': [
        {
          'id': 'variant-1',
          'size': 'M',
          'color_name': 'Negro',
          'stock': 4,
          'min_stock': 2,
        },
      ],
    });

    expect(product.category, 'Vestidos');
    expect(product.imageUrl, 'https://example.com/vestido.png');
    expect(product.variants.single.colorName, 'Negro');
    expect(product.variants.single.stock, 4);
  });
}
