import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:girscope/secret.dart';

class IecApiService {
  static const String _baseUrl = 'https://api.iec.vu/girscope/apiget.php';
  
  static Future<Map<String, String>> getContent(String file) async {
    try {
      final url = Uri.parse('$_baseUrl?token=${SupabaseCredentials.IEC_TOKEN}&file=$file');
      
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
  
  static Future<String> getAboutUs() async {
    final content = await getContent('aboutus');
    return content['english'] ?? '';
  }
  
  static Future<String> getPrivacyPolicy() async {
    final content = await getContent('privacypolicy');
    return content['english'] ?? '';
  }
  
  static Future<String> getTermsAndConditions() async {
    final content = await getContent('termsandconditions');
    return content['english'] ?? '';
  }
}