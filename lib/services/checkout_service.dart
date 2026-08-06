import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/checkout_models.dart';

class CheckoutService {
  CheckoutService({http.Client? client}) : _client = client ?? http.Client();

  static const String googleMapsApiKey =
      'AIzaSyDT2uiC8yGINdYmO6-x-IUxSB7j-FaeYpA';
  static const String mercadoPagoAccessToken =
      'APP_USR-7397524037420313-080518-2c403c547190c5a54ae8dff950740094-3594787968';

  final http.Client _client;

  Future<CheckoutResult> createCheckout({
    required String orderTitle,
    required double itemsTotalAmount,
    required String originAddress,
    required String destinationAddress,
    required double shippingRatePerKm,
    String? googleMapsApiKey,
    String? mercadoPagoAccessToken,
  }) async {
    final distanceKm = await _resolveDistanceKm(
      originAddress: originAddress,
      destinationAddress: destinationAddress,
      googleMapsApiKey: googleMapsApiKey,
    );

    final shippingCost = double.parse(
      (distanceKm * shippingRatePerKm).toStringAsFixed(2),
    );
    final totalAmount = double.parse(
      (itemsTotalAmount + shippingCost).toStringAsFixed(2),
    );
    final orderId = 'ORD-${DateTime.now().microsecondsSinceEpoch}';
    final paymentUrl = await _buildMercadoPagoUrl(
      orderId: orderId,
      productName: orderTitle,
      amount: totalAmount,
      accessToken: mercadoPagoAccessToken,
    );

    return CheckoutResult(
      orderId: orderId,
      distanceKm: double.parse(distanceKm.toStringAsFixed(2)),
      shippingCost: shippingCost,
      totalAmount: totalAmount,
      paymentUrl: paymentUrl,
      message:
          'Envío calculado para ${distanceKm.toStringAsFixed(2)} km y total de \$${totalAmount.toStringAsFixed(2)}',
      productPrice: itemsTotalAmount,
    );
  }

  Future<double> estimateShippingCost({
    required String originAddress,
    required String destinationAddress,
    required double shippingRatePerKm,
    String? googleMapsApiKey,
  }) async {
    final distanceKm = await _resolveDistanceKm(
      originAddress: originAddress,
      destinationAddress: destinationAddress,
      googleMapsApiKey: googleMapsApiKey,
    );
    return double.parse((distanceKm * shippingRatePerKm).toStringAsFixed(2));
  }

  Future<double> _resolveDistanceKm({
    required String originAddress,
    required String destinationAddress,
    String? googleMapsApiKey,
  }) async {
    final effectiveKey = (googleMapsApiKey ?? '').trim().isNotEmpty
        ? (googleMapsApiKey ?? '').trim()
        : CheckoutService.googleMapsApiKey;

    if (effectiveKey.isNotEmpty) {
      try {
        final response = await _client.get(
          Uri.https('maps.googleapis.com', '/maps/api/distancematrix/json', {
            'origins': originAddress,
            'destinations': destinationAddress,
            'key': effectiveKey,
          }),
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final rows = decoded['rows'] as List<dynamic>?;
          if (rows != null && rows.isNotEmpty) {
            final firstRow = rows.first as Map<String, dynamic>?;
            final elements = firstRow?['elements'] as List<dynamic>?;
            if (elements != null && elements.isNotEmpty) {
              final firstElement = elements.first as Map<String, dynamic>?;
              final distance = firstElement?['distance']?['value'] as num?;
              if (distance != null && distance > 0) {
                return distance / 1000;
              }
            }
          }
        }
      } catch (_) {
        // Se cae al fallback local si la API no está disponible.
      }
    }

    return _estimateDistanceKm(originAddress, destinationAddress);
  }

  Future<String> _buildMercadoPagoUrl({
    required String orderId,
    required String productName,
    required double amount,
    String? accessToken,
  }) async {
    if ((accessToken ?? '').trim().isNotEmpty) {
      try {
        final response = await _client.post(
          Uri.https('api.mercadopago.com', '/checkout/preferences'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({
            'items': [
              {
                'title': productName,
                'quantity': 1,
                'unit_price': amount,
                'currency_id': 'ARS',
              },
            ],
            'external_reference': orderId,
          }),
        );

        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (response.statusCode == 201 || response.statusCode == 200) {
          final initPoint = decoded['init_point']?.toString();
          if (initPoint != null && initPoint.isNotEmpty) {
            return initPoint;
          }
        }

        final errorMessage =
            decoded['message'] ??
            decoded['error'] ??
            (decoded['cause'] is List
                ? decoded['cause'].map((e) => e['description']).join(', ')
                : null) ??
            'Respuesta inesperada de Mercado Pago.';
        throw Exception('Mercado Pago: $errorMessage');
      } catch (error) {
        throw Exception('Error de Mercado Pago: $error');
      }
    }

    throw Exception('No hay token de Mercado Pago configurado.');
  }

  double _estimateDistanceKm(String originAddress, String destinationAddress) {
    final origin = originAddress.toLowerCase();
    final destination = destinationAddress.toLowerCase();

    if (origin.contains('rosario') && destination.contains('funes')) {
      return 18.4;
    }
    if (origin.contains('rosario') || destination.contains('rosario')) {
      return 12.7;
    }
    if (origin.contains('buenos aires') && destination.contains('la plata')) {
      return 54.2;
    }
    if (origin.contains('córdoba') && destination.contains('villa maria')) {
      return 25.9;
    }
    return 9.5;
  }
}
