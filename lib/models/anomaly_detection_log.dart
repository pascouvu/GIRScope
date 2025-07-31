class AnomalyDetectionLog {
  final DateTime timestamp;
  final String sessionId;
  final List<TransactionAnalysisLog> transactionLogs;
  final AnalysisParameters parameters;
  final AnalysisSummary summary;

  AnomalyDetectionLog({
    required this.timestamp,
    required this.sessionId,
    required this.transactionLogs,
    required this.parameters,
    required this.summary,
  });
}

class TransactionAnalysisLog {
  final String transactionId;
  final String vehicleId;
  final String vehicleName;
  final DateTime transactionDate;
  final BaselineAnalysis baseline;
  final List<AnomalyAnalysisLog> anomalyAnalyses;
  final String result;

  TransactionAnalysisLog({
    required this.transactionId,
    required this.vehicleId,
    required this.vehicleName,
    required this.transactionDate,
    required this.baseline,
    required this.anomalyAnalyses,
    required this.result,
  });
}

class BaselineAnalysis {
  final DateTime baselineStart;
  final DateTime baselineEnd;
  final int totalHistoricalTransactions;
  final int usableTransactions;
  final String status;
  final String? reason;

  BaselineAnalysis({
    required this.baselineStart,
    required this.baselineEnd,
    required this.totalHistoricalTransactions,
    required this.usableTransactions,
    required this.status,
    this.reason,
  });
}

class AnomalyAnalysisLog {
  final String analysisType;
  final bool hasData;
  final int sampleCount;
  final StatisticalCalculation? statistics;
  final double? actualValue;
  final double? zScore;
  final bool isAnomaly;
  final String? severity;
  final String? description;
  final String notes;

  AnomalyAnalysisLog({
    required this.analysisType,
    required this.hasData,
    required this.sampleCount,
    this.statistics,
    this.actualValue,
    this.zScore,
    required this.isAnomaly,
    this.severity,
    this.description,
    required this.notes,
  });
}

class StatisticalCalculation {
  final List<double> rawData;
  final double mean;
  final double standardDeviation;
  final double variance;
  final double min;
  final double max;
  final double threshold;

  StatisticalCalculation({
    required this.rawData,
    required this.mean,
    required this.standardDeviation,
    required this.variance,
    required this.min,
    required this.max,
    required this.threshold,
  });
}

class AnalysisParameters {
  final DateTime periodStart;
  final DateTime periodEnd;
  final int baselineDays;
  final double standardDeviationThreshold;
  final int minimumHistoricalSamples;
  final bool statisticalAnalysisEnabled;

  AnalysisParameters({
    required this.periodStart,
    required this.periodEnd,
    required this.baselineDays,
    required this.standardDeviationThreshold,
    required this.minimumHistoricalSamples,
    required this.statisticalAnalysisEnabled,
  });
}

class AnalysisSummary {
  final int totalTransactionsAnalyzed;
  final int transactionsWithAnomalies;
  final int totalAnomaliesDetected;
  final Map<String, int> anomaliesByType;
  final Map<String, int> anomaliesBySeverity;
  final Duration analysisTime;

  AnalysisSummary({
    required this.totalTransactionsAnalyzed,
    required this.transactionsWithAnomalies,
    required this.totalAnomaliesDetected,
    required this.anomaliesByType,
    required this.anomaliesBySeverity,
    required this.analysisTime,
  });
}