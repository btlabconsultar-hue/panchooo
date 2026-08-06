import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/checkout_models.dart';
import '../providers/app_state.dart';
import '../route_observer.dart';
import 'cart_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with RouteAware {
  final _storeController = TextEditingController(
    text: 'Colegio San José, Rosario, Santa Fe',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadProducts();
    });
  }

  static const List<StoreProduct> _fallbackProducts = [
    StoreProduct(
      id: 'p1',
      name: '⚽ Pelota Oficial',
      price: 2500,
      stock: 12,
      description: 'Ideal para entrenar y jugar todos los días.',
    ),
    StoreProduct(
      id: 'p2',
      name: '👕 Camiseta Deportiva',
      price: 1800,
      stock: 8,
      description: 'Cómoda, fresca y lista para la cancha.',
    ),
    StoreProduct(
      id: 'p3',
      name: '🎒 Mochila de Entrenamiento',
      price: 3200,
      stock: 6,
      description: 'Perfecta para llevar todo tu equipo.',
    ),
  ];

  final Map<String, CartItem> _cartItems = {};
  String? _feedback;

  int get _cartCount =>
      _cartItems.values.fold(0, (total, item) => total + item.quantity);

  void _addToCart(StoreProduct product) {
    setState(() {
      final existing = _cartItems[product.id];
      final currentQuantity = existing?.quantity ?? 0;
      if (currentQuantity >= product.stock) {
        _feedback = 'No hay suficiente stock de ${product.name}.';
        return;
      }

      if (existing != null) {
        _cartItems[product.id] = CartItem(
          product: product,
          quantity: existing.quantity + 1,
        );
      } else {
        _cartItems[product.id] = CartItem(product: product, quantity: 1);
      }
      _feedback = '${product.name} agregado al carrito';
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _storeController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<AppState>().loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SportShop'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () async {
              final appState = context.read<AppState>();
              await Navigator.pushNamed(context, '/admin-login');
              await appState.loadProducts();
            },
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CartScreen(cartItems: _cartItems.values.toList()),
                  ),
                ),
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.redAccent,
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF0B5ED7), Color(0xFF1E88E5)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🏪 SportShop',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tu tienda deportiva online con envío en menos de 24 hs.',
                  style: TextStyle(fontSize: 15, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '📍 Origen de envío: Colegio San José, Rosario',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Productos destacados',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('Products')
                .snapshots(),
            builder: (context, snapshot) {
              final products = snapshot.hasData
                  ? snapshot.data!.docs
                        .map((doc) => StoreProduct.fromFirestoreMap(doc.data()))
                        .toList()
                  : appState.products;

              final effectiveProducts = products.isEmpty
                  ? _fallbackProducts
                  : products;

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Error cargando productos: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData && appState.products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: effectiveProducts.map((product) {
                  return SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 24,
                    child: GestureDetector(
                      onTap: product.stock > 0
                          ? () => _addToCart(product)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _cartItems.containsKey(product.id)
                              ? const Color(0xFFEAF3FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _cartItems.containsKey(product.id)
                                ? const Color(0xFF0B5ED7)
                                : const Color(0xFFE5E7EB),
                          ),
                          boxShadow: [
                            const BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.04),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              product.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.stock > 0
                                  ? 'Stock disponible: ${product.stock}'
                                  : 'Agotado',
                              style: TextStyle(
                                fontSize: 12,
                                color: product.stock > 0
                                    ? Colors.green.shade700
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '\$${product.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      product.stock == 0
                                          ? 'Agotado'
                                          : _cartItems.containsKey(product.id)
                                          ? 'Agregado'
                                          : 'Agregar',
                                      style: TextStyle(
                                        color:
                                            _cartItems.containsKey(product.id)
                                            ? Colors.green
                                            : const Color(0xFF0B5ED7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      _cartItems.containsKey(product.id)
                                          ? Icons.check_circle
                                          : Icons.add_shopping_cart,
                                      color: product.stock == 0
                                          ? Colors.red
                                          : _cartItems.containsKey(product.id)
                                          ? Colors.green
                                          : const Color(0xFF0B5ED7),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Datos de entrega',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _storeController,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Origen del envío',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _cartCount == 0
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CartScreen(cartItems: _cartItems.values.toList()),
                      ),
                    ),
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text(
                _cartCount == 0
                    ? 'Agregá productos al carrito'
                    : 'Ir al carrito',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_feedback != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_feedback!),
              ),
            ),
        ],
      ),
    );
  }
}
