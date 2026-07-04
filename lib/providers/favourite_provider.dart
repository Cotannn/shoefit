import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shoefit/services/favourite_service.dart';

class FavouriteProvider extends ChangeNotifier {
  FavouriteProvider({required FavouriteService favouriteService})
    : _favouriteService = favouriteService;

  final FavouriteService _favouriteService;
  StreamSubscription<Set<String>>? _subscription;
  String? _userId;

  Set<String> _favouriteIds = <String>{};
  bool _isLoading = false;
  bool _isMutating = false;

  Set<String> get favouriteIds => _favouriteIds;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;

  void bindUser(String? userId) {
    if (_userId == userId) {
      return;
    }

    _userId = userId;
    _subscription?.cancel();
    _favouriteIds = <String>{};

    if (userId == null) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    _subscription = _favouriteService.streamFavouriteIds(userId).listen((ids) {
      _favouriteIds = ids;
      _isLoading = false;
      notifyListeners();
    });
  }

  bool isFavourite(String productId) => _favouriteIds.contains(productId);

  Future<void> toggleFavourite(String productId) async {
    final userId = _userId;
    if (userId == null) {
      throw Exception('Please sign in to save favourites.');
    }

    _isMutating = true;
    notifyListeners();

    try {
      await _favouriteService.toggleFavourite(
        userId: userId,
        productId: productId,
      );
      final isFavourite = await _favouriteService.fetchFavouriteStatus(
        userId: userId,
        productId: productId,
      );
      final updatedIds = {..._favouriteIds};
      if (isFavourite) {
        updatedIds.add(productId);
      } else {
        updatedIds.remove(productId);
      }
      _favouriteIds = updatedIds;
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
