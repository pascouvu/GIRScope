import 'package:girscope/utils/json_utils.dart';

class FuelTransaction {
  final String id;
  final String transacId;
  final DateTime date;
  final String vehicleName;
  final String vehicleId;
  final String driverName;
  final String driverId;
  final String siteName;
  final double volume;
  final double? kdelta;
  final double? kcons;
  final double? hcons;
  final bool manual;
  final bool mtrForced;
  final bool volMax;
  final bool newKmeter;
  final bool newHmeter;

  FuelTransaction({
    required this.id,
    required this.transacId,
    required this.date,
    required this.vehicleName,
    required this.vehicleId,
    required this.driverName,
    required this.driverId,
    required this.siteName,
    required this.volume,
    this.kdelta,
    this.kcons,
    this.hcons,
    required this.manual,
    required this.mtrForced,
    required this.volMax,
    required this.newKmeter,
    required this.newHmeter,
  });

  

  factory FuelTransaction.fromJson(Map<String, dynamic> json) {
    try {
      print('FuelTransaction.fromJson - Processing transaction data...');
      
      // Debug logging for problematic fields
      if (json['vehicle_name'] != null) {
        print('FuelTransaction - vehicle_name type: ${json['vehicle_name'].runtimeType}, value: ${json['vehicle_name']}');
      }
      if (json['vehicle'] != null) {
        print('FuelTransaction - vehicle type: ${json['vehicle'].runtimeType}, value: ${json['vehicle']}');
      }
      if (json['driver_name'] != null) {
        print('FuelTransaction - driver_name type: ${json['driver_name'].runtimeType}, value: ${json['driver_name']}');
      }
      if (json['driver'] != null) {
        print('FuelTransaction - driver type: ${json['driver'].runtimeType}, value: ${json['driver']}');
      }
      if (json['site_name'] != null) {
        print('FuelTransaction - site_name type: ${json['site_name'].runtimeType}, value: ${json['site_name']}');
      }
      if (json['site'] != null) {
        print('FuelTransaction - site type: ${json['site'].runtimeType}, value: ${json['site']}');
      }

      return FuelTransaction(
        id: json['id']?.toString() ?? '',
        transacId: json['transac_id']?.toString() ?? '0',
        date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
        vehicleName: safeStringValue(json['vehicle_name'] ?? json['vehicle']),
        vehicleId: safeStringValue(json['vehicle']?['id']),
        driverName: safeStringValue(json['driver_name'] ?? json['driver']),
        driverId: safeStringValue(json['driver']?['id']),
        siteName: safeStringValue(json['site_name'] ?? json['site']),
        volume: (json['volume'] ?? 0).toDouble(),
        kdelta: json['kdelta']?.toDouble(),
        kcons: json['kcons']?.toDouble(),
        hcons: json['hcons']?.toDouble(),
        manual: json['manual'] ?? false,
        mtrForced: json['mtr_forced'] ?? false,
        volMax: json['vol_max'] ?? false,
        newKmeter: json['new_kmeter'] ?? false,
        newHmeter: json['new_hmeter'] ?? false,
      );
    } catch (e) {
      print('FuelTransaction.fromJson - Error parsing transaction: $e');
      print('FuelTransaction.fromJson - JSON keys: ${json.keys.toList()}');
      rethrow;
    }
  }

  List<AnomalyType> get anomalies {
    List<AnomalyType> anomalies = [];
    if (manual) anomalies.add(AnomalyType.manual);
    if (mtrForced) anomalies.add(AnomalyType.forcedMeter);
    if (volMax) anomalies.add(AnomalyType.maxVolume);
    if (newKmeter || newHmeter) anomalies.add(AnomalyType.meterReset);
    if ((kcons != null && kcons! > 50) || (hcons != null && hcons! > 50)) {
      anomalies.add(AnomalyType.highConsumption);
    }
    return anomalies;
  }

  bool get hasAnomalies => anomalies.isNotEmpty;
}

enum AnomalyType {
  manual('Manual Fueling', '🟠'),
  forcedMeter('Forced Meter', '🔴'),
  maxVolume('Max Volume', '⚪'),
  meterReset('Meter Reset', '🟡'),
  highConsumption('High Consumption', '🟣');

  const AnomalyType(this.label, this.emoji);
  final String label;
  final String emoji;
}