import 'package:flutter/material.dart';
import 'package:girscope/models/vehicle.dart';
import 'package:girscope/services/supabase_service.dart';
import 'package:girscope/widgets/vehicle_card.dart';

class VehiclesTab extends StatefulWidget {
  const VehiclesTab({super.key});

  @override
  State<VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState extends State<VehiclesTab> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Vehicle> _allVehicles = [];
  List<Vehicle> _filteredVehicles = [];
  List<String> _departments = [];
  String? _selectedDepartment;
  List<String> _models = [];
  String? _selectedModel;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final vehicles = await _supabaseService.getVehicles();
      
      if (mounted) {
        final departments = vehicles
            .map((v) => v.departmentName)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();
        departments.sort((a, b) => a.compareTo(b));

        setState(() {
          _allVehicles = vehicles;
          _filteredVehicles = vehicles;
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
    _filterVehicles();
  }

  void _filterVehicles() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredVehicles = _allVehicles.where((vehicle) {
        final matchesSearch = query.isEmpty ||
            vehicle.name.toLowerCase().contains(query) ||
            vehicle.badge.toLowerCase().contains(query) ||
            vehicle.code.toLowerCase().contains(query);
        
        final matchesDepartment = _selectedDepartment == null ||
            vehicle.departmentName == _selectedDepartment;
        
        return matchesSearch && matchesDepartment;
      }).toList();
    });
  }

  void _selectDepartment(String? department) {
    setState(() {
      _selectedDepartment = department;
    });
    _filterVehicles();
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
            Text('Loading vehicles...'),
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
              'Error loading vehicles',
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
              onPressed: _loadVehicles,
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
                  hintText: 'Search vehicles...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainer,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
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
            ],
          ),
        ),
        Expanded(
          child: _filteredVehicles.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text('No vehicles found'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadVehicles,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredVehicles.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: VehicleCard(vehicle: _filteredVehicles[index]),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}