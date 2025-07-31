import 'dart:math';
import 'package:girscope/models/fuel_transaction.dart';

/// Service for performing statistical calculations and analysis
class StatisticalAnalysisService {
  // Statistical thresholds
  static const double standardDeviationThreshold = 2.0;
  static const int minimumHistoricalSamples = 5;
  
  /// Calculates basic statistics for a dataset
  StatisticalSummary calculateStatistics(List<double> values) {
    if (values.isEmpty) {
      return StatisticalSummary(mean: 0, standardDeviation: 0, min: 0, max: 0);
    }
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
        .map((x) => pow(x - mean, 2))
        .reduce((a, b) => a + b) / values.length;
    final standardDeviation = sqrt(variance);
    
    return StatisticalSummary(
      mean: mean,
      standardDeviation: standardDeviation,
      min: values.reduce(min),
      max: values.reduce(max),
    );
  }
  
  /// Calculates anomaly severity based on z-score
  AnomalySeverity calculateSeverity(double absZScore) {
    if (absZScore >= 3.0) return AnomalySeverity.critical;
    if (absZScore >= 2.5) return AnomalySeverity.high;
    if (absZScore >= 2.0) return AnomalySeverity.medium;
    return AnomalySeverity.low;
  }
  
  /// Generates consumption anomaly description
  String generateConsumptionDescription(double actual, StatisticalSummary stats, double zScore) {
    final direction = zScore > 0 ? 'higher' : 'lower';
    final percentage = ((actual - stats.mean) / stats.mean * 100).abs();
    return 'Fuel consumption of ${actual.toStringAsFixed(1)} L/100km is ${percentage.toStringAsFixed(0)}% $direction than the typical ${stats.mean.toStringAsFixed(1)} L/100km for this vehicle.';
  }
  
  /// Generates volume anomaly description
  String generateVolumeDescription(double actual, StatisticalSummary stats, double zScore) {
    final direction = zScore > 0 ? 'larger' : 'smaller';
    final percentage = ((actual - stats.mean) / stats.mean * 100).abs();
    return 'Fuel volume of ${actual.toStringAsFixed(1)}L is ${percentage.toStringAsFixed(0)}% $direction than the typical ${stats.mean.toStringAsFixed(1)}L for this vehicle.';
  }
  
  /// Generates frequency anomaly description
  String generateFrequencyDescription(double actual, StatisticalSummary stats, double zScore) {
    if (actual == 0.0) {
      return 'Same-day refueling detected. This is normal behavior and not considered an anomaly.';
    }
    final direction = zScore > 0 ? 'longer' : 'shorter';
    return 'Time since last fueling (${actual.toStringAsFixed(0)} days) is $direction than the typical ${stats.mean.toStringAsFixed(0)} days between fuelings.';
  }
  
  /// Formats a date for user-friendly display
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Statistical anomaly detected through pattern analysis
class StatisticalAnomaly {
  final StatisticalAnomalyType type;
  final AnomalySeverity severity;
  final double actualValue;
  final double expectedValue;
  final double standardDeviation;
  final double zScore;
  final String description;
  final List<HistoricalDataPoint>? historicalData;
  
  StatisticalAnomaly({
    required this.type,
    required this.severity,
    required this.actualValue,
    required this.expectedValue,
    required this.standardDeviation,
    required this.zScore,
    required this.description,
    this.historicalData,
  });
}

/// Historical data point used in anomaly calculation
class HistoricalDataPoint {
  final DateTime date;
  final double value;
  final String transactionId;
  
  HistoricalDataPoint({
    required this.date,
    required this.value,
    required this.transactionId,
  });
}

enum StatisticalAnomalyType {
  consumption,
  volume,
  frequency,
  timing,
}

enum AnomalySeverity {
  low,
  medium,
  high,
  critical,
}

class StatisticalSummary {
  final double mean;
  final double standardDeviation;
  final double min;
  final double max;
  
  StatisticalSummary({
    required this.mean,
    required this.standardDeviation,
    required this.min,
    required this.max,
  });
}