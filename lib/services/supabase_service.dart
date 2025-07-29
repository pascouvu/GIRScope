import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/models/vehicle.dart';
import 'package:girscope/models/driver.dart'; // To fetch from external API
import 'package:girscope/services/api_service.dart';
import 'package:girscope/models/site.dart';
import 'package:girscope/models/department.dart';

class SupabaseService { // Temporary comment
  final SupabaseClient _supabase = Supabase.instance.client;
  final ApiService _apiService = ApiService(); // Instance of your existing API service

  // Method to sync all historical fuel transactions from the external API to Supabase
  Future<void> syncFuelTransactions() async {
    print('SupabaseService: Starting fuel transaction sync...');
    String? lastId;
    bool moreData = true;
    int totalSynced = 0;

    // Get the last synced ID from Supabase to resume sync
    try {
      final Map<String, dynamic>? lastTransaction = await _supabase
          .from('fuel_transactions')
          .select('id')
          .order('date', ascending: false) // Assuming 'date' is a good ordering column
          .limit(1)
          .maybeSingle();
      
      if (lastTransaction != null && lastTransaction.isNotEmpty) {
        lastId = lastTransaction['id'] as String?;
        print('SupabaseService: Resuming sync from lastId: \$lastId');
      }
    } catch (e) {
      print('SupabaseService: Error getting last synced ID from Supabase: \$e');
      // Continue without lastId if there's an error, will fetch all
    }

    while (moreData) {
      try {
        final Map<String, dynamic> result = await _apiService.getFuelTransactionsPaginated(lastId: lastId);
        final List<FuelTransaction> transactions = result['transactions'];
        moreData = result['more'];

        if (transactions.isEmpty) {
          break;
        }

        // Prepare data for Supabase insertion
        final List<Map<String, dynamic>> dataToInsert = transactions.map((t) => {
              'id': t.id,
              'transac_id': t.transacId,
              'date': t.date.toIso8601String(),
              'vehicle_name': t.vehicleName,
              'vehicle_id': t.vehicleId,
              'driver_name': t.driverName,
              'driver_id': t.driverId,
              'site_name': t.siteName,
              'volume': t.volume,
              'kdelta': t.kdelta,
              'kcons': t.kcons,
              'hcons': t.hcons,
              'manual': t.manual,
              'mtr_forced': t.mtrForced,
              'vol_max': t.volMax,
              'new_kmeter': t.newKmeter,
              'new_hmeter': t.newHmeter,
              'has_anomalies': t.hasAnomalies,
              'anomalies_json': t.anomalies.map((a) => {'label': a.label, 'emoji': a.emoji}).toList(),
            }).toList();

        // Insert into Supabase
        await _supabase.from('fuel_transactions').upsert(dataToInsert, onConflict: 'id');
        totalSynced += transactions.length;
        print('SupabaseService: Synced \$totalSynced transactions. Last transaction ID: \${transactions.last.id}');
        lastId = transactions.last.id; // Update lastId for next iteration

      } catch (e) {
        print('SupabaseService: Error during sync: \$e');
        moreData = false; // Stop on error
      }
    }
    print('SupabaseService: Fuel transaction sync complete. Total synced: \$totalSynced');
  }

  // Method to get fuel transactions from Supabase for a specific driver
  Future<List<FuelTransaction>> getDriverRefuelingData(String driverId, {int days = 30}) async {
    final now = DateTime.now();
    final cutoffDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));

    final List<Map<String, dynamic>> response = await _supabase
        .from('fuel_transactions')
        .select('*')
        .eq('driver_id', driverId) // Assuming 'driver_id' column in Supabase
        .gte('date', cutoffDate.toIso8601String()) // Filter by date
        .order('date', ascending: false);

    return response.map((json) => FuelTransaction.fromJson(json)).toList();
  }

  // Method to get fuel transactions from Supabase for a specific vehicle
  Future<List<FuelTransaction>> getVehicleRefuelingData(String vehicleId, {int days = 30}) async {
    final now = DateTime.now();
    final cutoffDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));

    final List<Map<String, dynamic>> response = await _supabase
        .from('fuel_transactions')
        .select('*')
        .eq('vehicle_id', vehicleId) // Assuming 'vehicle_id' column in Supabase
        .gte('date', cutoffDate.toIso8601String()) // Filter by date
        .order('date', ascending: false);

    return response.map((json) => FuelTransaction.fromJson(json)).toList();
  }

  Future<List<FuelTransaction>> getFuelTransactions({DateTime? startDate, DateTime? endDate}) async {
    var query = _supabase.from('fuel_transactions').select('*');

    if (startDate != null) {
      query = query.gte('date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('date', endDate.toIso8601String());
    }

    final List<Map<String, dynamic>> response = await query.order('date', ascending: false);
    return response.map((json) => FuelTransaction.fromJson(json)).toList();
  }

  Future<void> syncVehicles() async {
    print('SupabaseService: Starting vehicle sync...');
    try {
      final List<Vehicle> vehicles = (await _apiService.getVehicles()).cast<Vehicle>();
      final List<Map<String, dynamic>> vehiclesToInsert = [];
      final Set<Map<String, dynamic>> productsToInsert = {};
      final List<Map<String, dynamic>> vehicleProductsToInsert = [];
      final Set<String> seenVehicleProductKeys = {};

      for (var vehicle in vehicles) {
        vehiclesToInsert.add({
          'id': vehicle.id,
          'name': vehicle.name,
          'badge': vehicle.badge,
          'pubsn_badge': vehicle.pubsnBadge,
          'ctrl_badge': vehicle.ctrlBadge,
          'code': vehicle.code,
          'pin_code': vehicle.pinCode,
          'model': vehicle.model,
          'department_id': vehicle.departmentId,
          'department_name': vehicle.departmentName,
          'kmeter': vehicle.odometer,
          'hmeter': vehicle.hourMeter,
          'notes': vehicle.notes,
        });

        for (var vtank in vehicle.vtanks) {
          productsToInsert.add({
            'id': vtank.id,
            'name': vtank.product,
            'capacity': vtank.capacity,
          });
          final String key = '${vehicle.id}-${vtank.id}';
          if (!seenVehicleProductKeys.contains(key)) {
            vehicleProductsToInsert.add({
              'vehicle_id': vehicle.id,
              'product_id': vtank.id,
              'capacity': vtank.capacity,
            });
            seenVehicleProductKeys.add(key);
          }
        }
      }

      if (productsToInsert.isNotEmpty) {
        await _supabase.from('products').upsert(productsToInsert.toList(), onConflict: 'id');
        print('SupabaseService: Synced ${productsToInsert.length} products.');
      }

      await _supabase.from('vehicles').upsert(vehiclesToInsert, onConflict: 'id');
      print('SupabaseService: Synced ${vehicles.length} vehicles.');

      if (vehicleProductsToInsert.isNotEmpty) {
        await _supabase.from('vehicle_products').upsert(vehicleProductsToInsert.toList(), onConflict: 'vehicle_id,product_id');
        print('SupabaseService: Synced ${vehicleProductsToInsert.length} vehicle products.');
      }
    } catch (e) {
      print('SupabaseService: Error during vehicle sync: $e');
      rethrow;
    }
  }

  Future<void> syncDrivers() async {
    print('SupabaseService: Starting driver sync...');
    try {
      final List<Driver> drivers = (await _apiService.getDrivers()).cast<Driver>();
      final List<Map<String, dynamic>> dataToInsert = drivers.map((driver) => {
            'id': driver.id,
            'name': driver.name,
            'first_name': driver.firstName,
            'badge': driver.badge,
            'pubsn_badge': driver.pubsnBadge,
            'ctrl_badge': driver.ctrlBadge,
            'code': driver.code,
            'pin_code': driver.pinCode,
            'department_id': driver.departmentId,
            'department_name': driver.departmentName,
            'activity_prompt': driver.activityPrompt,
            'nce_prompt': driver.ncePrompt,
            'notes': driver.notes,
          }).toList();

      await _supabase.from('drivers').upsert(dataToInsert, onConflict: 'id');
      print('SupabaseService: Synced ${drivers.length} drivers.');
    } catch (e) {
      print('SupabaseService: Error during driver sync: $e');
      rethrow;
    }
  }

  Future<void> syncAllDepartments() async {
    print('SupabaseService: Starting all departments sync...');
    try {
      final List<Vehicle> vehicles = (await _apiService.getVehicles()).cast<Vehicle>();
      final List<Driver> drivers = (await _apiService.getDrivers()).cast<Driver>();

      final Set<Department> uniqueDepartments = {};

      for (var vehicle in vehicles) {
        if (vehicle.departmentId != null && vehicle.departmentName.isNotEmpty) {
          uniqueDepartments.add(Department(id: vehicle.departmentId!, name: vehicle.departmentName));
        }
      }
      for (var driver in drivers) {
        if (driver.departmentId != null && driver.departmentName.isNotEmpty) {
          uniqueDepartments.add(Department(id: driver.departmentId!, name: driver.departmentName));
        }
      }

      if (uniqueDepartments.isNotEmpty) {
        final List<Map<String, dynamic>> dataToInsert = uniqueDepartments.map((dept) => {
              'id': dept.id,
              'name': dept.name,
            }).toList();
        await _supabase.from('departments').upsert(dataToInsert, onConflict: 'id');
        print('SupabaseService: Synced ${uniqueDepartments.length} unique departments.');
      }
    } catch (e) {
      print('SupabaseService: Error during all departments sync: $e');
      rethrow;
    }
  }

  Future<void> syncSites() async {
    print('SupabaseService: Starting site sync...');
    try {
      final List<Site> sites = (await _apiService.getSites()).cast<Site>();
      final List<Map<String, dynamic>> dataToInsert = sites.map((site) => {
            'id': site.id,
            'name': site.name,
            'code': site.code,
            'address': site.address,
            'city': site.city,
            'zip_code': site.zipCode,
            'country': site.country,
            'latitude': site.latitude,
            'longitude': site.longitude,
          }).toList();

      await _supabase.from('sites').upsert(dataToInsert, onConflict: 'id');
      print('SupabaseService: Synced ${sites.length} sites.');
    } catch (e) {
      print('SupabaseService: Error during site sync: $e');
      rethrow;
    }
  }

  Future<List<Driver>> getDrivers() async {
    final List<Map<String, dynamic>> response = await _supabase
        .from('drivers')
        .select('*')
        .order('name', ascending: true);
    return response.map((json) => Driver.fromJson(json)).toList();
  }

  Future<List<Vehicle>> getVehicles() async {
    final List<Map<String, dynamic>> response = await _supabase
        .from('vehicles')
        .select('*')
        .order('name', ascending: true);
    return response.map((json) => Vehicle.fromJson(json)).toList();
  }
}
