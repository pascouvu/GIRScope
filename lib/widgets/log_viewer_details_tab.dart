import 'package:flutter/material.dart';
import 'package:girscope/models/anomaly_detection_log.dart';

class LogViewerDetailsTab extends StatelessWidget {
  final AnomalyDetectionLog log;

  const LogViewerDetailsTab({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: log.transactionLogs.length,
      itemBuilder: (context, index) {
        final transactionLog = log.transactionLogs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              '${transactionLog.vehicleName} - ${transactionLog.transactionId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Date: ${transactionLog.transactionDate.toString().split(' ')[0]} - Result: ${transactionLog.result}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            leading: _getResultIcon(transactionLog.result),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baseline Analysis
                    const Text(
                      'Baseline Analysis:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${transactionLog.baseline.status}'),
                          Text('Historical Transactions: ${transactionLog.baseline.totalHistoricalTransactions}'),
                          Text('Usable Transactions: ${transactionLog.baseline.usableTransactions}'),
                          if (transactionLog.baseline.reason != null)
                            Text('Reason: ${transactionLog.baseline.reason}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Anomaly Analyses
                    if (transactionLog.anomalyAnalyses.isNotEmpty) ...[
                      const Text(
                        'Anomaly Analyses:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...transactionLog.anomalyAnalyses.map((analysis) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: analysis.isAnomaly ? Colors.red[50] : Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: analysis.isAnomaly ? Colors.red[200]! : Colors.green[200]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${analysis.analysisType} ${analysis.isAnomaly ? '⚠️' : '✅'}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Sample Count: ${analysis.sampleCount}'),
                            if (analysis.actualValue != null)
                              Text('Actual Value: ${analysis.actualValue!.toStringAsFixed(2)}'),
                            if (analysis.zScore != null)
                              Text('Z-Score: ${analysis.zScore!.toStringAsFixed(2)}'),
                            if (analysis.severity != null)
                              Text('Severity: ${analysis.severity}'),
                            if (analysis.description != null)
                              Text('Description: ${analysis.description}'),
                            Text('Notes: ${analysis.notes}'),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getResultIcon(String result) {
    switch (result.toLowerCase()) {
      case 'anomaly':
      case 'anomalies detected':
        return const Icon(Icons.warning, color: Colors.red);
      case 'normal':
      case 'no anomalies':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'insufficient data':
        return const Icon(Icons.info, color: Colors.orange);
      case 'error':
        return const Icon(Icons.error, color: Colors.red);
      default:
        return const Icon(Icons.analytics, color: Colors.blue);
    }
  }
}