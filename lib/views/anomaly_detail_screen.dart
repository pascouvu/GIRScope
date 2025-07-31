import 'package:flutter/material.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/services/anomaly_detection_service.dart';

class AnomalyDetailScreen extends StatelessWidget {
  final FuelTransaction transaction;

  const AnomalyDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anomaly Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Overview Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.warning,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transaction Overview',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDateTime(transaction.date),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildInfoRow(context, 'Vehicle', transaction.vehicleName, Icons.directions_car),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, 'Driver', transaction.driverName, Icons.person),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, 'Site', transaction.siteName, Icons.location_on),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildValueCard(
                            context,
                            'Volume',
                            '${transaction.volume.toStringAsFixed(1)} L',
                            Icons.local_gas_station,
                          ),
                        ),
                        if (transaction.kdelta != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildValueCard(
                              context,
                              'Distance',
                              '${transaction.kdelta!.toStringAsFixed(0)} km',
                              Icons.route,
                            ),
                          ),
                        ],
                        if (transaction.kcons != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildValueCard(
                              context,
                              'Consumption',
                              '${transaction.kcons!.toStringAsFixed(1)} L/100km',
                              Icons.analytics,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Anomaly Analysis Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Anomaly Analysis',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Check if any anomalies exist
                    if (transaction.anomalies.isEmpty && !transaction.hasStatisticalAnomalies)
                      const Text('No anomalies found for this transaction.'),
                    
                    // Traditional anomalies
                    ...transaction.anomalies.map((anomaly) {
                      print('Processing traditional anomaly: ${anomaly.label}');
                      return _buildAnomalyExplanation(context, anomaly, transaction);
                    }),
                    
                    // Statistical anomalies
                    ...transaction.allStatisticalAnomalies.map((anomaly) {
                      print('Processing statistical anomaly: ${anomaly.type}');
                      return _buildStatisticalAnomalyExplanation(context, anomaly, transaction);
                    }),
                  ],
                ),
              ),
            ),
            
            if (transaction.kcons != null && transaction.kdelta != null) ...[
              const SizedBox(height: 16),
              _buildConsumptionCalculationCard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildValueCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomalyExplanation(BuildContext context, AnomalyType anomaly, FuelTransaction transaction) {
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
            (() {
              String explanation = '';
              switch (anomaly) {
                case AnomalyType.manual:
                  explanation = 'This transaction on ${_formatDate(transaction.date)} was flagged as manual fueling. This means the fuel volume (${transaction.volume.toStringAsFixed(1)} L) was entered manually rather than automatically measured by the system, which could indicate a system malfunction or manual override.';
                  break;
                case AnomalyType.forcedMeter:
                  explanation = 'The meter reading was forced during this transaction on ${_formatDate(transaction.date)}. This typically occurs when there\'s a discrepancy between expected and actual meter readings, requiring manual intervention.';
                  break;
                case AnomalyType.maxVolume:
                  explanation = 'The maximum volume limit was reached during this fueling operation on ${_formatDate(transaction.date)}. A volume of ${transaction.volume.toStringAsFixed(1)} L was recorded, which could indicate the vehicle\'s tank capacity was exceeded or there was an issue with the volume measurement system.';
                  break;
                case AnomalyType.meterReset:
                  String meterType = '';
                  if (transaction.newKmeter && transaction.newHmeter) {
                    meterType = 'odometer and hour meter';
                  } else if (transaction.newKmeter) {
                    meterType = 'odometer';
                  } else if (transaction.newHmeter) {
                    meterType = 'hour meter';
                  }
                  explanation = 'The $meterType was reset during this transaction period on ${_formatDate(transaction.date)}. This creates a discontinuity in the mileage/hour tracking and affects consumption calculations.';
                  break;
                case AnomalyType.highConsumption:
                  explanation = 'The calculated fuel consumption of ${transaction.kcons?.toStringAsFixed(1) ?? 'N/A'} L/100km on ${_formatDate(transaction.date)} exceeds the normal threshold of 50 L/100km. This could indicate inefficient driving, vehicle maintenance issues, or data recording errors.';
                  break;
              }
              return explanation;
            })(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getAnomalyTextColor(anomaly),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticalAnomalyExplanation(BuildContext context, StatisticalAnomaly anomaly, FuelTransaction transaction) {
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
          Container(
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
              ],
            ),
          ),
          
          // Show historical data breakdown if available
          if (anomaly.historicalData != null && anomaly.historicalData!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildHistoricalDataBreakdown(context, anomaly, transaction),
          ],
        ],
      ),
    );
  }

  Color _getStatisticalAnomalyBackgroundColor(StatisticalAnomalyType type) {
    switch (type) {
      case StatisticalAnomalyType.consumption:
        return Colors.blue.shade50;
      case StatisticalAnomalyType.volume:
        return Colors.teal.shade50;
      case StatisticalAnomalyType.frequency:
        return Colors.indigo.shade50;
      case StatisticalAnomalyType.timing:
        return Colors.cyan.shade50;
    }
  }

  Color _getStatisticalAnomalyBorderColor(StatisticalAnomalyType type) {
    switch (type) {
      case StatisticalAnomalyType.consumption:
        return Colors.blue.shade200;
      case StatisticalAnomalyType.volume:
        return Colors.teal.shade200;
      case StatisticalAnomalyType.frequency:
        return Colors.indigo.shade200;
      case StatisticalAnomalyType.timing:
        return Colors.cyan.shade200;
    }
  }

  Color _getStatisticalAnomalyTextColor(StatisticalAnomalyType type) {
    switch (type) {
      case StatisticalAnomalyType.consumption:
        return Colors.blue.shade800;
      case StatisticalAnomalyType.volume:
        return Colors.teal.shade800;
      case StatisticalAnomalyType.frequency:
        return Colors.indigo.shade800;
      case StatisticalAnomalyType.timing:
        return Colors.cyan.shade800;
    }
  }

  String _getStatisticalAnomalyEmoji(StatisticalAnomalyType type) {
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

  String _getStatisticalAnomalyTitle(StatisticalAnomalyType type) {
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

  Color _getSeverityColor(AnomalySeverity severity) {
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

  String _getSeverityLabel(AnomalySeverity severity) {
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

  Widget _buildConsumptionCalculationCard(BuildContext context) {
    // Calculate dynamic threshold from historical data instead of hardcoded 50
    double dynamicThreshold = 50.0; // fallback
    bool isHighConsumption = false;
    
    // Try to get the baseline consumption from statistical anomalies
    if (transaction.hasStatisticalAnomalies) {
      final consumptionAnomaly = transaction.allStatisticalAnomalies
          .where((a) => a.type == StatisticalAnomalyType.consumption)
          .firstOrNull;
      if (consumptionAnomaly != null) {
        // Use 2 standard deviations above the mean as the threshold
        dynamicThreshold = consumptionAnomaly.expectedValue + (2 * consumptionAnomaly.standardDeviation);
        isHighConsumption = transaction.kcons! > dynamicThreshold;
      }
    }
    
    // If no statistical data available, use traditional logic
    if (!transaction.hasStatisticalAnomalies) {
      isHighConsumption = transaction.kcons! > 50;
      dynamicThreshold = 50.0;
    }
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isHighConsumption 
            ? Colors.purple.shade300
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: isHighConsumption ? Colors.purple : Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Consumption Calculation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isHighConsumption ? Colors.purple : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Formula: Volume ÷ Distance × 100',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Calculation: ${transaction.volume.toStringAsFixed(1)}L ÷ ${transaction.kdelta!.toStringAsFixed(0)}km × 100',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Result: ${transaction.kcons!.toStringAsFixed(1)} L/100km',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            if (isHighConsumption) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.purple.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'High Consumption Alert',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This consumption rate (${transaction.kcons!.toStringAsFixed(1)} L/100km) exceeds the normal threshold of ${dynamicThreshold.toStringAsFixed(1)} L/100km.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Normal consumption rate (below ${dynamicThreshold.toStringAsFixed(1)} L/100km threshold)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getAnomalyBackgroundColor(AnomalyType anomaly) {
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

  Color _getAnomalyBorderColor(AnomalyType anomaly) {
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

  Color _getAnomalyTextColor(AnomalyType anomaly) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildHistoricalDataBreakdown(BuildContext context, StatisticalAnomaly anomaly, FuelTransaction currentTransaction) {
    final historicalData = anomaly.historicalData!;
    final metricName = _getMetricName(anomaly.type);
    final unit = _getMetricUnit(anomaly.type);
    
    // Create a combined list including the current anomalous transaction
    final allTransactions = <({DateTime date, double value, bool isAnomaly})>[
      // Add all historical transactions
      ...historicalData.map((dataPoint) => (
        date: dataPoint.date,
        value: dataPoint.value,
        isAnomaly: false,
      )),
      // Add the current anomalous transaction
      (
        date: currentTransaction.date,
        value: anomaly.actualValue,
        isAnomaly: true,
      ),
    ];
    
    // Sort all transactions by date (most recent first)
    allTransactions.sort((a, b) => b.date.compareTo(a.date));
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                size: 16,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Historical Data Breakdown',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Baseline calculation based on ${historicalData.length} historical transactions:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          
          // Historical transactions list
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Date',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            metricName,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // All transactions (historical + current) in chronological order
                  ...allTransactions.map((transactionData) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: transactionData.isAnomaly ? Colors.red.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: transactionData.isAnomaly ? Colors.red.shade300 : Colors.grey.shade200,
                        width: transactionData.isAnomaly ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              if (transactionData.isAnomaly) ...[
                                Icon(
                                  Icons.warning,
                                  size: 16,
                                  color: Colors.red.shade600,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                _formatDate(transactionData.date),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: transactionData.isAnomaly ? FontWeight.bold : FontWeight.normal,
                                  color: transactionData.isAnomaly ? Colors.red.shade800 : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${transactionData.value.toStringAsFixed(1)}$unit',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: transactionData.isAnomaly ? FontWeight.bold : FontWeight.w500,
                              color: transactionData.isAnomaly ? Colors.red.shade800 : null,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Calculation summary
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calculation Summary:',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Average of ${historicalData.length} values = ${anomaly.expectedValue.toStringAsFixed(1)}$unit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue.shade700,
                  ),
                ),
                Text(
                  'Standard deviation = ${anomaly.standardDeviation.toStringAsFixed(1)}$unit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue.shade700,
                  ),
                ),
                Text(
                  'Current value (${anomaly.actualValue.toStringAsFixed(1)}$unit) is ${anomaly.zScore.abs().toStringAsFixed(1)}σ from mean',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMetricName(StatisticalAnomalyType type) {
    switch (type) {
      case StatisticalAnomalyType.consumption:
        return 'Consumption';
      case StatisticalAnomalyType.volume:
        return 'Volume';
      case StatisticalAnomalyType.frequency:
        return 'Days';
      case StatisticalAnomalyType.timing:
        return 'Hour';
    }
  }

  String _getMetricUnit(StatisticalAnomalyType type) {
    switch (type) {
      case StatisticalAnomalyType.consumption:
        return ' L/100km';
      case StatisticalAnomalyType.volume:
        return 'L';
      case StatisticalAnomalyType.frequency:
        return ' days';
      case StatisticalAnomalyType.timing:
        return 'h';
    }
  }
}