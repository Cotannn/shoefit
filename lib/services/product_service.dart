import 'dart:async';

import 'package:shoefit/models/shoe_model.dart';
import 'package:shoefit/services/api_client.dart';
import 'package:shoefit/services/api_readers.dart';

class ProductService {
  ProductService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Stream<List<ShoeModel>> streamProducts() async* {
    yield await fetchProducts();
  }

  Future<List<ShoeModel>> fetchProducts() async {
    final data = readObject(await _apiClient.get('/products.php'));
    return readListField(data, ['products', 'data']).map((item) {
      final map = readObject(item, label: 'product');
      return ShoeModel.fromMap(map);
    }).toList();
  }

  Future<void> addProduct(ShoeModel product) async {
    await _apiClient.post('/product_save.php', body: product.toMap());
  }

  Future<void> updateProduct(ShoeModel product) async {
    await _apiClient.post('/product_save.php', body: product.toMap());
  }

  Future<void> deleteProduct(String productId) async {
    final parsedId = _parseId(productId);
    await _apiClient.post(
      '/product_delete.php',
      body: {'id': parsedId, 'product_id': parsedId},
    );
  }

  Future<ShoeModel?> fetchProductById(String productId) async {
    final data = readObject(
      await _apiClient.get(
        '/product_detail.php',
        queryParameters: {'id': _parseId(productId)},
      ),
    );
    final product = readFirst(data, ['product', 'data']);
    if (product == null) {
      return null;
    }
    return ShoeModel.fromMap(readObject(product, label: 'product'));
  }

  Future<int> fetchProductCount() async {
    final data = readObject(await _apiClient.get('/test.php'));
    return readNum(
      readFirst(data, ['totalProducts', 'total_products']),
    ).toInt();
  }

  Object _parseId(String value) => int.tryParse(value) ?? value;
}
