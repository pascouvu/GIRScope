import 'package:flutter/material.dart';
import 'package:girscope/models/anomaly_detection_log.dart';

class LogViewerSummaryTab extends StatelessWidget {
  final AnomalyDetectionLog log;

  const LogViewerSummaryTab({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Analyzed',
                  '${log.summary.totalTransactionsAnalyzed}',
                  Icons.analytics,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Anomalies Found',
                  '${log.summary.totalAnomaliesDetected}',
                  Icons.warning,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Analysis Time',
                  '${log.summary.analysisTime.inMilliseconds}ms',
                  Icons.timer,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Success Rate',
                  '${((log.summary.totalTransactionsAnalyzed - log.summary.transactionsWithAnomalies) / log.summary.totalTransactionsAnalyzed * 100).toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.teal,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Analysis Details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analysis Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Session ID', log.sessionId),
                  _buildInfoRow('Timestamp', log.timestamp.toString()),
                  _buildInfoRow('Transaction Logs', '${log.transactionLogs.length}'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Parameters Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analysis Parameters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Period Start', log.parameters.periodStart.toString()),
                  _buildInfoRow('Period End', log.parameters.periodEnd.toString()),
                  _buildInfoRow('Baseline Days', '${log.parameters.baselineDays}'),
                  _buildInfoRow('SD Threshold', '${log.parameters.standardDeviationThreshold}'),
                  _buildInfoRow('Min Samples', '${log.parameters.minimumHistoricalSamples}'),
                  _buildInfoRow('Statistical Analysis', '${log.parameters.statisticalAnalysisEnabled}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}