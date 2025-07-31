import 'dart:math';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/services/supabase_service.dart';
import 'package:girscope/models/anomaly_detection_log.dart';

class AnomalyDetectionService {
  final SupabaseService _supabaseService = SupabaseService();
  
  // Statistical thresholds
  static const double _standardDeviationThreshold = 2.0;
  static const int _minimumHistoricalSamples = 5;
  static const int _baselineDays = 90; // 3 months baseline
  
  // Current analysis log
  AnomalyDetectionLog? _currentLog;
  
  /// Analyzes transactions for anomalies based on historical patterns with comprehensive logging
  Future<Map<String, List<StatisticalAnomaly>>> analyzeAnomalies({
    required List<FuelTransaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final stopwatch = Stopwatch()..start();
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final transactionLogs = <TransactionAnalysisLog>[];
    final anomaliesMap = <String, List<StatisticalAnomaly>>{};
    
    // Log analysis parameters
    final parameters = AnalysisParameters(
      periodStart: startDate,
      periodEnd: endDate,
      baselineDays: _baselineDays,
      standardDeviationThreshold: _standardDeviationThreshold,
      minimumHistoricalSamples: _minimumHistoricalSamples,
      statisticalAnalysisEnabled: true,
    );
    
    print('🔍 Starting anomaly detection analysis...');
    print('📊 Session ID: $sessionId');
    print('📅 Analysis period: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
    print('📈 Transactions to analyze: ${transactions.length}');
    print('⚙️ Parameters: ${_baselineDays}d baseline, ${_standardDeviationThreshold}σ threshold, min ${_minimumHistoricalSamples} samples');
    
    for (final transaction in transactions) {
      print('\n🚗 Analyzing transaction ${transaction.id} (${transaction.vehicleName})...');
      print('🔍 DEBUG: Current transaction vehicle_id: "${transaction.vehicleId}" (length: ${transaction.vehicleId.length})');
      
      final (anomalies, transactionLog) = await _detectAnomaliesForTransactionWithLogging(
        transaction, 
        startDate, 
        endDate,
        sessionId,
      );
      
      transactionLogs.add(transactionLog);
      
      if (anomalies.isNotEmpty) {
        anomaliesMap[transaction.id] = anomalies;
        print('⚠️ Found ${anomalies.length} anomalies for transaction ${transaction.id}');
      } else {
        print('✅ No anomalies detected for transaction ${transaction.id}');
      }
    }
    
    stopwatch.stop();
    
    // Create summary
    final anomaliesByType = <String, int>{};
    final anomaliesBySeverity = <String, int>{};
    int totalAnomalies = 0;
    
    for (final anomalies in anomaliesMap.values) {
      totalAnomalies += anomalies.length;
      for (final anomaly in anomalies) {
        final type = anomaly.type.toString().split('.').last;
        final severity = anomaly.severity.toString().split('.').last;
        anomaliesByType[type] = (anomaliesByType[type] ?? 0) + 1;
        anomaliesBySeverity[severity] = (anomaliesBySeverity[severity] ?? 0) + 1;
      }
    }
    
    final summary = AnalysisSummary(
      totalTransactionsAnalyzed: transactions.length,
      transactionsWithAnomalies: anomaliesMap.length,
      totalAnomaliesDetected: totalAnomalies,
      anomaliesByType: anomaliesByType,
      anomaliesBySeverity: anomaliesBySeverity,
      analysisTime: stopwatch.elapsed,
    );
    
    // Store the complete log
    _currentLog = AnomalyDetectionLog(
      timestamp: DateTime.now(),
      sessionId: sessionId,
      transactionLogs: transactionLogs,
      parameters: parameters,
      summary: summary,
    );
    
    print('\n📋 Analysis Summary:');
    print('⏱️ Analysis time: ${stopwatch.elapsed.inMilliseconds}ms');
    print('📊 Transactions analyzed: ${transactions.length}');
    print('⚠️ Transactions with anomalies: ${anomaliesMap.length}');
    print('🔍 Total anomalies detected: $totalAnomalies');
    print('📈 Anomalies by type: $anomaliesByType');
    print('🚨 Anomalies by severity: $anomaliesBySeverity');
    
    return anomaliesMap;
  }
  
  /// Get the current analysis log
  AnomalyDetectionLog? getCurrentAnalysisLog() => _currentLog;
  
  /// Detects anomalies for a specific transaction with detailed logging
  Future<(List<StatisticalAnomaly>, TransactionAnalysisLog)> _detectAnomaliesForTransactionWithLogging(
    FuelTransaction transaction,
    DateTime periodStart,
    DateTime periodEnd,
    String sessionId,
  ) async {
    final List<StatisticalAnomaly> anomalies = [];
    final List<AnomalyAnalysisLog> analysisLogs = [];
    
    // Get historical data for baseline comparison
    // Baseline should be the 90 days BEFORE the analysis period starts
    final baselineEnd = periodStart.subtract(const Duration(days: 1));
    final baselineStart = baselineEnd.subtract(const Duration(days: _baselineDays));
    
    print('📊 Analysis period: ${periodStart.toIso8601String()} to ${periodEnd.toIso8601String()}');
    print('📊 Baseline period: ${baselineStart.toIso8601String()} to ${baselineEnd.toIso8601String()}');
    
    // Get ALL vehicle historical data (not limited by days)
    print('🔍 DEBUG: Fetching data for vehicle ID: "${transaction.vehicleId}"');
    print('🔍 DEBUG: Vehicle name: "${transaction.vehicleName}"');
    print('🔍 DEBUG: Transaction ID being analyzed: "${transaction.id}"');
    print('🔍 DEBUG: Vehicle ID length: ${transaction.vehicleId.length}');
    print('🔍 DEBUG: Vehicle ID is empty: ${transaction.vehicleId.isEmpty}');
    
    // Use vehicle name if vehicle ID is empty
    final List<FuelTransaction> vehicleHistory;
    if (transaction.vehicleId.isEmpty) {
      print('🔄 Vehicle ID is empty, using vehicle name "${transaction.vehicleName}" for query');
      vehicleHistory = await _supabaseService.getVehicleRefuelingDataByName(
        transaction.vehicleName,
      );
    } else {
      vehicleHistory = await _supabaseService.getVehicleRefuelingDataUnlimited(
        transaction.vehicleId,
      );
    }
    
    print('📈 Total historical data found: ${vehicleHistory.length} transactions');
    
    // Debug: Print ALL transaction volumes for this vehicle
    if (vehicleHistory.isNotEmpty) {
      print('🔍 DEBUG: All volumes for ${transaction.vehicleName}:');
      for (int i = 0; i < vehicleHistory.length && i < 10; i++) {
        print('   - ${vehicleHistory[i].date.day}/${vehicleHistory[i].date.month}/${vehicleHistory[i].date.year}: ${vehicleHistory[i].volume}L (ID: ${vehicleHistory[i].id})');
      }
      if (vehicleHistory.length > 10) {
        print('   ... and ${vehicleHistory.length - 10} more transactions');
      }
    }
    
    // Debug: Print some sample transaction dates
    if (vehicleHistory.isNotEmpty) {
      print('📅 Sample transaction dates:');
      for (int i = 0; i < vehicleHistory.length && i < 3; i++) {
        print('   - ${vehicleHistory[i].date.toIso8601String()}');
      }
    }
    
    // Filter for baseline period (90 days before analysis period)
    final baselineTransactions = vehicleHistory
        .where((t) => t.date.isAfter(baselineStart) && t.date.isBefore(baselineEnd))
        .toList();
    
    // Also get transactions in the analysis period for comparison
    final analysisTransactions = vehicleHistory
        .where((t) => t.date.isAfter(periodStart) && t.date.isBefore(periodEnd))
        .toList();
    
    print('📈 Baseline transactions (${baselineStart.day}/${baselineStart.month}/${baselineStart.year} to ${baselineEnd.day}/${baselineEnd.month}/${baselineEnd.year}): ${baselineTransactions.length}');
    print('📈 Analysis period transactions (${periodStart.day}/${periodStart.month}/${periodStart.year} to ${periodEnd.day}/${periodEnd.month}/${periodEnd.year}): ${analysisTransactions.length}');
    
    // Debug: If no baseline transactions, let's see what dates we have
    if (baselineTransactions.isEmpty && vehicleHistory.isNotEmpty) {
      print('🔍 DEBUG: No baseline transactions found. Let\'s check date ranges:');
      final sortedHistory = vehicleHistory.toList()..sort((a, b) => a.date.compareTo(b.date));
      print('   - Earliest transaction: ${sortedHistory.first.date.toIso8601String()}');
      print('   - Latest transaction: ${sortedHistory.last.date.toIso8601String()}');
      print('   - Baseline needed: ${baselineStart.toIso8601String()} to ${baselineEnd.toIso8601String()}');
      print('   - Analysis period: ${periodStart.toIso8601String()} to ${periodEnd.toIso8601String()}');
      
      // Let's try a more flexible approach - use the earliest available data as baseline
      if (sortedHistory.first.date.isBefore(periodStart)) {
        print('🔄 Using flexible baseline: all data before analysis period');
        final flexibleBaselineTransactions = vehicleHistory
            .where((t) => t.date.isBefore(periodStart))
            .toList();
        print('📈 Flexible baseline transactions: ${flexibleBaselineTransactions.length}');
        
        // Update baseline transactions to use flexible approach
        baselineTransactions.clear();
        baselineTransactions.addAll(flexibleBaselineTransactions);
      } else {
        // If no data before analysis period, use older data from the available range
        print('🔄 No data before analysis period. Using historical data approach...');
        final totalDays = sortedHistory.last.date.difference(sortedHistory.first.date).inDays;
        if (totalDays > 30) {
          // Use first 70% of data as baseline, last 30% as comparison period
          final splitPoint = sortedHistory.first.date.add(Duration(days: (totalDays * 0.7).round()));
          final historicalBaselineTransactions = vehicleHistory
              .where((t) => t.date.isBefore(splitPoint))
              .toList();
          print('📈 Historical baseline transactions (before ${splitPoint.day}/${splitPoint.month}): ${historicalBaselineTransactions.length}');
          
          baselineTransactions.clear();
          baselineTransactions.addAll(historicalBaselineTransactions);
        }
      }
    }
    
    print('📈 Historical data: ${vehicleHistory.length} total, ${baselineTransactions.length} in baseline period');
    
    // Generate user-friendly log entry
    print('\n🚗 Vehicle: ${transaction.vehicleName}');
    print('📅 Transaction Date: ${_formatDate(transaction.date)}');
    
    final baseline = BaselineAnalysis(
      baselineStart: baselineStart,
      baselineEnd: baselineEnd,
      totalHistoricalTransactions: vehicleHistory.length,
      usableTransactions: baselineTransactions.length,
      status: baselineTransactions.length >= _minimumHistoricalSamples ? 'SUFFICIENT' : 'INSUFFICIENT',
      reason: baselineTransactions.length < _minimumHistoricalSamples 
          ? 'Need at least $_minimumHistoricalSamples samples, found ${baselineTransactions.length}'
          : null,
    );
    
    if (baselineTransactions.length < _minimumHistoricalSamples) {
      print('❌ Vehicle: ${transaction.vehicleName} - from last 3 months period, insufficient data (${baselineTransactions.length} transactions) - analysis skipped');
      return (anomalies, TransactionAnalysisLog(
        transactionId: transaction.id,
        vehicleId: transaction.vehicleId,
        vehicleName: transaction.vehicleName,
        transactionDate: transaction.date,
        baseline: baseline,
        anomalyAnalyses: analysisLogs,
        result: 'SKIPPED - Insufficient historical data',
      ));
    }
    
    // Analyze consumption anomalies
    if (transaction.kcons != null) {
      print('🔍 Analyzing consumption: ${transaction.kcons} L/100km');
      final (consumptionAnomaly, consumptionLog) = _analyzeConsumptionAnomalyWithLogging(
        transaction, 
        baselineTransactions
      );
      analysisLogs.add(consumptionLog);
      if (consumptionAnomaly != null) {
        anomalies.add(consumptionAnomaly);
        print('⚠️ Consumption anomaly detected: ${consumptionAnomaly.severity.name}');
      }
    } else {
      analysisLogs.add(AnomalyAnalysisLog(
        analysisType: 'Consumption',
        hasData: false,
        sampleCount: 0,
        isAnomaly: false,
        notes: 'No consumption data available for this transaction',
      ));
      print('ℹ️ No consumption data available');
    }
    
    // Analyze volume anomalies
    print('🔍 Analyzing volume: ${transaction.volume} L');
    final (volumeAnomaly, volumeLog) = _analyzeVolumeAnomalyWithLogging(
      transaction, 
      baselineTransactions
    );
    analysisLogs.add(volumeLog);
    if (volumeAnomaly != null) {
      anomalies.add(volumeAnomaly);
      print('⚠️ Volume anomaly detected: ${volumeAnomaly.severity.name}');
    }
    
    // Analyze frequency anomalies
    print('🔍 Analyzing frequency patterns...');
    final (frequencyAnomaly, frequencyLog) = await _analyzeFrequencyAnomalyWithLogging(
      transaction, 
      baselineTransactions,
      vehicleHistory,
    );
    analysisLogs.add(frequencyLog);
    if (frequencyAnomaly != null) {
      anomalies.add(frequencyAnomaly);
      print('⚠️ Frequency anomaly detected: ${frequencyAnomaly.severity.name}');
    }
    
    // Skip timing analysis - not necessary to track refueling time
    // print('🔍 Analyzing timing: ${transaction.date.hour}:${transaction.date.minute.toString().padLeft(2, '0')}');
    // Timing analysis removed as requested
    
    final transactionLog = TransactionAnalysisLog(
      transactionId: transaction.id,
      vehicleId: transaction.vehicleId,
      vehicleName: transaction.vehicleName,
      transactionDate: transaction.date,
      baseline: baseline,
      anomalyAnalyses: analysisLogs,
      result: anomalies.isEmpty ? 'NORMAL' : 'ANOMALOUS (${anomalies.length} anomalies)',
    );
    
    return (anomalies, transactionLog);
  }
  

  
  /// Analyzes fuel consumption anomalies
  StatisticalAnomaly? _analyzeConsumptionAnomaly(
    FuelTransaction transaction,
    List<FuelTransaction> baseline,
  ) {
    if (transaction.kcons == null) return null;
    
    final consumptions = baseline
        .where((t) => t.kcons != null && t.kcons! > 0)
        .map((t) => t.kcons!)
        .toList();
    
    if (consumptions.length < _minimumHistoricalSamples) return null;
    
    final stats = _calculateStatistics(consumptions);
    final zScore = (transaction.kcons! - stats.mean) / stats.standardDeviation;
    
    if (zScore.abs() > _standardDeviationThreshold) {
      return StatisticalAnomaly(
        type: StatisticalAnomalyType.consumption,
        severity: _calculateSeverity(zScore.abs()),
        actualValue: transaction.kcons!,
        expectedValue: stats.mean,
        standardDeviation: stats.standardDeviation,
        zScore: zScore,
        description: _generateConsumptionDescription(transaction.kcons!, stats, zScore),
      );
    }
    
    return null;
  }
  
  /// Analyzes fuel volume anomalies
  StatisticalAnomaly? _analyzeVolumeAnomaly(
    FuelTransaction transaction,
    List<FuelTransaction> baseline,
  ) {
    final volumes = baseline.map((t) => t.volume).toList();
    
    if (volumes.length < _minimumHistoricalSamples) return null;
    
    final stats = _calculateStatistics(volumes);
    final zScore = (transaction.volume - stats.mean) / stats.standardDeviation;
    
    if (zScore.abs() > _standardDeviationThreshold) {
      return StatisticalAnomaly(
        type: StatisticalAnomalyType.volume,
        severity: _calculateSeverity(zScore.abs()),
        actualValue: transaction.volume,
        expectedValue: stats.mean,
        standardDeviation: stats.standardDeviation,
        zScore: zScore,
        description: _generateVolumeDescription(transaction.volume, stats, zScore),
      );
    }
    
    return null;
  }
  
  /// Analyzes fueling frequency anomalies
  Future<StatisticalAnomaly?> _analyzeFrequencyAnomaly(
    FuelTransaction transaction,
    List<FuelTransaction> baseline,
    List<FuelTransaction> allHistory,
  ) async {
    if (baseline.isEmpty) return null;
    
    // Calculate average days between fuelings in baseline
    baseline.sort((a, b) => a.date.compareTo(b.date));
    final intervals = <double>[];
    
    for (int i = 1; i < baseline.length; i++) {
      final daysBetween = baseline[i].date.difference(baseline[i - 1].date).inDays.toDouble();
      if (daysBetween > 0) intervals.add(daysBetween);
    }
    
    if (intervals.length < 2) return null;
    
    final stats = _calculateStatistics(intervals);
    
    // Find the most recent transaction before current one
    final previousTransactions = allHistory
        .where((t) => t.date.isBefore(transaction.date))
        .toList();
    
    if (previousTransactions.isEmpty) return null;
    
    previousTransactions.sort((a, b) => b.date.compareTo(a.date));
    final daysSinceLastFueling = transaction.date
        .difference(previousTransactions.first.date)
        .inDays
        .toDouble();
    
    final zScore = (daysSinceLastFueling - stats.mean) / stats.standardDeviation;
    
    if (zScore.abs() > _standardDeviationThreshold) {
      return StatisticalAnomaly(
        type: StatisticalAnomalyType.frequency,
        severity: _calculateSeverity(zScore.abs()),
        actualValue: daysSinceLastFueling,
        expectedValue: stats.mean,
        standardDeviation: stats.standardDeviation,
        zScore: zScore,
        description: _generateFrequencyDescription(daysSinceLastFueling, stats, zScore),
      );
    }
    
    return null;
  }
  
  /// Analyzes timing anomalies (hour of day patterns)
  StatisticalAnomaly? _analyzeTimingAnomaly(
    FuelTransaction transaction,
    List<FuelTransaction> baseline,
  ) {
    final hours = baseline.map((t) => t.date.hour.toDouble()).toList();
    
    if (hours.length < _minimumHistoricalSamples) return null;
    
    final stats = _calculateStatistics(hours);
    final currentHour = transaction.date.hour.toDouble();
    final zScore = (currentHour - stats.mean) / stats.standardDeviation;
    
    if (zScore.abs() > _standardDeviationThreshold) {
      return StatisticalAnomaly(
        type: StatisticalAnomalyType.timing,
        severity: _calculateSeverity(zScore.abs()),
        actualValue: currentHour,
        expectedValue: stats.mean,
        standardDeviation: stats.standardDeviation,
        zScore: zScore,
        description: _generateTimingDescription(currentHour, stats, zScore),
      );
    }
    
    return null;
  }
  
  /// Calculates basic statistics for a dataset
  StatisticalSummary _calculateStatistics(List<double> values) {
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
  AnomalySeverity _calculateSeverity(double absZScore) {
    if (absZScore >= 3.0) return AnomalySeverity.critical;
    if (absZScore >= 2.5) return AnomalySeverity.high;
    if (absZScore >= 2.0) return AnomalySeverity.medium;
    return AnomalySeverity.low;
  }
  

  
  String _generateConsumptionDescription(double actual, StatisticalSummary stats, double zScore) {
    final direction = zScore > 0 ? 'higher' : 'lower';
    final percentage = ((actual - stats.mean) / stats.mean * 100).abs();
    return 'Fuel consumption of ${actual.toStringAsFixed(1)} L/100km is ${percentage.toStringAsFixed(0)}% $direction than the typical ${stats.mean.toStringAsFixed(1)} L/100km for this vehicle.';
  }
  
  String _generateVolumeDescription(double actual, StatisticalSummary stats, double zScore) {
    final direction = zScore > 0 ? 'larger' : 'smaller';
    final percentage = ((actual - stats.mean) / stats.mean * 100).abs();
    return 'Fuel volume of ${actual.toStringAsFixed(1)}L is ${percentage.toStringAsFixed(0)}% $direction than the typical ${stats.mean.toStringAsFixed(1)}L for this vehicle.';
  }
  
  String _generateFrequencyDescription(double actual, StatisticalSummary stats, double zScore) {
    final direction = zScore > 0 ? 'longer' : 'shorter';
    return 'Time since last fueling (${actual.toStringAsFixed(0)} days) is $direction than the typical ${stats.mean.toStringAsFixed(0)} days between fuelings.';
  }
  
  String _generateTimingDescription(double actual, StatisticalSummary stats, double zScore) {
    final actualHour = actual.toInt();
    final typicalHour = stats.mean.toInt();
    return 'Fueling at ${actualHour}:00 is unusual compared to the typical ${typicalHour}:00 fueling time for this vehicle.';
  }
  
  /// Formats a date for user-friendly display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  /// Analyzes fuel consumption anomalies with logging
  (StatisticalAnomaly?, AnomalyAnalysisLog) _analyzeConsumptionAnomalyWithLogging(
    FuelTransaction transaction,
    List<FuelTransaction> baseline,
  ) {
    if (transaction.kcons == null) {
      return (null, AnomalyAnalysisLog(
        analysisType: 'Consumption',
        hasData: false,
        sampleCount: 0,
        isAnomaly: false,
        notes: 'No consumption data available for this transaction',
      ));
    }
    
    final consumptions = baseline
        .where((t) => t.kcons != null && t.kcons! > 0)
        .map((t) => t.kcons!)
        .toList();
    
    if (consumptions.length < _minimumHistoricalSamples) {
      return (null, AnomalyAnalysisLog(
        analysisType: 'Consumption',
        hasData: true,
        sampleCount: consumptions.length,
        isAnomaly: false,
        notes: 'Insufficient samples for analysis (${consumptions.length} < $_minimumHistoricalSamples)',
      ));
    }
    
    final stats = _calculateStatistics(consumptions);
    final zScore = (transaction.kcons! - stats.mean) / stats.standardDeviation;
    final isAnomaly = zScore.abs() > _standardDeviationThreshold;
    
    print('📊 Consumption stats: mean=${stats.mean.toStringAsFixed(2)}, std=${stats.standardDeviation.toStringAsFixed(2)}, min=${stats.min.toStringAsFixed(2)}, max=${stats.max.toStringAsFixed(2)}');
    print('📈 Z-score: ${zScore.toStringAsFixed(3)} (threshold: $_standardDeviationThreshold)');
    
    final statisticalCalc = StatisticalCalculation(
      rawData: consumptions,
      mean: stats.mean,
      standardDeviation: stats.standardDeviation,
      variance: pow(stats.standardDeviation, 2).toDouble(),
      min: stats.min,
      max: stats.max,
      threshold: _standardDeviationThreshold,
    );
    
    // Create historical data points for the anomaly
    final historicalDataPoints = baseline
        .where((t) => t.kcons != null && t.kcons! > 0)
        .map((t) => HistoricalDataPoint(
          date: t.date,
          value: t.kcons!,
          transactionId: t.id,
        )).toList();
    
    StatisticalAnomaly? anomaly;
    if (isAnomaly) {
      anomaly = StatisticalAnomaly(
        type: StatisticalAnomalyType.consumption,
        severity: _calculateSeverity(zScore.abs()),
        actualValue: transaction.kcons!,
        expectedValue: stats.mean,
        standardDeviation: stats.standardDeviation,
        zScore: zScore,
        description: _generateConsumptionDescription(transaction.kcons!, stats, zScore),
        historicalData: historicalDataPoints,
      );
    }
    
    // Generate user-friendly log message
    final baselineAvg = stats.mean.toStringAsFixed(1);
    final currentValue = transaction.kcons!.toStringAsFixed(1);
    final anomalyStatus = isAnomaly ? 'ANOMALY DETECTED' : 'no anomaly';
    
    print('✅ Vehicle: ${transaction.vehicleName} - from last 3 months period, consumption = ${baselineAvg}L/100km and for this filter period = ${currentValue}L/100km - $anomalyStatus');
    
    final log = AnomalyAnalysisLog(
      analysisType: 'Consumption',
      hasData: true,
      sampleCount: consumptions.length,
      statistics: statisticalCalc,
      actualValue: transaction.kcons!,
      zScore: zScore,
      isAnomaly: isAnomaly,
      severity: isAnomaly ? anomaly!.severity.name : null,
      description: isAnomaly ? anomaly!.description : null,
      notes: 'Vehicle: ${transaction.vehicleName} - from last 3 months period, consumption = ${baselineAvg}L/100km and for this filter period = ${currentValue}L/100km - $anomalyStatus',
    );
    
    return (anomaly, log);
  }
  
  /// Analyzes fuel volume anomalies with logging
  (StatisticalAnomaly?, AnomalyAnalysisLog) _analyzeVolumeAnomalyWithLogging(
    FuelTransaction transaction,
    List<FuelTransaction> baseline,
  ) {
    final volumes = baseline.map((t) => t.volume).toList();
    
    if (volumes.length < _minimumHistoricalSamples) {
      return (null, AnomalyAnalysisLog(
        analysisType: 'Volume',
        hasData: true,
        sampleCount: volumes.length,
        isAnomaly: false,
        notes: 'Insufficient samples for analysis (${volumes.length} < $_minimumHistoricalSamples)',
      ));
    }
    
    final stats = _calculateStatistics(volumes);
    final zScore = (transaction.volume - stats.mean) / stats.standardDeviation;
    final isAnomaly = zScore.abs() > _standardDeviationThreshold;
    
    print('📊 Volume stats: mean=${stats.mean.toStringAsFixed(2)}, std=${stats.standardDeviation.toStringAsFixed(2)}, min=${stats.min.toStringAsFixed(2)}, max=${stats.max.toStringAsFixed(2)}');
    print('📈 Z-score: ${zScore.toStringAsFixed(3)} (threshold: $_standardDeviationThreshold)');
    
    final statisticalCalc = StatisticalCalculation(
      rawData: volumes,
      mean: stats.mean,
      standardDeviation: stats.standardDeviation,
      variance: pow(stats.standardDeviation, 2).toDouble(),
      min: stats.min,
      max: stats.max,
      threshold: _standardDeviationThreshold,
    );
    
    // Create historical data points for the anomaly
    final historicalDataPoints = baseline.map((t) => HistoricalDataPoint(
      date: t.date,
      value: t.volume,
      transactionId: t.id,
    )).toList();
    
    StatisticalAnomaly? anomaly;
    if (isAnomaly) {
      anomaly = StatisticalAnomaly(
        type: StatisticalAnomalyType.volume,
        severity: _calculateSeverity(zScore.abs()),
        actualValue: transaction.volume,
        expectedValue: stats.mean,
        standardDeviation: stats.standardDeviation,
        zScore: zScore,
        description: _generateVolumeDescription(transaction.volume, stats, zScore),
        historicalData: historicalDataPoints,
      );
    }
    
    // Generate user-friendly log message
    final baselineAvg = stats.mean.toStringAsFixed(1);
    final currentValue = transaction.volume.toStringAsFixed(1);
    final anomalyStatus = isAnomaly ? 'ANOMALY DETECTED' : 'no anomaly';
    
    print('✅ Vehicle: ${transaction.vehicleName} - from last 3 months period, volume = ${baselineAvg}L and for this filter period = ${currentValue}L - $anomalyStatus');
    
    final log = AnomalyAnalysisLog(
      analysisType: 'Volume',
      hasData: true,
      sampleCount: volumes.length,
      statistics: statisticalCalc,
      actualValue: transaction.volume,
      zScore: zScore,
      isAnomaly: isAnomaly,
      severity: isAnomaly ? anomaly!.severity.name : null,
      description: isAnomaly ? anomaly!.description : null,
      notes: 'Vehicle: ${transaction.vehicleName} - from last 3 months period, volume = ${baselineAvg}L and for this filter period = ${currentValue}L - $anomalyStatus',
    );
    
    return (anomaly, log);
  }
  
  /// Analyzes fueling frequency anomalies with logging
  Future<(StatisticalAnomaly?, AnomalyAnalysisLog)> _analyzeFrequencyAnomalyWithLogging(
    FuelTransaction transaction,
    List<FuelTransaction> baseline,
    List<FuelTransaction> allHistory,
  ) async {
    if (baseline.isEmpty) {
      return (null, AnomalyAnalysisLog(
        analysisType: 'Frequency',
        hasData: false,
        sampleCount: 0,
        isAnomaly: false,
        notes: 'No baseline transactions available for frequency analysis',
      ));
    }
    
    // Calculate average days between fuelings in baseline
    baseline.sort((a, b) => a.date.compareTo(b.date));
    final intervals = <double>[];
    
    for (int i = 1; i < baseline.length; i++) {
      final daysBetween = baseline[i].date.difference(baseline[i - 1].date).inDays.toDouble();
      if (daysBetween > 0) intervals.add(daysBetween);
    }
    
    if (intervals.length < 2) {
      return (null, AnomalyAnalysisLog(
        analysisType: 'Frequency',
        hasData: true,
        sampleCount: intervals.length,
        isAnomaly: false,
        notes: 'Insufficient interval data for frequency analysis (${intervals.length} < 2)',
      ));
    }
    
    final stats = _calculateStatistics(intervals);
    
    // Find the most recent transaction before current one
    final previousTransactions = allHistory
        .where((t) => t.date.isBefore(transaction.date))
        .toList();
    
    if (previousTransactions.isEmpty) {
      return (null, AnomalyAnalysisLog(
        analysisType: 'Frequency',
        hasData: true,
        sampleCount: intervals.length,
        isAnomaly: false,
        notes: 'No previous transactions found for frequency comparison',
      ));
    }
    
    previousTransactions.sort((a, b) => b.date.compareTo(a.date));
    final daysSinceLastFueling = transaction.date
        .difference(previousTransactions.first.date)
        .inDays
        .toDouble();
    
    final zScore = (daysSinceLastFueling - stats.mean) / stats.standardDeviation;
    final isAnomaly = zScore.abs() > _standardDeviationThreshold;
    
    print('📊 Frequency stats: mean=${stats.mean.toStringAsFixed(2)} days, std=${stats.standardDeviation.toStringAsFixed(2)}, intervals analyzed=${intervals.length}');
    print('📈 Days since last fueling: ${daysSinceLastFueling.toStringAsFixed(1)}, Z-score: ${zScore.toStringAsFixed(3)}');
    
    final statisticalCalc = StatisticalCalculation(
      rawData: intervals,
      mean: stats.mean,
      standardDeviation: stats.standardDeviation,
      variance: pow(stats.standardDeviation, 2).toDouble(),
      min: stats.min,
      max: stats.max,
      threshold: _standardDeviationThreshold,
    );
    
    StatisticalAnomaly? anomaly;
    if (isAnomaly) {
      anomaly = StatisticalAnomaly(
        type: StatisticalAnomalyType.frequency,
        severity: _calculateSeverity(zScore.abs()),
        actualValue: daysSinceLastFueling,
        expectedValue: stats.mean,
        standardDeviation: stats.standardDeviation,
        zScore: zScore,
        description: _generateFrequencyDescription(daysSinceLastFueling, stats, zScore),
      );
    }
    
    // Generate user-friendly log message
    final baselineAvg = stats.mean.toStringAsFixed(1);
    final currentValue = daysSinceLastFueling.toStringAsFixed(1);
    final anomalyStatus = isAnomaly ? 'ANOMALY DETECTED' : 'no anomaly';
    
    print('✅ Vehicle: ${transaction.vehicleName} - from last 3 months period, frequency = ${baselineAvg} days and for this filter period = ${currentValue} days since last fueling - $anomalyStatus');
    
    final log = AnomalyAnalysisLog(
      analysisType: 'Frequency',
      hasData: true,
      sampleCount: intervals.length,
      statistics: statisticalCalc,
      actualValue: daysSinceLastFueling,
      zScore: zScore,
      isAnomaly: isAnomaly,
      severity: isAnomaly ? anomaly!.severity.name : null,
      description: isAnomaly ? anomaly!.description : null,
      notes: 'Vehicle: ${transaction.vehicleName} - from last 3 months period, frequency = ${baselineAvg} days and for this filter period = ${currentValue} days since last fueling - $anomalyStatus',
    );
    
    return (anomaly, log);
  }
  
  /// Analyzes timing anomalies with logging
  (StatisticalAnomaly?, AnomalyAnalysisLog) _analyzeTimingAnomalyWithLogging(
    FuelTransaction transaction,
    List<FuelTransaction> baseline,
  ) {
    final hours = baseline.map((t) => t.date.hour.toDouble()).toList();
    
    if (hours.length < _minimumHistoricalSamples) {
      return (null, AnomalyAnalysisLog(
        analysisType: 'Timing',
        hasData: true,
        sampleCount: hours.length,
        isAnomaly: false,
        notes: 'Insufficient samples for timing analysis (${hours.length} < $_minimumHistoricalSamples)',
      ));
    }
    
    final stats = _calculateStatistics(hours);
    final currentHour = transaction.date.hour.toDouble();
    final zScore = (currentHour - stats.mean) / stats.standardDeviation;
    final isAnomaly = zScore.abs() > _standardDeviationThreshold;
    
    print('📊 Timing stats: mean=${stats.mean.toStringAsFixed(2)}h, std=${stats.standardDeviation.toStringAsFixed(2)}, range=${stats.min.toStringAsFixed(0)}h-${stats.max.toStringAsFixed(0)}h');
    print('📈 Current hour: ${currentHour.toStringAsFixed(0)}h, Z-score: ${zScore.toStringAsFixed(3)}');
    
    final statisticalCalc = StatisticalCalculation(
      rawData: hours,
      mean: stats.mean,
      standardDeviation: stats.standardDeviation,
      variance: pow(stats.standardDeviation, 2).toDouble(),
      min: stats.min,
      max: stats.max,
      threshold: _standardDeviationThreshold,
    );
    
    StatisticalAnomaly? anomaly;
    if (isAnomaly) {
      anomaly = StatisticalAnomaly(
        type: StatisticalAnomalyType.timing,
        severity: _calculateSeverity(zScore.abs()),
        actualValue: currentHour,
        expectedValue: stats.mean,
        standardDeviation: stats.standardDeviation,
        zScore: zScore,
        description: _generateTimingDescription(currentHour, stats, zScore),
      );
    }
    
    // Generate user-friendly log message
    final baselineAvg = stats.mean.toStringAsFixed(1);
    final currentValue = currentHour.toStringAsFixed(0);
    final anomalyStatus = isAnomaly ? 'ANOMALY DETECTED' : 'no anomaly';
    
    print('✅ Vehicle: ${transaction.vehicleName} - from last 3 months period, timing = ${baselineAvg}h and for this filter period = ${currentValue}h - $anomalyStatus');
    
    final log = AnomalyAnalysisLog(
      analysisType: 'Timing',
      hasData: true,
      sampleCount: hours.length,
      statistics: statisticalCalc,
      actualValue: currentHour,
      zScore: zScore,
      isAnomaly: isAnomaly,
      severity: isAnomaly ? anomaly!.severity.name : null,
      description: isAnomaly ? anomaly!.description : null,
      notes: 'Vehicle: ${transaction.vehicleName} - from last 3 months period, timing = ${baselineAvg}h and for this filter period = ${currentValue}h - $anomalyStatus',
    );
    
    return (anomaly, log);
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