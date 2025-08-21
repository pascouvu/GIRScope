import 'package:girscope/utils/json_utils.dart';

class Product {
  final String id;
  final String name;
  final double? capacity;
  final String? businessId;

  Product({
    required this.id,
    required this.name,
    this.capacity,
    this.businessId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: safeStringValue(json['name']),
      capacity: json['capacity']?.toDouble(),
      businessId: safeStringValue(json['business_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'business_id': businessId,
    };
  }
}
