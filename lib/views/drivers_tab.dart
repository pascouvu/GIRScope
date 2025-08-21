import 'package:flutter/material.dart';
import 'package:girscope/models/driver.dart';
import 'package:girscope/services/supabase_service.dart';
import 'package:girscope/widgets/driver_card.dart';
import 'package:girscope/widgets/business_logo_widget.dart';

class DriversTab extends StatefulWidget {
  const DriversTab({super.key});

  @override
  State<DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends State<DriversTab> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Driver> _allDrivers = [];
  List<Driver> _filteredDrivers = [];
  List<String> _departments = [];
  String? _selectedDepartment;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final drivers = await _supabaseService.getDrivers();
      
      if (mounted) {
        final departments = drivers
            .map((d) => d.departmentName)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();
        departments.sort((a, b) => a.compareTo(b));

        setState(() {
          _allDrivers = drivers;
          _filteredDrivers = drivers;
          _departments = departments;
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

  void _onSearchChanged() {
    _filterDrivers();
  }

  void _filterDrivers() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredDrivers = _allDrivers.where((driver) {
        final matchesSearch = query.isEmpty ||
            driver.fullName.toLowerCase().contains(query) ||
            driver.badge.toLowerCase().contains(query) ||
            driver.code.toLowerCase().contains(query);
        
        final matchesDepartment = _selectedDepartment == null ||
            driver.departmentName == _selectedDepartment;
        
        return matchesSearch && matchesDepartment;
      }).toList();
    });
  }

  void _selectDepartment(String? department) {
    setState(() {
      _selectedDepartment = department;
    });
    _filterDrivers();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading drivers...'),
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
              'Error loading drivers',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDrivers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search drivers...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainer,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text('All Departments'),
                              selected: _selectedDepartment == null,
                              onSelected: (_) => _selectDepartment(null),
                            ),
                          ),
                          ..._departments.map((dept) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(dept),
                              selected: _selectedDepartment == dept,
                              onSelected: (_) => _selectDepartment(dept),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const BusinessLogoWidget(
                    width: 80,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredDrivers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text('No drivers found'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDrivers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredDrivers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DriverCard(driver: _filteredDrivers[index]),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}