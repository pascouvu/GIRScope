import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/services/supabase_service.dart';
import 'package:girscope/models/anomaly_detection_log.dart';
import 'package:girscope/services/statistical_analysis_service.dart';
import 'package:girscope/services/anomaly_analyzers.dart';

/// Main anomaly detection service - simplified and modular
class AnomalyDetectionService {
  final SupabaseService _supabaseService = SupabaseService();
  final AnomalyAnalyzers _analyzers = AnomalyAnalyzers();
  final StatisticalAnalysisService _statsService = StatisticalAnalysisService();
  
  // Configuration constants
  static const int _baselineDays = 90;
  static const int _minimumHistoricalSamples = 5;
  
  // Current analysis log
  AnomalyDetectionLog? _currentLog;
  
  /// Main entry point for anomaly analysis
  Future<Map<String, List<StatisticalAnomaly>>> analyzeAnomalies({
    required List<FuelTransaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final stopwatch = Stopwatch()..start();
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final transactionLogs = <TransactionAnalysisLog>[];
    final anomaliesMap = <String, List<StatisticalAnomaly>>{};
    
    _logAnalysisStart(sessionId, startDate, endDate, transactions.length);
    
    // Process each transaction
    for (final transaction in transactions) {
      final (anomalies, transactionLog) = await _analyzeTransaction(
        transaction, startDate, endDate, sessionId
      );
      
      transactionLogs.add(transactionLog);
      if (anomalies.isNotEmpty) {
        anomaliesMap[transaction.id] = anomalies;
      }
    }
    
    stopwatch.stop();
    
    // Store results and log summary
    _currentLog = _createAnalysisLog(
      sessionId, startDate, endDate, transactionLogs, anomaliesMap, stopwatch.elapsed
    );
    
    _logAnalysisSummary(anomaliesMap, stopwatch.elapsed, transactions.length);
    
    return anomaliesMap;
  }
  
  /// Get the current analysis log
  AnomalyDetectionLog? getCurrentAnalysisLog() => _currentLog;
  
  /// Analyze a single transaction for anomalies
  Future<(List<StatisticalAnomaly>, TransactionAnalysisLog)> _analyzeTransaction(
    FuelTransaction transaction,
    DateTime startDate,
    DateTime endDate,
    String sessionId,
  ) async {
    print('\n🚗 Analyzing transaction ${transaction.id} (${transaction.vehicleName})...');
    
    // Get historical data
    final vehicleHistory = await _getVehicleHistory(transaction);
    
    // Use your plan: analyze last 30 days against 30-120 days baseline
    final baselineTransactions = _getBaselineTransactions(vehicleHistory, transaction.date);
    
    // Check if we have enough data
    if (baselineTransactions.length < _minimumHistoricalSamples) {
      return _handleInsufficientData(transaction, vehicleHistory, baselineTransactions);
    }
    
    // Run anomaly analyses
    final anomalies = <StatisticalAnomaly>[];
    final analysisLogs = <AnomalyAnalysisLog>[];
    
    // Consumption analysis
    if (transaction.kcons != null) {
      final (anomaly, log) = _analyzers.analyzeConsumptionAnomalyWithLogging(
        transaction, baselineTransactions
      );
      analysisLogs.add(log);
      if (anomaly != null) anomalies.add(anomaly);
    }
    
    // Volume analysis
    final (volumeAnomaly, volumeLog) = _analyzers.analyzeVolumeAnomalyWithLogging(
      transaction, baselineTransactions
    );
    analysisLogs.add(volumeLog);
    if (volumeAnomaly != null) anomalies.add(volumeAnomaly);
    
    // Frequency analysis
    final (frequencyAnomaly, frequencyLog) = await _analyzers.analyzeFrequencyAnomalyWithLogging(
      transaction, baselineTransactions, vehicleHistory
    );
    analysisLogs.add(frequencyLog);
    if (frequencyAnomaly != null) anomalies.add(frequencyAnomaly);
    
    // Create transaction log
    final transactionLog = TransactionAnalysisLog(
      transactionId: transaction.id,
      vehicleId: transaction.vehicleId,
      vehicleName: transaction.vehicleName,
      transactionDate: transaction.date,
      baseline: _createBaselineAnalysis(vehicleHistory, baselineTransactions, startDate),
      anomalyAnalyses: analysisLogs,
      result: anomalies.isEmpty ? 'NORMAL' : 'ANOMALOUS (${anomalies.length} anomalies)',
    );
    
    return (anomalies, transactionLog);
  }
  
  /// Get vehicle historical data
  Future<List<FuelTransaction>> _getVehicleHistory(FuelTransaction transaction) async {
    if (transaction.vehicleId.isEmpty) {
      print('🔄 Vehicle ID is empty, using vehicle name "${transaction.vehicleName}" for query');
      return await _supabaseService.getVehicleRefuelingDataByName(transaction.vehicleName);
    } else {
      return await _supabaseService.getVehicleRefuelingDataUnlimited(transaction.vehicleId);
    }
  }
  
  /// Get baseline transactions for analysis
  List<FuelTransaction> _getBaselineTransactions(
    List<FuelTransaction> vehicleHistory, 
    DateTime periodStart
  ) {
    // Implement your plan: Use 30-120 days ago as baseline (3 months historical data)
    // This ensures clean separation between analysis period (last 30 days) and baseline
    
    final now = DateTime.now();
    final baselineEnd = now.subtract(const Duration(days: 30)); // 30 days ago
    final baselineStart = now.subtract(const Duration(days: 120)); // 120 days ago
    
    print('🔍 BASELINE: Analysis period: Last 30 days (${now.subtract(const Duration(days: 30)).toString().substring(0, 10)} to ${now.toString().substring(0, 10)})');
    print('🔍 BASELINE: Baseline period: 30-120 days ago (${baselineStart.toString().substring(0, 10)} to ${baselineEnd.toString().substring(0, 10)})');
    print('🔍 BASELINE: Total vehicle history: ${vehicleHistory.length} transactions');
    
    // Get baseline transactions from 30-120 days ago
    var baselineTransactions = vehicleHistory
        .where((t) => t.date.isAfter(baselineStart) && t.date.isBefore(baselineEnd))
        .toList();
    
    print('🔍 BASELINE: Baseline transactions found: ${baselineTransactions.length}');
    
    // Fallback: if insufficient baseline data, extend the baseline period
    if (baselineTransactions.length < _minimumHistoricalSamples && vehicleHistory.isNotEmpty) {
      // Extend baseline to 180 days ago if needed
      final extendedBaselineStart = now.subtract(const Duration(days: 180));
      baselineTransactions = vehicleHistory
          .where((t) => t.date.isAfter(extendedBaselineStart) && t.date.isBefore(baselineEnd))
          .toList();
      print('🔄 Extended baseline to 180 days: ${baselineTransactions.length} transactions');
      
      // Final fallback: use any historical data before 30 days ago
      if (baselineTransactions.length < _minimumHistoricalSamples) {
        baselineTransactions = vehicleHistory
            .where((t) => t.date.isBefore(baselineEnd))
            .toList();
        print('🔄 Using all historical data before 30 days: ${baselineTransactions.length} transactions');
      }
    }
    
    if (baselineTransactions.isNotEmpty) {
      baselineTransactions.sort((a, b) => a.date.compareTo(b.date));
      print('🔍 BASELINE: Final baseline range: ${baselineTransactions.first.date.toString().substring(0, 10)} to ${baselineTransactions.last.date.toString().substring(0, 10)}');
    }
    
    return baselineTransactions;
  }
  
  /// Handle insufficient data case
  (List<StatisticalAnomaly>, TransactionAnalysisLog) _handleInsufficientData(
    FuelTransaction transaction,
    List<FuelTransaction> vehicleHistory,
    List<FuelTransaction> baselineTransactions,
  ) {
    print('❌ Vehicle: ${transaction.vehicleName} - insufficient data (${baselineTransactions.length} transactions)');
    
    return (<StatisticalAnomaly>[], TransactionAnalysisLog(
      transactionId: transaction.id,
      vehicleId: transaction.vehicleId,
      vehicleName: transaction.vehicleName,
      transactionDate: transaction.date,
      baseline: BaselineAnalysis(
        baselineStart: DateTime.now().subtract(Duration(days: _baselineDays)),
        baselineEnd: DateTime.now(),
        totalHistoricalTransactions: vehicleHistory.length,
        usableTransactions: baselineTransactions.length,
        status: 'INSUFFICIENT',
        reason: 'Need at least $_minimumHistoricalSamples samples, found ${baselineTransactions.length}',
      ),
      anomalyAnalyses: [],
      result: 'SKIPPED - Insufficient historical data',
    ));
  }
  
  /// Create baseline analysis object
  BaselineAnalysis _createBaselineAnalysis(
    List<FuelTransaction> vehicleHistory,
    List<FuelTransaction> baselineTransactions,
    DateTime periodStart,
  ) {
    final baselineEnd = periodStart.subtract(const Duration(days: 1));
    final baselineStart = baselineEnd.subtract(const Duration(days: _baselineDays));
    
    return BaselineAnalysis(
      baselineStart: baselineStart,
      baselineEnd: baselineEnd,
      totalHistoricalTransactions: vehicleHistory.length,
      usableTransactions: baselineTransactions.length,
      status: baselineTransactions.length >= _minimumHistoricalSamples ? 'SUFFICIENT' : 'INSUFFICIENT',
      reason: baselineTransactions.length < _minimumHistoricalSamples 
          ? 'Need at least $_minimumHistoricalSamples samples, found ${baselineTransactions.length}'
          : null,
    );
  }
  
  /// Create complete analysis log
  AnomalyDetectionLog _createAnalysisLog(
    String sessionId,
    DateTime startDate,
    DateTime endDate,
    List<TransactionAnalysisLog> transactionLogs,
    Map<String, List<StatisticalAnomaly>> anomaliesMap,
    Duration analysisTime,
  ) {
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
    
    return AnomalyDetectionLog(
      timestamp: DateTime.now(),
      sessionId: sessionId,
      transactionLogs: transactionLogs,
      parameters: AnalysisParameters(
        periodStart: startDate,
        periodEnd: endDate,
        baselineDays: _baselineDays,
        standardDeviationThreshold: StatisticalAnalysisService.standardDeviationThreshold,
        minimumHistoricalSamples: _minimumHistoricalSamples,
        statisticalAnalysisEnabled: true,
      ),
      summary: AnalysisSummary(
        totalTransactionsAnalyzed: transactionLogs.length,
        transactionsWithAnomalies: anomaliesMap.length,
        totalAnomaliesDetected: totalAnomalies,
        anomaliesByType: anomaliesByType,
        anomaliesBySeverity: anomaliesBySeverity,
        analysisTime: analysisTime,
      ),
    );
  }
  
  /// Log analysis start
  void _logAnalysisStart(String sessionId, DateTime startDate, DateTime endDate, int transactionCount) {
    print('🔍 Starting anomaly detection analysis...');
    print('📊 Session ID: $sessionId');
    print('📅 Analysis period: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
    print('📈 Transactions to analyze: $transactionCount');
  }
  
  /// Log analysis summary
  void _logAnalysisSummary(Map<String, List<StatisticalAnomaly>> anomaliesMap, Duration analysisTime, int totalTransactions) {
    final totalAnomalies = anomaliesMap.values.fold(0, (sum, list) => sum + list.length);
    
    print('\n📋 Analysis Summary:');
    print('⏱️ Analysis time: ${analysisTime.inMilliseconds}ms');
    print('📊 Transactions analyzed: $totalTransactions');
    print('⚠️ Transactions with anomalies: ${anomaliesMap.length}');
    print('🔍 Total anomalies detected: $totalAnomalies');
  }
}