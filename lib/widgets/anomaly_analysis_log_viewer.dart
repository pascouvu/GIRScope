import 'package:flutter/material.dart';
import 'package:girscope/models/anomaly_detection_log.dart';
import 'package:girscope/widgets/log_viewer_summary_tab.dart';
import 'package:girscope/widgets/log_viewer_parameters_tab.dart';
import 'package:girscope/widgets/log_viewer_details_tab.dart';

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
                LogViewerSummaryTab(log: widget.log!),
                LogViewerParametersTab(log: widget.log!),
                LogViewerDetailsTab(log: widget.log!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}