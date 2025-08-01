import 'package:flutter/material.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/services/statistical_analysis_service.dart';

/// Widgets for displaying anomaly explanations
class AnomalyExplanationWidgets {
  
  /// Build traditional anomaly explanation
  static Widget buildTraditionalAnomalyExplanation(
    BuildContext context, 
    AnomalyType anomaly, 
    FuelTransaction transaction
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getAnomalyBackgroundColor(anomaly),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getAnomalyBorderColor(anomaly),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                anomaly.emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                anomaly.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getAnomalyTextColor(anomaly),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _generateAnomalyExplanation(anomaly, transaction),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getAnomalyTextColor(anomaly),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build statistical anomaly explanation
  static Widget buildStatisticalAnomalyExplanation(
    BuildContext context, 
    StatisticalAnomaly anomaly, 
    FuelTransaction transaction
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatisticalAnomalyBackgroundColor(anomaly.type),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatisticalAnomalyBorderColor(anomaly.type),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getStatisticalAnomalyEmoji(anomaly.type),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getStatisticalAnomalyTitle(anomaly.type),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getStatisticalAnomalyTextColor(anomaly.type),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSeverityColor(anomaly.severity),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getSeverityLabel(anomaly.severity),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            anomaly.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getStatisticalAnomalyTextColor(anomaly.type),
            ),
          ),
          const SizedBox(height: 12),
          _buildStatisticalDetails(context, anomaly),
          
          // Historical data breakdown removed - frequency timeline in Statistical Details is preferred
        ],
      ),
    );
  }
  
  /// Build statistical details section
  static Widget _buildStatisticalDetails(BuildContext context, StatisticalAnomaly anomaly) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistical Details:',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Actual: ${anomaly.actualValue.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Text(
                  'Expected: ${anomaly.expectedValue.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Z-Score: ${anomaly.zScore.toStringAsFixed(2)} (${anomaly.zScore.abs().toStringAsFixed(1)}σ from mean)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          
          // Add frequency timeline for frequency anomalies
          if (anomaly.type == StatisticalAnomalyType.frequency && 
              anomaly.historicalData != null && 
              anomaly.historicalData!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildFrequencyTimeline(context, anomaly),
          ],
        ],
      ),
    );
  }
  
  // Removed unused _buildHistoricalDataBreakdown method - frequency timeline is preferred
  
  // Helper methods for colors and styling
  static Color _getAnomalyBackgroundColor(AnomalyType anomaly) {
    switch (anomaly) {
      case AnomalyType.manual:
        return Colors.orange.shade50;
      case AnomalyType.forcedMeter:
        return Colors.red.shade50;
      case AnomalyType.maxVolume:
        return Colors.grey.shade50;
      case AnomalyType.meterReset:
        return Colors.yellow.shade50;
      case AnomalyType.highConsumption:
        return Colors.purple.shade50;
    }
  }

  static Color _getAnomalyBorderColor(AnomalyType anomaly) {
    switch (anomaly) {
      case AnomalyType.manual:
        return Colors.orange.shade200;
      case AnomalyType.forcedMeter:
        return Colors.red.shade200;
      case AnomalyType.maxVolume:
        return Colors.grey.shade200;
      case AnomalyType.meterReset:
        return Colors.yellow.shade200;
      case AnomalyType.highConsumption:
        return Colors.purple.shade200;
    }
  }

  static Color _getAnomalyTextColor(AnomalyType anomaly) {
    switch (anomaly) {
      case AnomalyType.manual:
        return Colors.orange.shade800;
      case AnomalyType.forcedMeter:
        return Colors.red.shade800;
      case AnomalyType.maxVolume:
        return Colors.grey.shade800;
      case AnomalyType.meterReset:
        return Colors.yellow.shade800;
      case AnomalyType.highConsumption:
        return Colors.purple.shade800;
    }
  }
  
  static Color _getStatisticalAnomalyBackgroundColor(StatisticalAnomalyType type) {
    switch (type) {
      case StatisticalAnomalyType.consumption:
        return Colors.blue.shade50;
      case StatisticalAnomalyType.volume:
        return Colors.teal.shade50;
      case StatisticalAnomalyType.frequency:
        return Colors.indigo.shade50;
      case StatisticalAnomalyType.timing:
        return Colors.purple.shade50;
    }
  }

  static Color _getStatisticalAnomalyBorderColor(StatisticalAnomalyType type) {
    switch (type) {
      case StatisticalAnomalyType.consumption:
        return Colors.blue.shade200;
      case StatisticalAnomalyType.volume:
        return Colors.teal.shade200;
      case StatisticalAnomalyType.frequency:
        return Colors.indigo.shade200;
      case StatisticalAnomalyType.timing:
        return Colors.purple.shade200;
    }
  }

  static Color _getStatisticalAnomalyTextColor(StatisticalAnomalyType type) {
    switch (type) {
      case StatisticalAnomalyType.consumption:
        return Colors.blue.shade800;
      case StatisticalAnomalyType.volume:
        return Colors.teal.shade800;
      case StatisticalAnomalyType.frequency:
        return Colors.indigo.shade800;
      case StatisticalAnomalyType.timing:
        return Colors.purple.shade800;
    }
  }

  static String _getStatisticalAnomalyEmoji(StatisticalAnomalyType type) {
    switch (type) {
      case StatisticalAnomalyType.consumption:
        return '📊';
      case StatisticalAnomalyType.volume:
        return '📈';
      case StatisticalAnomalyType.frequency:
        return '⏱️';
      case StatisticalAnomalyType.timing:
        return '🕐';
    }
  }

  static String _getStatisticalAnomalyTitle(StatisticalAnomalyType type) {
    switch (type) {
      case StatisticalAnomalyType.consumption:
        return 'Statistical Consumption Anomaly';
      case StatisticalAnomalyType.volume:
        return 'Statistical Volume Anomaly';
      case StatisticalAnomalyType.frequency:
        return 'Statistical Frequency Anomaly';
      case StatisticalAnomalyType.timing:
        return 'Statistical Timing Anomaly';
    }
  }

  static Color _getSeverityColor(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.critical:
        return Colors.red.shade600;
      case AnomalySeverity.high:
        return Colors.orange.shade600;
      case AnomalySeverity.medium:
        return Colors.yellow.shade600;
      case AnomalySeverity.low:
        return Colors.green.shade600;
    }
  }

  static String _getSeverityLabel(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.critical:
        return 'CRITICAL';
      case AnomalySeverity.high:
        return 'HIGH';
      case AnomalySeverity.medium:
        return 'MEDIUM';
      case AnomalySeverity.low:
        return 'LOW';
    }
  }

  static String _getMetricName(StatisticalAnomalyType type) {
    switch (type) {
      case StatisticalAnomalyType.consumption:
        return 'Consumption';
      case StatisticalAnomalyType.volume:
        return 'Volume';
      case StatisticalAnomalyType.frequency:
        return 'Days';
      case StatisticalAnomalyType.timing:
        return 'Timing';
    }
  }

  static String _getMetricUnit(StatisticalAnomalyType type) {
    switch (type) {
      case StatisticalAnomalyType.consumption:
        return ' L/100km';
      case StatisticalAnomalyType.volume:
        return 'L';
      case StatisticalAnomalyType.frequency:
        return ' days';
      case StatisticalAnomalyType.timing:
        return ' hours';
    }
  }
  
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  /// Build frequency timeline showing previous 2 + current + next 2 transactions
  static Widget _buildFrequencyTimeline(BuildContext context, StatisticalAnomaly anomaly) {
    final timeline = anomaly.historicalData!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency Timeline:',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Showing refueling pattern (typical: ${anomaly.expectedValue.toStringAsFixed(1)} days)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        
        // Timeline visualization
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: timeline.asMap().entries.map((entry) {
              final index = entry.key;
              final dataPoint = entry.value;
              final isCurrentTransaction = index == 2; // Middle transaction (current)
              final isAnomalousInterval = isCurrentTransaction && dataPoint.value > anomaly.expectedValue + anomaly.standardDeviation;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: isCurrentTransaction 
                      ? (isAnomalousInterval ? Colors.red.shade50 : Colors.blue.shade50)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isCurrentTransaction 
                        ? (isAnomalousInterval ? Colors.red.shade300 : Colors.blue.shade300)
                        : Colors.grey.shade200,
                    width: isCurrentTransaction ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Date
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          if (isCurrentTransaction) ...[
                            Icon(
                              isAnomalousInterval ? Icons.warning : Icons.arrow_forward,
                              size: 14,
                              color: isAnomalousInterval ? Colors.red.shade600 : Colors.blue.shade600,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            _formatDate(dataPoint.date),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: isCurrentTransaction ? FontWeight.bold : FontWeight.normal,
                              color: isCurrentTransaction 
                                  ? (isAnomalousInterval ? Colors.red.shade800 : Colors.blue.shade800)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Days since previous (skip first transaction as it has no previous)
                    if (index > 0) ...[
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isAnomalousInterval 
                                ? Colors.red.shade100 
                                : (dataPoint.value <= anomaly.expectedValue + anomaly.standardDeviation 
                                    ? Colors.green.shade100 
                                    : Colors.orange.shade100),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${dataPoint.value.toStringAsFixed(0)} days',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                              color: isAnomalousInterval 
                                  ? Colors.red.shade800
                                  : (dataPoint.value <= anomaly.expectedValue + anomaly.standardDeviation 
                                      ? Colors.green.shade800 
                                      : Colors.orange.shade800),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ] else ...[
                      const Expanded(
                        flex: 1,
                        child: Text(
                          '—',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                    
                    // Status indicator
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isCurrentTransaction) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: isAnomalousInterval ? Colors.red.shade600 : Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                isAnomalousInterval ? 'ANOMALY' : 'CURRENT',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ] else if (index > 0) ...[
                            Icon(
                              dataPoint.value <= anomaly.expectedValue + anomaly.standardDeviation 
                                  ? Icons.check_circle 
                                  : Icons.warning,
                              size: 12,
                              color: dataPoint.value <= anomaly.expectedValue + anomaly.standardDeviation 
                                  ? Colors.green.shade600 
                                  : Colors.orange.shade600,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 6),
        
        // Legend
        Row(
          children: [
            _buildLegendItem(context, Colors.green.shade100, Colors.green.shade800, 'Normal'),
            const SizedBox(width: 12),
            _buildLegendItem(context, Colors.orange.shade100, Colors.orange.shade800, 'High'),
            const SizedBox(width: 12),
            _buildLegendItem(context, Colors.red.shade100, Colors.red.shade800, 'Anomaly'),
          ],
        ),
      ],
    );
  }
  
  /// Build legend item for frequency timeline
  static Widget _buildLegendItem(BuildContext context, Color bgColor, Color textColor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: textColor.withValues(alpha: 0.3)),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
  
  static String _generateAnomalyExplanation(AnomalyType anomaly, FuelTransaction transaction) {
    switch (anomaly) {
      case AnomalyType.manual:
        return 'This transaction was flagged as manual fueling. The fuel volume (${transaction.volume.toStringAsFixed(1)} L) was entered manually rather than automatically measured.';
      case AnomalyType.forcedMeter:
        return 'The meter reading was forced during this transaction, typically due to discrepancies between expected and actual readings.';
      case AnomalyType.maxVolume:
        return 'The maximum volume limit was reached during this fueling operation (${transaction.volume.toStringAsFixed(1)} L).';
      case AnomalyType.meterReset:
        String meterType = '';
        if (transaction.newKmeter && transaction.newHmeter) {
          meterType = 'odometer and hour meter';
        } else if (transaction.newKmeter) {
          meterType = 'odometer';
        } else if (transaction.newHmeter) {
          meterType = 'hour meter';
        }
        return 'The $meterType was reset during this transaction period, creating a discontinuity in tracking.';
      case AnomalyType.highConsumption:
        return 'The calculated fuel consumption of ${transaction.kcons?.toStringAsFixed(1) ?? 'N/A'} L/100km exceeds the normal threshold.';
    }
  }
}