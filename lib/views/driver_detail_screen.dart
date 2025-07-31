import 'package:flutter/material.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/models/driver.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/services/supabase_service.dart';
import 'package:intl/intl.dart';

class DriverDetailScreen extends StatefulWidget {
  final Driver driver;

  const DriverDetailScreen({super.key, required this.driver});

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

enum DateFilterOption { last3Days, last7Days, last30Days }

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<FuelTransaction> _refuelingData = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateFilterOption _selectedDateFilter = DateFilterOption.last30Days;

  @override
  void initState() {
    super.initState();
    _loadRefuelingData();
  }

  Future<void> _loadRefuelingData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final days = _getSelectedDays();
      final data = await _supabaseService.getDriverRefuelingData(widget.driver.id, days: days);
      
      setState(() {
        _refuelingData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  int _getSelectedDays() {
    switch (_selectedDateFilter) {
      case DateFilterOption.last3Days:
        return 3;
      case DateFilterOption.last7Days:
        return 7;
      case DateFilterOption.last30Days:
        return 30;
    }
  }

  String _getDateFilterLabel() {
    switch (_selectedDateFilter) {
      case DateFilterOption.last3Days:
        return 'Last 3 Days';
      case DateFilterOption.last7Days:
        return 'Last 7 Days';
      case DateFilterOption.last30Days:
        return 'Last 30 Days';
    }
  }

  String _getFilterOptionLabel(DateFilterOption option) {
    switch (option) {
      case DateFilterOption.last3Days:
        return 'Last 3 Days';
      case DateFilterOption.last7Days:
        return 'Last 7 Days';
      case DateFilterOption.last30Days:
        return 'Last 30 Days';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.driver.fullName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Driver Info Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      widget.driver.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Badge', widget.driver.badge),
                _buildInfoRow('Code', widget.driver.code),
                _buildInfoRow('Department', widget.driver.departmentName),
              ],
            ),
          ),
          
          // Refueling Data Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_gas_station, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      'Refueling Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_refuelingData.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_refuelingData.length} transactions',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Date Filter Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<DateFilterOption>(
                      value: _selectedDateFilter,
                      isExpanded: true,
                      onChanged: (DateFilterOption? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedDateFilter = newValue;
                          });
                          _loadRefuelingData();
                        }
                      },
                      items: DateFilterOption.values.map((DateFilterOption option) {
                        return DropdownMenuItem<DateFilterOption>(
                          value: option,
                          child: Text(_getFilterOptionLabel(option)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Refueling List
          Expanded(
            child: _buildRefuelingList(),
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
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefuelingList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading refueling data',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadRefuelingData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_refuelingData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_gas_station_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No refueling data found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No transactions in the ${_getDateFilterLabel().toLowerCase()}',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRefuelingData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _refuelingData.length,
        itemBuilder: (context, index) {
          final transaction = _refuelingData[index];
          return _buildRefuelingCard(transaction);
        },
      ),
    );
  }

  Widget _buildRefuelingCard(FuelTransaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header: Date + Time on left, Volume on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${DateFormat('MMM dd, yyyy').format(transaction.date)} ${DateFormat('HH:mm').format(transaction.date)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${transaction.volume.toStringAsFixed(1)}L',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          
          // Compact info: Vehicle on left, Location on right
          Row(
            children: [
              // Vehicle info
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        transaction.vehicleName.isEmpty ? 'Unknown Vehicle' : transaction.vehicleName,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Location info
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        transaction.siteName.isEmpty ? 'Unknown Site' : transaction.siteName,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Anomalies (if any)
          if (transaction.hasAnomalies) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: transaction.anomalies.map((anomaly) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${anomaly.emoji} ${anomaly.label}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}