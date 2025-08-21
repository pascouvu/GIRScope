import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:girscope/services/supabase_service.dart';
import 'package:girscope/services/auth_service.dart';
import 'package:girscope/widgets/responsive_wrapper.dart';
import 'package:girscope/widgets/business_logo_widget.dart';
import 'package:girscope/views/home_screen.dart';
import 'package:girscope/utils/app_version.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  String _appVersion = '1.0.0';

  Map<String, SyncStatus> _syncStatuses = {
    'Departments': SyncStatus.pending,
    'Sites': SyncStatus.pending,
    'Vehicles': SyncStatus.pending,
    'Drivers': SyncStatus.pending,
    'Fuel Transactions': SyncStatus.pending,
  };

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _startSyncProcess();
  }

  Future<void> _loadAppVersion() async {
    final version = await AppVersion.getVersionAsync();
    if (mounted) {
      setState(() {
        _appVersion = version;
      });
    }
  }

  Future<void> _startSyncProcess() async {
    print('*** SyncScreen: _startSyncProcess called');
    
    // Get the current user's business context
    try {
      final business = await AuthService.getUserBusiness();
      if (business == null) {
        print('*** SyncScreen: No business found for user, skipping sync');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
        return;
      }
      
      // Set the business context for the API service
      _supabaseService.setBusinessContext(business);
      print('*** SyncScreen: Business context set - ${business.businessName}');
      
    } catch (e) {
      print('*** SyncScreen: Error getting business context: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
      return;
    }

    if (kIsWeb) {
      print('*** SyncScreen: Web platform, performing quick sync simulation');
      // On web, simulate sync process for better UX
      await _performSync('Departments', () async {
        await Future.delayed(const Duration(milliseconds: 300));
        print('*** SyncScreen: Web - Departments sync simulated');
      });
      await _performSync('Sites', () async {
        await Future.delayed(const Duration(milliseconds: 300));
        print('*** SyncScreen: Web - Sites sync simulated');
      });
      await _performSync('Vehicles', () async {
        await Future.delayed(const Duration(milliseconds: 300));
        print('*** SyncScreen: Web - Vehicles sync simulated');
      });
      await _performSync('Drivers', () async {
        await Future.delayed(const Duration(milliseconds: 300));
        print('*** SyncScreen: Web - Drivers sync simulated');
      });
      await _performSync('Fuel Transactions', () async {
        await Future.delayed(const Duration(milliseconds: 300));
        print('*** SyncScreen: Web - Fuel Transactions sync simulated');
      });
    } else {
      print('*** SyncScreen: Mobile platform, performing actual sync');
      // On mobile, perform actual sync
      await _performSync('Departments', _supabaseService.syncAllDepartments);
      await _performSync('Sites', _supabaseService.syncSites);
      await _performSync('Vehicles', _supabaseService.syncVehicles);
      await _performSync('Drivers', _supabaseService.syncDrivers);
      await _performSync('Fuel Transactions', _supabaseService.syncFuelTransactions);
    }

    print('*** SyncScreen: All syncs completed, waiting before navigation');
    // After all syncs are done, wait for 1 second and navigate
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      print('*** SyncScreen: Navigating to HomePage');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  Future<void> _performSync(String item, Future<void> Function() syncFunction) async {
    if (!mounted) return;
    setState(() {
      _syncStatuses[item] = SyncStatus.syncing;
    });
    try {
      await syncFunction();
      if (!mounted) return;
      setState(() {
        _syncStatuses[item] = SyncStatus.completed;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _syncStatuses[item] = SyncStatus.failed;
        print('Sync failed for $item: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App logo
                    Image.asset(
                      'assets/images/logo.png',
                      height: 150,
                      width: 150,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'GIRScope',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'v$_appVersion',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Show different content for web vs mobile
                    if (kIsWeb) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Loading Application',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 16),
                          const BusinessLogoWidget(
                            width: 60,
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        'Web version - Read-only mode',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Data synchronization is disabled on web',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Syncing Data',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 16),
                          const BusinessLogoWidget(
                            width: 60,
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Sync status items
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _syncStatuses.entries.map((entry) {
                          final item = entry.key;
                          final status = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: _buildStatusIcon(status),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '$item - ${_getStatusText(status)}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Developer logo and info at bottom right
            Positioned(
              bottom: 20,
              right: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Developed by IEC',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'www.iec.vu',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/images/ieclogo.png',
                    height: 60,
                    width: 60,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return const Icon(Icons.hourglass_empty, color: Colors.grey);
      case SyncStatus.syncing:
        return const CircularProgressIndicator(strokeWidth: 2);
      case SyncStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case SyncStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
    }
  }

  String _getStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.completed:
        return 'Synced';
      case SyncStatus.failed:
        return 'Failed';
    }
  }
}

enum SyncStatus { pending, syncing, completed, failed }
