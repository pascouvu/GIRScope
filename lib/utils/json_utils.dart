String safeStringValue(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is Map) return value['name']?.toString() ?? value.toString();
  return value.toString();
}