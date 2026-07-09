import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shoefit/models/shoe_model.dart';
import 'package:shoefit/services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider({required ProductService productService})
    : _productService = productService {
    _subscription = _productService.streamProducts().listen(
      (products) {
        _products = products;
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

  final ProductService _productService;
  late final StreamSubscription<List<ShoeModel>> _subscription;

  List<ShoeModel> _products = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  List<ShoeModel> get products => _products;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  List<ShoeModel> get featuredProducts =>
      _products.where((product) => product.isFeatured).toList();
  List<ShoeModel> get newArrivals =>
      _products.where((product) => product.isNewArrival).toList();
  List<ShoeModel> get popularProducts {
    final cloned = [..._products];
    cloned.sort((a, b) => b.rating.compareTo(a.rating));
    return cloned.take(10).toList();
  }

  Future<void> addProduct(ShoeModel product) =>
      _runSave(() => _productService.addProduct(product));

  Future<void> updateProduct(ShoeModel product) =>
      _runSave(() => _productService.updateProduct(product));

  Future<void> deleteProduct(String productId) =>
      _runSave(() => _productService.deleteProduct(productId));

  Future<void> refreshProducts() async {
    _errorMessage = null;
    try {
      _products = await _productService.fetchProducts();
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _runSave(Future<void> Function() action) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      _products = await _productService.fetchProducts();
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
