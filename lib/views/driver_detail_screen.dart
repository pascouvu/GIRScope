import 'package:flutter/material.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/models/driver.dart';
import 'package:girscope/services/supabase_service.dart';
import 'package:girscope/widgets/driver_info_card.dart';
import 'package:girscope/widgets/date_filter_dropdown.dart';
import 'package:girscope/widgets/refueling_card.dart';
import 'package:girscope/views/profile_screen.dart';
import 'package:intl/intl.dart';

class DriverDetailScreen extends StatefulWidget {
  final Driver driver;

  const DriverDetailScreen({super.key, required this.driver});

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<FuelTransaction> _refuelingData = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateFilterOption _selectedDateFilter = DateFilterOption.last30Days;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

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
      case DateFilterOption.last60Days:
        return 60;
      case DateFilterOption.last90Days:
        return 90;
      case DateFilterOption.customRange:
        if (_customStartDate != null && _customEndDate != null) {
          return _customEndDate!.difference(_customStartDate!).inDays + 1;
        }
        return 30; // fallback
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
      case DateFilterOption.last60Days:
        return 'Last 60 Days';
      case DateFilterOption.last90Days:
        return 'Last 90 Days';
      case DateFilterOption.customRange:
        if (_customStartDate != null && _customEndDate != null) {
          return 'Custom Range (${DateFormat('dd/MM').format(_customStartDate!)} - ${DateFormat('dd/MM').format(_customEndDate!)})';
        }
        return 'Custom Range';
    }
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
        _selectedDateFilter = DateFilterOption.customRange;
      });
      _loadRefuelingData();
    }
  }

  void _onFilterChanged(DateFilterOption newFilter) {
    setState(() {
      _selectedDateFilter = newFilter;
    });
    _loadRefuelingData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.driver.name),
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
      body: RefreshIndicator(
        onRefresh: _loadRefuelingData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Driver Info Card
              DriverInfoCard(driver: widget.driver),
              
              // Refueling Data Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_gas_station, color: Colors.orange, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Refueling History',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_refuelingData.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_refuelingData.length} transactions',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Date Filter Dropdown
                    DateFilterDropdown(
                      selectedFilter: _selectedDateFilter,
                      customStartDate: _customStartDate,
                      customEndDate: _customEndDate,
                      onFilterChanged: _onFilterChanged,
                      onCustomRangeSelected: _selectCustomDateRange,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Refueling List
              _buildRefuelingList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefuelingList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 12),
            Text(
              'Error loading refueling data',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadRefuelingData,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      );
    }

    if (_refuelingData.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_gas_station_outlined,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                'No refueling data found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No transactions in the ${_getDateFilterLabel().toLowerCase()}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: _refuelingData.map((transaction) => RefuelingCard(transaction: transaction)).toList(),
      ),
    );
  }
}