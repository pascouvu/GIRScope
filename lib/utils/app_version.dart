import 'package:package_info_plus/package_info_plus.dart';

class AppVersion {
  static String _version = '1.0.0';
  static String _buildNumber = '';
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
      _isInitialized = true;
    } catch (e) {
      print('Error loading package info: $e');
      // Keep default values if package info fails to load
    }
  }

  static String get version => _version;
  static String get buildNumber => _buildNumber;
  static String get fullVersion => '$_version+$_buildNumber';
  
  static Future<String> getVersionAsync() async {
    await initialize();
    return _version;
  }
  
  static Future<String> getFullVersionAsync() async {
    await initialize();
    return fullVersion;
  }
}
