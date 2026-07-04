import 'package:shoefit/models/cart_item_model.dart';

class OrderModel {
  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.totalPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.stripePaymentId,
    required this.orderStatus,
    required this.orderDate,
  });

  final String orderId;
  final String userId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final List<CartItemModel> items;
  final double subtotal;
  final double shippingFee;
  final double totalPrice;
  final String paymentMethod;
  final String paymentStatus;
  final String stripePaymentId;
  final String orderStatus;
  final DateTime orderDate;

  int get itemCount =>
      items.fold(0, (runningTotal, item) => runningTotal + item.quantity);

  Map<String, dynamic> toMap() {
    return {
      'order_id': int.tryParse(orderId) ?? orderId,
      'user_id': userId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_address': deliveryAddress,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'shipping_fee': shippingFee,
      'total_price': totalPrice,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'stripe_payment_id': stripePaymentId,
      'order_status': orderStatus,
      'order_date': orderDate.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return OrderModel(
      orderId: _readString(_readAny(map, ['orderId', 'order_id'])).isEmpty
          ? id
          : _readString(_readAny(map, ['orderId', 'order_id'])),
      userId: _readString(_readAny(map, ['userId', 'user_id'])),
      customerName: _readString(
        _readAny(map, ['customerName', 'customer_name']),
      ),
      customerPhone: _readString(
        _readAny(map, ['customerPhone', 'customer_phone']),
      ),
      deliveryAddress: _readString(
        _readAny(map, ['deliveryAddress', 'delivery_address']),
      ),
      items: _readItems(_readAny(map, ['items'])),
      subtotal: _readDouble(_readAny(map, ['subtotal'])),
      shippingFee: _readDouble(_readAny(map, ['shippingFee', 'shipping_fee'])),
      totalPrice: _readDouble(_readAny(map, ['totalPrice', 'total_price'])),
      paymentMethod:
          _readString(
            _readAny(map, ['paymentMethod', 'payment_method']),
          ).isEmpty
          ? 'Demo card'
          : _readString(_readAny(map, ['paymentMethod', 'payment_method'])),
      paymentStatus:
          _readString(
            _readAny(map, ['paymentStatus', 'payment_status']),
          ).isEmpty
          ? 'pending'
          : _readString(_readAny(map, ['paymentStatus', 'payment_status'])),
      stripePaymentId: _readString(
        _readAny(map, ['stripePaymentId', 'stripe_payment_id']),
      ),
      orderStatus:
          _readString(_readAny(map, ['orderStatus', 'order_status'])).isEmpty
          ? 'Processing'
          : _readString(_readAny(map, ['orderStatus', 'order_status'])),
      orderDate: _readDate(_readAny(map, ['orderDate', 'order_date'])),
    );
  }

  static dynamic _readAny(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) {
        return map[key];
      }
    }
    return null;
  }

  static List<CartItemModel> _readItems(dynamic rawItems) {
    if (rawItems is! List) {
      return const [];
    }

    final items = <CartItemModel>[];
    for (var index = 0; index < rawItems.length; index++) {
      final rawItem = rawItems[index];
      if (rawItem is Map) {
        items.add(
          CartItemModel.fromMap(
            Map<String, dynamic>.from(rawItem),
            id: '${rawItem['id'] ?? rawItem['cart_item_id'] ?? 'item_$index'}',
          ),
        );
      }
    }
    return items;
  }

  static String _readString(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _readDate(dynamic rawValue) {
    if (rawValue is DateTime) {
      return rawValue;
    }
    if (rawValue is String) {
      final normalizedValue = rawValue.contains('T')
          ? rawValue
          : rawValue.replaceFirst(' ', 'T');
      return DateTime.tryParse(normalizedValue) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
