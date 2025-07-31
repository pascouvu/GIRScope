import 'package:flutter/material.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/services/supabase_service.dart';
import 'package:girscope/services/anomaly_detection_service.dart';
import 'package:girscope/services/statistical_analysis_service.dart';
import 'package:girscope/widgets/anomaly_card.dart';
import 'package:girscope/widgets/anomaly_analysis_log_viewer.dart';
import 'package:girscope/widgets/simple_analysis_log_viewer.dart';

enum DateFilter { last3Days, last7Days, last30Days, custom }

class AnomaliesTab extends StatefulWidget {
  const AnomaliesTab({super.key});

  @override
  State<AnomaliesTab> createState() => _AnomaliesTabState();
}

class _AnomaliesTabState extends State<AnomaliesTab> {
  final SupabaseService _supabaseService = SupabaseService();
  final AnomalyDetectionService _anomalyService = AnomalyDetectionService();
  
  List<FuelTransaction> _transactions = [];
  List<FuelTransaction> _filteredTransactions = [];
  DateFilter _selectedFilter = DateFilter.last7Days;
  String _selectedAnomalyType = 'all';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isLoading = true;
  String? _error;
  bool _useStatisticalAnalysis = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final (startDate, endDate) = _getDateRange();
      final transactions = await _supabaseService.getFuelTransactions(
        startDate: startDate,
        endDate: endDate,
      );
      
      List<FuelTransaction> processedTransactions = transactions;
      
      // Apply statistical anomaly detection if enabled
      if (_useStatisticalAnalysis) {
        try {
          final anomaliesMap = await _anomalyService.analyzeAnomalies(
            transactions: transactions,
            startDate: startDate,
            endDate: endDate,
          );
          
          // Merge statistical anomalies with original transactions
          processedTransactions = _mergeStatisticalAnomalies(transactions, anomaliesMap);
        } catch (e) {
          print('Statistical analysis failed: $e');
          // Continue with original transactions if statistical analysis fails
        }
      }
      
      if (mounted) {
        setState(() {
          _transactions = processedTransactions;
          _filteredTransactions = _filterTransactionsByAnomalyType(processedTransactions);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();
    final endDate = now;
    
    switch (_selectedFilter) {
      case DateFilter.last3Days:
        return (now.subtract(const Duration(days: 3)), endDate);
      case DateFilter.last7Days:
        return (now.subtract(const Duration(days: 7)), endDate);
      case DateFilter.last30Days:
        return (now.subtract(const Duration(days: 30)), endDate);
      case DateFilter.custom:
        return (
          _customStartDate ?? now.subtract(const Duration(days: 7)),
          _customEndDate ?? endDate,
        );
    }
  }

  List<FuelTransaction> _filterTransactionsByAnomalyType(List<FuelTransaction> transactions) {
    if (_selectedAnomalyType == 'all') {
      return transactions.where((t) => t.hasAnomalies).toList();
    }
    
    return transactions.where((transaction) {
      // Check traditional anomalies
      final hasTraditionalAnomaly = transaction.anomalies.any((anomaly) => 
        anomaly.label.toLowerCase().contains(_selectedAnomalyType.toLowerCase()));
      
      // Check statistical anomalies
      final hasStatisticalAnomaly = transaction.hasStatisticalAnomalies && 
        transaction.allStatisticalAnomalies.any((anomaly) =>
          _getStatisticalAnomalyLabel(anomaly.type).toLowerCase().contains(_selectedAnomalyType.toLowerCase()));
      
      return hasTraditionalAnomaly || hasStatisticalAnomaly;
    }).toList();
  }

  void _selectDateFilter(DateFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadTransactions();
  }

  void _selectAnomalyType(String anomalyType) {
    setState(() {
      _selectedAnomalyType = anomalyType;
      _filteredTransactions = _filterTransactionsByAnomalyType(_transactions);
    });
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _customStartDate ?? DateTime.now().subtract(const Duration(days: 7)),
        end: _customEndDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedFilter = DateFilter.custom;
      });
      _loadTransactions();
    }
  }

  List<FuelTransaction> _mergeStatisticalAnomalies(
    List<FuelTransaction> originalTransactions,
    Map<String, List<StatisticalAnomaly>> anomaliesMap,
  ) {
    // Merge statistical anomalies with original transactions
    return originalTransactions.map((transaction) {
      final statisticalAnomalies = anomaliesMap[transaction.id];
      if (statisticalAnomalies != null) {
        return transaction.copyWithStatisticalAnomalies(statisticalAnomalies);
      }
      return transaction;
    }).toList();
  }

  List<String> _getAvailableAnomalyTypes() {
    final types = <String>{'all'};
    for (final transaction in _transactions) {
      // Traditional anomalies
      for (final anomaly in transaction.anomalies) {
        types.add(anomaly.label.toLowerCase());
      }
      // Statistical anomalies
      if (transaction.hasStatisticalAnomalies) {
        for (final anomaly in transaction.allStatisticalAnomalies) {
          types.add(_getStatisticalAnomalyLabel(anomaly.type).toLowerCase());
        }
      }
    }
    return types.toList();
  }
  
  String _getStatisticalAnomalyLabel(StatisticalAnomalyType type) {
    switch (type) {
      case StatisticalAnomalyType.consumption:
        return 'Statistical Consumption';
      case StatisticalAnomalyType.volume:
        return 'Statistical Volume';
      case StatisticalAnomalyType.frequency:
        return 'Statistical Frequency';
      case StatisticalAnomalyType.timing:
        return 'Statistical Timing';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Filter Section
              Row(
                children: [
                  Icon(
                    Icons.date_range,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Date Filter',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DateFilter>(
                    value: _selectedFilter,
                    isExpanded: true,
                    onChanged: (DateFilter? newValue) {
                      if (newValue != null) {
                        if (newValue == DateFilter.custom) {
                          _selectCustomDateRange();
                        } else {
                          _selectDateFilter(newValue);
                        }
                      }
                    },
                    items: [
                      const DropdownMenuItem(
                        value: DateFilter.last3Days,
                        child: Text('Last 3 Days'),
                      ),
                      const DropdownMenuItem(
                        value: DateFilter.last7Days,
                        child: Text('Last 7 Days'),
                      ),
                      const DropdownMenuItem(
                        value: DateFilter.last30Days,
                        child: Text('Last 30 Days'),
                      ),
                      DropdownMenuItem(
                        value: DateFilter.custom,
                        child: Text(_selectedFilter == DateFilter.custom && _customStartDate != null
                            ? 'Custom (${_customStartDate!.day}/${_customStartDate!.month} - ${_customEndDate!.day}/${_customEndDate!.month})'
                            : 'Custom Range'),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Statistical Analysis Toggle
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Statistical Analysis',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _useStatisticalAnalysis,
                    onChanged: (value) {
                      setState(() {
                        _useStatisticalAnalysis = value;
                      });
                      _loadTransactions();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Anomaly Type Filter Section
              Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Anomaly Type',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAnomalyType,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _selectAnomalyType(newValue);
                      }
                    },
                    items: _getAvailableAnomalyTypes().map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Row(
                          children: [
                            if (type != 'all') ...[
                              Text(_getAnomalyEmoji(type)),
                              const SizedBox(width: 8),
                            ],
                            Text(type == 'all' ? 'All Anomalies' : _capitalize(type)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              if (_filteredTransactions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_filteredTransactions.length} anomal${_filteredTransactions.length == 1 ? 'y' : 'ies'} found',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_useStatisticalAnalysis) ...[
                      TextButton.icon(
                        onPressed: () {
                          final log = _anomalyService.getCurrentAnalysisLog();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SimpleAnalysisLogViewer(log: log),
                            ),
                          );
                        },
                        icon: const Icon(Icons.list_alt, size: 16),
                        label: const Text('Analysis Log'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          final log = _anomalyService.getCurrentAnalysisLog();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AnomalyAnalysisLogViewer(log: log),
                            ),
                          );
                        },
                        icon: const Icon(Icons.analytics, size: 16),
                        label: const Text('Technical'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.secondary,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  String _getAnomalyEmoji(String anomalyType) {
    switch (anomalyType.toLowerCase()) {
      case 'manual fueling':
      case 'manual':
        return '🟠';
      case 'forced meter':
      case 'forced':
        return '🔴';
      case 'max volume':
      case 'volume':
        return '⚪';
      case 'meter reset':
      case 'reset':
        return '🟡';
      case 'high consumption':
      case 'consumption':
        return '🟣';
      default:
        return '⚠️';
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading anomalies...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading anomalies',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTransactions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedAnomalyType == 'all' ? 'No anomalies found' : 'No ${_selectedAnomalyType} anomalies found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedAnomalyType == 'all' 
                ? 'All transactions look normal for this period'
                : 'Try selecting a different anomaly type or date range',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredTransactions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnomalyCard(transaction: _filteredTransactions[index]),
          );
        },
      ),
    );
  }
}