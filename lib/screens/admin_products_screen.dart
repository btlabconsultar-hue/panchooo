import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/checkout_models.dart';
import '../providers/app_state.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;

    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    if (name.isEmpty || description.isEmpty || price <= 0 || stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completá nombre, descripción, precio y stock válido.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final appState = context.read<AppState>();
      final product = StoreProduct(
        id: 'product-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        price: price,
        description: description,
        stock: stock,
      );
      await appState.addProduct(product);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Producto creado correctamente.')),
      );
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _stockController.text = '1';
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final mercadoOrders = appState.checkoutOrders
        .where((order) => order.paymentUrl.contains('mercadopago'))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos del catálogo'),
        actions: [
          IconButton(
            onPressed: () async {
              final appState = context.read<AppState>();
              final navigator = Navigator.of(context);
              await appState.logoutAdmin();
              if (!mounted) return;
              navigator.pushReplacementNamed('/admin-login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 18,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D5DE0),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.add_box_outlined, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Crear producto',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            filled: true,
                            fillColor: const Color(0xFFF3F7FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Descripción',
                            filled: true,
                            fillColor: const Color(0xFFF3F7FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Precio',
                                  filled: true,
                                  fillColor: const Color(0xFFF3F7FF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _stockController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Stock',
                                  filled: true,
                                  fillColor: const Color(0xFFF3F7FF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _saveProduct,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              _isSaving ? 'Guardando...' : 'Guardar producto',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0D5DE0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Productos cargados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (appState.products.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aún no hay productos cargados en Firestore.'),
                ),
              )
            else
              ...appState.products.map(
                (product) => Card(
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                      '${product.description}\nStock: ${product.stock}',
                    ),
                    isThreeLine: true,
                    trailing: Text('\$${product.price.toStringAsFixed(0)}'),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Órdenes recibidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (mercadoOrders.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aún no se registraron órdenes de Mercado Pago.'),
                ),
              )
            else
              ...mercadoOrders.map(
                (order) => Card(
                  child: ListTile(
                    title: Text(order.productName),
                    subtitle: Text(
                      '${order.destinationAddress} · Envío \$${order.shippingCost.toStringAsFixed(0)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${order.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.createdAt.toLocal().toString().split('.').first,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
