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
      price:
          (map['precio'] as num?)?.toDouble() ??
          (map['price'] as num?)?.toDouble() ??
          0,
      description: map['description']?.toString() ?? '',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
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
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
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
      productPrice: (map['productPrice'] as num?)?.toDouble() ?? 0,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0,
      shippingCost: (map['shippingCost'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      paymentUrl: map['paymentUrl']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      destinationAddress: map['destinationAddress']?.toString() ?? '',
    );
  }
}
