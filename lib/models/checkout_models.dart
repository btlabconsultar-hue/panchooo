double _parseDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) {
    return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
  }
  return 0.0;
}

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    return int.tryParse(v) ??
        double.tryParse(v.replaceAll(',', '.'))?.toInt() ??
        0;
  }
  return 0;
}

class ShippingAddress {
  const ShippingAddress({
    required this.province,
    required this.locality,
    required this.address,
  });

  final String province;
  final String locality;
  final String address;

  String get fullAddress {
    final parts = <String>[
      address,
      locality,
      province,
    ].where((value) => value.trim().isNotEmpty).toList();
    return parts.join(', ');
  }
}

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.stock,
    this.imageUrl,
  });

  final String id;
  final String name;
  final double price;
  final String description;
  final int stock;
  final String? imageUrl;

  StoreProduct copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    int? stock,
    String? imageUrl,
  }) {
    return StoreProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toFirestoreMap() => {
    'id': id,
    'titulo': name,
    'precio': price,
    'description': description,
    'stock': stock,
    'imageUrl': imageUrl,
  };

  factory StoreProduct.fromFirestoreMap(Map<String, dynamic> map) {
    return StoreProduct(
      id: map['id']?.toString() ?? '',
      name: map['titulo']?.toString() ?? map['name']?.toString() ?? 'Producto',
      price: _parseDouble(map['precio'] ?? map['price']),
      description: map['description']?.toString() ?? '',
      stock: _parseInt(map['stock']),
      imageUrl: map['imageUrl']?.toString(),
    );
  }
}

class CartItem {
  const CartItem({required this.product, required this.quantity});

  final StoreProduct product;
  final int quantity;

  double get subtotal => product.price * quantity;

  Map<String, dynamic> toMap() => {
    'product': product.toFirestoreMap(),
    'quantity': quantity,
  };

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: StoreProduct.fromFirestoreMap(
        map['product'] as Map<String, dynamic>,
      ),
      quantity: _parseInt(map['quantity']),
    );
  }
}

class CheckoutResult {
  const CheckoutResult({
    required this.orderId,
    required this.distanceKm,
    required this.shippingCost,
    required this.totalAmount,
    required this.paymentUrl,
    required this.message,
    required this.productPrice,
  });

  final String orderId;
  final double distanceKm;
  final double shippingCost;
  final double totalAmount;
  final String paymentUrl;
  final String message;
  final double productPrice;
}

class CheckoutOrder {
  const CheckoutOrder({
    required this.id,
    required this.productName,
    required this.productPrice,
    required this.distanceKm,
    required this.shippingCost,
    required this.totalAmount,
    required this.paymentUrl,
    required this.createdAt,
    required this.destinationAddress,
  });

  final String id;
  final String productName;
  final double productPrice;
  final double distanceKm;
  final double shippingCost;
  final double totalAmount;
  final String paymentUrl;
  final DateTime createdAt;
  final String destinationAddress;

  Map<String, dynamic> toFirestoreMap() => {
    'id': id,
    'productName': productName,
    'productPrice': productPrice,
    'distanceKm': distanceKm,
    'shippingCost': shippingCost,
    'totalAmount': totalAmount,
    'paymentUrl': paymentUrl,
    'createdAt': createdAt.toIso8601String(),
    'destinationAddress': destinationAddress,
  };

  factory CheckoutOrder.fromFirestoreMap(Map<String, dynamic> map) {
    return CheckoutOrder(
      id: map['id']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      productPrice: _parseDouble(map['productPrice']),
      distanceKm: _parseDouble(map['distanceKm']),
      shippingCost: _parseDouble(map['shippingCost']),
      totalAmount: _parseDouble(map['totalAmount']),
      paymentUrl: map['paymentUrl']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      destinationAddress: map['destinationAddress']?.toString() ?? '',
    );
  }
}
