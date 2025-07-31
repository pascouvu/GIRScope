import 'package:girscope/utils/json_utils.dart';
import 'package:girscope/services/anomaly_detection_service.dart';

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
  final List<StatisticalAnomaly>? statisticalAnomalies;

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
    this.statisticalAnomalies,
  });

  factory FuelTransaction.fromJson(Map<String, dynamic> json) {
    try {
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
    print('FuelTransaction.anomalies getter - manual: $manual, mtrForced: $mtrForced, volMax: $volMax, newKmeter: $newKmeter, newHmeter: $newHmeter, kcons: $kcons, hcons: $hcons');
    if (manual) anomalies.add(AnomalyType.manual);
    if (mtrForced) anomalies.add(AnomalyType.forcedMeter);
    if (volMax) anomalies.add(AnomalyType.maxVolume);
    if (newKmeter || newHmeter) anomalies.add(AnomalyType.meterReset);
    
    // Use dynamic threshold based on statistical analysis if available
    double consumptionThreshold = 50.0; // fallback
    if (hasStatisticalAnomalies) {
      final consumptionAnomaly = allStatisticalAnomalies
          .where((a) => a.type == StatisticalAnomalyType.consumption)
          .firstOrNull;
      if (consumptionAnomaly != null) {
        // Use 2 standard deviations above the mean as the threshold
        consumptionThreshold = consumptionAnomaly.expectedValue + (2 * consumptionAnomaly.standardDeviation);
      }
    }
    
    if ((kcons != null && kcons! > consumptionThreshold) || (hcons != null && hcons! > consumptionThreshold)) {
      anomalies.add(AnomalyType.highConsumption);
    }
    print('FuelTransaction.anomalies getter - Anomalies found: ${anomalies.map((e) => e.label).join(', ')}');
    return anomalies;
  }

  bool get hasAnomalies => anomalies.isNotEmpty || hasStatisticalAnomalies;
  
  bool get hasStatisticalAnomalies => statisticalAnomalies?.isNotEmpty ?? false;
  
  List<StatisticalAnomaly> get allStatisticalAnomalies => statisticalAnomalies ?? [];
  
  /// Creates a copy of this transaction with statistical anomalies
  FuelTransaction copyWithStatisticalAnomalies(List<StatisticalAnomaly> anomalies) {
    return FuelTransaction(
      id: id,
      transacId: transacId,
      date: date,
      vehicleName: vehicleName,
      vehicleId: vehicleId,
      driverName: driverName,
      driverId: driverId,
      siteName: siteName,
      volume: volume,
      kdelta: kdelta,
      kcons: kcons,
      hcons: hcons,
      manual: manual,
      mtrForced: mtrForced,
      volMax: volMax,
      newKmeter: newKmeter,
      newHmeter: newHmeter,
      statisticalAnomalies: anomalies,
    );
  }
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