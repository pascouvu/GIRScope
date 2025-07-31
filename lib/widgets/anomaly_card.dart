import 'package:flutter/material.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/services/statistical_analysis_service.dart';
import 'package:girscope/views/anomaly_detail_screen.dart';

class AnomalyCard extends StatelessWidget {
  final FuelTransaction transaction;

  const AnomalyCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
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
            // Header with date and basic info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.warning,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(transaction.date),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(transaction.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Vehicle, Driver, Site in compact format
            Text(
              '🚗 ${transaction.vehicleName}  👤 ${transaction.driverName}  📍 ${transaction.siteName}',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            
            const Divider(height: 1),
            const SizedBox(height: 12),
            
            // Compact data display
            _buildCompactDataDisplay(context),
            
            const SizedBox(height: 12),
            
            // Anomaly descriptions and details button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Traditional anomalies
                      ...transaction.anomalies.map((anomaly) => 
                        _buildCompactAnomalyDescription(context, anomaly)
                      ),
                      // Statistical anomalies
                      ...transaction.allStatisticalAnomalies.map((anomaly) =>
                        _buildCompactStatisticalAnomalyDescription(context, anomaly)
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AnomalyDetailScreen(transaction: transaction),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildCompactDataDisplay(BuildContext context) {
    // Calculate consumption correctly
    double calculatedConsumption = transaction.kdelta != null && transaction.kdelta! > 0 
        ? (transaction.volume / transaction.kdelta!) * 100 
        : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_gas_station,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Vol: ${transaction.volume.toStringAsFixed(1)}L  '
              '${transaction.kdelta != null ? 'Dist: ${transaction.kdelta!.toStringAsFixed(0)}km  ' : ''}'
              '${transaction.kdelta != null ? 'Cons: ${calculatedConsumption.toStringAsFixed(1)}L/100km' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAnomalyDescription(BuildContext context, AnomalyType anomaly) {
    String description;
    String status;
    Color statusColor;

    switch (anomaly) {
      case AnomalyType.manual:
        description = 'Manual fueling detected';
        status = 'WARNING';
        statusColor = Colors.orange;
        break;
      case AnomalyType.forcedMeter:
        description = 'Forced meter reading';
        status = 'CRITICAL';
        statusColor = Colors.red;
        break;
      case AnomalyType.maxVolume:
        description = 'Maximum volume reached';
        status = 'INFO';
        statusColor = Colors.grey;
        break;
      case AnomalyType.meterReset:
        description = 'Meter reset detected';
        status = 'WARNING';
        statusColor = Colors.yellow.shade700;
        break;
      case AnomalyType.highConsumption:
        description = 'High consumption detected';
        status = 'WARNING';
        statusColor = Colors.purple;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              status,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            anomaly.emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatisticalAnomalyDescription(BuildContext context, StatisticalAnomaly anomaly) {
    String description;
    String status;
    Color statusColor;
    String emoji;

    // Determine status and color based on severity
    switch (anomaly.severity) {
      case AnomalySeverity.critical:
        status = 'CRITICAL';
        statusColor = Colors.red;
        break;
      case AnomalySeverity.high:
        status = 'HIGH';
        statusColor = Colors.orange;
        break;
      case AnomalySeverity.medium:
        status = 'MEDIUM';
        statusColor = Colors.yellow.shade700;
        break;
      case AnomalySeverity.low:
        status = 'OK';
        statusColor = Colors.green;
        break;
    }

    // Generate description based on anomaly type
    switch (anomaly.type) {
      case StatisticalAnomalyType.consumption:
        emoji = '📊';
        if (anomaly.severity == AnomalySeverity.low) {
          description = 'Consumption within normal range (${anomaly.actualValue.toStringAsFixed(1)}L/100km)';
        } else {
          description = 'Consumption ${anomaly.actualValue.toStringAsFixed(1)}L/100km vs expected ${anomaly.expectedValue.toStringAsFixed(1)}L/100km';
        }
        break;
      case StatisticalAnomalyType.volume:
        emoji = '📈';
        if (anomaly.severity == AnomalySeverity.low) {
          description = 'Volume within normal range (${anomaly.actualValue.toStringAsFixed(1)}L)';
        } else {
          description = 'Volume ${anomaly.actualValue.toStringAsFixed(1)}L vs expected ${anomaly.expectedValue.toStringAsFixed(1)}L';
        }
        break;
      case StatisticalAnomalyType.frequency:
        emoji = '⏱️';
        if (anomaly.actualValue == 0.0) {
          description = 'Same-day refueling (normal behavior)';
          status = 'OK';
          statusColor = Colors.green;
        } else if (anomaly.severity == AnomalySeverity.low) {
          description = 'Refueling frequency normal (${anomaly.actualValue.toStringAsFixed(0)} days)';
        } else {
          description = 'Typical ${anomaly.expectedValue.toStringAsFixed(0)} days but period: ${anomaly.actualValue.toStringAsFixed(0)} days';
        }
        break;
      case StatisticalAnomalyType.timing:
        emoji = '🕐';
        if (anomaly.severity == AnomalySeverity.low) {
          description = 'Timing within normal range';
        } else {
          description = 'Unusual timing pattern detected';
        }
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              status,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}