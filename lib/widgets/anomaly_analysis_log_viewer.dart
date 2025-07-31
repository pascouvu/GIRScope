import 'package:flutter/material.dart';
import 'package:girscope/models/anomaly_detection_log.dart';

class AnomalyAnalysisLogViewer extends StatefulWidget {
  final AnomalyDetectionLog? log;

  const AnomalyAnalysisLogViewer({super.key, this.log});

  @override
  State<AnomalyAnalysisLogViewer> createState() => _AnomalyAnalysisLogViewerState();
}

class _AnomalyAnalysisLogViewerState extends State<AnomalyAnalysisLogViewer> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.log == null) {
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
        title: const Text('Analysis Log'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Summary', icon: Icon(Icons.summarize)),
                Tab(text: 'Parameters', icon: Icon(Icons.settings)),
                Tab(text: 'Details', icon: Icon(Icons.list_alt)),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildParametersTab(),
                _buildDetailsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    final log = widget.log!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Analysis Session',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Session ID', log.sessionId),
                  _buildInfoRow('Timestamp', _formatDateTime(log.timestamp)),
                  _buildInfoRow('Analysis Time', '${log.summary.analysisTime.inMilliseconds}ms'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Summary Stats Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Analysis Summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Transactions Analyzed',
                          log.summary.totalTransactionsAnalyzed.toString(),
                          Icons.receipt,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'With Anomalies',
                          log.summary.transactionsWithAnomalies.toString(),
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
                          'Total Anomalies',
                          log.summary.totalAnomaliesDetected.toString(),
                          Icons.error,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Detection Rate',
                          '${(log.summary.transactionsWithAnomalies / log.summary.totalTransactionsAnalyzed * 100).toStringAsFixed(1)}%',
                          Icons.percent,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Anomalies by Type Card
          if (log.summary.anomaliesByType.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Anomalies by Type',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...log.summary.anomaliesByType.entries.map((entry) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getTypeColor(entry.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_capitalizeType(entry.key))),
                            Text(
                              entry.value.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Anomalies by Severity Card
          if (log.summary.anomaliesBySeverity.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.priority_high, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Anomalies by Severity',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...log.summary.anomaliesBySeverity.entries.map((entry) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getSeverityColor(entry.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_capitalizeSeverity(entry.key))),
                            Text(
                              entry.value.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParametersTab() {
    final log = widget.log!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Analysis Parameters',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Analysis Period Start', _formatDateTime(log.parameters.periodStart)),
              _buildInfoRow('Analysis Period End', _formatDateTime(log.parameters.periodEnd)),
              _buildInfoRow('Baseline Days', '${log.parameters.baselineDays} days'),
              _buildInfoRow('Standard Deviation Threshold', '${log.parameters.standardDeviationThreshold}σ'),
              _buildInfoRow('Minimum Historical Samples', log.parameters.minimumHistoricalSamples.toString()),
              _buildInfoRow('Statistical Analysis Enabled', log.parameters.statisticalAnalysisEnabled ? 'Yes' : 'No'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    final log = widget.log!;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: log.transactionLogs.length,
      itemBuilder: (context, index) {
        final transactionLog = log.transactionLogs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text('${transactionLog.vehicleName} - ${transactionLog.transactionId.substring(0, 8)}...'),
            subtitle: Text('${_formatDateTime(transactionLog.transactionDate)} - ${transactionLog.result}'),
            leading: Icon(
              transactionLog.result.contains('ANOMALOUS') ? Icons.warning : Icons.check_circle,
              color: transactionLog.result.contains('ANOMALOUS') ? Colors.orange : Colors.green,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baseline Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Baseline Analysis',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Period: ${_formatDate(transactionLog.baseline.baselineStart)} to ${_formatDate(transactionLog.baseline.baselineEnd)}'),
                          Text('Historical Transactions: ${transactionLog.baseline.totalHistoricalTransactions}'),
                          Text('Usable for Analysis: ${transactionLog.baseline.usableTransactions}'),
                          Text('Status: ${transactionLog.baseline.status}'),
                          if (transactionLog.baseline.reason != null)
                            Text('Reason: ${transactionLog.baseline.reason}', style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Analysis Details
                    Text(
                      'Analysis Details',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    ...transactionLog.anomalyAnalyses.map((analysis) => 
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                Icon(
                                  analysis.isAnomaly ? Icons.warning : Icons.check_circle,
                                  size: 16,
                                  color: analysis.isAnomaly ? Colors.red : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${analysis.analysisType} Analysis',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (analysis.severity != null) ...[
                                  const Spacer(),
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
                            const SizedBox(height: 8),
                            
                            if (analysis.hasData && analysis.statistics != null) ...[
                              Text('Sample Count: ${analysis.sampleCount}'),
                              Text('Mean: ${analysis.statistics!.mean.toStringAsFixed(2)}'),
                              Text('Std Dev: ${analysis.statistics!.standardDeviation.toStringAsFixed(2)}'),
                              Text('Range: ${analysis.statistics!.min.toStringAsFixed(2)} - ${analysis.statistics!.max.toStringAsFixed(2)}'),
                              if (analysis.actualValue != null)
                                Text('Actual Value: ${analysis.actualValue!.toStringAsFixed(2)}'),
                              if (analysis.zScore != null)
                                Text('Z-Score: ${analysis.zScore!.toStringAsFixed(3)}'),
                            ],
                            
                            const SizedBox(height: 8),
                            Text(
                              analysis.notes,
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                            
                            if (analysis.description != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  analysis.description!,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'consumption':
        return Colors.blue;
      case 'volume':
        return Colors.teal;
      case 'frequency':
        return Colors.indigo;
      case 'timing':
        return Colors.cyan;
      default:
        return Colors.grey;
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

  String _capitalizeType(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }

  String _capitalizeSeverity(String severity) {
    return severity[0].toUpperCase() + severity.substring(1);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}