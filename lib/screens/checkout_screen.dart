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

  double get _subtotal =>
      _cartItems.values.fold(0.0, (sum, item) => sum + item.subtotal);

  void _addToCart(StoreProduct product) {
    setState(() {
      final existing = _cartItems[product.id];
      final currentQuantity = existing?.quantity ?? 0;
      if (currentQuantity >= product.stock) {
        _feedback = product.stock == 0
            ? 'No hay stock disponible de ${product.name}.'
            : 'Máximo ${product.stock} unidades de ${product.name} disponibles.';
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
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<AppState>().loadProducts();
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(cartItems: _cartItems.values.toList()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1000;
    final cartItems = _cartItems.values.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Inicio'),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: _openCart,
                          child: const Text('Carrito'),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Productos'),
                        ),
                        const Spacer(),
                        FilledButton.tonal(
                          onPressed: () async {
                            await Navigator.pushNamed(context, '/admin-login');
                          },
                          child: const Text('Admin'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF071A3D), Color(0xFF0D5DE0)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.16,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.sports_soccer_outlined,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'SportShop Premium',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Equipá tu próxima fecha con productos de alto rendimiento y una experiencia de compra de nivel web.',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: const [
                                  _HeroChip(label: '🚚 Envío en 24 hs'),
                                  _HeroChip(label: '💳 Pago seguro'),
                                  _HeroChip(label: '⭐ Productos premium'),
                                  _HeroChip(label: '📍 Rosario y alrededores'),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Container(
                          width: 260,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estado de compra',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                cartItems.isEmpty
                                    ? 'Tu carrito está listo para recibir productos.'
                                    : '${cartItems.length} producto${cartItems.length == 1 ? '' : 's'} en el carrito',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '\$${_subtotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: cartItems.isEmpty ? null : _openCart,
                                icon: const Icon(Icons.shopping_bag_outlined),
                                label: Text(
                                  cartItems.isEmpty
                                      ? 'Agregá productos'
                                      : 'Ver carrito',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0D5DE0),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildProductsSection(
                            context,
                            appState,
                            width: width,
                          ),
                        ),
                        const SizedBox(width: 24),
                        SizedBox(
                          width: 320,
                          child: _buildSummaryPanel(context),
                        ),
                      ],
                    )
                  else ...[
                    _buildProductsSection(context, appState, width: width),
                    const SizedBox(height: 24),
                    _buildSummaryPanel(context),
                  ],
                  const SizedBox(height: 24),
                  if (_feedback != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Text(_feedback!),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: cartItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openCart,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text('Carrito (${_cartCount})'),
              backgroundColor: const Color(0xFF0D5DE0),
            )
          : null,
    );
  }

  Widget _buildProductsSection(
    BuildContext context,
    AppState appState, {
    required double width,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.storefront_outlined, color: Color(0xFF0D5DE0)),
            const SizedBox(width: 8),
            Text(
              'Catálogo destacado',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Cada producto está pensado para que tu compra se sienta premium, clara y rápida.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('Products').snapshots(),
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

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE8EDF7)),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: effectiveProducts.map((product) {
                  final cardWidth = width >= 1100
                      ? 280.0
                      : width >= 700
                      ? 220.0
                      : double.infinity;

                  return SizedBox(
                    width: cardWidth,
                    child: _ProductCard(
                      product: product,
                      isSelected: _cartItems.containsKey(product.id),
                      onTap: product.stock > 0
                          ? () => _addToCart(product)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryPanel(BuildContext context) {
    final items = _cartItems.values.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.receipt_long_outlined, color: Color(0xFF0D5DE0)),
              SizedBox(width: 8),
              Text(
                'Resumen rápido',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'Todavía no agregaste productos. El resumen se verá así de limpio cuando arranques tu compra.',
            )
          else ...[
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}× ${item.product.name}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text('\$${item.subtotal.toStringAsFixed(0)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('\$${_subtotal.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [Text('Envío'), Text('A calcular')],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: items.isEmpty ? null : _openCart,
              icon: const Icon(Icons.arrow_forward_ios_rounded),
              label: Text(items.isEmpty ? 'Elegí productos' : 'Ir al checkout'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  final StoreProduct product;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = isSelected ? Colors.green : const Color(0xFF0D5DE0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF9F0) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSelected
                  ? Colors.green.shade100
                  : const Color(0xFFE7EDF7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.sports_soccer_outlined, color: primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: product.stock > 0
                          ? const Color(0xFFE8F4FF)
                          : const Color(0xFFFFF2F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      product.stock > 0 ? 'En stock' : 'Agotado',
                      style: TextStyle(
                        color: product.stock > 0
                            ? const Color(0xFF0B6FC7)
                            : const Color(0xFFB53A22),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                product.description,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF5E6C84),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Precio',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7B8BA8),
                        ),
                      ),
                      Text(
                        '\$${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Color(0xFF0D5DE0),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 120,
                      maxWidth: 150,
                      minHeight: 36,
                      maxHeight: 40,
                    ),
                    child: FilledButton.icon(
                      onPressed: product.stock > 0 ? onTap : null,
                      icon: Icon(
                        isSelected
                            ? Icons.check_circle_outline
                            : Icons.add_shopping_cart_outlined,
                        size: 16,
                      ),
                      label: Text(
                        isSelected ? 'En carrito' : 'Agregar',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.green
                            : const Color(0xFF0D5DE0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
