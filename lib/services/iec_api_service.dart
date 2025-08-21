import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:girscope/models/business.dart';

class IecApiService {
  static const String _baseUrl = 'https://api.iec.vu/girscope/apiget.php';
  static const String _defaultToken = 'dd7JJfo5apbDej20250801'; // Fallback token
  
  // Business context for API calls
  Business? _currentBusiness;
  
  // Set the current business context
  void setBusinessContext(Business business) {
    _currentBusiness = business;
    print('*** IecApiService: Business context set - ${business.businessName}');
  }
  
  // Get the token for the current business (or use default)
  String get _token {
    // For now, use the default token since IEC API is separate from business API
    // In the future, businesses could have their own IEC tokens
    return _defaultToken;
  }
  
  Future<Map<String, String>> getContent(String file) async {
    try {
      final url = Uri.parse('$_baseUrl?token=$_token&file=$file');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        return {
          'english': data['english'] ?? '',
          'french': data['french'] ?? '',
          'spanish': data['spanish'] ?? '',
        };
      } else {
        throw Exception('Failed to load content: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching content: $e');
    }
  }
  
  Future<String> getAboutUs() async {
    final content = await getContent('aboutus');
    return content['english'] ?? '';
  }
  
  Future<String> getPrivacyPolicy() async {
    final content = await getContent('privacypolicy');
    return content['english'] ?? '';
  }
  
  Future<String> getTermsAndConditions() async {
    final content = await getContent('termsandconditions');
    return content['english'] ?? '';
  }
}