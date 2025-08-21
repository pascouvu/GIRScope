import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/models/vehicle.dart';
import 'package:girscope/models/driver.dart';
import 'package:girscope/services/api_service.dart';
import 'package:girscope/models/site.dart';
import 'package:girscope/models/department.dart';
import 'package:girscope/models/business.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ApiService _apiService = ApiService();
  
  // Business context for all operations
  Business? _currentBusiness;
  
  // Set the current business context
  void setBusinessContext(Business business) {
    _currentBusiness = business;
    _apiService.setBusinessContext(business);
    print('*** SupabaseService: Business context set - ${business.businessName}');
  }
  
  // Get current business ID
  String? get currentBusinessId => _currentBusiness?.id;

  // Method to sync all historical fuel transactions from the external API to Supabase
  Future<void> syncFuelTransactions() async {
    if (_currentBusiness == null) {
      throw Exception('Business context not set. Call setBusinessContext() first.');
    }
    
    print('*** SupabaseService: Starting fuel transaction sync for business: ${_currentBusiness!.businessName}');
    String? lastId;
    bool moreData = true;
    int totalSynced = 0;
    int errorCount = 0;
    const maxErrors = 3; // Maximum number of errors before stopping

    // Get the last synced ID from Supabase to resume sync (filtered by business)
    try {
      final Map<String, dynamic>? lastTransaction = await _supabase
          .from('fuel_transactions')
          .select('id')
          .eq('business_id', _currentBusiness!.id)
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (lastTransaction != null && lastTransaction.isNotEmpty) {
        lastId = lastTransaction['id'] as String?;
        print('*** SupabaseService: Resuming sync from lastId: $lastId');
      }
    } catch (e) {
      print('*** SupabaseService: Error getting last synced ID from Supabase: $e');
      // Continue without lastId if there's an error, will fetch all
    }

    while (moreData && errorCount < maxErrors) {
      try {
        final Map<String, dynamic> result = await _apiService.getFuelTransactionsPaginated(lastId: lastId);
        final List<FuelTransaction> transactions = result['transactions'];
        moreData = result['more'];

        if (transactions.isEmpty) {
          print('*** SupabaseService: No more transactions to sync');
          break;
        }

        // --- Start: Ensure all vehicles from transactions exist ---
        final vehicleIdsInBatch = transactions
            .map((t) => t.vehicleId)
            .where((id) => id != null)
            .toSet();

        if (vehicleIdsInBatch.isNotEmpty) {
          try {
            final existingVehiclesResponse = await _supabase
                .from('vehicles')
                .select('id')
                .inFilter('id', vehicleIdsInBatch.toList())
                .eq('business_id', _currentBusiness!.id);

            final existingVehicleIds =
                existingVehiclesResponse.map((v) => v['id'].toString()).toSet();

            final missingVehicleIds =
                vehicleIdsInBatch.difference(existingVehicleIds);

            if (missingVehicleIds.isNotEmpty) {
              print('*** SupabaseService: Found ${missingVehicleIds.length} missing vehicles. Creating placeholder entries...');
              final List<Map<String, dynamic>> placeholderVehicles = transactions
                  .where((t) => missingVehicleIds.contains(t.vehicleId))
                  .map((t) => {
                        'id': t.vehicleId!,
                        'name': t.vehicleName, // The only NOT NULL field
                        'business_id': _currentBusiness!.id,
                      })
                  .toList();
              
              // Deduplicate placeholderVehicles before inserting
              final uniquePlaceholderVehicles = { for (var v in placeholderVehicles) v['id']: v };

              await _supabase.from('vehicles').upsert(uniquePlaceholderVehicles.values.toList(), onConflict: 'id');
              print('*** SupabaseService: Created ${uniquePlaceholderVehicles.length} placeholder vehicles.');
            }
          } catch (e) {
            print('*** SupabaseService: Error ensuring vehicles exist: $e');
            // Continue with sync even if this step fails
          }
        }
        // --- End: Ensure all vehicles from transactions exist ---

        // --- Start: Ensure all drivers from transactions exist ---
        final driverIdsInBatch = transactions
            .map((t) => t.driverId)
            .where((id) => id != null)
            .toSet();

        if (driverIdsInBatch.isNotEmpty) {
          try {
            final existingDriversResponse = await _supabase
                .from('drivers')
                .select('id')
                .inFilter('id', driverIdsInBatch.toList())
                .eq('business_id', _currentBusiness!.id);

            final existingDriverIds =
                existingDriversResponse.map((d) => d['id'].toString()).toSet();

            final missingDriverIds = driverIdsInBatch.difference(existingDriverIds);

            if (missingDriverIds.isNotEmpty) {
              print('*** SupabaseService: Found ${missingDriverIds.length} missing drivers. Creating placeholder entries...');
              final List<Map<String, dynamic>> placeholderDrivers = transactions
                  .where((t) => missingDriverIds.contains(t.driverId))
                  .map((t) => {
                        'id': t.driverId!,
                        'name': t.driverName, // The only NOT NULL field
                        'first_name': '', // Provide a default empty string
                        'business_id': _currentBusiness!.id,
                      })
                  .toList();
              
              final uniquePlaceholderDrivers = { for (var d in placeholderDrivers) d['id']: d };

              await _supabase.from('drivers').upsert(uniquePlaceholderDrivers.values.toList(), onConflict: 'id');
              print('*** SupabaseService: Created ${uniquePlaceholderDrivers.length} placeholder drivers.');
            }
          } catch (e) {
            print('*** SupabaseService: Error ensuring drivers exist: $e');
            // Continue with sync even if this step fails
          }
        }
        // --- End: Ensure all drivers from transactions exist ---

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
              'business_id': _currentBusiness!.id,
            }).toList();

        // Insert into Supabase
        await _supabase.from('fuel_transactions').upsert(dataToInsert, onConflict: 'id');
        totalSynced += transactions.length;
        print('*** SupabaseService: Synced $totalSynced transactions. Last transaction ID: ${transactions.last.id}');
        lastId = transactions.last.id; // Update lastId for next iteration
        
        // Reset error count on successful sync
        errorCount = 0;

      } catch (e, stackTrace) {
        errorCount++;
        print('*** SupabaseService: Error during sync (error $errorCount/$maxErrors): $e');
        print('Stack trace: $stackTrace');
        if (e is PostgrestException) {
          print('PostgrestException details: ${e.details}');
        }
        
        // If we've reached the maximum number of errors, stop syncing
        if (errorCount >= maxErrors) {
          print('*** SupabaseService: Maximum error count reached, stopping sync');
          moreData = false;
        } else {
          // Continue with next batch
          print('*** SupabaseService: Continuing sync despite error');
        }
      }
    }
    print('*** SupabaseService: Fuel transaction sync complete. Total synced: $totalSynced');
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

  // Method to get ALL fuel transactions from Supabase for a specific vehicle (no date limit)
  Future<List<FuelTransaction>> getVehicleRefuelingDataUnlimited(String vehicleId) async {
    final List<Map<String, dynamic>> response = await _supabase
        .from('fuel_transactions')
        .select('*')
        .eq('vehicle_id', vehicleId) // Get all transactions for this vehicle
        .order('date', ascending: false);

    print('SupabaseService: Found ${response.length} total transactions for vehicle $vehicleId');
    return response.map((json) => FuelTransaction.fromJson(json)).toList();
  }

  // Method to get ALL fuel transactions from Supabase for a specific vehicle by name (fallback when ID is empty)
  Future<List<FuelTransaction>> getVehicleRefuelingDataByName(String vehicleName) async {
    final List<Map<String, dynamic>> response = await _supabase
        .from('fuel_transactions')
        .select('*')
        .eq('vehicle_name', vehicleName) // Get all transactions for this vehicle by name
        .order('date', ascending: false);

    print('SupabaseService: Found ${response.length} total transactions for vehicle name "$vehicleName"');
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
    
    // Debug: Print sample transaction data to see what we're getting
    if (response.isNotEmpty) {
      print('🔍 DEBUG: Sample transaction from getFuelTransactions:');
      final sample = response.first;
      print('   - ID: ${sample['id']}');
      print('   - Vehicle ID: "${sample['vehicle_id']}" (${sample['vehicle_id']?.toString().length ?? 0} chars)');
      print('   - Vehicle Name: "${sample['vehicle_name']}"');
      print('   - Volume: ${sample['volume']}');
      print('   - Date: ${sample['date']}');
    }
    
    return response.map((json) => FuelTransaction.fromJson(json)).toList();
  }

  Future<void> syncVehicles() async {
    if (_currentBusiness == null) {
      throw Exception('Business context not set. Call setBusinessContext() first.');
    }
    
    print('*** SupabaseService: Starting vehicle sync for business: ${_currentBusiness!.businessName}');
    try {
      final List<Vehicle> vehicles = (await _apiService.getVehicles()).cast<Vehicle>();
      final Map<String, Vehicle> uniqueVehicles = { for (var v in vehicles) v.id: v };
      final List<Map<String, dynamic>> vehiclesToInsert = [];
      final Map<String, Map<String, dynamic>> uniqueProducts = {};
      final Map<String, Map<String, dynamic>> uniqueVehicleProducts = {};

      for (var vehicle in uniqueVehicles.values) {
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
          'kmeter': vehicle.odometer?.toInt(),
          'hmeter': vehicle.hourMeter,
          'notes': vehicle.notes,
          'business_id': _currentBusiness!.id,
        });

        for (var vtank in vehicle.vtanks) {
          if (!uniqueProducts.containsKey(vtank.id)) {
            uniqueProducts[vtank.id] = {
              'id': vtank.id,
              'name': vtank.product,
              'capacity': vtank.capacity,
              'business_id': _currentBusiness!.id,
            };
          }
          final String key = '${vehicle.id}-${vtank.id}';
          if (!uniqueVehicleProducts.containsKey(key)) {
            uniqueVehicleProducts[key] = {
              'vehicle_id': vehicle.id,
              'product_id': vtank.id,
              'capacity': vtank.capacity,
              'business_id': _currentBusiness!.id,
            };
          }
        }
      }

      if (uniqueProducts.isNotEmpty) {
        await _supabase.from('products').upsert(uniqueProducts.values.toList(), onConflict: 'id');
        print('*** SupabaseService: Synced ${uniqueProducts.length} products.');
      }

      await _supabase.from('vehicles').upsert(vehiclesToInsert, onConflict: 'id');
      print('*** SupabaseService: Synced ${uniqueVehicles.length} vehicles.');

      if (uniqueVehicleProducts.isNotEmpty) {
        await _supabase.from('vehicle_products').upsert(uniqueVehicleProducts.values.toList(), onConflict: 'vehicle_id,product_id');
        print('*** SupabaseService: Synced ${uniqueVehicleProducts.length} vehicle products.');
      }
    } catch (e) {
      print('*** SupabaseService: Error during vehicle sync: $e');
      rethrow;
    }
  }

  Future<void> syncDrivers() async {
    if (_currentBusiness == null) {
      throw Exception('Business context not set. Call setBusinessContext() first.');
    }
    
    print('*** SupabaseService: Starting driver sync for business: ${_currentBusiness!.businessName}');
    try {
      await syncAllDepartments();
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
            'business_id': _currentBusiness!.id,
          }).toList();

      await _supabase.from('drivers').upsert(dataToInsert, onConflict: 'id');
      print('SupabaseService: Synced ${drivers.length} drivers.');
    } catch (e) {
      print('SupabaseService: Error during driver sync: $e');
      rethrow;
    }
  }

  Future<void> syncAllDepartments() async {
    if (_currentBusiness == null) {
      throw Exception('Business context not set. Call setBusinessContext() first.');
    }
    
    print('*** SupabaseService: Starting all departments sync for business: ${_currentBusiness!.businessName}');
    try {
      print('*** SupabaseService: Fetching vehicles and drivers for department sync');
      final List<Vehicle> vehicles = (await _apiService.getVehicles()).cast<Vehicle>();
      final List<Driver> drivers = (await _apiService.getDrivers()).cast<Driver>();
      print('*** SupabaseService: Fetched ${vehicles.length} vehicles and ${drivers.length} drivers');

      final Map<String, String> departmentMap = {};

      // Gather all departments with names first
      for (var vehicle in vehicles) {
        if (vehicle.departmentId != null && vehicle.departmentName.isNotEmpty) {
          departmentMap[vehicle.departmentId!] = vehicle.departmentName;
        }
      }
      for (var driver in drivers) {
        if (driver.departmentId != null && driver.departmentName.isNotEmpty) {
          departmentMap.putIfAbsent(driver.departmentId!, () => driver.departmentName);
        }
      }

      // Add any departments that only have an ID, using a placeholder name
      for (var vehicle in vehicles) {
        if (vehicle.departmentId != null) {
          departmentMap.putIfAbsent(vehicle.departmentId!, () => 'Department ${vehicle.departmentId!}');
        }
      }
      for (var driver in drivers) {
        if (driver.departmentId != null) {
          departmentMap.putIfAbsent(driver.departmentId!, () => 'Department ${driver.departmentId!}');
        }
      }

      print('*** SupabaseService: Found ${departmentMap.length} unique departments');

      if (departmentMap.isNotEmpty) {
        final List<Map<String, dynamic>> dataToInsert = departmentMap.entries.map((entry) => {
              'id': entry.key,
              'name': entry.value,
              'business_id': _currentBusiness!.id,
            }).toList();
        await _supabase.from('departments').upsert(dataToInsert, onConflict: 'id');
        print('*** SupabaseService: Synced ${departmentMap.length} unique departments.');
      } else {
        print('*** SupabaseService: No departments to sync');
      }
    } catch (e) {
      print('*** SupabaseService: Error during all departments sync: $e');
      rethrow;
    }
  }

  Future<void> syncSites() async {
    if (_currentBusiness == null) {
      throw Exception('Business context not set. Call setBusinessContext() first.');
    }
    
    print('*** SupabaseService: Starting site sync for business: ${_currentBusiness!.businessName}');
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
            'business_id': _currentBusiness!.id,
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
