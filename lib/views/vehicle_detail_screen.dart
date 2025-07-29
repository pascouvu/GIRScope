import 'package:flutter/material.dart';
import 'package:girscope/models/vehicle.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/services/supabase_service.dart';
import 'package:intl/intl.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

enum DateFilterOption { last3Days, last7Days, last30Days }

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
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
      final data = await _supabaseService.getVehicleRefuelingData(widget.vehicle.id, days: days);
      
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
        title: Text(widget.vehicle.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Vehicle Info Card
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
                    const Icon(Icons.directions_car, color: Colors.blue, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.vehicle.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Badge', widget.vehicle.displayBadge),
                _buildInfoRow('Model', widget.vehicle.model),
                _buildInfoRow('Department', widget.vehicle.departmentName),
                if (widget.vehicle.odometer != null)
                  _buildInfoRow('Odometer', '${widget.vehicle.odometer!.toStringAsFixed(0)} km'),
                if (widget.vehicle.hourMeter != null)
                  _buildInfoRow('Hour Meter', '${widget.vehicle.hourMeter!.toStringAsFixed(1)} h'),
                if (widget.vehicle.vtanks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Fuel Tanks:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...widget.vehicle.vtanks.map((vtank) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          vtank.product.isEmpty ? 'Unknown Product' : vtank.product,
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (vtank.capacity != null) ...[
                          const Text(' - ', style: TextStyle(fontSize: 14)),
                          Text(
                            '${vtank.capacity!.toStringAsFixed(0)}L',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  )),
                ],
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
            width: 90,
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
      margin: const EdgeInsets.only(bottom: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(transaction.date),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${transaction.volume.toStringAsFixed(1)}L',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  transaction.driverName.isEmpty ? 'Unknown Driver' : transaction.driverName,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.red),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  transaction.siteName.isEmpty ? 'Unknown Site' : transaction.siteName,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                DateFormat('HH:mm').format(transaction.date),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (transaction.hasAnomalies) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: transaction.anomalies.map((anomaly) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${anomaly.emoji} ${anomaly.label}',
                    style: const TextStyle(
                      fontSize: 12,
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