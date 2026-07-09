import 'dart:async';

import 'package:shoefit/services/api_client.dart';
import 'package:shoefit/services/api_readers.dart';

class FavouriteService {
  FavouriteService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Stream<Set<String>> streamFavouriteIds(String userId) async* {
    yield await fetchFavouriteIds(userId);
  }

  Future<Set<String>> fetchFavouriteIds(String userId) async {
    final data = readObject(
      await _apiClient.get(
        '/favourites.php',
        queryParameters: {'user_id': userId},
      ),
    );

    final ids = <String>{};
    for (final key in ['favourites', 'products', 'data']) {
      for (final item in readList(data[key])) {
        if (item is Map) {
          final map = readObject(item, label: 'favourite');
          final productId = readString(
            readFirst(map, ['product_id', 'id', 'shoe_id']),
          );
          if (productId.isNotEmpty) {
            ids.add(productId);
          }
          continue;
        }

        final productId = readString(item);
        if (productId.isNotEmpty) {
          ids.add(productId);
        }
      }
    }

    return ids;
  }

  Future<void> toggleFavourite({
    required String userId,
    required String productId,
  }) async {
    await _apiClient.post(
      '/favourite_toggle.php',
      body: {'user_id': userId, 'product_id': _parseId(productId)},
    );
  }

  Future<bool> fetchFavouriteStatus({
    required String userId,
    required String productId,
  }) async {
    final data = readObject(
      await _apiClient.get(
        '/favourite_status.php',
        queryParameters: {'user_id': userId, 'product_id': _parseId(productId)},
      ),
    );
    return readBool(readFirst(data, ['is_favourite', 'isFavourite']));
  }

  Object _parseId(String value) => int.tryParse(value) ?? value;
}
