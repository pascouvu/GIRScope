import 'package:flutter/material.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/models/vehicle.dart';
import 'package:girscope/services/supabase_service.dart';
import 'package:girscope/widgets/vehicle_info_card.dart';
import 'package:girscope/widgets/date_filter_dropdown.dart';
import 'package:girscope/widgets/fuel_consumption_chart.dart';
import 'package:girscope/widgets/refueling_content.dart';
import 'package:girscope/views/profile_screen.dart';
import 'package:intl/intl.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
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
        title: Text(widget.vehicle.name),
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
              // Vehicle Info Card
              VehicleInfoCard(vehicle: widget.vehicle),
              
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
                          'Refueling Data',
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
              
              // Fuel Consumption Chart
              if (_refuelingData.isNotEmpty) ...[
                const SizedBox(height: 12),
                FuelConsumptionChart(refuelingData: _refuelingData),
              ],
              
              const SizedBox(height: 8),
              
              // Refueling List Content
              RefuelingContent(
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                refuelingData: _refuelingData,
                dateFilterLabel: _getDateFilterLabel(),
                onRetry: _loadRefuelingData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}