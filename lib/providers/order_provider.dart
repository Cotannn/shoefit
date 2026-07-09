import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shoefit/models/order_model.dart';
import 'package:shoefit/services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider({required OrderService orderService})
    : _orderService = orderService;

  final OrderService _orderService;
  StreamSubscription<List<OrderModel>>? _userSubscription;
  StreamSubscription<List<OrderModel>>? _adminSubscription;
  String? _userId;
  bool _isAdmin = false;

  List<OrderModel> _orders = [];
  List<OrderModel> _adminOrders = [];
  bool _isLoading = false;
  bool _isAdminLoading = false;

  List<OrderModel> get orders => _orders;
  List<OrderModel> get adminOrders => _adminOrders;
  bool get isLoading => _isLoading;
  bool get isAdminLoading => _isAdminLoading;

  void bindUser(String? userId) {
    if (_userId == userId) {
      return;
    }

    _userId = userId;
    _userSubscription?.cancel();
    _orders = [];

    if (userId == null) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _userSubscription = _orderService
        .streamUserOrders(userId)
        .listen(
          (orders) {
            _orders = orders;
            _isLoading = false;
            notifyListeners();
          },
          onError: (_) {
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void bindAdmin(bool isAdmin) {
    if (_isAdmin == isAdmin) {
      return;
    }

    _isAdmin = isAdmin;
    _adminSubscription?.cancel();
    _adminOrders = [];

    if (!isAdmin) {
      notifyListeners();
      return;
    }

    _isAdminLoading = true;
    notifyListeners();

    _adminSubscription = _orderService.streamAllOrders().listen(
      (orders) {
        _adminOrders = orders;
        _isAdminLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isAdminLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _orderService.updateOrderStatus(orderId: orderId, status: status);
    _orders = _replaceStatus(_orders, orderId, status);
    _adminOrders = _replaceStatus(_adminOrders, orderId, status);
    notifyListeners();
  }

  Future<void> confirmOrderReceived({
    required String userId,
    required String orderId,
  }) async {
    await _orderService.confirmOrderReceived(userId: userId, orderId: orderId);
    _orders = _replaceStatus(_orders, orderId, 'Completed');
    _adminOrders = _replaceStatus(_adminOrders, orderId, 'Completed');
    notifyListeners();
  }

  Future<void> refreshAdminOrders() async {
    if (!_isAdmin) {
      return;
    }
    final orders = await _orderService.fetchAllOrders();
    _adminOrders = orders;
    notifyListeners();
  }

  Future<Map<String, num>> fetchDashboardStats() {
    return _orderService.fetchDashboardStats();
  }

  List<OrderModel> _replaceStatus(
    List<OrderModel> source,
    String orderId,
    String status,
  ) {
    return source
        .map(
          (order) => order.orderId == orderId
              ? order.copyWith(orderStatus: status)
              : order,
        )
        .toList();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _adminSubscription?.cancel();
    super.dispose();
  }
}
