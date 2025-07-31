import 'package:flutter/material.dart';
import 'package:girscope/services/anomaly_detection_service.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/services/statistical_analysis_service.dart';

class StatisticalAnomalyDemo extends StatefulWidget {
  const StatisticalAnomalyDemo({super.key});

  @override
  State<StatisticalAnomalyDemo> createState() => _StatisticalAnomalyDemoState();
}

class _StatisticalAnomalyDemoState extends State<StatisticalAnomalyDemo> {
  final AnomalyDetectionService _anomalyService = AnomalyDetectionService();
  bool _isAnalyzing = false;
  Map<String, List<StatisticalAnomaly>>? _results;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Statistical Anomaly Detection Demo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'This demo shows how the new statistical anomaly detection works by analyzing patterns in fuel consumption, volume, frequency, and timing.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isAnalyzing ? null : _runDemo,
              child: _isAnalyzing
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Analyzing...'),
                      ],
                    )
                  : const Text('Run Statistical Analysis Demo'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade600, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Analysis Error',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
            ],
            if (_results != null) ...[
              const SizedBox(height: 16),
              _buildResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_results!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
            const SizedBox(width: 8),
            Text(
              'No statistical anomalies detected in the sample data.',
              style: TextStyle(color: Colors.green.shade700),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistical Anomalies Found: ${_results!.length}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._results!.entries.map((entry) => _buildAnomalyResult(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildAnomalyResult(String transactionId, List<StatisticalAnomaly> anomalies) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            'Transaction: ${transactionId.substring(0, 8)}...',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...anomalies.map((anomaly) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(anomaly.severity),
                    borderRadius: BorderRadius.circular(4),
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
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_getTypeLabel(anomaly.type)}: ${anomaly.description}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _runDemo() async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
      _results = null;
    });

    try {
      // Create sample transactions for demo
      final sampleTransactions = _createSampleTransactions();
      
      final results = await _anomalyService.analyzeAnomalies(
        transactions: sampleTransactions,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );

      setState(() {
        _results = results;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isAnalyzing = false;
      });
    }
  }

  List<FuelTransaction> _createSampleTransactions() {
    final now = DateTime.now();
    return [
      FuelTransaction(
        id: 'demo_1',
        transacId: '1001',
        date: now.subtract(const Duration(days: 1)),
        vehicleName: 'Demo Vehicle 1',
        vehicleId: 'vehicle_1',
        driverName: 'Demo Driver 1',
        driverId: 'driver_1',
        siteName: 'Demo Site',
        volume: 45.5,
        kdelta: 120.0,
        kcons: 37.9,
        hcons: null,
        manual: false,
        mtrForced: false,
        volMax: false,
        newKmeter: false,
        newHmeter: false,
      ),
      FuelTransaction(
        id: 'demo_2',
        transacId: '1002',
        date: now.subtract(const Duration(days: 2)),
        vehicleName: 'Demo Vehicle 1',
        vehicleId: 'vehicle_1',
        driverName: 'Demo Driver 1',
        driverId: 'driver_1',
        siteName: 'Demo Site',
        volume: 85.2, // Unusually high volume
        kdelta: 95.0,
        kcons: 89.7, // Very high consumption
        hcons: null,
        manual: false,
        mtrForced: false,
        volMax: false,
        newKmeter: false,
        newHmeter: false,
      ),
    ];
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

  String _getTypeLabel(StatisticalAnomalyType type) {
    switch (type) {
      case StatisticalAnomalyType.consumption:
        return 'Consumption';
      case StatisticalAnomalyType.volume:
        return 'Volume';
      case StatisticalAnomalyType.frequency:
        return 'Frequency';
      case StatisticalAnomalyType.timing:
        return 'Timing';
    }
  }
}