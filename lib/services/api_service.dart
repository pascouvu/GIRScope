import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:girscope/models/site.dart';
import 'package:girscope/services/auth_service.dart';
import 'package:girscope/models/driver.dart';
import 'package:girscope/models/vehicle.dart';
import 'package:girscope/models/fuel_transaction.dart';
import 'package:girscope/models/business.dart';

class ApiService {
  // Remove hardcoded credentials - these will now come from the business context
  // static const String baseUrl = 'https://pierre-brunet-entreprise-vu-gir.klervi.net/api-impexp';
  // static const String apiKey = 'c08951d341ca7c8b2d034c8d05ca8537';

  // Business context for API calls
  Business? _currentBusiness;

  // Set the current business context
  void setBusinessContext(Business business) {
    _currentBusiness = business;
    print('*** ApiService: Business context set - ${business.businessName} (${business.apiUrl})');
  }

  // If an ApiService instance is created without an explicit business context,
  // attempt to resolve the current business from the authenticated user.
  Future<void> _ensureBusinessContext() async {
    if (_currentBusiness != null) return;
    try {
      final business = await AuthService.getUserBusiness();
      if (business != null) {
        setBusinessContext(business);
      }
    } catch (e) {
      // Ignore - we'll throw later when trying to use headers/baseUrl if still null
      print('ApiService: _ensureBusinessContext failed: $e');
    }
  }

  // Recursively search a dynamic value for the first Map<String, dynamic>.
  Map<String, dynamic>? _extractFirstMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List) {
      for (var item in value) {
        final found = _extractFirstMap(item);
        if (found != null) return found;
      }
    }
    return null;
  }

  // Get headers with business-specific API key
  Map<String, String> get headers {
    if (_currentBusiness == null) {
      throw Exception('Business context not set. Call setBusinessContext() first.');
    }
    
    return {
      'X-Klervi-API-Key': _currentBusiness!.apiKey,
      'Content-Type': 'application/json',
    };
  }

  // Get the base URL for the current business
  String get baseUrl {
    if (_currentBusiness == null) {
      throw Exception('Business context not set. Call setBusinessContext() first.');
    }
    
    return _currentBusiness!.apiUrl;
  }

  // Test connectivity to the API with business-specific credentials
  Future<bool> testConnection() async {
    await _ensureBusinessContext();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rcm/sites'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      print('API Test - Status Code: ${response.statusCode}');
      print('API Test - Response Headers: ${response.headers}');
      print('API Test - Response Body (first 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('API Test - Connection Error: $e');
      return false;
    }
  }

  Future<List<Site>> getSites() async {
    await _ensureBusinessContext();
    try {
      print('Fetching sites from: $baseUrl/rcm/sites');
      final response = await http.get(
        Uri.parse('$baseUrl/rcm/sites'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      print('Sites API - Status Code: ${response.statusCode}');
      print('Sites API - Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        print('Sites API - Decoded JSON type: ${jsonResponse.runtimeType}');
        print('Sites API - Decoded JSON preview: ${jsonResponse is Map ? (jsonResponse.keys.toList()) : (jsonResponse is List ? '[List length ${jsonResponse.length}]' : jsonResponse)}');
        
        List<dynamic> data;
        if (jsonResponse is List) {
          data = jsonResponse;
        } else if (jsonResponse is Map<String, dynamic>) {
          // Look for common wrappers; support `result` which this API uses
          final candidate = jsonResponse['result'] ?? jsonResponse['sites'] ?? jsonResponse['data'] ?? jsonResponse['results'];
          if (candidate == null) {
            data = [jsonResponse];
          } else if (candidate is List) {
            data = candidate;
          } else if (candidate is Map<String, dynamic>) {
            data = [candidate];
          } else {
            // Fallback: wrap as single-item list
            data = [candidate];
          }
        } else {
          throw Exception('Unexpected response format: ${jsonResponse.runtimeType}');
        }
        
        print('Sites API - Data payload length: ${data.length}');
        final sites = data.map((json) => Site.fromJson(json)).toList();
        print('Sites API - Found ${sites.length} sites (after parsing)');
        return sites;
      } else {
        throw Exception('Failed to load sites: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Sites API - Exception: $e');
      throw Exception('Error fetching sites: $e');
    }
  }

  Future<List<Driver>> getDrivers() async {
    await _ensureBusinessContext();
    try {
      print('*** API Service: Fetching drivers from: $baseUrl/drivers');
      final response = await http.get(
        Uri.parse('$baseUrl/drivers'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      print('*** Drivers API - Status Code: ${response.statusCode}');
      print('*** Drivers API - Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        
        List<dynamic> data;
        if (jsonResponse is List) {
          data = jsonResponse;
        } else if (jsonResponse is Map<String, dynamic>) {
          data = jsonResponse['result'] ?? 
                 jsonResponse['drivers'] ?? 
                 jsonResponse['data'] ?? 
                 jsonResponse['results'] ?? 
                 [jsonResponse];
        } else {
          throw Exception('Unexpected response format: ${jsonResponse.runtimeType}');
        }
        
        final drivers = data.map((json) => Driver.fromJson(json)).toList();
        print('*** Drivers API - Found ${drivers.length} drivers');
        return drivers;
      } else {
        throw Exception('Failed to load drivers: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('*** Drivers API - Exception: $e');
      throw Exception('Error fetching drivers: $e');
    }
  }

  Future<List<Vehicle>> getVehicles() async {
    await _ensureBusinessContext();
    try {
      print('Fetching vehicles from: $baseUrl/vehicles');
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      print('Vehicles API - Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        
        List<dynamic> data;
        if (jsonResponse is List) {
          data = jsonResponse;
        } else if (jsonResponse is Map<String, dynamic>) {
          data = jsonResponse['result'] ?? 
                 jsonResponse['vehicles'] ?? 
                 jsonResponse['data'] ?? 
                 jsonResponse['results'] ?? 
                 [jsonResponse];
        } else {
          throw Exception('Unexpected response format: ${jsonResponse.runtimeType}');
        }
        
        final vehicles = data.map((json) => Vehicle.fromJson(json)).toList();
        print('Vehicles API - Found ${vehicles.length} vehicles');
        return vehicles;
      } else {
        throw Exception('Failed to load vehicles: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Vehicles API - Exception: $e');
      throw Exception('Error fetching vehicles: $e');
    }
  }

  Future<Map<String, dynamic>> getFuelTransactionsPaginated({String? lastId}) async {
    await _ensureBusinessContext();
    try {
      final uri = Uri.parse('$baseUrl/transac_fuels').replace(
        queryParameters: {
          if (lastId != null) 'last_id': lastId,
        },
      );

      print('Fetching fuel transactions from: $uri');
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

      print('Fuel Transactions API - Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        print('Fuel Transactions API - Raw JSON Response: ${jsonResponse}');
        
        List<dynamic> data;
        bool more = false;

        if (jsonResponse is Map<String, dynamic>) {
          data = jsonResponse['result'] ?? jsonResponse['data'] ?? jsonResponse['transactions'] ?? jsonResponse['results'] ?? [];
          more = jsonResponse['more'] ?? false;
        } else if (jsonResponse is List) {
          data = jsonResponse;
          more = false; // If it's a list, assume no 'more' flag unless specified otherwise by API
        } else {
          throw Exception('Unexpected response format: ${jsonResponse.runtimeType}');
        }
        
        final transactions = data.map((json) => FuelTransaction.fromJson(json)).toList();
        print('Fuel Transactions API - Found ${transactions.length} transactions. More: $more');
        return {'transactions': transactions, 'more': more};
      } else {
        throw Exception('Failed to load fuel transactions: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Fuel Transactions API - Exception: $e');
      throw Exception('Error fetching fuel transactions: $e');
    }
  }

  Future<List<FuelTransaction>> getDriverRefuelingData(String driverId, {int limit = 25, int offset = 0, int days = 30}) async {
    await _ensureBusinessContext();
    try {
      final uri = Uri.parse('$baseUrl/transac_fuels').replace(
        queryParameters: {
          'driver_id': driverId,
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      print('Fetching driver refueling data from: $uri');
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

      print('Driver Refueling API - Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        
        List<dynamic> data;
        if (jsonResponse is List) {
          data = jsonResponse;
        } else if (jsonResponse is Map<String, dynamic>) {
          data = jsonResponse['result'] ?? 
                 jsonResponse['data'] ?? 
                 jsonResponse['transactions'] ?? 
                 jsonResponse['results'] ?? 
                 [jsonResponse];
        } else {
          throw Exception('Unexpected response format: ${jsonResponse.runtimeType}');
        }
        
        final transactions = data.map((json) => FuelTransaction.fromJson(json)).toList();
        print('Driver Refueling API - Found ${transactions.length} transactions (offset: $offset, limit: $limit)');
        return transactions;
      } else {
        throw Exception('Failed to load driver refueling data: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Driver Refueling API - Exception: $e');
      throw Exception('Error fetching driver refueling data: $e');
    }
  }

  Future<List<FuelTransaction>> getVehicleRefuelingData(String vehicleId, {int limit = 25, int offset = 0, int days = 30}) async {
    await _ensureBusinessContext();
    try {
      final uri = Uri.parse('$baseUrl/transac_fuels').replace(
        queryParameters: {
          'vehicle_id': vehicleId,
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      print('Fetching vehicle refueling data from: $uri');
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

      print('Vehicle Refueling API - Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        
        List<dynamic> data;
        if (jsonResponse is List) {
          data = jsonResponse;
        } else if (jsonResponse is Map<String, dynamic>) {
          data = jsonResponse['result'] ?? 
                 jsonResponse['data'] ?? 
                 jsonResponse['transactions'] ?? 
                 jsonResponse['results'] ?? 
                 [jsonResponse];
        } else {
          throw Exception('Unexpected response format: ${jsonResponse.runtimeType}');
        }
        
        final transactions = data.map((json) => FuelTransaction.fromJson(json)).toList();
        print('Vehicle Refueling API - Found ${transactions.length} transactions (offset: $offset, limit: $limit)');
        return transactions;
      } else {
        throw Exception('Failed to load vehicle refueling data: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Vehicle Refueling API - Exception: $e');
      throw Exception('Error fetching vehicle refueling data: $e');
    }
  }

  /// Fetch live status for a single site (returns a Site built from the API's `result` object)
  Future<Site> getSiteStatus(String siteId) async {
    await _ensureBusinessContext();
    try {
      final uri = Uri.parse('$baseUrl/rcm/sites/$siteId');
      print('Fetching site status from: $uri');

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      print('Site Status API - Status Code: ${response.statusCode}');
      print('Site Status API - Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);

        // Try to find the first Map<String, dynamic> in the response body
        final Map<String, dynamic>? data = _extractFirstMap(jsonResponse) ??
            (jsonResponse is Map<String, dynamic> ? jsonResponse : null);

        if (data == null) {
          throw Exception('Unexpected site status response format: ${jsonResponse.runtimeType}');
        }

        final site = Site.fromJson(data);
        print('Site Status API - Loaded site ${site.id} (${site.name})');
        return site;
      } else {
        throw Exception('Failed to load site status: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Site Status API - Exception for site $siteId: $e');
      throw Exception('Error fetching site status for $siteId: $e');
    }
  }
}
