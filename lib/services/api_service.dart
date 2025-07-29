import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:girscope/models/site.dart';
import 'package:girscope/models/driver.dart';
import 'package:girscope/models/vehicle.dart';
import 'package:girscope/models/fuel_transaction.dart';

class ApiService {
  static const String baseUrl = 'https://pierre-brunet-entreprise-vu-gir.klervi.net/api-impexp';
  static const String apiKey = 'c08951d341ca7c8b2d034c8d05ca8537';

  static Map<String, String> get headers => {
    'X-Klervi-API-Key': apiKey,
    'Content-Type': 'application/json',
  };

  // Test connectivity to the API
  Future<bool> testConnection() async {
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
    try {
      print('Fetching sites from: $baseUrl/rcm/sites');
      final response = await http.get(
        Uri.parse('$baseUrl/rcm/sites'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      print('Sites API - Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        
        List<dynamic> data;
        if (jsonResponse is List) {
          data = jsonResponse;
        } else if (jsonResponse is Map<String, dynamic>) {
          data = jsonResponse['sites'] ?? 
                 jsonResponse['data'] ?? 
                 jsonResponse['results'] ?? 
                 [jsonResponse];
        } else {
          throw Exception('Unexpected response format: ${jsonResponse.runtimeType}');
        }
        
        final sites = data.map((json) => Site.fromJson(json)).toList();
        print('Sites API - Found ${sites.length} sites');
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
    try {
      print('Fetching drivers from: $baseUrl/drivers');
      final response = await http.get(
        Uri.parse('$baseUrl/drivers'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      print('Drivers API - Status Code: ${response.statusCode}');

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
        print('Drivers API - Found ${drivers.length} drivers');
        return drivers;
      } else {
        throw Exception('Failed to load drivers: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Drivers API - Exception: $e');
      throw Exception('Error fetching drivers: $e');
    }
  }

  Future<List<Vehicle>> getVehicles() async {
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

  
}