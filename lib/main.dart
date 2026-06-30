import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

void _showActionMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _showQrChargeDialog(BuildContext context) async {
  final amountController = TextEditingController();
  final referenceController = TextEditingController();
  String selectedBank = 'BNB (Banco Nacional)';

  final banks = [
    'BNB (Banco Nacional)',
    'Banco Union',
    'Mercantil Santa Cruz',
    'Banco Fassil (Intervenido)',
    'Banco Sol',
    'Banco Ganadero',
    'Banco Economico',
    'BCP (Banco de Credito)',
  ];

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Cobro QR Dinamico'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedBank,
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Banco',
                  border: OutlineInputBorder(),
                ),
                items: banks.map((bank) {
                  return DropdownMenuItem(value: bank, child: Text(bank));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedBank = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monto en Bs',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: referenceController,
                decoration: const InputDecoration(
                  labelText: 'Referencia / Concepto',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2, size: 120),
                    const SizedBox(height: 8),
                    Text(
                      'Generando QR para $selectedBank...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (double.tryParse(amountController.text.trim()) == null) return;
              Navigator.pop(dialogContext);
              _showActionMessage(
                context,
                'Cobro QR ($selectedBank) preparado por ${amountController.text.trim()} Bs.',
              );
            },
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    ),
  );

  amountController.dispose();
  referenceController.dispose();
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
                error: accountSnapshot.error,
                onRetry: () => setState(() {}),
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
  const _ProfileErrorPage({
    required this.email,
    required this.error,
    required this.onRetry,
  });

  final String email;
  final Object? error;
  final VoidCallback onRetry;

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
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF737373),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar perfil'),
                  ),
                  const SizedBox(height: 8),
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
  late ProductRepository _productRepository;
  late OperationalRepository _operationalRepository;
  List<Product> _products = DemoData.products;
  List<SaleLine> _cart = [];
  DashboardSummary _summary = DashboardSummary.demo;
  List<CustomerOrder> _orders = DemoData.orders;
  CashRegisterStatus? _cashRegister;
  bool _catalogLoading = false;
  bool _operationsLoading = false;
  String? _catalogError;

  @override
  void initState() {
    super.initState();
    _activeAccount = widget._initialAccount ?? DemoData.accounts.first;
    if (!widget._demoMode) {
      _productRepository = ProductRepository();
      _operationalRepository = OperationalRepository();
      _loadProducts();
      _loadOperations();
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
    });

    try {
      final products = await _productRepository.fetchProducts();
      if (!mounted) return;
      setState(() => _products = products);
    } catch (error) {
      if (!mounted) return;
      setState(() => _catalogError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _catalogLoading = false);
      }
    }
  }

  Future<void> _loadOperations() async {
    if (widget._demoMode) return;
    setState(() => _operationsLoading = true);

    try {
      final results = await Future.wait([
        _operationalRepository.fetchDashboardSummary(),
        _activeAccount.role == AccountRole.customer
            ? _operationalRepository.fetchMyOrders()
            : Future<List<CustomerOrder>>.value(const []),
        _activeAccount.role.permissions.canManageCash
            ? _operationalRepository.fetchOpenCashRegister()
            : Future<CashRegisterStatus?>.value(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as DashboardSummary;
        _orders = results[1] as List<CustomerOrder>;
        _cashRegister = results[2] as CashRegisterStatus?;
      });
    } catch (error) {
      if (mounted) {
        _showMessage('No se pudo cargar reportes/caja: $error', error: true);
      }
    } finally {
      if (mounted) setState(() => _operationsLoading = false);
    }
  }

  Future<void> _showProductForm([Product? product]) async {
    if (widget._demoMode) {
      _showMessage('Inicia sesion para guardar prendas en Supabase.');
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          ProductFormDialog(product: product, repository: _productRepository),
    );

    if (saved == true) {
      await _loadProducts();
      if (mounted) {
        _showMessage(
          product == null ? 'Prenda creada.' : 'Prenda actualizada.',
        );
      }
    }
  }

  Future<void> _archiveProduct(Product product) async {
    if (widget._demoMode) {
      _showMessage('La desactivacion esta disponible con Supabase.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar prenda'),
        content: Text(
          '${product.name} dejara de mostrarse en el catalogo publico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _productRepository.archiveProduct(product.id);
      await _loadProducts();
      if (mounted) _showMessage('Prenda desactivada.');
    } catch (error) {
      if (mounted) _showMessage('No se pudo desactivar: $error', error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFFB91C1C) : null,
      ),
    );
  }

  void _addProductToCart(Product product) {
    final available = product.variants
        .where((variant) => variant.stock > 0)
        .toList();
    if (available.isEmpty) {
      _showMessage('La prenda no tiene stock disponible.', error: true);
      return;
    }

    final variant = available.first;
    final existingIndex = _cart.indexWhere(
      (item) => item.variantId == variant.id,
    );

    setState(() {
      if (existingIndex == -1) {
        _cart.add(
          SaleLine(
            productId: product.id,
            variantId: variant.id,
            product: product.name,
            size: variant.size,
            colorName: variant.colorName,
            quantity: 1,
            unitPrice: product.price,
            total: product.price,
            imageUrl: product.imageUrl,
          ),
        );
      } else {
        final current = _cart[existingIndex];
        if (current.quantity >= variant.stock) {
          _showMessage(
            'No hay mas stock disponible para esa talla.',
            error: true,
          );
          return;
        }
        _cart[existingIndex] = SaleLine(
          productId: current.productId,
          variantId: current.variantId,
          product: current.product,
          size: current.size,
          colorName: current.colorName,
          quantity: current.quantity + 1,
          unitPrice: current.unitPrice,
          total: current.total + product.price,
          imageUrl: current.imageUrl,
        );
      }
    });

    _showMessage('${product.name} agregado.');
  }

  void _clearCart() {
    setState(() => _cart = []);
    _showMessage('Carrito limpio.');
  }

  Future<void> _confirmStaffSale(PaymentMethod method) async {
    if (_cart.isEmpty) {
      _showMessage('Agrega productos antes de confirmar.', error: true);
      return;
    }
    if (widget._demoMode) {
      _showMessage(
        'Venta demo confirmada. Con Supabase se descuenta stock real.',
      );
      _clearCart();
      return;
    }

    try {
      await _operationalRepository.confirmSale(cart: _cart, method: method);
      _clearCart();
      await Future.wait([_loadProducts(), _loadOperations()]);
      if (mounted) {
        _showMessage('Venta guardada y stock descontado.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('No se pudo confirmar venta: $error', error: true);
      }
    }
  }

  Future<void> _confirmCustomerOrder() async {
    if (_cart.isEmpty) {
      _showMessage('Agrega una prenda antes de continuar.', error: true);
      return;
    }
    if (widget._demoMode) {
      _showMessage(
        'Pedido demo preparado. Con Supabase se guarda en Mis pedidos.',
      );
      return;
    }

    try {
      await _operationalRepository.createCustomerOrder(cart: _cart);
      _clearCart();
      await Future.wait([_loadProducts(), _loadOperations()]);
      if (mounted) {
        _showMessage('Pedido registrado. La tienda lo vera como pendiente.');
      }
    } catch (error) {
      if (mounted) _showMessage('No se pudo crear pedido: $error', error: true);
    }
  }

  Future<void> _openCashRegister() async {
    if (widget._demoMode) {
      _showMessage('Caja demo abierta.');
      return;
    }

    final amount = await _askAmount(
      title: 'Abrir caja',
      label: 'Monto inicial en Bs',
      action: 'Abrir',
    );
    if (amount == null) return;

    try {
      await _operationalRepository.openCashRegister(amount);
      await _loadOperations();
      if (mounted) _showMessage('Caja abierta.');
    } catch (error) {
      if (mounted) _showMessage('No se pudo abrir caja: $error', error: true);
    }
  }

  Future<void> _closeCashRegister() async {
    if (widget._demoMode) {
      _showMessage('Caja demo cerrada.');
      return;
    }

    final amount = await _askAmount(
      title: 'Cerrar caja',
      label: 'Monto contado en Bs',
      action: 'Cerrar',
    );
    if (amount == null) return;

    try {
      await _operationalRepository.closeCashRegister(amount);
      await _loadOperations();
      if (mounted) _showMessage('Caja cerrada.');
    } catch (error) {
      if (mounted) _showMessage('No se pudo cerrar caja: $error', error: true);
    }
  }

  Future<double?> _askAmount({
    required String title,
    required String label,
    required String action,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(controller.text.trim());
              if (amount != null) Navigator.pop(context, amount);
            },
            child: Text(action),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
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
        _MetricGrid(role: _activeAccount.role, summary: _summary, cart: _cart),
        const SizedBox(height: 16),
      ],
      if (_activeAccount.role == AccountRole.customer)
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: _CatalogPanel(
                  products: _products,
                  canManage: false,
                  canSell: false,
                  canShop: true,
                  isLoading: _catalogLoading,
                  error: _catalogError,
                  onRetry: _loadProducts,
                  onAddProduct: null,
                  onEditProduct: null,
                  onArchiveProduct: null,
                  onProductAction: _addProductToCart,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: _CustomerPanel(
                  cart: _cart,
                  orders: _orders,
                  onContinue: _confirmCustomerOrder,
                ),
              ),
            ],
          )
        else ...[
          _CatalogPanel(
            products: _products,
            canManage: false,
            canSell: false,
            canShop: true,
            isLoading: _catalogLoading,
            error: _catalogError,
            onRetry: _loadProducts,
            onAddProduct: null,
            onEditProduct: null,
            onArchiveProduct: null,
            onProductAction: _addProductToCart,
          ),
          const SizedBox(height: 16),
          _CustomerPanel(
            cart: _cart,
            orders: _orders,
            onContinue: _confirmCustomerOrder,
          ),
        ]
      else if (isWide)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: _CatalogPanel(
                products: _products,
                canManage: permissions.canManageInventory,
                canSell: permissions.canCreateSales,
                canShop: false,
                isLoading: _catalogLoading,
                error: _catalogError,
                onRetry: _loadProducts,
                onAddProduct: permissions.canManageInventory
                    ? () => _showProductForm()
                    : null,
                onEditProduct: permissions.canManageInventory
                    ? _showProductForm
                    : null,
                onArchiveProduct: permissions.canManageInventory
                    ? _archiveProduct
                    : null,
                onProductAction: _addProductToCart,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _SalePanel(
                    cart: _cart,
                    canSell: permissions.canCreateSales,
                    canTakeQr: permissions.canTakeQrPayments,
                    onNewSale: _clearCart,
                    onConfirm: _confirmStaffSale,
                  ),
                  const SizedBox(height: 16),
                  if (permissions.canManageCash) ...[
                    _CashPanel(
                      status: _cashRegister,
                      loading: _operationsLoading,
                      onOpen: _openCashRegister,
                      onClose: _closeCashRegister,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _AccessPanel(account: _activeAccount),
                ],
              ),
            ),
          ],
        )
      else ...[
        _CatalogPanel(
          products: _products,
          canManage: permissions.canManageInventory,
          canSell: permissions.canCreateSales,
          canShop: false,
          isLoading: _catalogLoading,
          error: _catalogError,
          onRetry: _loadProducts,
          onAddProduct: permissions.canManageInventory
              ? () => _showProductForm()
              : null,
          onEditProduct: permissions.canManageInventory
              ? _showProductForm
              : null,
          onArchiveProduct: permissions.canManageInventory
              ? _archiveProduct
              : null,
          onProductAction: _addProductToCart,
        ),
        const SizedBox(height: 16),
        _SalePanel(
          cart: _cart,
          canSell: permissions.canCreateSales,
          canTakeQr: permissions.canTakeQrPayments,
          onNewSale: _clearCart,
          onConfirm: _confirmStaffSale,
        ),
        const SizedBox(height: 16),
        if (permissions.canManageCash) ...[
          _CashPanel(
            status: _cashRegister,
            loading: _operationsLoading,
            onOpen: _openCashRegister,
            onClose: _closeCashRegister,
          ),
          const SizedBox(height: 16),
        ],
        _AccessPanel(account: _activeAccount),
      ],
      const SizedBox(height: 16),
      if (permissions.canViewReports) ...[
        _ReportsPanel(summary: _summary, loading: _operationsLoading),
        const SizedBox(height: 16),
      ],
      _OperationsGrid(account: _activeAccount),
      const SizedBox(height: 16),
      const _SupabaseNextSteps(),
    ];

    return Scaffold(
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                _showMessage('Tienes ${_cart.length} producto(s) en tu carrito.');
              },
              backgroundColor: const Color(0xFF0A0A0A),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_bag),
              label: Text('${_cart.length}'),
            )
          : null,
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
                ? () => _showQrChargeDialog(context)
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
  const _MetricGrid({
    required this.role,
    required this.summary,
    required this.cart,
  });

  final AccountRole role;
  final DashboardSummary summary;
  final List<SaleLine> cart;

  @override
  Widget build(BuildContext context) {
    final metrics = role == AccountRole.customer
        ? [
            Metric(
              'Catalogo',
              '${summary.activeProducts} prendas',
              Icons.storefront,
            ),
            Metric(
              'Mi carrito',
              '${cart.length} producto(s)',
              Icons.shopping_bag,
            ),
            Metric(
              'Mis pedidos',
              '${summary.customerOrders} pedidos',
              Icons.receipt_long,
            ),
            Metric(
              'Pendientes',
              '${summary.pendingOrders} pedido(s)',
              Icons.local_shipping_outlined,
            ),
          ]
        : [
            Metric(
              'Caja hoy',
              'Bs ${summary.cashToday.toStringAsFixed(0)}',
              Icons.point_of_sale,
            ),
            Metric('Ventas hoy', '${summary.salesToday}', Icons.receipt_long),
            Metric(
              'Stock bajo',
              '${summary.lowStockVariants} variantes',
              Icons.inventory_2,
            ),
            Metric(
              'Pagos QR',
              '${summary.qrPaymentsToday} pagos',
              Icons.qr_code,
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

class _CatalogPanel extends StatefulWidget {
  const _CatalogPanel({
    required this.products,
    required this.canManage,
    required this.canSell,
    required this.canShop,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onAddProduct,
    required this.onEditProduct,
    required this.onArchiveProduct,
    required this.onProductAction,
  });

  final List<Product> products;
  final bool canManage;
  final bool canSell;
  final bool canShop;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback? onAddProduct;
  final ValueChanged<Product>? onEditProduct;
  final ValueChanged<Product>? onArchiveProduct;
  final ValueChanged<Product> onProductAction;

  @override
  State<_CatalogPanel> createState() => _CatalogPanelState();
}

class _CatalogPanelState extends State<_CatalogPanel> {
  String _selectedFilter = 'Todo';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.products.map((item) => item.category).toSet()
      ..removeWhere((item) => item.isEmpty);
    final filters = ['Todo', ...categories, 'Stock bajo'];
    final visibleProducts = widget.products.where((product) {
      // Filter by search text
      final query = _searchController.text.toLowerCase();
      final matchesSearch = product.name.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query);
      if (!matchesSearch) return false;

      // Filter by chip selection
      if (_selectedFilter == 'Todo') return true;
      if (_selectedFilter == 'Stock bajo') {
        return product.variants.any((variant) => variant.stock <= 2);
      }
      return product.category == _selectedFilter;
    }).toList();

    return _Panel(
      title: widget.canManage ? 'Catalogo e inventario' : 'Catalogo',
      subtitle: widget.canManage
          ? 'Prendas, marcas, modelos, colores, tallas, imagenes y stock.'
          : 'Explora las prendas disponibles.',
      action: widget.onAddProduct == null
          ? null
          : OutlinedButton.icon(
              onPressed: widget.onAddProduct,
              icon: const Icon(Icons.add),
              label: const Text('Prenda'),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o marca...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          _FilterBar(
            filters: filters,
            selected: _selectedFilter,
            onSelected: (filter) => setState(() => _selectedFilter = filter),
          ),
          const SizedBox(height: 14),
          if (widget.isLoading)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (widget.error != null)
            _CatalogError(error: widget.error!, onRetry: widget.onRetry)
          else if (visibleProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('No hay prendas para mostrar.')),
            )
          else
            for (final product in visibleProducts) ...[
              _ProductTile(
                product: product,
                canManage: widget.canManage,
                canSell: widget.canSell,
                canShop: widget.canShop,
                onEdit: widget.onEditProduct,
                onArchive: widget.onArchiveProduct,
                onAction: widget.onProductAction,
              ),
              if (product != visibleProducts.last) const Divider(height: 18),
            ],
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in filters)
          ChoiceChip(
            selected: filter == selected,
            label: Text(filter),
            onSelected: (_) => onSelected(filter),
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
    required this.canShop,
    required this.onEdit,
    required this.onArchive,
    required this.onAction,
  });

  final Product product;
  final bool canManage;
  final bool canSell;
  final bool canShop;
  final ValueChanged<Product>? onEdit;
  final ValueChanged<Product>? onArchive;
  final ValueChanged<Product> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductImage(product: product),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Bs ${product.price.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.brand} · ${product.model} · ${product.colorName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF737373),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final variant in product.variants)
                      _StockPill(variant: variant),
                  ],
                ),
                if (isMobile) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bs ${product.price.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      _ProductActions(
                        product: product,
                        canManage: canManage,
                        canSell: canSell,
                        canShop: canShop,
                        onEdit: onEdit,
                        onArchive: onArchive,
                        onAction: onAction,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 12),
            _ProductActions(
              product: product,
              canManage: canManage,
              canSell: canSell,
              canShop: canShop,
              onEdit: onEdit,
              onArchive: onArchive,
              onAction: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductActions extends StatelessWidget {
  const _ProductActions({
    required this.product,
    required this.canManage,
    required this.canSell,
    required this.canShop,
    required this.onEdit,
    required this.onArchive,
    required this.onAction,
  });

  final Product product;
  final bool canManage;
  final bool canSell;
  final bool canShop;
  final ValueChanged<Product>? onEdit;
  final ValueChanged<Product>? onArchive;
  final ValueChanged<Product> onAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        IconButton.outlined(
          visualDensity: VisualDensity.compact,
          onPressed: canManage && onEdit != null ? () => onEdit!(product) : null,
          tooltip: 'Editar prenda y stock',
          icon: const Icon(Icons.edit_outlined, size: 18),
        ),
        IconButton.filled(
          visualDensity: VisualDensity.compact,
          onPressed: canSell || canShop ? () => onAction(product) : null,
          tooltip: canShop ? 'Agregar al carrito' : 'Agregar a venta',
          icon: Icon(
            canShop ? Icons.shopping_bag : Icons.add_shopping_cart,
            size: 18,
          ),
        ),
        if (canManage)
          IconButton.outlined(
            visualDensity: VisualDensity.compact,
            onPressed: onArchive == null ? null : () => onArchive!(product),
            tooltip: 'Desactivar prenda',
            icon: const Icon(Icons.visibility_off_outlined, size: 18),
          ),
      ],
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: product.imageUrl == null || product.imageUrl!.isEmpty
          ? Center(
              child: Text(
                product.category.isEmpty
                    ? '?'
                    : product.category.characters.first,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF171717),
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Image.network(
              product.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.broken_image_outlined),
            ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'No se pudo cargar el catalogo.',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
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
    required this.onNewSale,
    required this.onConfirm,
  });

  final List<SaleLine> cart;
  final bool canSell;
  final bool canTakeQr;
  final VoidCallback onNewSale;
  final ValueChanged<PaymentMethod> onConfirm;

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
        onPressed: canSell ? onNewSale : null,
        tooltip: 'Nueva venta',
        icon: const Icon(Icons.restart_alt),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cart.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Agrega prendas para iniciar la venta.'),
              ),
            ),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: canSell ? () => onConfirm(PaymentMethod.cash) : null,
                icon: const Icon(Icons.payments),
                label: const Text('Efectivo'),
              ),
              OutlinedButton.icon(
                onPressed: canSell && canTakeQr
                    ? () => onConfirm(PaymentMethod.qr)
                    : null,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('QR'),
              ),
              OutlinedButton.icon(
                onPressed: canSell ? () => onConfirm(PaymentMethod.card) : null,
                icon: const Icon(Icons.credit_card),
                label: const Text('Tarjeta'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerPanel extends StatelessWidget {
  const _CustomerPanel({
    required this.cart,
    required this.orders,
    required this.onContinue,
  });

  final List<SaleLine> cart;
  final List<CustomerOrder> orders;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _Panel(
          title: 'Mi carrito',
          subtitle: 'Productos seleccionados para comprar.',
          action: const _RoleBadge(role: AccountRole.customer),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in cart)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const _IconBox(icon: Icons.checkroom),
                  title: Text(item.product),
                  subtitle: Text(
                    'Talla ${item.size} · ${item.quantity} unidad(es)',
                  ),
                  trailing: Text(
                    'Bs ${item.total.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              if (cart.isEmpty)
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _IconBox(icon: Icons.checkroom),
                  title: Text('Tu carrito esta vacio'),
                  subtitle: Text('Agrega una prenda desde el catalogo'),
                  trailing: Text(
                    'Bs 0',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              const Divider(height: 22),
              _TotalRow(
                label: 'Total',
                value: cart.fold<double>(0, (sum, item) => sum + item.total),
                isStrong: true,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Continuar pedido'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Mis pedidos',
          subtitle: 'Seguimiento de compras realizadas.',
          child: Column(
            children: [
              if (orders.isEmpty)
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _IconBox(icon: Icons.receipt_long),
                  title: Text('Todavia no tienes pedidos reales'),
                  subtitle: Text('Cuando confirmes el carrito apareceran aqui'),
                )
              else
                for (final order in orders) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _IconBox(
                      icon: order.status == 'paid'
                          ? Icons.check_circle_outline
                          : Icons.local_shipping_outlined,
                    ),
                    title: Text(order.code),
                    subtitle: Text(
                      '${order.statusLabel} - ${order.itemsCount} prenda(s)',
                    ),
                    trailing: Text(
                      'Bs ${order.total.toStringAsFixed(0)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (order != orders.last) const Divider(height: 18),
                ],
              if (orders.isNotEmpty) const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const _IconBox(icon: Icons.local_shipping_outlined),
                title: const Text('Pedido #MT-0018'),
                subtitle: const Text('Preparando · 2 prendas'),
                trailing: Text(
                  'Bs 605',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Divider(height: 18),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _IconBox(icon: Icons.check_circle_outline),
                title: Text('Pedido #MT-0012'),
                subtitle: Text('Entregado'),
                trailing: Text(
                  'Bs 280',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ],
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

class _CashPanel extends StatelessWidget {
  const _CashPanel({
    required this.status,
    required this.loading,
    required this.onOpen,
    required this.onClose,
  });

  final CashRegisterStatus? status;
  final bool loading;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isOpen = status != null;

    return _Panel(
      title: 'Control de caja',
      subtitle: isOpen
          ? 'Caja abierta para registrar ventas y cierre.'
          : 'Abre caja antes de iniciar el turno.',
      action: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isOpen ? Icons.lock_open : Icons.lock_outline,
              color: const Color(0xFF171717),
            ),
            title: Text(isOpen ? 'Caja abierta' : 'Caja cerrada'),
            subtitle: Text(
              isOpen
                  ? 'Apertura Bs ${status!.openingAmount.toStringAsFixed(0)}'
                  : 'Registra monto inicial para controlar el efectivo.',
            ),
            trailing: Text(
              isOpen
                  ? 'Bs ${status!.expectedAmount.toStringAsFixed(0)}'
                  : 'Bs 0',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isOpen || loading ? null : onOpen,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Abrir caja'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: !isOpen || loading ? null : onClose,
                  icon: const Icon(Icons.stop),
                  label: const Text('Cerrar caja'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportsPanel extends StatelessWidget {
  const _ReportsPanel({required this.summary, required this.loading});

  final DashboardSummary summary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Reportes contables',
      subtitle:
          'Lectura diaria, mensual y anual para administrador o contador.',
      action: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const _RoleBadge(role: AccountRole.admin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ReportValue(label: 'Hoy', value: summary.dailyRevenue),
              _ReportValue(label: 'Mes', value: summary.monthlyRevenue),
              _ReportValue(label: 'Ano', value: summary.yearlyRevenue),
              _ReportValue(label: 'Ticket prom.', value: summary.averageTicket),
            ],
          ),
          const SizedBox(height: 18),
          _MiniBarChart(
            title: 'Ventas por periodo',
            values: [
              ChartValue('Dia', summary.dailyRevenue),
              ChartValue('Mes', summary.monthlyRevenue),
              ChartValue('Ano', summary.yearlyRevenue),
            ],
          ),
          const SizedBox(height: 16),
          _MiniBarChart(
            title: 'Metodos de pago hoy',
            values: [
              ChartValue('Efectivo', summary.cashPaymentsToday),
              ChartValue('QR', summary.qrRevenueToday),
              ChartValue('Tarjeta', summary.cardRevenueToday),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportValue extends StatelessWidget {
  const _ReportValue({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: _Surface(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF737373),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bs ${value.toStringAsFixed(0)}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.title, required this.values});

  final String title;
  final List<ChartValue> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<double>(
      0,
      (max, item) => item.value > max ? item.value : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        for (final item in values) ...[
          Row(
            children: [
              SizedBox(width: 72, child: Text(item.label)),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = maxValue <= 0
                        ? 0.0
                        : constraints.maxWidth * (item.value / maxValue);
                    return Stack(
                      children: [
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Container(
                          width: width.clamp(0, constraints.maxWidth),
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF171717),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 82,
                child: Text(
                  'Bs ${item.value.toStringAsFixed(0)}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (item != values.last) const SizedBox(height: 8),
        ],
      ],
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
    final operations = account.role == AccountRole.customer
        ? const [
            Operation(
              'Catalogo',
              'Explorar prendas por categoria, talla y precio.',
              Icons.storefront,
              true,
            ),
            Operation(
              'Mi carrito',
              'Revisar productos y continuar el pedido.',
              Icons.shopping_bag,
              true,
            ),
            Operation(
              'Mis pedidos',
              'Consultar estado e historial de compras.',
              Icons.receipt_long,
              true,
            ),
            Operation(
              'Mi perfil',
              'Actualizar datos personales y contacto.',
              Icons.person,
              true,
            ),
          ]
        : [
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
              'Buscar clientes y consultar compras.',
              Icons.people_alt,
              permissions.canCreateSales,
            ),
            Operation(
              'Reportes',
              account.role == AccountRole.seller
                  ? 'Consultar ventas y cierre del turno propio.'
                  : 'Ventas, margen, rotacion y stock bajo.',
              Icons.bar_chart,
              permissions.canViewReports,
            ),
            Operation(
              'Configuracion',
              'Usuarios, sucursales y parametros del negocio.',
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
      'Proyecto Supabase y Flutter conectados.',
      'Tres usuarios creados: admin, vendedor y cliente.',
      'Ejecutar supabase_three_roles_migration.sql.',
      'Siguiente fase: productos, ventas y pedidos con datos reales.',
    ];

    return _Panel(
      title: 'Estado Supabase',
      subtitle: 'Checklist de integracion del backend.',
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
      name: 'Vendedora Caja',
      email: 'ventas@mitienda.bo',
      role: AccountRole.seller,
      description:
          'Opera ventas rapidas, cobros QR y consulta catalogo disponible.',
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
      imageUrl:
          'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=900&q=80',
      variants: const [
        ProductVariant(id: 'demo-blazer-s', size: 'S', stock: 3),
        ProductVariant(id: 'demo-blazer-m', size: 'M', stock: 7),
        ProductVariant(id: 'demo-blazer-l', size: 'L', stock: 2),
      ],
    ),
    Product(
      name: 'Vestido satinado',
      brand: 'Luna Alta',
      model: 'Nerea',
      category: 'Vestidos',
      price: 280,
      colorName: 'Rosa vino',
      imageUrl:
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=80',
      variants: const [
        ProductVariant(id: 'demo-vestido-xs', size: 'XS', stock: 1),
        ProductVariant(id: 'demo-vestido-s', size: 'S', stock: 4),
        ProductVariant(id: 'demo-vestido-m', size: 'M', stock: 5),
      ],
    ),
    Product(
      name: 'Jean tiro alto',
      brand: 'Denim Sur',
      model: 'Andes',
      category: 'Jeans',
      price: 210,
      colorName: 'Grafito',
      imageUrl:
          'https://images.unsplash.com/photo-1542272604-787c3835535d?auto=format&fit=crop&w=900&q=80',
      variants: const [
        ProductVariant(id: 'demo-jean-36', size: '36', stock: 5),
        ProductVariant(id: 'demo-jean-38', size: '38', stock: 8),
        ProductVariant(id: 'demo-jean-40', size: '40', stock: 3),
      ],
    ),
    Product(
      name: 'Camisa seda fria',
      brand: 'Atelier Sol',
      model: 'Brisa',
      category: 'Camisas',
      price: 185,
      colorName: 'Mostaza',
      imageUrl:
          'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?auto=format&fit=crop&w=900&q=80',
      variants: const [
        ProductVariant(id: 'demo-camisa-s', size: 'S', stock: 6),
        ProductVariant(id: 'demo-camisa-m', size: 'M', stock: 2),
        ProductVariant(id: 'demo-camisa-l', size: 'L', stock: 1),
      ],
    ),
  ];

  static const cart = [
    SaleLine(
      productId: 'demo-blazer',
      variantId: 'demo-blazer-m',
      product: 'Blazer lino premium',
      size: 'M',
      colorName: 'Azul petroleo',
      quantity: 1,
      unitPrice: 325,
      total: 325,
    ),
    SaleLine(
      productId: 'demo-vestido',
      variantId: 'demo-vestido-s',
      product: 'Vestido satinado',
      size: 'S',
      colorName: 'Rosa vino',
      quantity: 1,
      unitPrice: 280,
      total: 280,
    ),
  ];

  static const orders = [
    CustomerOrder(
      id: 'demo-order-1',
      code: '#MT-0018',
      status: 'draft',
      itemsCount: 2,
      total: 605,
    ),
    CustomerOrder(
      id: 'demo-order-2',
      code: '#MT-0012',
      status: 'paid',
      itemsCount: 1,
      total: 280,
    ),
  ];
}

enum AccountRole { admin, seller, customer }

extension AccountRoleInfo on AccountRole {
  String get label {
    return switch (this) {
      AccountRole.admin => 'Administrador',
      AccountRole.seller => 'Vendedor/Cajero',
      AccountRole.customer => 'Cliente',
    };
  }

  IconData get icon {
    return switch (this) {
      AccountRole.admin => Icons.admin_panel_settings,
      AccountRole.seller => Icons.point_of_sale,
      AccountRole.customer => Icons.person,
    };
  }

  String get description {
    return switch (this) {
      AccountRole.admin =>
        'Acceso total: usuarios, inventario, ventas, caja, reportes y configuracion.',
      AccountRole.seller =>
        'Opera ventas, cobros QR, caja, clientes y reportes de su turno.',
      AccountRole.customer =>
        'Explora el catalogo, administra su carrito y consulta sus pedidos.',
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
      AccountRole.seller => const RolePermissions(
        canManageInventory: true,
        canCreateSales: true,
        canTakeQrPayments: true,
        canManageCash: true,
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
      'seller' => AccountRole.seller,
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

class OperationalRepository {
  OperationalRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<DashboardSummary> fetchDashboardSummary() async {
    final response = await _client.rpc('boutique_dashboard_summary');
    if (response is List && response.isNotEmpty) {
      return DashboardSummary.fromMap(response.first as Map<String, dynamic>);
    }
    if (response is Map<String, dynamic>) {
      return DashboardSummary.fromMap(response);
    }
    return DashboardSummary.demo;
  }

  Future<List<CustomerOrder>> fetchMyOrders() async {
    final response = await _client
        .from('sales')
        .select('id,status,total,created_at,sale_items(id)')
        .eq('customer_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .limit(10);

    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(CustomerOrder.fromMap)
        .toList();
  }

  Future<CashRegisterStatus?> fetchOpenCashRegister() async {
    final response = await _client.rpc('boutique_open_cash_register');
    if (response is List && response.isNotEmpty) {
      return CashRegisterStatus.fromMap(response.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> openCashRegister(double openingAmount) async {
    await _client.rpc(
      'boutique_open_register',
      params: {'opening_amount_input': openingAmount},
    );
  }

  Future<void> closeCashRegister(double closingAmount) async {
    await _client.rpc(
      'boutique_close_register',
      params: {'closing_amount_input': closingAmount},
    );
  }

  Future<void> confirmSale({
    required List<SaleLine> cart,
    required PaymentMethod method,
  }) async {
    await _client.rpc(
      'boutique_confirm_sale',
      params: {
        'items_input': cart.map((item) => item.toSalePayload()).toList(),
        'payment_method_input': method.databaseValue,
      },
    );
  }

  Future<void> createCustomerOrder({required List<SaleLine> cart}) async {
    await _client.rpc(
      'boutique_create_customer_order',
      params: {
        'items_input': cart.map((item) => item.toSalePayload()).toList(),
      },
    );
  }
}

class ProductRepository {
  ProductRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Product>> fetchProducts() async {
    dynamic response;
    try {
      response = await _client
          .from('products')
          .select(
            'id,name,brand,model,description,image_url,base_price,'
            'categories(name),'
            'product_variants(id,size,color_name,color_hex,stock,min_stock)',
          )
          .eq('active', true)
          .order('created_at', ascending: false);
    } on PostgrestException catch (error) {
      if (error.code != '42703') rethrow;
      response = await _client
          .from('products')
          .select(
            'id,name,brand,model,description,base_price,'
            'categories(name),'
            'product_variants(id,size,color_name,color_hex,stock,min_stock)',
          )
          .eq('active', true)
          .order('created_at', ascending: false);
    }

    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Product.fromMap)
        .toList();
  }

  Future<void> saveProduct(ProductDraft draft, {Product? existing}) async {
    final category = await _client
        .from('categories')
        .upsert({'name': draft.category}, onConflict: 'name')
        .select('id')
        .single();
    final categoryId = category['id'] as String;

    if (existing == null) {
      final created = await _client
          .from('products')
          .insert({
            'category_id': categoryId,
            'name': draft.name,
            'brand': draft.brand,
            'model': draft.model,
            'description': draft.description,
            'base_price': draft.price,
          })
          .select('id')
          .single();
      final productId = created['id'] as String;
      final imageUrl = await _uploadImage(
        productId: productId,
        bytes: draft.imageBytes,
        fileName: draft.imageFileName,
      );

      if (imageUrl != null) {
        await _client
            .from('products')
            .update({'image_url': imageUrl})
            .eq('id', productId);
      }

      await _insertVariants(productId, draft.variants);
      return;
    }

    final imageUrl = await _uploadImage(
      productId: existing.id,
      bytes: draft.imageBytes,
      fileName: draft.imageFileName,
    );
    final productChanges = <String, dynamic>{
      'category_id': categoryId,
      'name': draft.name,
      'brand': draft.brand,
      'model': draft.model,
      'description': draft.description,
      'base_price': draft.price,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (imageUrl != null) productChanges['image_url'] = imageUrl;

    await _client.from('products').update(productChanges).eq('id', existing.id);

    final submittedIds = draft.variants
        .map((variant) => variant.id)
        .where((id) => id.isNotEmpty)
        .toSet();
    for (final previous in existing.variants) {
      if (previous.id.isNotEmpty && !submittedIds.contains(previous.id)) {
        await _client.from('product_variants').delete().eq('id', previous.id);
      }
    }

    for (final variant in draft.variants) {
      final data = {
        'product_id': existing.id,
        'size': variant.size,
        'color_name': variant.colorName,
        'color_hex': variant.colorHex,
        'stock': variant.stock,
        'min_stock': variant.minStock,
      };
      if (variant.id.isEmpty) {
        await _client.from('product_variants').insert(data);
      } else {
        await _client
            .from('product_variants')
            .update(data)
            .eq('id', variant.id);
      }
    }
  }

  Future<void> archiveProduct(String productId) async {
    await _client
        .from('products')
        .update({
          'active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', productId);
  }

  Future<void> _insertVariants(
    String productId,
    List<ProductVariant> variants,
  ) async {
    await _client
        .from('product_variants')
        .insert(
          variants
              .map(
                (variant) => {
                  'product_id': productId,
                  'size': variant.size,
                  'color_name': variant.colorName,
                  'color_hex': variant.colorHex,
                  'stock': variant.stock,
                  'min_stock': variant.minStock,
                },
              )
              .toList(),
        );
  }

  Future<String?> _uploadImage({
    required String productId,
    required Uint8List? bytes,
    required String? fileName,
  }) async {
    if (bytes == null || fileName == null) return null;

    final extension = fileName.split('.').last.toLowerCase();
    final safeExtension = {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)
        ? extension
        : 'jpg';
    final path =
        '$productId/${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
    final contentType = switch (safeExtension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    await _client.storage
        .from('product-images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return _client.storage.from('product-images').getPublicUrl(path);
  }
}

class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({super.key, required this.repository, this.product});

  final ProductRepository repository;
  final Product? product;

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late List<ProductVariant> _variants;
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name);
    _brandController = TextEditingController(text: product?.brand);
    _modelController = TextEditingController(text: product?.model);
    _categoryController = TextEditingController(text: product?.category);
    _priceController = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(text: product?.description);
    _variants = product?.variants.toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: const Text('¿Desde dónde quieres cargar la foto?'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Cámara'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Galería'),
          ),
        ],
      ),
    );

    if (source == null) return;

    final image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1800,
      imageQuality: 88,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();

    setState(() {
      _imageBytes = bytes;
      _imageFileName = image.name;
    });
  }

  Future<void> _editVariant([int? index]) async {
    final current = index == null ? null : _variants[index];
    final sizeController = TextEditingController(text: current?.size);
    final colorController = TextEditingController(text: current?.colorName);
    final stockController = TextEditingController(
      text: current?.stock.toString() ?? '',
    );
    final minStockController = TextEditingController(
      text: current?.minStock.toString() ?? '2',
    );

    final result = await showDialog<ProductVariant>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? 'Agregar variante' : 'Editar variante'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sizeController,
                decoration: const InputDecoration(
                  labelText: 'Talla',
                  hintText: 'S, M, L, 36, Unica',
                ),
              ),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock'),
              ),
              TextField(
                controller: minStockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock minimo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final size = sizeController.text.trim();
              final color = colorController.text.trim();
              final stock = int.tryParse(stockController.text.trim());
              final minStock = int.tryParse(minStockController.text.trim());
              if (size.isEmpty ||
                  color.isEmpty ||
                  stock == null ||
                  minStock == null) {
                return;
              }
              Navigator.pop(
                context,
                ProductVariant(
                  id: current?.id ?? '',
                  size: size,
                  colorName: color,
                  stock: stock,
                  minStock: minStock,
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    sizeController.dispose();
    colorController.dispose();
    stockController.dispose();
    minStockController.dispose();

    if (result == null) return;
    setState(() {
      if (index == null) {
        _variants.add(result);
      } else {
        _variants[index] = result;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_variants.isEmpty) {
      setState(() => _error = 'Agrega al menos una talla/color con stock.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.repository.saveProduct(
        ProductDraft(
          name: _nameController.text.trim(),
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          category: _categoryController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          description: _descriptionController.text.trim(),
          variants: _variants,
          imageBytes: _imageBytes,
          imageFileName: _imageFileName,
        ),
        existing: widget.product,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar prenda' : 'Nueva prenda'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _FormFieldBox(controller: _nameController, label: 'Nombre'),
                    _FormFieldBox(controller: _brandController, label: 'Marca'),
                    _FormFieldBox(
                      controller: _modelController,
                      label: 'Modelo',
                    ),
                    _FormFieldBox(
                      controller: _categoryController,
                      label: 'Categoria',
                    ),
                    _FormFieldBox(
                      controller: _priceController,
                      label: 'Precio (Bs)',
                      number: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripcion',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _imageBytes != null
                          ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                          : widget.product?.imageUrl != null
                          ? Image.network(
                              widget.product!.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _saving ? null : _pickImage,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Elegir JPG o PNG'),
                          ),
                          const Text(
                            'Maximo 5 MB. La imagen se recorta automaticamente en el catalogo.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tallas, colores y stock',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _editVariant(),
                      icon: const Icon(Icons.add),
                      label: const Text('Variante'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < _variants.length; index++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${_variants[index].size} · ${_variants[index].colorName}',
                    ),
                    subtitle: Text(
                      'Stock ${_variants[index].stock} · Minimo ${_variants[index].minStock}',
                    ),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          onPressed: _saving ? null : () => _editVariant(index),
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar variante',
                        ),
                        IconButton(
                          onPressed: _saving
                              ? null
                              : () => setState(() => _variants.removeAt(index)),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Quitar variante',
                        ),
                      ],
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_saving ? 'Guardando...' : 'Guardar prenda'),
        ),
      ],
    );
  }
}

class _FormFieldBox extends StatelessWidget {
  const _FormFieldBox({
    required this.controller,
    required this.label,
    this.number = false,
  });

  final TextEditingController controller;
  final String label;
  final bool number;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 205,
      child: TextFormField(
        controller: controller,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Campo requerido';
          }
          if (number && double.tryParse(value.trim()) == null) {
            return 'Numero invalido';
          }
          return null;
        },
      ),
    );
  }
}

class Product {
  const Product({
    this.id = '',
    required this.name,
    required this.brand,
    required this.model,
    required this.category,
    required this.price,
    required this.colorName,
    required this.variants,
    this.description,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String brand;
  final String model;
  final String category;
  final double price;
  final String colorName;
  final List<ProductVariant> variants;
  final String? description;
  final String? imageUrl;

  factory Product.fromMap(Map<String, dynamic> map) {
    final category = map['categories'];
    final variantsData = (map['product_variants'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final variants = variantsData.map(ProductVariant.fromMap).toList();

    return Product(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      model: map['model'] as String? ?? '',
      category: category is Map<String, dynamic>
          ? category['name'] as String? ?? 'Sin categoria'
          : 'Sin categoria',
      price: (map['base_price'] as num?)?.toDouble() ?? 0,
      colorName: variants.isEmpty ? 'Sin color' : variants.first.colorName,
      variants: variants,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
    );
  }
}

class ProductVariant {
  const ProductVariant({
    this.id = '',
    required this.size,
    required this.stock,
    this.colorName = 'Sin color',
    this.colorHex,
    this.minStock = 2,
  });

  final String id;
  final String size;
  final int stock;
  final String colorName;
  final String? colorHex;
  final int minStock;

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] as String? ?? '',
      size: map['size'] as String? ?? 'Unica',
      stock: map['stock'] as int? ?? 0,
      colorName: map['color_name'] as String? ?? 'Sin color',
      colorHex: map['color_hex'] as String?,
      minStock: map['min_stock'] as int? ?? 2,
    );
  }
}

class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.brand,
    required this.model,
    required this.category,
    required this.price,
    required this.description,
    required this.variants,
    this.imageBytes,
    this.imageFileName,
  });

  final String name;
  final String brand;
  final String model;
  final String category;
  final double price;
  final String description;
  final List<ProductVariant> variants;
  final Uint8List? imageBytes;
  final String? imageFileName;
}

class SaleLine {
  const SaleLine({
    required this.productId,
    required this.variantId,
    required this.product,
    required this.size,
    required this.colorName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.imageUrl,
  });

  final String productId;
  final String variantId;
  final String product;
  final String size;
  final String colorName;
  final int quantity;
  final double unitPrice;
  final double total;
  final String? imageUrl;

  Map<String, dynamic> toSalePayload() {
    return {
      'variant_id': variantId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }
}

class Metric {
  const Metric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

enum PaymentMethod {
  cash('cash'),
  qr('qr'),
  card('card');

  const PaymentMethod(this.databaseValue);

  final String databaseValue;
}

class CashRegisterStatus {
  const CashRegisterStatus({
    required this.id,
    required this.openingAmount,
    required this.expectedAmount,
  });

  final String id;
  final double openingAmount;
  final double expectedAmount;

  factory CashRegisterStatus.fromMap(Map<String, dynamic> map) {
    return CashRegisterStatus(
      id: map['id'] as String? ?? '',
      openingAmount: (map['opening_amount'] as num?)?.toDouble() ?? 0,
      expectedAmount: (map['expected_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.code,
    required this.status,
    required this.itemsCount,
    required this.total,
  });

  final String id;
  final String code;
  final String status;
  final int itemsCount;
  final double total;

  String get statusLabel {
    return switch (status) {
      'paid' => 'Pagado',
      'cancelled' => 'Cancelado',
      _ => 'Pendiente',
    };
  }

  factory CustomerOrder.fromMap(Map<String, dynamic> map) {
    final id = map['id'] as String? ?? '';
    final items = map['sale_items'] as List<dynamic>? ?? const [];
    return CustomerOrder(
      id: id,
      code: '#${id.isEmpty ? 'PEDIDO' : id.substring(0, 8).toUpperCase()}',
      status: map['status'] as String? ?? 'draft',
      itemsCount: items.length,
      total: (map['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ChartValue {
  const ChartValue(this.label, this.value);

  final String label;
  final double value;
}

class DashboardSummary {
  const DashboardSummary({
    required this.activeProducts,
    required this.salesToday,
    required this.lowStockVariants,
    required this.qrPaymentsToday,
    required this.customerOrders,
    required this.pendingOrders,
    required this.cashToday,
    required this.dailyRevenue,
    required this.monthlyRevenue,
    required this.yearlyRevenue,
    required this.averageTicket,
    required this.cashPaymentsToday,
    required this.qrRevenueToday,
    required this.cardRevenueToday,
  });

  final int activeProducts;
  final int salesToday;
  final int lowStockVariants;
  final int qrPaymentsToday;
  final int customerOrders;
  final int pendingOrders;
  final double cashToday;
  final double dailyRevenue;
  final double monthlyRevenue;
  final double yearlyRevenue;
  final double averageTicket;
  final double cashPaymentsToday;
  final double qrRevenueToday;
  final double cardRevenueToday;

  static const demo = DashboardSummary(
    activeProducts: 24,
    salesToday: 18,
    lowStockVariants: 7,
    qrPaymentsToday: 6,
    customerOrders: 2,
    pendingOrders: 1,
    cashToday: 1245,
    dailyRevenue: 1245,
    monthlyRevenue: 18340,
    yearlyRevenue: 94200,
    averageTicket: 208,
    cashPaymentsToday: 620,
    qrRevenueToday: 485,
    cardRevenueToday: 140,
  );

  factory DashboardSummary.fromMap(Map<String, dynamic> map) {
    int intValue(String key) => (map[key] as num?)?.toInt() ?? 0;
    double money(String key) => (map[key] as num?)?.toDouble() ?? 0;

    return DashboardSummary(
      activeProducts: intValue('active_products'),
      salesToday: intValue('sales_today'),
      lowStockVariants: intValue('low_stock_variants'),
      qrPaymentsToday: intValue('qr_payments_today'),
      customerOrders: intValue('customer_orders'),
      pendingOrders: intValue('pending_orders'),
      cashToday: money('cash_today'),
      dailyRevenue: money('daily_revenue'),
      monthlyRevenue: money('monthly_revenue'),
      yearlyRevenue: money('yearly_revenue'),
      averageTicket: money('average_ticket'),
      cashPaymentsToday: money('cash_payments_today'),
      qrRevenueToday: money('qr_revenue_today'),
      cardRevenueToday: money('card_revenue_today'),
    );
  }
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
