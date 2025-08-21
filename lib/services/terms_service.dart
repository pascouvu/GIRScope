import 'package:shared_preferences/shared_preferences.dart';

class TermsService {
  static const String _termsAcceptedKey = 'terms_accepted';
  static const String _termsVersionKey = 'terms_version';
  static const String _currentTermsVersion = '1.0.0';

  /// Check if user has accepted the current version of terms
  static Future<bool> hasAcceptedTerms() async {
    print('*** TermsService: Checking terms acceptance');
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_termsAcceptedKey) ?? false;
    final acceptedVersion = prefs.getString(_termsVersionKey) ?? '';
    print('*** TermsService: accepted=$accepted, acceptedVersion=$acceptedVersion, currentVersion=$_currentTermsVersion');
    
    // Check if user accepted terms and it's the current version
    final result = accepted && acceptedVersion == _currentTermsVersion;
    print('*** TermsService: result=$result');
    return result;
  }

  /// Mark terms as accepted for current version
  static Future<void> acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_termsAcceptedKey, true);
    await prefs.setString(_termsVersionKey, _currentTermsVersion);
  }

  /// Reset terms acceptance (for testing or new terms version)
  static Future<void> resetTermsAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_termsAcceptedKey);
    await prefs.remove(_termsVersionKey);
  }

  /// Get current terms version
  static String getCurrentTermsVersion() {
    return _currentTermsVersion;
  }
}
