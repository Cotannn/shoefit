import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shoefit/config/app_environment.dart';
import 'package:shoefit/models/cart_item_model.dart';
import 'package:shoefit/models/shoe_model.dart';
import 'package:shoefit/services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  CartProvider({required CartService cartService}) : _cartService = cartService;

  final CartService _cartService;
  StreamSubscription<List<CartItemModel>>? _subscription;
  String? _userId;

  List<CartItemModel> _items = [];
  bool _isLoading = false;
  bool _isMutating = false;
  String? _errorMessage;

  List<CartItemModel> get items => _items;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get errorMessage => _errorMessage;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get shippingFee => _items.isEmpty ? 0 : AppEnvironment.shippingFee;
  double get total => subtotal + shippingFee;

  void bindUser(String? userId) {
    if (_userId == userId) {
      return;
    }

    _userId = userId;
    _subscription?.cancel();
    _items = [];

    if (userId == null) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _subscription = _cartService
        .streamCartItems(userId)
        .listen(
          (items) {
            _items = items;
            _isLoading = false;
            notifyListeners();
          },
          onError: (Object error) {
            _errorMessage = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> addToCart({
    required ShoeModel shoe,
    required int selectedSize,
    required int quantity,
  }) async {
    final userId = _requireUser();
    await _runMutation(() {
      return _cartService.addToCart(
        userId: userId,
        shoe: shoe,
        selectedSize: selectedSize,
        quantity: quantity,
      );
    });
  }

  Future<void> incrementItem(CartItemModel item) {
    return updateQuantity(item: item, quantity: item.quantity + 1);
  }

  Future<void> decrementItem(CartItemModel item) {
    return updateQuantity(item: item, quantity: item.quantity - 1);
  }

  Future<void> updateQuantity({
    required CartItemModel item,
    required int quantity,
  }) async {
    final userId = _requireUser();
    await _runMutation(() {
      return _cartService.updateQuantity(
        userId: userId,
        cartItemId: item.id,
        quantity: quantity,
      );
    });
  }

  Future<void> removeItem(CartItemModel item) async {
    final userId = _requireUser();
    await _runMutation(() {
      return _cartService.removeItem(userId: userId, cartItemId: item.id);
    });
  }

  Future<void> clearCart() async {
    final userId = _requireUser();
    await _runMutation(() => _cartService.clearCart(userId));
  }

  String _requireUser() {
    final userId = _userId;
    if (userId == null) {
      throw Exception('Please sign in to continue.');
    }
    return userId;
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    _isMutating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
