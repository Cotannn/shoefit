import 'package:shoefit/config/app_environment.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.address,
    required this.city,
    required this.state,
    required this.postcode,
    required this.createdAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String address;
  final String city;
  final String state;
  final String postcode;
  final DateTime createdAt;

  bool get isAdmin =>
      role.trim().toLowerCase() == 'admin' ||
      AppEnvironment.isAdminEmail(email);

  String get fullAddress => [
    address,
    city,
    state,
    postcode,
  ].where((item) => item.trim().isNotEmpty).join(', ');

  UserModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? address,
    String? city,
    String? state,
    String? postcode,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postcode: postcode ?? this.postcode,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'address': address,
      'city': city,
      'state': state,
      'postcode': postcode,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return UserModel(
      uid: documentId ?? _readString(_readAny(map, ['uid', 'id', 'user_id'])),
      fullName: _readString(_readAny(map, ['fullName', 'full_name', 'name'])),
      email: _readString(_readAny(map, ['email'])),
      phone: _readString(_readAny(map, ['phone'])),
      role: _readString(_readAny(map, ['role'])).isEmpty
          ? 'customer'
          : _readString(_readAny(map, ['role'])),
      address: _readString(_readAny(map, ['address'])),
      city: _readString(_readAny(map, ['city'])),
      state: _readString(_readAny(map, ['state'])),
      postcode: _readString(_readAny(map, ['postcode'])),
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

  static String _readString(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString();
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
