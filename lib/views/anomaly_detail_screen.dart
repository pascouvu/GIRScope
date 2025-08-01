import 'dart:math';
import 'package:flutter/material.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/services/supabase_service.dart';
import 'package:girscope/widgets/anomaly_explanation_widgets.dart';
import 'package:girscope/views/profile_screen.dart';

class AnomalyDetailScreen extends StatefulWidget {
  final FuelTransaction transaction;

  const AnomalyDetailScreen({super.key, required this.transaction});

  @override
  State<AnomalyDetailScreen> createState() => _AnomalyDetailScreenState();
}

class _AnomalyDetailScreenState extends State<AnomalyDetailScreen> {
  double? _expectedConsumption;
  double? _consumptionThreshold;
  bool _isLoadingBaseline = true;

  @override
  void initState() {
    super.initState();
    _loadBaselineConsumption();
  }

  Future<void> _loadBaselineConsumption() async {
    try {
      // Get historical transactions for this vehicle to calculate baseline
      final supabaseService = SupabaseService();
      List<FuelTransaction> historicalTransactions;
      
      // Try to get by vehicle ID first, fallback to vehicle name if ID is empty
      if (widget.transaction.vehicleId.isNotEmpty) {
        historicalTransactions = await supabaseService.getVehicleRefuelingDataUnlimited(
          widget.transaction.vehicleId
        );
      } else {
        historicalTransactions = await supabaseService.getVehicleRefuelingDataByName(
          widget.transaction.vehicleName
        );
      }
      
      // Filter out the current transaction and only keep transactions before this one
      historicalTransactions = historicalTransactions
          .where((t) => t.date.isBefore(widget.transaction.date))
          .toList();
      
      if (historicalTransactions.isNotEmpty) {
        // Calculate baseline consumption from historical data
        final consumptions = historicalTransactions
            .where((t) => t.kdelta != null && t.kdelta! > 0)
            .map((t) => (t.volume / t.kdelta!) * 100)
            .toList();
        
        if (consumptions.isNotEmpty) {
          final sum = consumptions.reduce((a, b) => a + b);
          final mean = sum / consumptions.length;
          
          // Calculate standard deviation
          final variance = consumptions
              .map((x) => (x - mean) * (x - mean))
              .reduce((a, b) => a + b) / consumptions.length;
          final stdDev = variance > 0 ? sqrt(variance) : 0.0;
          
          setState(() {
            _expectedConsumption = mean;
            _consumptionThreshold = mean + (2 * stdDev);
            _isLoadingBaseline = false;
          });
          return;
        }
      }
    } catch (e) {
      print('Error loading baseline consumption: $e');
    }
    
    // Fallback to reasonable defaults if no historical data
    setState(() {
      _expectedConsumption = 15.0;
      _consumptionThreshold = 25.0;
      _isLoadingBaseline = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anomaly Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            tooltip: 'Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Overview Card
            _buildTransactionOverviewCard(context),
            
            const SizedBox(height: 16),
            
            // Anomaly Analysis Card
            _buildAnomalyAnalysisCard(context),
            
            // Consumption Calculation Card (if applicable)
            if (widget.transaction.kcons != null && widget.transaction.kdelta != null) ...[
              const SizedBox(height: 16),
              _buildConsumptionCalculationCard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionOverviewCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact header
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Overview',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDateTime(widget.transaction.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Compact info rows
            _buildCompactInfoRow(context, 'Vehicle', widget.transaction.vehicleName, Icons.directions_car),
            const SizedBox(height: 4),
            _buildCompactInfoRow(context, 'Driver', widget.transaction.driverName, Icons.person),
            const SizedBox(height: 4),
            _buildCompactInfoRow(context, 'Site', widget.transaction.siteName, Icons.location_on),
            const SizedBox(height: 10),
            
            // Compact value display - single row with volume prominently displayed
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_gas_station,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Volume: ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${widget.transaction.volume.toStringAsFixed(1)} L',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  if (widget.transaction.kdelta != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.route,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.transaction.kdelta!.toStringAsFixed(0)} km',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyAnalysisCard(BuildContext context) {
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
            
            // Check if any anomalies exist
            if (widget.transaction.anomalies.isEmpty && !widget.transaction.hasStatisticalAnomalies)
              const Text('No anomalies found for this transaction.'),
            
            // Traditional anomalies
            ...widget.transaction.anomalies.map((anomaly) =>
              AnomalyExplanationWidgets.buildTraditionalAnomalyExplanation(
                context, anomaly, widget.transaction
              )
            ),
            
            // Statistical anomalies
            ...widget.transaction.allStatisticalAnomalies.map((anomaly) =>
              AnomalyExplanationWidgets.buildStatisticalAnomalyExplanation(
                context, anomaly, widget.transaction
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionCalculationCard(BuildContext context) {
    // Calculate the correct consumption from volume and distance
    double calculatedConsumption = (widget.transaction.volume / widget.transaction.kdelta!) * 100;
    
    // Use the dynamically loaded baseline data
    double expectedConsumption = _expectedConsumption ?? 15.0;
    double dynamicThreshold = _consumptionThreshold ?? 25.0;
    bool isHighConsumption = calculatedConsumption > dynamicThreshold;
    
    // Show loading state if baseline data is still loading
    if (_isLoadingBaseline) {
      expectedConsumption = 0.0;
      dynamicThreshold = 0.0;
    }
    
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
                  'Consumption Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isHighConsumption ? Colors.purple : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Simple consumption display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_gas_station,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Consumption on last refuel: ${calculatedConsumption.toStringAsFixed(1)} L/100km',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            if (isHighConsumption) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.purple.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Anomaly - High consumption detected (threshold: ${dynamicThreshold.toStringAsFixed(1)} L/100km)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
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
                        'Normal consumption rate (expected: ${expectedConsumption.toStringAsFixed(1)} L/100km)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
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

  Widget _buildCompactInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'N/A' : value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
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

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}