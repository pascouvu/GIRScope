import 'package:flutter/material.dart';
import 'package:girscope/models/fuel_transaction.dart';

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
                    ...transaction.anomalies.map((anomaly) => _buildAnomalyExplanation(context, anomaly)),
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

  Widget _buildAnomalyExplanation(BuildContext context, AnomalyType anomaly) {
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
            _getAnomalyExplanation(anomaly),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getAnomalyTextColor(anomaly),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionCalculationCard(BuildContext context) {
    final isHighConsumption = transaction.kcons! > 50;
    
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
                      'This consumption rate (${transaction.kcons!.toStringAsFixed(1)} L/100km) exceeds the normal threshold of 50 L/100km.',
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
                        'Normal consumption rate (below 50 L/100km threshold)',
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

  String _getAnomalyExplanation(AnomalyType anomaly) {
    switch (anomaly) {
      case AnomalyType.manual:
        return 'This transaction was flagged as manual fueling. This means the fuel volume was entered manually rather than automatically measured by the system, which could indicate a system malfunction or manual override.';
      case AnomalyType.forcedMeter:
        return 'The meter reading was forced during this transaction. This typically occurs when there\'s a discrepancy between expected and actual meter readings, requiring manual intervention.';
      case AnomalyType.maxVolume:
        return 'The maximum volume limit was reached during this fueling operation. This could indicate the vehicle\'s tank capacity was exceeded or there was an issue with the volume measurement system.';
      case AnomalyType.meterReset:
        return 'The odometer or hour meter was reset during this transaction period. This creates a discontinuity in the mileage/hour tracking and affects consumption calculations.';
      case AnomalyType.highConsumption:
        return 'The calculated fuel consumption (${transaction.kcons?.toStringAsFixed(1) ?? 'N/A'} L/100km) exceeds the normal threshold of 50 L/100km. This could indicate inefficient driving, vehicle maintenance issues, or data recording errors.';
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}