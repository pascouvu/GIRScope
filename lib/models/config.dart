import 'dart:convert';
import 'dart:io';

class SmtpConfig {
  final String host;
  final int port;
  final String username;
  final String password;

  SmtpConfig({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
  });

  factory SmtpConfig.fromJson(Map<String, dynamic> json) {
    return SmtpConfig(
      host: json['host'],
      port: json['port'],
      username: json['username'],
      password: json['password'],
    );
  }
}

class Config {
  final SmtpConfig smtp;
  final List<String> recipients;
  final int lookbackDays;

  Config({
    required this.smtp,
    required this.recipients,
    required this.lookbackDays,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      smtp: SmtpConfig.fromJson(json['smtp']),
      recipients: List<String>.from(json['recipients']),
      lookbackDays: json['lookback_days'],
    );
  }

  static Future<Config> load() async {
    final file = File('config.json');
    final content = await file.readAsString();
    final json = jsonDecode(content);
    return Config.fromJson(json);
  }
}
