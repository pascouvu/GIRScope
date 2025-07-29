import 'package:girscope/utils/json_utils.dart';

class Vehicle {
  final String id;
  final String name;
  final String badge;
  final String? pubsnBadge;
  final String? ctrlBadge;
  final String code;
  final String? pinCode;
  final String model;
  final String? departmentId;
  final String departmentName;
  final double? odometer;
  final double? hourMeter;
  final String? notes;
  final List<VTank> vtanks;

  Vehicle({
    required this.id,
    required this.name,
    required this.badge,
    this.pubsnBadge,
    this.ctrlBadge,
    required this.code,
    this.pinCode,
    required this.model,
    this.departmentId,
    required this.departmentName,
    this.odometer,
    this.hourMeter,
    this.notes,
    required this.vtanks,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id']?.toString() ?? '0';
      
      final vtanks = (json['vtanks'] as List<dynamic>?)
          ?.map((vtank) => VTank.fromJson(vtank))
          .toList() ?? [];
      
      return Vehicle(
        id: id,
        name: safeStringValue(json['name']),
        badge: safeStringValue(json['badge']),
        pubsnBadge: safeStringValue(json['pubsn_badge']),
        ctrlBadge: safeStringValue(json['ctrl_badge']),
        code: safeStringValue(json['code']),
        pinCode: safeStringValue(json['pin_code']),
        model: safeStringValue(json['model']),
        departmentId: safeStringValue(json['department']?['id']),
        departmentName: safeStringValue(json['department']?['name'] ?? json['department']),
        odometer: json['kmeter']?.toDouble(),
        hourMeter: json['hmeter']?.toDouble(),
        notes: safeStringValue(json['notes']),
        vtanks: vtanks,
      );
    } catch (e) {
      print('Vehicle.fromJson - Error parsing vehicle: $e');
      print('Vehicle.fromJson - JSON data: $json');
      rethrow;
    }
  }
  
  

  String get displayBadge => badge.isNotEmpty ? badge : code;
}

class VTank {
  final String id;
  final String product;
  final double? capacity;

  VTank({
    required this.id,
    required this.product,
    this.capacity,
  });

  factory VTank.fromJson(Map<String, dynamic> json) {
    try {
      return VTank(
        id: json['id']?.toString() ?? '',
        product: safeStringValue(json['product']),
        capacity: json['capacity']?.toDouble(),
      );
    } catch (e) {
      print('VTank.fromJson - Error parsing vtank: $e');
      print('VTank.fromJson - JSON data: $json');
      rethrow;
    }
  }
}