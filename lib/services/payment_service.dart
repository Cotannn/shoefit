import 'package:shoefit/config/app_environment.dart';
import 'package:shoefit/models/cart_item_model.dart';
import 'package:shoefit/models/order_model.dart';
import 'package:shoefit/models/user_model.dart';
import 'package:shoefit/services/api_client.dart';
import 'package:shoefit/services/api_readers.dart';
import 'package:shoefit/services/order_service.dart';

class PaymentService {
  PaymentService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient() {
    _orderService = OrderService(apiClient: _apiClient);
  }

  final ApiClient _apiClient;
  late final OrderService _orderService;

  Future<OrderModel> checkout({
    required UserModel user,
    required List<CartItemModel> items,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
  }) async {
    if (items.isEmpty) {
      throw Exception('Your cart is empty.');
    }

    final shippingFee = AppEnvironment.shippingFee;

    final data = readObject(
      await _apiClient.post(
        '/checkout.php',
        body: {
          'user_id': user.uid,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'delivery_address': deliveryAddress,
          'payment_method': 'Demo card',
          'payment_status': 'paid',
          'shipping_fee': shippingFee,
        },
      ),
    );

    final orderData = _tryReadOrderPayload(data);
    if (orderData != null) {
      return OrderModel.fromMap(
        orderData,
        id: '${readFirst(orderData, ['order_id', 'orderId', 'id']) ?? ''}',
      );
    }

    final orderId = readString(readFirst(data, ['order_id', 'orderId', 'id']));
    if (orderId.isNotEmpty) {
      return _fetchOrderDetail(user.uid, orderId);
    }

    final orders = await _orderService.fetchUserOrders(user.uid);
    if (orders.isEmpty) {
      throw Exception(
        'Checkout completed but the API did not return the new order.',
      );
    }

    final latestOrders = [...orders]
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
    final latestOrder = latestOrders.first;
    if (latestOrder.items.isNotEmpty) {
      return latestOrder;
    }

    return _fetchOrderDetail(
      user.uid,
      latestOrder.orderId,
      fallback: latestOrder,
    );
  }

  Future<OrderModel> _fetchOrderDetail(
    String userId,
    String orderId, {
    OrderModel? fallback,
  }) async {
    try {
      return await _orderService.fetchOrderDetail(
        userId: userId,
        orderId: orderId,
      );
    } catch (_) {
      if (fallback != null) {
        return fallback;
      }
      rethrow;
    }
  }

  Map<String, dynamic>? _tryReadOrderPayload(Map<String, dynamic> data) {
    final rawOrder = readFirst(data, ['order', 'data']);
    if (rawOrder is Map) {
      return readObject(rawOrder, label: 'order');
    }
    return null;
  }
}
