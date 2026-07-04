import 'dart:async';

import 'package:shoefit/models/cart_item_model.dart';
import 'package:shoefit/models/shoe_model.dart';
import 'package:shoefit/services/api_client.dart';
import 'package:shoefit/services/api_readers.dart';

class CartService {
  CartService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Stream<List<CartItemModel>> streamCartItems(String userId) async* {
    while (true) {
      yield await fetchCartItems(userId);
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  Future<List<CartItemModel>> fetchCartItems(String userId) async {
    final data = readObject(
      await _apiClient.get(
        '/cart_list.php',
        queryParameters: {'user_id': userId},
      ),
    );
    return readListField(data, ['items', 'cart_items', 'data']).map((item) {
      final map = readObject(item, label: 'cart item');
      return CartItemModel.fromMap(map);
    }).toList();
  }

  Future<void> addToCart({
    required String userId,
    required ShoeModel shoe,
    required int selectedSize,
    required int quantity,
  }) async {
    await _apiClient.post(
      '/cart_add.php',
      body: {
        'user_id': userId,
        'shoe_id': _parseId(shoe.id),
        'selected_size': selectedSize,
        'quantity': quantity,
      },
    );
  }

  Future<void> updateQuantity({
    required String userId,
    required String cartItemId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeItem(userId: userId, cartItemId: cartItemId);
      return;
    }

    await _apiClient.post(
      '/cart_update.php',
      body: {
        'user_id': userId,
        'cart_item_id': _parseId(cartItemId),
        'quantity': quantity,
      },
    );
  }

  Future<void> removeItem({
    required String userId,
    required String cartItemId,
  }) async {
    await _apiClient.post(
      '/cart_remove.php',
      body: {'user_id': userId, 'cart_item_id': _parseId(cartItemId)},
    );
  }

  Future<void> clearCart(String userId) async {
    await _apiClient.post('/cart_clear.php', body: {'user_id': userId});
  }

  Object _parseId(String value) => int.tryParse(value) ?? value;
}
