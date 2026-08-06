import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/checkout_models.dart';
import '../providers/app_state.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, required this.cartItems});

  final List<CartItem> cartItems;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartItem> items;
  final _destinationController = TextEditingController();
  bool _isProcessing = false;
  bool _isCalculatingShipping = false;
  double? _shippingCost;
  String? _shippingMessage;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    items = widget.cartItems
        .map((item) => CartItem(product: item.product, quantity: item.quantity))
        .toList();
    _destinationController.addListener(_onDestinationChanged);
    _refreshShipping();
  }

  double get _subtotal => items.fold(0, (sum, item) => sum + item.subtotal);

  int get _totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  double get _estimatedTotal {
    if (_shippingCost == null) {
      return _subtotal;
    }
    return _subtotal + _shippingCost!;
  }

  void _updateQuantity(CartItem item, int quantity) {
    setState(() {
      if (quantity <= 0) {
        items.removeWhere((it) => it.product.id == item.product.id);
      } else {
        final index = items.indexWhere(
          (it) => it.product.id == item.product.id,
        );
        if (index != -1) {
          items[index] = CartItem(product: item.product, quantity: quantity);
        }
      }
    });
  }

  void _onDestinationChanged() {
    setState(() {
      _shippingCost = null;
      _shippingMessage = 'Completá la dirección para calcular envío.';
    });
  }

  Future<void> _refreshShipping() async {
    final destinationAddress = _destinationController.text.trim();
    if (destinationAddress.isEmpty) {
      setState(() {
        _shippingCost = null;
        _shippingMessage = 'Completá la dirección para calcular envío.';
      });
      return;
    }

    setState(() {
      _isCalculatingShipping = true;
      _shippingMessage = null;
    });

    try {
      final appState = context.read<AppState>();
      final shippingCost = await appState.estimateShippingCost(
        originAddress: 'Colegio San José, Rosario, Santa Fe',
        destinationAddress: destinationAddress,
        shippingRatePerKm: 120,
      );
      if (!mounted) return;
      setState(() {
        _shippingCost = shippingCost;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _shippingCost = null;
          _shippingMessage = 'No se pudo calcular el envío. Intenta de nuevo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isCalculatingShipping = false);
      }
    }
  }

  Future<void> _checkout() async {
    if (items.isEmpty) {
      setState(
        () => _feedback =
            'El carrito está vacío. Agregá productos antes de pagar.',
      );
      return;
    }

    final destinationAddress = _destinationController.text.trim();
    if (destinationAddress.isEmpty) {
      setState(() {
        _feedback = 'Ingresá una dirección para calcular el envío y pagar.';
      });
      return;
    }

    final appState = context.read<AppState>();

    if (_shippingCost == null) {
      await _refreshShipping();
      if (_shippingCost == null) {
        setState(() {
          _feedback =
              'No se pudo calcular el envío. Revisá la dirección e intentá de nuevo.';
        });
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _feedback = null;
    });

    try {
      final result = await appState.createCheckoutOrder(
        items: items,
        originAddress: 'Colegio San José, Rosario, Santa Fe',
        destinationAddress: destinationAddress,
        shippingRatePerKm: 120,
      );

      if (!mounted) return;
      setState(() => _feedback = result.message);

      final uri = Uri.parse(result.paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el pago: ${result.paymentUrl}'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _feedback = 'Error al generar el pago: $error');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (items.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Tu carrito está vacío. Volvé a la tienda para agregar productos.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            else ...[
              Expanded(
                child: ListView.separated(
                  itemCount: items.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dirección de envío',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _destinationController,
                                decoration: InputDecoration(
                                  labelText: 'Tu dirección completa',
                                  hintText: 'Ej: Funes, Santa Fe',
                                  suffixIcon: FilledButton(
                                    onPressed: _isCalculatingShipping
                                        ? null
                                        : _refreshShipping,
                                    child: _isCalculatingShipping
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Calcular'),
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              if (_shippingMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _shippingMessage!,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    final item = items[index - 1];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFF0B5ED7),
                              foregroundColor: Colors.white,
                              child: Text(item.product.name.characters.first),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.product.description,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _QuantityButton(
                                        label: '-',
                                        onTap: () => _updateQuantity(
                                          item,
                                          item.quantity - 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          item.quantity.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      _QuantityButton(
                                        label: '+',
                                        onTap: () => _updateQuantity(
                                          item,
                                          item.quantity + 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${item.subtotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: 'Items',
                        value: '$_totalQuantity productos',
                      ),
                      _SummaryRow(
                        label: 'Subtotal',
                        value: '\$${_subtotal.toStringAsFixed(0)}',
                      ),
                      _SummaryRow(
                        label: 'Envío',
                        value: _isCalculatingShipping
                            ? 'Calculando...'
                            : _shippingCost != null
                            ? '\$${_shippingCost!.toStringAsFixed(0)}'
                            : _shippingMessage ?? 'Pendiente',
                      ),
                      const Divider(height: 28),
                      _SummaryRow(
                        label: 'Total estimado',
                        value: '\$${_estimatedTotal.toStringAsFixed(0)}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_feedback != null)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      _feedback!,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_isProcessing || _isCalculatingShipping)
                      ? null
                      : _checkout,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.payment),
                  label: Text(
                    _isProcessing
                        ? 'Procesando pago...'
                        : _shippingCost == null
                        ? 'Verifica la dirección'
                        : 'Pagar ahora',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
