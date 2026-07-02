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
  final _provinceController = TextEditingController();
  final _localityController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isProcessing = false;
  bool _isCalculatingShipping = false;
  double? _shippingCost;
  String? _shippingMessage = 'Ingrese la dirección';
  String? _feedback;

  @override
  void initState() {
    super.initState();
    items = widget.cartItems
        .map((item) => CartItem(product: item.product, quantity: item.quantity))
        .toList();
    _provinceController.addListener(_onAddressChanged);
    _localityController.addListener(_onAddressChanged);
    _addressController.addListener(_onAddressChanged);
    _refreshShipping();
  }

  double get _subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  int get _totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  double get _estimatedTotal =>
      _shippingCost == null ? _subtotal : _subtotal + _shippingCost!;

  void _updateQuantity(CartItem item, int quantity) {
    if (quantity > item.product.stock) {
      setState(() {
        _feedback =
            'El máximo para ${item.product.name} es ${item.product.stock} unidades.';
      });
      return;
    }

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
      _feedback = null;
    });
  }

  String _buildFullAddress() {
    final province = _provinceController.text.trim();
    final locality = _localityController.text.trim();
    final address = _addressController.text.trim();
    return [
      address,
      locality,
      province,
    ].where((part) => part.isNotEmpty).join(', ');
  }

  void _onAddressChanged() {
    setState(() {
      _shippingCost = null;
      _shippingMessage = null;
    });
  }

  Future<void> _refreshShipping() async {
    final destinationAddress = _buildFullAddress();
    if (destinationAddress.isEmpty ||
        _provinceController.text.trim().isEmpty ||
        _localityController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      setState(() {
        _shippingCost = null;
        _shippingMessage = null;
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
      setState(() => _shippingCost = shippingCost);
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

    final destinationAddress = _buildFullAddress();
    if (destinationAddress.isEmpty ||
        _provinceController.text.trim().isEmpty ||
        _localityController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      setState(() {
        _feedback =
            'Ingresá provincia, localidad y dirección para calcular el envío y pagar.';
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
    _provinceController.dispose();
    _localityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Checkout Premium'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          color: Color(0xFF0D5DE0),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tu pedido, listo para cerrar',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Completa la entrega con provincia, localidad y dirección para calcular el envío con precisión.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          'Tu carrito está vacío. Volvé a la tienda para agregar productos.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                  else if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildDeliveryCard(context),
                              const SizedBox(height: 16),
                              ...items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildItemCard(context, item),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(width: 340, child: _buildSummaryCard(context)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildDeliveryCard(context),
                        const SizedBox(height: 16),
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildItemCard(context, item),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryCard(context),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B5ED7), Color(0xFF2563EB)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.18),
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
              Icon(Icons.local_shipping_outlined, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Datos de entrega',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Agregá provincia, localidad y dirección para calcular el envío con estilo.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _AddressField(
            controller: _provinceController,
            label: 'Provincia',
            hint: 'Ej: Santa Fe',
            icon: Icons.map_outlined,
          ),
          const SizedBox(height: 12),
          _AddressField(
            controller: _localityController,
            label: 'Localidad',
            hint: 'Ej: Rosario',
            icon: Icons.location_city_outlined,
          ),
          const SizedBox(height: 12),
          _AddressField(
            controller: _addressController,
            label: 'Dirección',
            hint: 'Ej: Av. San Martín 123',
            icon: Icons.home_outlined,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.visibility_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _buildFullAddress().isEmpty
                        ? 'Tu dirección aparecerá aquí'
                        : _buildFullAddress(),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _isCalculatingShipping ? null : _refreshShipping,
              icon: _isCalculatingShipping
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.calculate_outlined),
              label: Text(
                _isCalculatingShipping ? 'Calculando...' : 'Calcular envío',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0B5ED7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (_shippingMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _shippingMessage!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, CartItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _QuantityButton(
                      label: '-',
                      enabled: item.quantity > 1,
                      onTap: () => _updateQuantity(item, item.quantity - 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        item.quantity.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _QuantityButton(
                      label: '+',
                      enabled: item.quantity < item.product.stock,
                      onTap: () => _updateQuantity(item, item.quantity + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '\$${item.subtotal.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
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
                'Resumen',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Items', value: '$_totalQuantity productos'),
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
                : 'Pendiente',
          ),
          const Divider(height: 28),
          _SummaryRow(
            label: 'Total estimado',
            value: '\$${_estimatedTotal.toStringAsFixed(0)}',
            isTotal: true,
          ),
          const SizedBox(height: 16),
          if (_feedback != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(_feedback!),
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
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF1F5F9) : const Color(0xFFE9EDF3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? const Color(0xFFE5E7EB) : const Color(0xFFC9D2DD),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: enabled ? Colors.black87 : Colors.black38,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: const Color(0xFF0B5ED7)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
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
