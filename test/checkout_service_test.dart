import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/checkout_models.dart';
import 'package:myapp/services/checkout_service.dart';

void main() {
  group('CheckoutService', () {
    test('calcula el total con envío y genera un link de pago', () async {
      final service = CheckoutService();
      final product = StoreProduct(
        id: 'p1',
        name: 'Pelota Oficial',
        price: 2500,
        description: 'Pelota para entrenamiento',
        stock: 10,
      );

      final result = await service.createCheckout(
        orderTitle: product.name,
        itemsTotalAmount: product.price.toDouble(),
        originAddress: 'Rosario Centro, Santa Fe',
        destinationAddress: 'Funes, Santa Fe',
        shippingRatePerKm: 120,
      );

      expect(result.totalAmount, greaterThan(product.price.toDouble()));
      expect(result.paymentUrl, startsWith('https://'));
      expect(result.distanceKm, greaterThan(0));
      expect(result.orderId, isNotEmpty);
    });
  });
}
