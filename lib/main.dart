import 'package:flutter/material.dart';

void main() {
  runApp(const BoutiqueApp());
}

class BoutiqueApp extends StatelessWidget {
  const BoutiqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF006D77);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mi Tienda Boutique',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE3E7EA)),
          ),
        ),
      ),
      home: const BoutiqueHomePage(),
    );
  }
}

class BoutiqueHomePage extends StatelessWidget {
  const BoutiqueHomePage({super.key});

  static final List<Product> products = [
    Product(
      name: 'Blazer lino premium',
      brand: 'Casa Mora',
      model: 'Roma',
      category: 'Blazers',
      price: 325,
      color: const Color(0xFF2F4858),
      colorName: 'Azul petróleo',
      variants: const [
        ProductVariant(size: 'S', stock: 3),
        ProductVariant(size: 'M', stock: 7),
        ProductVariant(size: 'L', stock: 2),
      ],
    ),
    Product(
      name: 'Vestido satinado',
      brand: 'Luna Alta',
      model: 'Nerea',
      category: 'Vestidos',
      price: 280,
      color: const Color(0xFFB56576),
      colorName: 'Rosa vino',
      variants: const [
        ProductVariant(size: 'XS', stock: 1),
        ProductVariant(size: 'S', stock: 4),
        ProductVariant(size: 'M', stock: 5),
      ],
    ),
    Product(
      name: 'Jean tiro alto',
      brand: 'Denim Sur',
      model: 'Andes',
      category: 'Jeans',
      price: 210,
      color: const Color(0xFF4A5568),
      colorName: 'Grafito',
      variants: const [
        ProductVariant(size: '36', stock: 5),
        ProductVariant(size: '38', stock: 8),
        ProductVariant(size: '40', stock: 3),
      ],
    ),
    Product(
      name: 'Camisa seda fría',
      brand: 'Atelier Sol',
      model: 'Brisa',
      category: 'Camisas',
      price: 185,
      color: const Color(0xFFE0A458),
      colorName: 'Mostaza',
      variants: const [
        ProductVariant(size: 'S', stock: 6),
        ProductVariant(size: 'M', stock: 2),
        ProductVariant(size: 'L', stock: 1),
      ],
    ),
  ];

  static const List<SaleLine> cart = [
    SaleLine(
      product: 'Blazer lino premium',
      size: 'M',
      quantity: 1,
      total: 325,
    ),
    SaleLine(product: 'Vestido satinado', size: 'S', quantity: 1, total: 280),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 980;
    final content = [
      const _Header(),
      const SizedBox(height: 18),
      const _MetricGrid(),
      const SizedBox(height: 18),
      if (isWide)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: _CatalogPanel(products: products)),
            const SizedBox(width: 16),
            const Expanded(flex: 4, child: _SalePanel(cart: cart)),
          ],
        )
      else ...[
        _CatalogPanel(products: products),
        const SizedBox(height: 16),
        const _SalePanel(cart: cart),
      ],
      const SizedBox(height: 18),
      const _RoadmapPanel(),
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 28 : 16,
                vertical: 18,
              ),
              sliver: SliverList(delegate: SliverChildListDelegate(content)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.storefront, color: Colors.white, size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mi Tienda Boutique',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Inventario por talla, color, marca, venta rápida, QR y caja.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5C6670),
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.qr_code_2),
          label: const Text('Cobrar QR'),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid();

  @override
  Widget build(BuildContext context) {
    final metrics = const [
      Metric(
        'Caja abierta',
        'Bs 1.245',
        Icons.point_of_sale,
        Color(0xFF006D77),
      ),
      Metric('Ventas hoy', '18', Icons.receipt_long, Color(0xFF8A5A44)),
      Metric('Stock bajo', '7 variantes', Icons.inventory_2, Color(0xFFC2410C)),
      Metric('Pedidos QR', '6 pagos', Icons.qr_code_scanner, Color(0xFF5B5F97)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900 ? 4 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) => _MetricCard(metric: metrics[index]),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final Metric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: metric.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(metric.icon, color: metric.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF5C6670),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metric.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogPanel extends StatelessWidget {
  const _CatalogPanel({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Catálogo e inventario',
      action: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Prenda'),
      ),
      child: Column(
        children: [
          const _FilterBar(),
          const SizedBox(height: 14),
          for (final product in products) ...[
            _ProductTile(product: product),
            if (product != products.last) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    final filters = const [
      'Todo',
      'Vestidos',
      'Blazers',
      'Jeans',
      'Stock bajo',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in filters)
          ChoiceChip(
            selected: filter == 'Todo',
            label: Text(filter),
            onSelected: (_) {},
          ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: product.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                product.category.characters.first,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.brand} · Modelo ${product.model} · ${product.colorName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5C6670),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final variant in product.variants)
                      _StockPill(variant: variant),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Bs ${product.price.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              IconButton.filledTonal(
                onPressed: () {},
                tooltip: 'Agregar a venta',
                icon: const Icon(Icons.add_shopping_cart),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockPill extends StatelessWidget {
  const _StockPill({required this.variant});

  final ProductVariant variant;

  @override
  Widget build(BuildContext context) {
    final isLow = variant.stock <= 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isLow ? const Color(0xFFFFEDD5) : const Color(0xFFE6F4F1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${variant.size}: ${variant.stock}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isLow ? const Color(0xFF9A3412) : const Color(0xFF006D77),
        ),
      ),
    );
  }
}

class _SalePanel extends StatelessWidget {
  const _SalePanel({required this.cart});

  final List<SaleLine> cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = cart.fold<double>(0, (sum, item) => sum + item.total);

    return _Panel(
      title: 'Venta rápida',
      action: IconButton.filledTonal(
        onPressed: () {},
        tooltip: 'Nueva venta',
        icon: const Icon(Icons.restart_alt),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in cart)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.product),
              subtitle: Text('Talla ${item.size} · ${item.quantity} unidad'),
              trailing: Text(
                'Bs ${item.total.toStringAsFixed(0)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const Divider(height: 24),
          _TotalRow(label: 'Subtotal', value: subtotal),
          const _TotalRow(label: 'Descuento', value: 0),
          _TotalRow(label: 'Total', value: subtotal, isStrong: true),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F5F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2, size: 42, color: Color(0xFF006D77)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Listo para generar QR boliviano y registrar pago en caja.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.payments),
            label: const Text('Confirmar venta'),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.isStrong = false,
  });

  final String label;
  final double value;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    final style = isStrong
        ? Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)
        : Theme.of(context).textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('Bs ${value.toStringAsFixed(0)}', style: style),
        ],
      ),
    );
  }
}

class _RoadmapPanel extends StatelessWidget {
  const _RoadmapPanel();

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Supabase Auth para clientes y administradores',
      'Tablas: productos, variantes, ventas, pagos, caja y movimientos',
      'RLS para pedidos propios de cliente y control total de administrador',
      'Web responsive, Android APK/AAB e iOS listo para despliegue',
    ];

    return _Panel(
      title: 'Próxima integración Supabase',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final step in steps)
            Chip(
              avatar: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(step),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class Product {
  const Product({
    required this.name,
    required this.brand,
    required this.model,
    required this.category,
    required this.price,
    required this.color,
    required this.colorName,
    required this.variants,
  });

  final String name;
  final String brand;
  final String model;
  final String category;
  final double price;
  final Color color;
  final String colorName;
  final List<ProductVariant> variants;
}

class ProductVariant {
  const ProductVariant({required this.size, required this.stock});

  final String size;
  final int stock;
}

class SaleLine {
  const SaleLine({
    required this.product,
    required this.size,
    required this.quantity,
    required this.total,
  });

  final String product;
  final String size;
  final int quantity;
  final double total;
}

class Metric {
  const Metric(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}
