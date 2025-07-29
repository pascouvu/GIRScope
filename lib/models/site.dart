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

class Tank {
  final String id;
  final String name;
  final double? volume;

  Tank({
    required this.id,
    required this.name,
    this.volume,
  });

  factory Tank.fromJson(Map<String, dynamic> json) {
    return Tank(
      id: json['id']?.toString() ?? '',
      name: safeStringValue(json['name']),
      volume: json['volume']?.toDouble(),
    );
  }
}

class Pump {
  final String id;
  final String name;

  Pump({
    required this.id,
    required this.name,
  });

  factory Pump.fromJson(Map<String, dynamic> json) {
    return Pump(
      id: json['id']?.toString() ?? '',
      name: safeStringValue(json['name']),
    );
  }
}

class Controller {
  final String id;
  final String name;

  Controller({
    required this.id,
    required this.name,
  });

  factory Controller.fromJson(Map<String, dynamic> json) {
    return Controller(
      id: json['id']?.toString() ?? '',
      name: safeStringValue(json['name']),
    );
  }
}