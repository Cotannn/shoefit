Map<String, dynamic> readObject(dynamic value, {String label = 'response'}) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  throw Exception('The ShoeFit API returned an invalid $label.');
}

dynamic readFirst(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (map.containsKey(key) && map[key] != null) {
      return map[key];
    }
  }
  return null;
}

Map<String, dynamic> readObjectField(
  Map<String, dynamic> map,
  List<String> keys, {
  String label = 'response object',
}) {
  final value = readFirst(map, keys);
  if (value == null) {
    throw Exception('The ShoeFit API did not return a valid $label.');
  }
  return readObject(value, label: label);
}

List<dynamic> readListField(Map<String, dynamic> map, List<String> keys) {
  return readList(readFirst(map, keys));
}

List<dynamic> readList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const [];
}

String readString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final stringValue = value.toString();
  return stringValue.isEmpty ? fallback : stringValue;
}

num readNum(dynamic value, {num fallback = 0}) {
  if (value is num) {
    return value;
  }
  if (value is String) {
    return num.tryParse(value) ?? fallback;
  }
  return fallback;
}

bool readBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return fallback;
  }
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}
