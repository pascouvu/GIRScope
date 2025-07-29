import 'package:flutter/material.dart';
import 'package:girscope/models/site.dart';
import 'package:girscope/services/api_service.dart';
import 'package:girscope/widgets/site_card.dart';
import 'package:girscope/widgets/connection_test_widget.dart';

class SitesTab extends StatefulWidget {
  const SitesTab({super.key});

  @override
  State<SitesTab> createState() => _SitesTabState();
}

class _SitesTabState extends State<SitesTab> {
  final ApiService _apiService = ApiService();
  List<Site> _sites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final sites = await _apiService.getSites();
      
      if (mounted) {
        setState(() {
          _sites = sites;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testConnection() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final isConnected = await _apiService.testConnection();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (isConnected) {
            _error = 'Connection test successful! Check console logs for details.';
          } else {
            _error = 'Connection test failed. Check console logs for details.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Connection test error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading sites...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading sites',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _loadSites,
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _testConnection,
                    child: const Text('Test Connection'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_sites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text('No sites found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sites.length + 1, // +1 for connection test widget
        itemBuilder: (context, index) {
          if (index == 0) {
            // Show connection test widget first
            return const ConnectionTestWidget();
          }
          
          final siteIndex = index - 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SiteCard(site: _sites[siteIndex]),
          );
        },
      ),
    );
  }
}