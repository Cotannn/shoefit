import 'dart:async';

import 'package:shoefit/models/order_model.dart';
import 'package:shoefit/services/api_client.dart';
import 'package:shoefit/services/api_readers.dart';

class OrderService {
  OrderService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Stream<List<OrderModel>> streamUserOrders(String userId) async* {
    while (true) {
      yield await fetchUserOrders(userId);
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  Stream<List<OrderModel>> streamAllOrders() async* {
    while (true) {
      yield await fetchAllOrders();
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  Future<List<OrderModel>> fetchUserOrders(String userId) async {
    final data = readObject(
      await _apiClient.get('/orders.php', queryParameters: {'user_id': userId}),
    );
    return _readOrders(data);
  }

  Future<List<OrderModel>> fetchAllOrders() async {
    final data = readObject(await _apiClient.get('/admin_orders.php'));
    return _readOrders(data);
  }

  Future<OrderModel> fetchOrderDetail({
    required String userId,
    required String orderId,
  }) async {
    final data = readObject(
      await _apiClient.get(
        '/order_detail.php',
        queryParameters: {'user_id': userId, 'order_id': _parseId(orderId)},
      ),
    );
    final order = readObjectField(data, ['order', 'data'], label: 'order');
    return OrderModel.fromMap(order, id: orderId);
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _apiClient.post(
      '/order_status_update.php',
      body: {'order_id': _parseId(orderId), 'order_status': status},
    );
  }

  Future<void> confirmOrderReceived({
    required String userId,
    required String orderId,
  }) async {
    if (userId.trim().isEmpty) {
      throw Exception('Please sign in again to confirm this order.');
    }

    await _apiClient.post(
      '/confirm_order_received.php',
      body: {'user_id': userId, 'order_id': _parseId(orderId)},
    );
  }

  Future<Map<String, num>> fetchDashboardStats() async {
    final data = readObject(await _apiClient.get('/test.php'));
    List<OrderModel> adminOrders = const [];
    try {
      adminOrders = await fetchAllOrders();
    } catch (_) {
      adminOrders = const [];
    }

    final pendingOrders = adminOrders.where((order) {
      final normalizedStatus = order.orderStatus.trim().toLowerCase();
      return normalizedStatus != 'delivered' && normalizedStatus != 'cancelled';
    }).length;
    final totalSales = adminOrders.fold<num>(
      0,
      (runningTotal, order) => runningTotal + order.totalPrice,
    );

    return {
      'totalProducts': readNum(
        readFirst(data, ['totalProducts', 'total_products']),
      ),
      'totalUsers': readNum(readFirst(data, ['totalUsers', 'total_users'])),
      'totalOrders': adminOrders.length,
      'pendingOrders': pendingOrders,
      'totalSales': totalSales,
    };
  }

  List<OrderModel> _readOrders(Map<String, dynamic> data) {
    return readListField(data, ['orders', 'data']).map((item) {
      final map = readObject(item, label: 'order');
      return OrderModel.fromMap(
        map,
        id: '${readFirst(map, ['order_id', 'orderId', 'id']) ?? ''}',
      );
    }).toList();
  }

  Object _parseId(String value) => int.tryParse(value) ?? value;
}
