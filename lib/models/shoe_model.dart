class ShoeModel {
  const ShoeModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.rating,
    required this.description,
    required this.imageUrl,
    required this.sizes,
    required this.material,
    required this.suitableUse,
    required this.stock,
    required this.isFeatured,
    required this.isNewArrival,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final double rating;
  final String description;
  final String imageUrl;
  final List<int> sizes;
  final String material;
  final String suitableUse;
  final int stock;
  final bool isFeatured;
  final bool isNewArrival;
  final DateTime createdAt;

  bool get isOutOfStock => stock <= 0;

  ShoeModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? category,
    double? price,
    double? rating,
    String? description,
    String? imageUrl,
    List<int>? sizes,
    String? material,
    String? suitableUse,
    int? stock,
    bool? isFeatured,
    bool? isNewArrival,
    DateTime? createdAt,
  }) {
    return ShoeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sizes: sizes ?? this.sizes,
      material: material ?? this.material,
      suitableUse: suitableUse ?? this.suitableUse,
      stock: stock ?? this.stock,
      isFeatured: isFeatured ?? this.isFeatured,
      isNewArrival: isNewArrival ?? this.isNewArrival,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'brand': brand,
      'category': category,
      'price': price,
      'rating': rating,
      'description': description,
      'image_url': imageUrl,
      'sizes': sizes,
      'material': material,
      'suitable_use': suitableUse,
      'stock': stock,
      'is_featured': isFeatured,
      'is_new_arrival': isNewArrival,
      'created_at': createdAt.toIso8601String(),
    };
    if (id.trim().isNotEmpty) {
      map['id'] = int.tryParse(id) ?? id;
    }
    return map;
  }

  factory ShoeModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return ShoeModel(
      id: id ?? _readString(_readAny(map, ['id', 'product_id'])),
      name: _readString(_readAny(map, ['name'])),
      brand: _readString(_readAny(map, ['brand'])),
      category: _readString(_readAny(map, ['category'])),
      price: _readDouble(_readAny(map, ['price'])),
      rating: _readDouble(_readAny(map, ['rating'])),
      description: _readString(_readAny(map, ['description'])),
      imageUrl: _readString(_readAny(map, ['imageUrl', 'image_url'])),
      sizes: _readSizes(_readAny(map, ['sizes'])),
      material: _readString(_readAny(map, ['material'])),
      suitableUse: _readString(_readAny(map, ['suitableUse', 'suitable_use'])),
      stock: _readInt(_readAny(map, ['stock'])),
      isFeatured: _readBool(_readAny(map, ['isFeatured', 'is_featured'])),
      isNewArrival: _readBool(
        _readAny(map, ['isNewArrival', 'is_new_arrival']),
      ),
      createdAt: _readDate(_readAny(map, ['createdAt', 'created_at'])),
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

  static List<int> _readSizes(dynamic rawSizes) {
    if (rawSizes is List) {
      return rawSizes
          .map((item) {
            if (item is num) {
              return item.toInt();
            }
            return int.tryParse(item.toString());
          })
          .whereType<int>()
          .toList();
    }

    if (rawSizes is String) {
      return rawSizes
          .split(',')
          .map((item) => int.tryParse(item.trim()))
          .whereType<int>()
          .toList();
    }

    return const [];
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

  static bool _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  static DateTime _readDate(dynamic rawValue) {
    if (rawValue is DateTime) {
      return rawValue;
    }
    if (rawValue is String) {
      final normalizedValue = rawValue.contains('T')
          ? rawValue
          : rawValue.replaceFirst(' ', 'T');
      return DateTime.tryParse(normalizedValue) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
