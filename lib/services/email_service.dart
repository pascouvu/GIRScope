import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:girscope/models/config.dart';

class EmailService {
  Future<void> sendReport(String htmlBody, Config config) async {
    final smtpServer = SmtpServer(
      config.smtp.host,
      port: config.smtp.port,
      username: config.smtp.username,
      password: config.smtp.password,
    );

    final message = Message()
      ..from = Address(config.smtp.username, 'GIRScope Anomaly Report')
      ..recipients.addAll(config.recipients)
      ..subject = 'Daily Anomaly Report - ${DateTime.now().toIso8601String().substring(0, 10)}'
      ..html = htmlBody;

    try {
      print('INFO: Sending email report...');
      final sendReport = await send(message, smtpServer);
      print('INFO: Email sent successfully: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('FATAL: Email could not be sent.');
      print('MailerException: ${e.message}');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      rethrow;
    }
  }
}
