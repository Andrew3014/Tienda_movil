import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://pakfwasisthdpfbsqvef.supabase.co',
  );
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_JZ7rsQ2p3kfOSR9oUoEMmw_Xj1askQF',
  );

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const BoutiqueApp());
}

class BoutiqueApp extends StatelessWidget {
  const BoutiqueApp({super.key, this.useAuth = true});

  final bool useAuth;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0A0A0A);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mi Tienda Boutique',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ink,
          brightness: Brightness.light,
          primary: ink,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        dividerColor: const Color(0xFFE5E5E5),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE5E5E5)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: const Color(0xFF0A0A0A),
          secondarySelectedColor: const Color(0xFF0A0A0A),
          side: const BorderSide(color: Color(0xFFE5E5E5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          labelStyle: const TextStyle(color: Color(0xFF262626)),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            side: const BorderSide(color: Color(0xFFE5E5E5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: useAuth ? const AuthGate() : const BoutiqueHomePage.demo(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = _supabase.auth.currentSession;

        if (session == null) {
          return const LoginPage();
        }

        return FutureBuilder<TestAccount>(
          future: _loadAccount(session.user),
          builder: (context, accountSnapshot) {
            if (accountSnapshot.connectionState != ConnectionState.done) {
              return const _LoadingPage(message: 'Cargando perfil...');
            }

            if (accountSnapshot.hasError || !accountSnapshot.hasData) {
              return _ProfileErrorPage(
                email: session.user.email ?? 'usuario sin email',
              );
            }

            return BoutiqueHomePage.authenticated(
              account: accountSnapshot.data!,
            );
          },
        );
      },
    );
  }

  Future<TestAccount> _loadAccount(User user) async {
    final profile = await _supabase
        .from('profiles')
        .select('full_name, role')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      throw StateError('El usuario no tiene fila en profiles.');
    }

    final role = AccountRoleParser.fromDatabase(profile['role'] as String?);

    return TestAccount(
      name: (profile['full_name'] as String?) ?? user.email ?? 'Usuario',
      email: user.email ?? 'sin-email',
      role: role,
      description: role.description,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: 'admin@mitienda.bo');
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'No se pudo iniciar sesion.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _Surface(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.storefront,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mi Tienda Boutique',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Ingreso con Supabase Auth',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF737373),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contrasena',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      onSubmitted: (_) => _isLoading ? null : _signIn(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFB91C1C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _signIn,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(_isLoading ? 'Ingresando...' : 'Ingresar'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const BoutiqueHomePage.demo(),
                                ),
                              );
                            },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Continuar en modo demo'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _ProfileErrorPage extends StatelessWidget {
  const _ProfileErrorPage({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _Surface(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.warning_amber, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    'Falta el perfil del usuario',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El usuario $email existe en Auth, pero todavia no tiene una fila en public.profiles con su rol.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Supabase.instance.client.auth.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Volver al login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BoutiqueHomePage extends StatefulWidget {
  const BoutiqueHomePage.authenticated({
    super.key,
    required TestAccount account,
  }) : _initialAccount = account,
       _demoMode = false;

  const BoutiqueHomePage.demo({super.key})
    : _initialAccount = null,
      _demoMode = true;

  final TestAccount? _initialAccount;
  final bool _demoMode;

  @override
  State<BoutiqueHomePage> createState() => _BoutiqueHomePageState();
}

class _BoutiqueHomePageState extends State<BoutiqueHomePage> {
  late TestAccount _activeAccount;

  @override
  void initState() {
    super.initState();
    _activeAccount = widget._initialAccount ?? DemoData.accounts.first;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1060;
    final permissions = _activeAccount.role.permissions;

    final dashboard = [
      _TopBar(
        account: _activeAccount,
        demoMode: widget._demoMode,
        onAccountChanged: (account) => setState(() {
          _activeAccount = account;
        }),
      ),
      const SizedBox(height: 16),
      _RoleSummary(account: _activeAccount),
      const SizedBox(height: 16),
      if (permissions.canViewMetrics) ...[
        _MetricGrid(role: _activeAccount.role),
        const SizedBox(height: 16),
      ],
      if (isWide)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: _CatalogPanel(
                products: DemoData.products,
                canManage: permissions.canManageInventory,
                canSell: permissions.canCreateSales,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _SalePanel(
                    cart: DemoData.cart,
                    canSell: permissions.canCreateSales,
                    canTakeQr: permissions.canTakeQrPayments,
                  ),
                  const SizedBox(height: 16),
                  _AccessPanel(account: _activeAccount),
                ],
              ),
            ),
          ],
        )
      else ...[
        _CatalogPanel(
          products: DemoData.products,
          canManage: permissions.canManageInventory,
          canSell: permissions.canCreateSales,
        ),
        const SizedBox(height: 16),
        _SalePanel(
          cart: DemoData.cart,
          canSell: permissions.canCreateSales,
          canTakeQr: permissions.canTakeQrPayments,
        ),
        const SizedBox(height: 16),
        _AccessPanel(account: _activeAccount),
      ],
      const SizedBox(height: 16),
      _OperationsGrid(account: _activeAccount),
      const SizedBox(height: 16),
      const _SupabaseNextSteps(),
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
              sliver: SliverList(delegate: SliverChildListDelegate(dashboard)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.account,
    required this.demoMode,
    required this.onAccountChanged,
  });

  final TestAccount account;
  final bool demoMode;
  final ValueChanged<TestAccount> onAccountChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _Surface(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.storefront, color: Colors.white),
          ),
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi Tienda Boutique',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  'Panel operativo para catalogo, ventas, caja y QR.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
          if (demoMode)
            SizedBox(
              width: 310,
              child: DropdownButtonFormField<TestAccount>(
                initialValue: account,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Cuenta de prueba',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  isDense: true,
                ),
                items: [
                  for (final item in DemoData.accounts)
                    DropdownMenuItem(
                      value: item,
                      child: Text('${item.name} - ${item.role.label}'),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) onAccountChanged(value);
                },
              ),
            )
          else
            _SessionLabel(email: account.email),
          _RoleBadge(role: account.role),
          FilledButton.icon(
            onPressed: account.role.permissions.canTakeQrPayments
                ? () {}
                : null,
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Cobrar QR'),
          ),
          if (!demoMode)
            OutlinedButton.icon(
              onPressed: () => Supabase.instance.client.auth.signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Salir'),
            ),
        ],
      ),
    );
  }
}

class _SessionLabel extends StatelessWidget {
  const _SessionLabel({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSummary extends StatelessWidget {
  const _RoleSummary({required this.account});

  final TestAccount account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _Surface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFF5F5F5),
            foregroundColor: const Color(0xFF0A0A0A),
            child: Icon(account.role.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.email,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  account.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF525252),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.role});

  final AccountRole role;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      const Metric('Caja abierta', 'Bs 1.245', Icons.point_of_sale),
      const Metric('Ventas hoy', '18', Icons.receipt_long),
      const Metric('Stock bajo', '7 variantes', Icons.inventory_2),
      Metric(
        role == AccountRole.customer ? 'Mis pedidos' : 'Pagos QR',
        role == AccountRole.customer ? '3 activos' : '6 pagos',
        role == AccountRole.customer ? Icons.shopping_bag : Icons.qr_code,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 520
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 104,
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

    return _Surface(
      child: Row(
        children: [
          _IconBox(icon: metric.icon),
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
                    color: const Color(0xFF737373),
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
    );
  }
}

class _CatalogPanel extends StatelessWidget {
  const _CatalogPanel({
    required this.products,
    required this.canManage,
    required this.canSell,
  });

  final List<Product> products;
  final bool canManage;
  final bool canSell;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Catalogo e inventario',
      subtitle: 'Prendas, marcas, modelos, colores, tallas y stock.',
      action: OutlinedButton.icon(
        onPressed: canManage ? () {} : null,
        icon: const Icon(Icons.add),
        label: const Text('Prenda'),
      ),
      child: Column(
        children: [
          const _FilterBar(),
          const SizedBox(height: 14),
          for (final product in products) ...[
            _ProductTile(
              product: product,
              canManage: canManage,
              canSell: canSell,
            ),
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
  const _ProductTile({
    required this.product,
    required this.canManage,
    required this.canSell,
  });

  final Product product;
  final bool canManage;
  final bool canSell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Center(
              child: Text(
                product.category.characters.first,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF171717),
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
                    color: const Color(0xFF737373),
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
              Wrap(
                spacing: 6,
                children: [
                  IconButton.outlined(
                    onPressed: canManage ? () {} : null,
                    tooltip: 'Editar stock',
                    icon: const Icon(Icons.tune, size: 18),
                  ),
                  IconButton.filled(
                    onPressed: canSell ? () {} : null,
                    tooltip: 'Agregar a venta',
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                  ),
                ],
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
        color: isLow ? const Color(0xFFFFF7ED) : const Color(0xFFFAFAFA),
        border: Border.all(
          color: isLow ? const Color(0xFFFED7AA) : const Color(0xFFE5E5E5),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${variant.size}: ${variant.stock}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isLow ? const Color(0xFF9A3412) : const Color(0xFF262626),
        ),
      ),
    );
  }
}

class _SalePanel extends StatelessWidget {
  const _SalePanel({
    required this.cart,
    required this.canSell,
    required this.canTakeQr,
  });

  final List<SaleLine> cart;
  final bool canSell;
  final bool canTakeQr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = cart.fold<double>(0, (sum, item) => sum + item.total);

    return _Panel(
      title: 'Venta rapida',
      subtitle: canSell
          ? 'Carrito, descuento, pago QR y cierre de venta.'
          : 'Sin permiso para crear ventas con esta cuenta.',
      action: IconButton.outlined(
        onPressed: canSell ? () {} : null,
        tooltip: 'Nueva venta',
        icon: const Icon(Icons.restart_alt),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in cart)
            ListTile(
              enabled: canSell,
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
          _QrCallout(enabled: canTakeQr),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: canSell ? () {} : null,
            icon: const Icon(Icons.payments),
            label: const Text('Confirmar venta'),
          ),
        ],
      ),
    );
  }
}

class _QrCallout extends StatelessWidget {
  const _QrCallout({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFFAFAFA) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.qr_code_2,
            size: 42,
            color: enabled ? const Color(0xFF0A0A0A) : const Color(0xFFA3A3A3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              enabled
                  ? 'Permiso activo para generar QR y registrar pago en caja.'
                  : 'QR bloqueado para esta cuenta de prueba.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF404040),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessPanel extends StatelessWidget {
  const _AccessPanel({required this.account});

  final TestAccount account;

  @override
  Widget build(BuildContext context) {
    final permissions = account.role.permissions;
    final items = [
      AccessItem('Catalogo', permissions.canViewCatalog),
      AccessItem('Inventario', permissions.canManageInventory),
      AccessItem('Ventas', permissions.canCreateSales),
      AccessItem('Pago QR', permissions.canTakeQrPayments),
      AccessItem('Caja', permissions.canManageCash),
      AccessItem('Reportes', permissions.canViewReports),
      AccessItem('Usuarios', permissions.canManageUsers),
    ];

    return _Panel(
      title: 'Matriz de acceso',
      subtitle: 'Permisos aplicados a la cuenta activa.',
      child: Column(
        children: [
          for (final item in items)
            _PermissionRow(label: item.label, enabled: item.enabled),
        ],
      ),
    );
  }
}

class _OperationsGrid extends StatelessWidget {
  const _OperationsGrid({required this.account});

  final TestAccount account;

  @override
  Widget build(BuildContext context) {
    final permissions = account.role.permissions;
    final operations = [
      Operation(
        'Productos',
        'Crear prendas, marcas, modelos y variantes.',
        Icons.inventory_2,
        permissions.canManageInventory,
      ),
      Operation(
        'Ventas',
        'Registrar carrito, descuento y comprobante.',
        Icons.receipt_long,
        permissions.canCreateSales,
      ),
      Operation(
        'Caja',
        'Abrir, mover y cerrar caja diaria.',
        Icons.point_of_sale,
        permissions.canManageCash,
      ),
      Operation(
        'Clientes',
        'Consultar historial propio o gestionar clientes.',
        Icons.people_alt,
        permissions.canManageUsers || account.role == AccountRole.customer,
      ),
      Operation(
        'Reportes',
        'Ventas, margen, rotacion y stock bajo.',
        Icons.bar_chart,
        permissions.canViewReports,
      ),
      Operation(
        'Configuracion',
        'Roles, usuarios, sucursales y parametros.',
        Icons.settings,
        permissions.canManageSettings,
      ),
    ];

    return _Panel(
      title: 'Funcionalidad por rol',
      subtitle: 'Los modulos se habilitan segun el nivel de cuenta.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 900 ? 3 : 1;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: operations.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 118,
            ),
            itemBuilder: (context, index) {
              return _OperationCard(operation: operations[index]);
            },
          );
        },
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({required this.operation});

  final Operation operation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: operation.enabled ? Colors.white : const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBox(icon: operation.icon, enabled: operation.enabled),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        operation.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: operation.enabled
                              ? const Color(0xFF171717)
                              : const Color(0xFFA3A3A3),
                        ),
                      ),
                    ),
                    Icon(
                      operation.enabled ? Icons.lock_open : Icons.lock_outline,
                      size: 16,
                      color: operation.enabled
                          ? const Color(0xFF171717)
                          : const Color(0xFFA3A3A3),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  operation.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupabaseNextSteps extends StatelessWidget {
  const _SupabaseNextSteps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Crear proyecto Supabase y guardar URL/anon key.',
      'Ejecutar docs/supabase_schema.sql en SQL Editor.',
      'Crear usuarios de prueba en Auth y asignar profiles.role.',
      'Conectar Flutter con supabase_flutter y variables de entorno.',
    ];

    return _Panel(
      title: 'Preparacion Supabase',
      subtitle: 'Checklist para pasar de demo local a login real.',
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

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.remove_circle_outline,
            size: 18,
            color: enabled ? const Color(0xFF171717) : const Color(0xFFA3A3A3),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(
            enabled ? 'Activo' : 'Bloqueado',
            style: TextStyle(
              color: enabled
                  ? const Color(0xFF171717)
                  : const Color(0xFFA3A3A3),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF737373),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, this.enabled = true});

  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF5F5F5) : const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: enabled ? const Color(0xFF171717) : const Color(0xFFA3A3A3),
        size: 20,
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final AccountRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(role.icon, size: 16),
          const SizedBox(width: 6),
          Text(role.label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class DemoData {
  const DemoData._();

  static const accounts = [
    TestAccount(
      name: 'Admin General',
      email: 'admin@mitienda.bo',
      role: AccountRole.admin,
      description:
          'Acceso total: usuarios, inventario, ventas, caja, reportes y configuracion.',
    ),
    TestAccount(
      name: 'Gerente Boutique',
      email: 'gerente@mitienda.bo',
      role: AccountRole.manager,
      description:
          'Gestiona ventas, inventario, caja y reportes, sin administrar roles criticos.',
    ),
    TestAccount(
      name: 'Vendedora Caja',
      email: 'ventas@mitienda.bo',
      role: AccountRole.seller,
      description:
          'Opera ventas rapidas, cobros QR y consulta catalogo disponible.',
    ),
    TestAccount(
      name: 'Encargado Stock',
      email: 'stock@mitienda.bo',
      role: AccountRole.inventory,
      description:
          'Actualiza prendas, variantes, tallas, colores y niveles de stock.',
    ),
    TestAccount(
      name: 'Cliente Demo',
      email: 'cliente@mitienda.bo',
      role: AccountRole.customer,
      description:
          'Visualiza catalogo y sus propios pedidos, sin acceso operativo interno.',
    ),
  ];

  static final products = [
    Product(
      name: 'Blazer lino premium',
      brand: 'Casa Mora',
      model: 'Roma',
      category: 'Blazers',
      price: 325,
      colorName: 'Azul petroleo',
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
      colorName: 'Grafito',
      variants: const [
        ProductVariant(size: '36', stock: 5),
        ProductVariant(size: '38', stock: 8),
        ProductVariant(size: '40', stock: 3),
      ],
    ),
    Product(
      name: 'Camisa seda fria',
      brand: 'Atelier Sol',
      model: 'Brisa',
      category: 'Camisas',
      price: 185,
      colorName: 'Mostaza',
      variants: const [
        ProductVariant(size: 'S', stock: 6),
        ProductVariant(size: 'M', stock: 2),
        ProductVariant(size: 'L', stock: 1),
      ],
    ),
  ];

  static const cart = [
    SaleLine(
      product: 'Blazer lino premium',
      size: 'M',
      quantity: 1,
      total: 325,
    ),
    SaleLine(product: 'Vestido satinado', size: 'S', quantity: 1, total: 280),
  ];
}

enum AccountRole { admin, manager, seller, inventory, customer }

extension AccountRoleInfo on AccountRole {
  String get label {
    return switch (this) {
      AccountRole.admin => 'Administrador',
      AccountRole.manager => 'Gerente',
      AccountRole.seller => 'Vendedor/Cajero',
      AccountRole.inventory => 'Inventario',
      AccountRole.customer => 'Cliente',
    };
  }

  IconData get icon {
    return switch (this) {
      AccountRole.admin => Icons.admin_panel_settings,
      AccountRole.manager => Icons.manage_accounts,
      AccountRole.seller => Icons.point_of_sale,
      AccountRole.inventory => Icons.inventory,
      AccountRole.customer => Icons.person,
    };
  }

  String get description {
    return switch (this) {
      AccountRole.admin =>
        'Acceso total: usuarios, inventario, ventas, caja, reportes y configuracion.',
      AccountRole.manager =>
        'Gestiona ventas, inventario, caja y reportes, sin administrar roles criticos.',
      AccountRole.seller =>
        'Opera ventas rapidas, cobros QR y consulta catalogo disponible.',
      AccountRole.inventory =>
        'Actualiza prendas, variantes, tallas, colores y niveles de stock.',
      AccountRole.customer =>
        'Visualiza catalogo y sus propios pedidos, sin acceso operativo interno.',
    };
  }

  RolePermissions get permissions {
    return switch (this) {
      AccountRole.admin => const RolePermissions(
        canManageUsers: true,
        canManageInventory: true,
        canCreateSales: true,
        canTakeQrPayments: true,
        canManageCash: true,
        canViewReports: true,
        canManageSettings: true,
      ),
      AccountRole.manager => const RolePermissions(
        canManageInventory: true,
        canCreateSales: true,
        canTakeQrPayments: true,
        canManageCash: true,
        canViewReports: true,
      ),
      AccountRole.seller => const RolePermissions(
        canCreateSales: true,
        canTakeQrPayments: true,
        canManageCash: true,
      ),
      AccountRole.inventory => const RolePermissions(
        canManageInventory: true,
        canViewReports: true,
      ),
      AccountRole.customer => const RolePermissions(),
    };
  }
}

class AccountRoleParser {
  const AccountRoleParser._();

  static AccountRole fromDatabase(String? value) {
    return switch (value) {
      'admin' => AccountRole.admin,
      'manager' => AccountRole.manager,
      'seller' => AccountRole.seller,
      'inventory' => AccountRole.inventory,
      'customer' => AccountRole.customer,
      _ => AccountRole.customer,
    };
  }
}

class RolePermissions {
  const RolePermissions({
    this.canViewCatalog = true,
    this.canViewMetrics = true,
    this.canManageUsers = false,
    this.canManageInventory = false,
    this.canCreateSales = false,
    this.canTakeQrPayments = false,
    this.canManageCash = false,
    this.canViewReports = false,
    this.canManageSettings = false,
  });

  final bool canViewCatalog;
  final bool canViewMetrics;
  final bool canManageUsers;
  final bool canManageInventory;
  final bool canCreateSales;
  final bool canTakeQrPayments;
  final bool canManageCash;
  final bool canViewReports;
  final bool canManageSettings;
}

class TestAccount {
  const TestAccount({
    required this.name,
    required this.email,
    required this.role,
    required this.description,
  });

  final String name;
  final String email;
  final AccountRole role;
  final String description;
}

class Product {
  const Product({
    required this.name,
    required this.brand,
    required this.model,
    required this.category,
    required this.price,
    required this.colorName,
    required this.variants,
  });

  final String name;
  final String brand;
  final String model;
  final String category;
  final double price;
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
  const Metric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class Operation {
  const Operation(this.title, this.description, this.icon, this.enabled);

  final String title;
  final String description;
  final IconData icon;
  final bool enabled;
}

class AccessItem {
  const AccessItem(this.label, this.enabled);

  final String label;
  final bool enabled;
}
