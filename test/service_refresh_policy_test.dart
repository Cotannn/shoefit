import 'package:flutter_test/flutter_test.dart';
import 'package:shoefit/services/api_client.dart';
import 'package:shoefit/services/cart_service.dart';
import 'package:shoefit/services/favourite_service.dart';
import 'package:shoefit/services/order_service.dart';
import 'package:shoefit/services/product_service.dart';

void main() {
  test('data streams perform one initial request and then close', () async {
    final client = _ReadRecordingApiClient();

    final results = await Future.wait([
      ProductService(
        apiClient: client,
      ).streamProducts().toList().timeout(const Duration(seconds: 1)),
      CartService(
        apiClient: client,
      ).streamCartItems('user_1').toList().timeout(const Duration(seconds: 1)),
      FavouriteService(apiClient: client)
          .streamFavouriteIds('user_1')
          .toList()
          .timeout(const Duration(seconds: 1)),
      OrderService(
        apiClient: client,
      ).streamUserOrders('user_1').toList().timeout(const Duration(seconds: 1)),
      OrderService(
        apiClient: client,
      ).streamAllOrders().toList().timeout(const Duration(seconds: 1)),
    ]);

    expect(results.every((events) => events.length == 1), isTrue);
    expect(client.getCalls, hasLength(5));
  });
}

class _ReadRecordingApiClient extends ApiClient {
  final List<String> getCalls = [];

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    getCalls.add(path);
    if (path == '/products.php') {
      return {'products': <dynamic>[]};
    }
    if (path == '/cart_list.php') {
      return {'items': <dynamic>[]};
    }
    if (path == '/favourites.php') {
      return {'favourites': <dynamic>[]};
    }
    return {'orders': <dynamic>[]};
  }
}
