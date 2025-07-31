import 'package:flutter/material.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/services/anomaly_detection_service.dart';
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
                        _formatDate(transaction.date),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(transaction.date),
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
            _buildInfoRow(context, 'Vehicle', transaction.vehicleName, Icons.directions_car),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'Driver', transaction.driverName, Icons.person),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'Site', transaction.siteName, Icons.location_on),
            const SizedBox(height: 16),
            const Divider(),
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
                const SizedBox(width: 12),
                if (transaction.kdelta != null)
                  Expanded(
                    child: _buildValueCard(
                      context,
                      'Distance',
                      '${transaction.kdelta!.toStringAsFixed(0)} km',
                      Icons.route,
                    ),
                  ),
                if (transaction.kcons != null)
                  Expanded(
                    child: _buildValueCard(
                      context,
                      'Consumption',
                      '${transaction.kcons!.toStringAsFixed(1)} L/100km',
                      Icons.analytics,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Traditional anomalies
                      ...transaction.anomalies.map((anomaly) => 
                        _buildAnomalyChip(context, anomaly)
                      ),
                      // Statistical anomalies
                      ...transaction.allStatisticalAnomalies.map((anomaly) =>
                        _buildStatisticalAnomalyChip(context, anomaly)
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

  Widget _buildAnomalyChip(BuildContext context, AnomalyType anomaly) {
    Color chipColor;
    Color textColor;

    switch (anomaly) {
      case AnomalyType.manual:
        chipColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case AnomalyType.forcedMeter:
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case AnomalyType.maxVolume:
        chipColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        break;
      case AnomalyType.meterReset:
        chipColor = Colors.yellow.shade100;
        textColor = Colors.yellow.shade800;
        break;
      case AnomalyType.highConsumption:
        chipColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            anomaly.emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            anomaly.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticalAnomalyChip(BuildContext context, StatisticalAnomaly anomaly) {
    Color chipColor;
    Color textColor;
    String emoji;
    String label;

    switch (anomaly.type) {
      case StatisticalAnomalyType.consumption:
        chipColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        emoji = '📊';
        label = 'Consumption';
        break;
      case StatisticalAnomalyType.volume:
        chipColor = Colors.teal.shade100;
        textColor = Colors.teal.shade800;
        emoji = '📈';
        label = 'Volume';
        break;
      case StatisticalAnomalyType.frequency:
        chipColor = Colors.indigo.shade100;
        textColor = Colors.indigo.shade800;
        emoji = '⏱️';
        label = 'Frequency';
        break;
      case StatisticalAnomalyType.timing:
        chipColor = Colors.cyan.shade100;
        textColor = Colors.cyan.shade800;
        emoji = '🕐';
        label = 'Timing';
        break;
    }

    // Add severity indicator
    String severityIndicator = '';
    switch (anomaly.severity) {
      case AnomalySeverity.critical:
        severityIndicator = '🔴';
        break;
      case AnomalySeverity.high:
        severityIndicator = '🟠';
        break;
      case AnomalySeverity.medium:
        severityIndicator = '🟡';
        break;
      case AnomalySeverity.low:
        severityIndicator = '🟢';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 2),
          Text(
            severityIndicator,
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 11,
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