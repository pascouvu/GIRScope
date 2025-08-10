import 'dart:io';
import 'package:logging/logging.dart';

class LoggingService {
  static const String _logFileName = 'anomaly_report.log';
  static const String _oldLogFileName = 'anomaly_report.log.old';
  static const int _maxLogSize = 10 * 1024 * 1024; // 10 MB

  static Future<void> setup() async {
    // Rotate logs if necessary
    await _rotateLog();

    // Configure the logger
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final logFile = File(_logFileName);
      final sink = logFile.openWrite(mode: FileMode.append);
      sink.writeln('${record.level.name}: ${record.time}: ${record.message}');
      if (record.error != null) {
        sink.writeln('ERROR: ${record.error}');
      }
      if (record.stackTrace != null) {
        sink.writeln('STACK TRACE:\n${record.stackTrace}');
      }
      sink.close();
    });
  }

  static Future<void> _rotateLog() async {
    final logFile = File(_logFileName);
    if (await logFile.exists()) {
      final size = await logFile.length();
      if (size > _maxLogSize) {
        final oldLogFile = File(_oldLogFileName);
        if (await oldLogFile.exists()) {
          await oldLogFile.delete();
        }
        await logFile.rename(_oldLogFileName);
      }
    }
  }
}
