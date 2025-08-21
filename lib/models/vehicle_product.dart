import 'package:girscope/utils/json_utils.dart';

class VehicleProduct {
  final String vehicleId;
  final String productId;
  final double? capacity;
  final String? businessId;

  VehicleProduct({
    required this.vehicleId,
    required this.productId,
    this.capacity,
    this.businessId,
  });

  factory VehicleProduct.fromJson(Map<String, dynamic> json) {
    return VehicleProduct(
      vehicleId: json['vehicle_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      capacity: json['capacity']?.toDouble(),
      businessId: safeStringValue(json['business_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'product_id': productId,
      'capacity': capacity,
      'business_id': businessId,
    };
  }
}
