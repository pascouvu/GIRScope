import 'package:flutter/material.dart';
import 'package:girscope/services/supabase_service.dart';
import 'package:girscope/views/home_screen.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final SupabaseService _supabaseService = SupabaseService();

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
    _startSyncProcess();
  }

  Future<void> _startSyncProcess() async {
    await _performSync('Departments', _supabaseService.syncAllDepartments);
    await _performSync('Sites', _supabaseService.syncSites);
    await _performSync('Vehicles', _supabaseService.syncVehicles);
    await _performSync('Drivers', _supabaseService.syncDrivers);
    await _performSync('Fuel Transactions', _supabaseService.syncFuelTransactions);

    // After all syncs are done, wait for 1 second and navigate
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
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
    return Scaffold(
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
                    Text(
                      'GIRScope',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Syncing Data',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
