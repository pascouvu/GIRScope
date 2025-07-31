import 'package:flutter/material.dart';
import 'package:girscope/models/anomaly_detection_log.dart';

class SimpleAnalysisLogViewer extends StatelessWidget {
  final AnomalyDetectionLog? log;

  const SimpleAnalysisLogViewer({super.key, this.log});

  @override
  Widget build(BuildContext context) {
    if (log == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analysis Log'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No analysis log available'),
              SizedBox(height: 8),
              Text(
                'Run statistical analysis first to see detailed logs',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Analysis Log'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Period: ${_formatDate(log!.parameters.periodStart)} to ${_formatDate(log!.parameters.periodEnd)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Vehicles analyzed: ${log!.summary.totalTransactionsAnalyzed} | Anomalies found: ${log!.summary.totalAnomaliesDetected}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          
          // Vehicle Analysis List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: log!.transactionLogs.length,
              itemBuilder: (context, index) {
                final transactionLog = log!.transactionLogs[index];
                return _buildVehicleLogCard(context, transactionLog);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleLogCard(BuildContext context, TransactionAnalysisLog transactionLog) {
    final hasAnomalies = transactionLog.result.contains('ANOMALOUS');
    final isSkipped = transactionLog.result.contains('SKIPPED');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Header
            Row(
              children: [
                Icon(
                  hasAnomalies ? Icons.warning : isSkipped ? Icons.info : Icons.check_circle,
                  color: hasAnomalies ? Colors.orange : isSkipped ? Colors.grey : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🚗 Vehicle: ${transactionLog.vehicleName}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Text(
              '📅 Transaction: ${_formatDateTime(transactionLog.transactionDate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Analysis Results
            if (isSkipped) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '❌ Analysis Skipped',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From last 3 months period, insufficient data (${transactionLog.baseline.usableTransactions} transactions) - analysis skipped',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Show analysis results for each type
              ...transactionLog.anomalyAnalyses.map((analysis) => 
                _buildAnalysisResult(context, analysis)
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResult(BuildContext context, AnomalyAnalysisLog analysis) {
    if (!analysis.hasData) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${_getAnalysisIcon(analysis.analysisType)} ${analysis.analysisType}: No data available',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
      );
    }

    if (analysis.sampleCount < 5) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${_getAnalysisIcon(analysis.analysisType)} ${analysis.analysisType}: Insufficient data (${analysis.sampleCount} samples)',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: analysis.isAnomaly ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: analysis.isAnomaly ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getAnalysisIcon(analysis.analysisType),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  analysis.notes,
                  style: TextStyle(
                    fontSize: 13,
                    color: analysis.isAnomaly ? Colors.red[800] : Colors.green[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (analysis.severity != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(analysis.severity!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    analysis.severity!.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getAnalysisIcon(String analysisType) {
    switch (analysisType.toLowerCase()) {
      case 'consumption':
        return '⛽';
      case 'volume':
        return '📊';
      case 'frequency':
        return '⏰';
      case 'timing':
        return '🕐';
      default:
        return '📈';
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade600;
      case 'high':
        return Colors.orange.shade600;
      case 'medium':
        return Colors.yellow.shade600;
      case 'low':
        return Colors.green.shade600;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}