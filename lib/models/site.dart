import 'package:girscope/utils/json_utils.dart';

class Site {
  final String id;
  final String name;
  final String? code;
  final String? address;
  final String? city;
  final String? zipCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? businessId;
  final List<Tank> tanks;
  final List<Pump> pumps;
  final List<Controller> controllers;

  Site({
    required this.id,
    required this.name,
    this.code,
    this.address,
    this.city,
    this.zipCode,
    this.country,
    this.latitude,
    this.longitude,
    this.businessId,
    required this.tanks,
    required this.pumps,
    required this.controllers,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id']?.toString() ?? '',
      name: safeStringValue(json['name']),
      code: safeStringValue(json['code']),
      address: safeStringValue(json['address']),
      city: safeStringValue(json['city']),
      zipCode: safeStringValue(json['zip_code']),
      country: safeStringValue(json['country']),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      businessId: safeStringValue(json['business_id']),
      tanks: (json['tanks'] as List<dynamic>?)
          ?.map((tank) => Tank.fromJson(tank))
          .toList() ?? [],
      pumps: (json['pumps'] as List<dynamic>?)
          ?.map((pump) => Pump.fromJson(pump))
          .toList() ?? [],
      controllers: (json['controllers'] as List<dynamic>?)
          ?.map((controller) => Controller.fromJson(controller))
          .toList() ?? [],
    );
  }

  String get coordinates => (latitude != null && longitude != null) 
      ? '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}'
      : 'No coordinates';
}

class ProductRef {
  final String id;
  final String name;

  ProductRef({required this.id, required this.name});

  factory ProductRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ProductRef(id: '', name: '');
    return ProductRef(
      id: json['id']?.toString() ?? '',
      name: safeStringValue(json['name']),
    );
  }
}

class Tank {
  final String id;
  final String name;
  final ProductRef? product;
  final double? capacity;
  final double? volume;
  final DateTime? volumeDate;
  final String? businessId;

  Tank({
    required this.id,
    required this.name,
    this.product,
    this.capacity,
    this.volume,
    this.volumeDate,
    this.businessId,
  });

  factory Tank.fromJson(Map<String, dynamic> json) {
    DateTime? parsedVolumeDate;
    try {
      if (json['volume_date'] != null) parsedVolumeDate = DateTime.tryParse(json['volume_date']);
    } catch (_) {}

    return Tank(
      id: json['id']?.toString() ?? '',
      name: safeStringValue(json['name']),
      product: json['product'] != null && json['product'] is Map<String, dynamic>
          ? ProductRef.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      capacity: json['capacity']?.toDouble(),
      volume: json['volume']?.toDouble(),
      volumeDate: parsedVolumeDate,
      businessId: safeStringValue(json['business_id']),
    );
  }
}

class TankRef {
  final String id;
  final String name;

  TankRef({required this.id, required this.name});

  factory TankRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return TankRef(id: '', name: '');
    return TankRef(id: json['id']?.toString() ?? '', name: safeStringValue(json['name']));
  }
}

class Pump {
  final String id;
  final String name;
  final String? num;
  final ProductRef? product;
  final TankRef? tank;
  final bool blocked;
  final bool manual;
  final bool pumping;
  final String? blockedReason;
  final dynamic transaction;

  Pump({
    required this.id,
    required this.name,
    this.num,
    this.product,
    this.tank,
    this.blocked = false,
    this.manual = false,
    this.pumping = false,
    this.blockedReason,
    this.transaction,
  });

  factory Pump.fromJson(Map<String, dynamic> json) {
    return Pump(
      id: json['id']?.toString() ?? '',
      name: safeStringValue(json['name']),
      num: json['num']?.toString(),
      product: json['product'] != null && json['product'] is Map<String, dynamic>
          ? ProductRef.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      tank: json['tank'] != null && json['tank'] is Map<String, dynamic>
          ? TankRef.fromJson(json['tank'] as Map<String, dynamic>)
          : null,
      blocked: json['blocked'] == true,
      manual: json['manual'] == true,
      pumping: json['pumping'] == true,
      blockedReason: safeStringValue(json['blocked_reason']),
      transaction: json['transaction'],
    );
  }
}

class Controller {
  final String id;
  final String name;
  final String? sn;
  final bool? online;
  final DateTime? date;
  final String? businessId;

  Controller({
    required this.id,
    required this.name,
    this.sn,
    this.online,
    this.date,
    this.businessId,
  });

  factory Controller.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    try {
      if (json['date'] != null) parsedDate = DateTime.tryParse(json['date']);
    } catch (_) {}

    return Controller(
      id: json['id']?.toString() ?? '',
      name: safeStringValue(json['name']),
      sn: safeStringValue(json['sn']),
      online: json['online'] is bool ? json['online'] as bool : null,
      date: parsedDate,
      businessId: safeStringValue(json['business_id']),
    );
  }
}