import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/services/statistical_analysis_service.dart';
import 'package:girscope/models/anomaly_detection_log.dart';

/// Individual anomaly analyzers for different types of anomalies
class AnomalyAnalyzers {
  final StatisticalAnalysisService _statsService = StatisticalAnalysisService();
  
  /// Analyzes fuel consumption anomalies with logging
  (StatisticalAnomaly?, AnomalyAnalysisLog) analyzeConsumptionAnomalyWithLogging(
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
    
    if (consumptions.length < StatisticalAnalysisService.minimumHistoricalSamples) {
      return (null, AnomalyAnalysisLog(
        analysisType: 'Consumption',
        hasData: true,
        sampleCount: consumptions.length,
        isAnomaly: false,
        notes: 'Insufficient samples for analysis (${consumptions.length} < ${StatisticalAnalysisService.minimumHistoricalSamples})',
      ));
    }
    
    final stats = _statsService.calculateStatistics(consumptions);
    final zScore = (transaction.kcons! - stats.mean) / stats.standardDeviation;
    final isAnomaly = zScore.abs() > StatisticalAnalysisService.standardDeviationThreshold;
    
    print('📊 Consumption stats: mean=${stats.mean.toStringAsFixed(2)}, std=${stats.standardDeviation.toStringAsFixed(2)}, min=${stats.min.toStringAsFixed(2)}, max=${stats.max.toStringAsFixed(2)}');
    print('📈 Z-score: ${zScore.toStringAsFixed(3)} (threshold: ${StatisticalAnalysisService.standardDeviationThreshold})');
    
    // Create historical data points for the anomaly
    final historicalDataPoints = baseline
        .where((t) => t.kcons != null && t.kcons! > 0)
        .map((t) => HistoricalDataPoint(
          date: t.date,
          value: t.kcons!,
          transactionId: t.id,
        )).toList();
    
    final statisticalCalc = StatisticalCalculation(
      rawData: consumptions,
      mean: stats.mean,
      standardDeviation: stats.standardDeviation,
      variance: stats.standardDeviation * stats.standardDeviation,
      min: stats.min,
      max: stats.max,
      threshold: StatisticalAnalysisService.standardDeviationThreshold,
    );
    
    StatisticalAnomaly? anomaly;
    if (isAnomaly) {
      anomaly = StatisticalAnomaly(
        type: StatisticalAnomalyType.consumption,
        severity: _statsService.calculateSeverity(zScore.abs()),
        actualValue: transaction.kcons!,
        expectedValue: stats.mean,
        standardDeviation: stats.standardDeviation,
        zScore: zScore,
        description: _statsService.generateConsumptionDescription(transaction.kcons!, stats, zScore),
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
  (StatisticalAnomaly?, AnomalyAnalysisLog) analyzeVolumeAnomalyWithLogging(
    FuelTransaction transaction,
    List<FuelTransaction> baseline,
  ) {
    // Debug logging for volume analysis
    print('🔍 VOLUME: Transaction ID: ${transaction.id}');
    print('🔍 VOLUME: Current transaction: ${transaction.date} (${transaction.volume}L)');
    print('🔍 VOLUME: Baseline transactions: ${baseline.length}');
    if (baseline.isNotEmpty) {
      print('🔍 VOLUME: Baseline dates: ${baseline.map((t) => '${t.date.toString().substring(0, 10)} (${t.volume}L)').take(5).join(', ')}...');
    }
    
    final volumes = baseline.map((t) => t.volume).toList();
    
    if (volumes.length < StatisticalAnalysisService.minimumHistoricalSamples) {
      return (null, AnomalyAnalysisLog(
        analysisType: 'Volume',
        hasData: true,
        sampleCount: volumes.length,
        isAnomaly: false,
        notes: 'Insufficient samples for analysis (${volumes.length} < ${StatisticalAnalysisService.minimumHistoricalSamples})',
      ));
    }
    
    final stats = _statsService.calculateStatistics(volumes);
    final zScore = (transaction.volume - stats.mean) / stats.standardDeviation;
    final isAnomaly = zScore.abs() > StatisticalAnalysisService.standardDeviationThreshold;
    
    print('📊 Volume stats: mean=${stats.mean.toStringAsFixed(2)}, std=${stats.standardDeviation.toStringAsFixed(2)}, min=${stats.min.toStringAsFixed(2)}, max=${stats.max.toStringAsFixed(2)}');
    print('📈 Z-score: ${zScore.toStringAsFixed(3)} (threshold: ${StatisticalAnalysisService.standardDeviationThreshold})');
    
    // Create historical data points for the anomaly
    final historicalDataPoints = baseline.map((t) => HistoricalDataPoint(
      date: t.date,
      value: t.volume,
      transactionId: t.id,
    )).toList();
    
    // The current transaction should already be included in the baseline with the new logic
    // No need to add it separately to avoid duplicates
    
    // Sort by date to show chronological order
    historicalDataPoints.sort((a, b) => a.date.compareTo(b.date));
    
    final statisticalCalc = StatisticalCalculation(
      rawData: volumes,
      mean: stats.mean,
      standardDeviation: stats.standardDeviation,
      variance: stats.standardDeviation * stats.standardDeviation,
      min: stats.min,
      max: stats.max,
      threshold: StatisticalAnalysisService.standardDeviationThreshold,
    );
    
    StatisticalAnomaly? anomaly;
    if (isAnomaly) {
      anomaly = StatisticalAnomaly(
        type: StatisticalAnomalyType.volume,
        severity: _statsService.calculateSeverity(zScore.abs()),
        actualValue: transaction.volume,
        expectedValue: stats.mean,
        standardDeviation: stats.standardDeviation,
        zScore: zScore,
        description: _statsService.generateVolumeDescription(transaction.volume, stats, zScore),
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
  Future<(StatisticalAnomaly?, AnomalyAnalysisLog)> analyzeFrequencyAnomalyWithLogging(
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
    
    final stats = _statsService.calculateStatistics(intervals);
    
    // Find the most recent transaction before current one
    final previousTransactions = allHistory
        .where((t) => t.date.isBefore(transaction.date))
        .toList();
    
    // Debug logging for frequency analysis
    print('🔍 FREQUENCY: Transaction ID: ${transaction.id}');
    print('🔍 FREQUENCY: Current transaction: ${transaction.date} (${transaction.vehicleName})');
    print('🔍 FREQUENCY: Total history transactions: ${allHistory.length}');
    print('🔍 FREQUENCY: Previous transactions available: ${previousTransactions.length}');
    
    // Show all history dates for debugging
    if (allHistory.isNotEmpty) {
      final allDates = allHistory.map((t) => '${t.date.toString().substring(0, 16)} (${t.id.substring(0, 8)})').take(10).join('\n  ');
      print('🔍 FREQUENCY: All history dates:\n  $allDates');
    }
    
    // Show previous transaction dates for debugging
    if (previousTransactions.isNotEmpty) {
      final prevDates = previousTransactions.map((t) => '${t.date.toString().substring(0, 16)} (${t.id.substring(0, 8)})').take(5).join('\n  ');
      print('🔍 FREQUENCY: Previous transaction dates:\n  $prevDates');
    }
    
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
    
    print('🔍 FREQUENCY: Most recent previous: ${previousTransactions.first.date} (${daysSinceLastFueling} days ago)');
    
    // Special handling for same-day refuelings (0 days)
    // Same-day refuelings are often normal behavior and shouldn't be flagged as anomalies
    bool isAnomaly = false;
    double zScore = 0.0;
    
    if (daysSinceLastFueling == 0.0) {
      // Same-day refueling - not considered an anomaly
      isAnomaly = false;
      zScore = 0.0; // Neutral z-score for same-day refuelings
    } else {
      // Normal frequency analysis for different-day refuelings
      zScore = (daysSinceLastFueling - stats.mean) / stats.standardDeviation;
      isAnomaly = zScore.abs() > StatisticalAnalysisService.standardDeviationThreshold;
    }
    
    print('📊 Frequency stats: mean=${stats.mean.toStringAsFixed(2)} days, std=${stats.standardDeviation.toStringAsFixed(2)}, intervals analyzed=${intervals.length}');
    print('📈 Days since last fueling: ${daysSinceLastFueling.toStringAsFixed(1)}, Z-score: ${zScore.toStringAsFixed(3)}');
    
    final statisticalCalc = StatisticalCalculation(
      rawData: intervals,
      mean: stats.mean,
      standardDeviation: stats.standardDeviation,
      variance: stats.standardDeviation * stats.standardDeviation,
      min: stats.min,
      max: stats.max,
      threshold: StatisticalAnalysisService.standardDeviationThreshold,
    );
    
    StatisticalAnomaly? anomaly;
    if (isAnomaly) {
      // Create frequency timeline: previous 2 + current + next 2 transactions
      final frequencyTimeline = _createFrequencyTimeline(transaction, allHistory);
      
      anomaly = StatisticalAnomaly(
        type: StatisticalAnomalyType.frequency,
        severity: _statsService.calculateSeverity(zScore.abs()),
        actualValue: daysSinceLastFueling,
        expectedValue: stats.mean,
        standardDeviation: stats.standardDeviation,
        zScore: zScore,
        description: _statsService.generateFrequencyDescription(daysSinceLastFueling, stats, zScore),
        historicalData: frequencyTimeline,
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

  /// Creates a frequency timeline showing previous 2 + current + next 2 transactions
  List<HistoricalDataPoint> _createFrequencyTimeline(
    FuelTransaction currentTransaction,
    List<FuelTransaction> allHistory,
  ) {
    // Sort all history by date
    final sortedHistory = List<FuelTransaction>.from(allHistory)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    // Find the index of the current transaction
    final currentIndex = sortedHistory.indexWhere((t) => t.id == currentTransaction.id);
    
    if (currentIndex == -1) {
      // Current transaction not found in history, return empty timeline
      return [];
    }
    
    // Get previous 2 transactions
    final previousTransactions = <FuelTransaction>[];
    for (int i = currentIndex - 1; i >= 0 && previousTransactions.length < 2; i--) {
      previousTransactions.insert(0, sortedHistory[i]);
    }
    
    // Get next 2 transactions
    final nextTransactions = <FuelTransaction>[];
    for (int i = currentIndex + 1; i < sortedHistory.length && nextTransactions.length < 2; i++) {
      nextTransactions.add(sortedHistory[i]);
    }
    
    // Combine all transactions for the timeline
    final timelineTransactions = [
      ...previousTransactions,
      currentTransaction,
      ...nextTransactions,
    ];
    
    // Convert to HistoricalDataPoint with day intervals
    final timeline = <HistoricalDataPoint>[];
    
    for (int i = 0; i < timelineTransactions.length; i++) {
      final transaction = timelineTransactions[i];
      double daysSincePrevious = 0.0;
      
      // Calculate days since previous transaction
      if (i > 0) {
        daysSincePrevious = transaction.date
            .difference(timelineTransactions[i - 1].date)
            .inDays
            .toDouble();
      }
      
      timeline.add(HistoricalDataPoint(
        date: transaction.date,
        value: daysSincePrevious,
        transactionId: transaction.id,
      ));
    }
    
    return timeline;
  }
}