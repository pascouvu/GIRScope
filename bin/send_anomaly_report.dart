import 'dart:io';
import 'dart:convert';

import 'package:girscope/models/config.dart';
import 'package:girscope/services/anomaly_detection_service.dart';
import 'package:girscope/services/email_service.dart';
import 'package:girscope/services/html_report_generator.dart';
import 'package:girscope/services/logging_service.dart';
import 'package:girscope/services/supabase_service.dart';
import 'package:girscope/secret.dart';
import 'package:logging/logging.dart';
import 'package:supabase/supabase.dart';

Future<void> main(List<String> args) async {
  await LoggingService.setup();
  final log = Logger('AnomalyReport');

  log.info('Starting daily anomaly report generation...');

  try {
    // 1. Load Configuration
    log.info('Loading configuration from config.json...');
    // Assumes config.json is in the same directory where the script is run.
    final configFile = File('config.json');
    final configContent = await configFile.readAsString();
    final configJson = jsonDecode(configContent);
    final config = Config.fromJson(configJson);
    log.info('Configuration loaded successfully.');

    // 2. Initialize Supabase
    log.info('Initializing Supabase client...');
    final supabaseClient = SupabaseClient(
      SupabaseCredentials.SUPABASE_URL,
      SupabaseCredentials.SUPABASE_ANON_KEY,
    );
    log.info('Supabase client initialized.');

    // 3. Instantiate Services
    // NOTE: This requires SupabaseService to be modified to accept a client.
    // This change cannot be tested in this environment.
    final supabaseService = SupabaseService(supabaseClient: supabaseClient);
    final anomalyDetectionService = AnomalyDetectionService();
    final htmlReportGenerator = HtmlReportGenerator();
    final emailService = EmailService();

    // 4. Sync all data to ensure it's up-to-date
    log.info('Starting data synchronization...');
    await supabaseService.syncAllDepartments();
    await supabaseService.syncSites();
    await supabaseService.syncVehicles();
    await supabaseService.syncDrivers();
    await supabaseService.syncFuelTransactions();
    log.info('Data synchronization complete.');

    // 5. Fetch transactions for the analysis period
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: config.lookbackDays));
    log.info('Fetching transactions from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}...');

    final transactions = await supabaseService.getFuelTransactions(
      startDate: startDate,
      endDate: endDate,
    );
    log.info('Found ${transactions.length} transactions to analyze.');

    if (transactions.isEmpty) {
      log.info('No transactions found for the period. Exiting.');
      return;
    }

    // 6. Analyze for anomalies
    log.info('Starting anomaly analysis...');
    final anomaliesMap = await anomalyDetectionService.analyzeAnomalies(
      transactions: transactions,
      startDate: startDate,
      endDate: endDate,
    );
    log.info('Anomaly analysis complete.');
    log.info('Found ${anomaliesMap.length} transactions with anomalies.');

    // 7. Generate and send the report
    log.info('Generating HTML report...');
    final htmlReport = htmlReportGenerator.generateReport(transactions, anomaliesMap);
    log.info('HTML report generated.');

    await emailService.sendReport(htmlReport, config);

  } catch (e, stackTrace) {
    log.severe('An error occurred during script execution.', e, stackTrace);
    // Exit with a non-zero code to indicate failure, useful for CRON jobs
    exit(1);
  }

  log.info('Script finished successfully.');
}
