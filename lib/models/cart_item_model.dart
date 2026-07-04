class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.shoeId,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.selectedSize,
    required this.price,
    required this.quantity,
  });

  final String id;
  final String shoeId;
  final String name;
  final String brand;
  final String imageUrl;
  final int selectedSize;
  final double price;
  final int quantity;

  double get totalPrice => price * quantity;

  CartItemModel copyWith({int? selectedSize, int? quantity}) {
    return CartItemModel(
      id: id,
      shoeId: shoeId,
      name: name,
      brand: brand,
      imageUrl: imageUrl,
      selectedSize: selectedSize ?? this.selectedSize,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': int.tryParse(id) ?? id,
      'shoe_id': int.tryParse(shoeId) ?? shoeId,
      'name': name,
      'brand': brand,
      'image_url': imageUrl,
      'selected_size': selectedSize,
      'price': price,
      'quantity': quantity,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return CartItemModel(
      id: id ?? _readString(_readAny(map, ['id', 'cart_item_id'])),
      shoeId: _readString(_readAny(map, ['shoeId', 'shoe_id', 'product_id'])),
      name: _readString(_readAny(map, ['name'])),
      brand: _readString(_readAny(map, ['brand'])),
      imageUrl: _readString(_readAny(map, ['imageUrl', 'image_url'])),
      selectedSize: _readInt(_readAny(map, ['selectedSize', 'selected_size'])),
      price: _readDouble(_readAny(map, ['price'])),
      quantity: _readInt(_readAny(map, ['quantity'])),
    );
  }

  static dynamic _readAny(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) {
        return map[key];
      }
    }
    return null;
  }

  static String _readString(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
