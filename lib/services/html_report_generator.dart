import 'package:girscope/models/anomaly_detection_log.dart';
import 'package:girscope/models/fuel_transaction.dart';

class HtmlReportGenerator {
  String generateReport(List<FuelTransaction> transactions, Map<String, List<StatisticalAnomaly>> anomaliesMap) {
    final buffer = StringBuffer();

    // Start HTML
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<title>Daily Anomaly Report</title>');
    buffer.writeln('<style>');
    buffer.writeln('body { font-family: sans-serif; }');
    buffer.writeln('table { border-collapse: collapse; width: 100%; }');
    buffer.writeln('th, td { border: 1px solid #dddddd; text-align: left; padding: 8px; }');
    buffer.writeln('th { background-color: #f2f2f2; }');
    buffer.writeln('.severity-critical { color: red; font-weight: bold; }');
    buffer.writeln('.severity-high { color: orange; }');
    buffer.writeln('.severity-medium { color: #e6e600; }');
    buffer.writeln('.severity-low { color: blue; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    // Header
    buffer.writeln('<h1>Daily Anomaly Report</h1>');
    buffer.writeln('<p>Date: ${DateTime.now().toIso8601String().substring(0, 10)}</p>');

    // Summary
    buffer.writeln('<h2>Summary</h2>');
    buffer.writeln('<ul>');
    buffer.writeln('<li>Total vehicles checked: ${transactions.map((t) => t.vehicleId).toSet().length}</li>');
    buffer.writeln('<li>Transactions with anomalies: ${anomaliesMap.length}</li>');
    buffer.writeln('</ul>');

    // Anomaly Details
    if (anomaliesMap.isNotEmpty) {
      buffer.writeln('<h2>Anomaly Details</h2>');
      buffer.writeln('<table>');
      buffer.writeln('<tr><th>Vehicle</th><th>Date</th><th>Anomaly Type</th><th>Severity</th><th>Description</th></tr>');

      anomaliesMap.forEach((transactionId, anomalies) {
        final transaction = transactions.firstWhere((t) => t.id == transactionId);
        anomalies.forEach((anomaly) {
          buffer.writeln('<tr>');
          buffer.writeln('<td>${transaction.vehicleName}</td>');
          buffer.writeln('<td>${transaction.date.toIso8601String().substring(0, 10)}</td>');
          buffer.writeln('<td>${anomaly.type.toString().split('.').last}</td>');
          buffer.writeln('<td><span class="severity-${anomaly.severity.toString().toLowerCase().split('.').last}">${anomaly.severity.toString().split('.').last}</span></td>');
          buffer.writeln('<td>${anomaly.description}</td>');
          buffer.writeln('</tr>');
        });
      });

      buffer.writeln('</table>');
    } else {
      buffer.writeln('<h2>No anomalies found.</h2>');
    }

    // All Vehicles Status
    buffer.writeln('<h2>All Vehicles Checked</h2>');
    buffer.writeln('<table>');
    buffer.writeln('<tr><th>Vehicle</th><th>Status</th></tr>');
    final checkedVehicles = transactions.map((t) => t.vehicleName).toSet();
    for (final vehicleName in checkedVehicles) {
      final vehicleTransactions = transactions.where((t) => t.vehicleName == vehicleName);
      final hasAnomaly = vehicleTransactions.any((t) => anomaliesMap.containsKey(t.id));
      final status = hasAnomaly ? 'Anomaly Detected' : 'OK';
      buffer.writeln('<tr><td>$vehicleName</td><td>$status</td></tr>');
    }
    buffer.writeln('</table>');


    // End HTML
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }
}
