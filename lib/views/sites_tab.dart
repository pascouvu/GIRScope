import 'dart:async';
import 'package:flutter/material.dart';
import 'package:girscope/models/site.dart';
import 'package:girscope/services/api_service.dart';
import 'package:girscope/widgets/site_card.dart';

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
  int _onlineControllers = 0;
  int _offlineControllers = 0;
  int _totalTanks = 0;
  Timer? _summaryTimer;
  final List<Map<String, dynamic>> _summaryEntries = [];

  @override
  void initState() {
    super.initState();
    _loadSites();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _summaryTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _summaryTimer?.cancel();
    _summaryTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _refreshSummary();
    });
  }

  Future<void> _refreshSummary() async {
    try {
      final sites = await _apiService.getSites();
      final List<Map<String, dynamic>> entries = [];
      int online = 0, offline = 0, tanks = 0;

      for (var site in sites) {
        // sites is a List<Site> from getSites(), so treat as Site
        tanks += site.tanks.length;
        final defaultTank = site.tanks.isNotEmpty ? site.tanks.first.name : '';
        for (var c in site.controllers) {
          if (c.sn == null || c.sn!.trim().isEmpty) continue;
          entries.add({'controller': c, 'tankName': defaultTank});
          if (c.online == true) {
            online++;
          } else {
            offline++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _summaryEntries.clear();
          _summaryEntries.addAll(entries);
          _onlineControllers = online;
          _offlineControllers = offline;
          _totalTanks = tanks;
        });
      }
    } catch (e) {
      print('Summary refresh failed: $e');
    }
  }

  List<Widget> _buildControllersSummary(BuildContext context) {
    final List<Widget> rows = [];

    // Prefer using the precomputed summary entries (from periodic refresh) when available
    final List<Map<String, dynamic>> entries = [];
    if (_summaryEntries.isNotEmpty) {
      entries.addAll(_summaryEntries);
    } else {
      // Build list of controller entries paired with a tank name (if available from parent site)
      for (var s in _sites) {
        final String defaultTank = s.tanks.isNotEmpty ? s.tanks.first.name : '';
        for (var c in s.controllers) {
          // Only include controllers that have a serial number (sn)
          if (c.sn == null || c.sn!.trim().isEmpty) continue;
          entries.add({'controller': c, 'tankName': defaultTank});
        }
      }
    }

    // Sort: online first
    entries.sort((a, b) {
      final Controller ca = a['controller'] as Controller;
      final Controller cb = b['controller'] as Controller;
      final aOnline = ca.online == true ? 0 : 1;
      final bOnline = cb.online == true ? 0 : 1;
      return aOnline.compareTo(bOnline);
    });

    for (var e in entries) {
      final Controller c = e['controller'] as Controller;
      final String tankName = (e['tankName'] as String?)?.isNotEmpty == true ? e['tankName'] as String : (c.name.isNotEmpty ? c.name : (c.sn ?? 'Unknown'));
      final online = c.online == true;
      final date = c.date;
      final formattedDate = date != null ? _formatDate(date) : '';
      final daysAgo = date != null ? _daysAgo(date) : 0;

      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // Tank name (prefer tank; fall back to controller name/serial)
            Expanded(child: Text(tankName, style: Theme.of(context).textTheme.bodyMedium)),
            // Status dot only (smaller width)
            SizedBox(
              width: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, size: 12, color: online ? Colors.green : Colors.red),
                ],
              ),
            ),
            SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formattedDate, style: Theme.of(context).textTheme.bodySmall),
                  if (daysAgo > 0) Text('(${daysAgo} day${daysAgo == 1 ? '' : 's'} ago)', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                ],
              ),
            ),
          ],
        ),
      ));
    }

    return rows;
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final day = two(d.day);
    final month = two(d.month);
    final year = d.year.toString().substring(2);
    final hour = two(d.hour);
    final minute = two(d.minute);
    final base = '$day/$month/$year $hour:$minute';
    final diff = DateTime.now().toLocal().difference(d);
    if (diff.inHours >= 24) {
      final days = diff.inDays;
      //return '$base (${days} day${days == 1 ? '' : 's'} ago)';
    }
    return base;
  }

  int _daysAgo(DateTime dt) {
    final diff = DateTime.now().toLocal().difference(dt.toLocal());
    return diff.inDays;
  }

  Future<void> _loadSites() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final sites = await _apiService.getSites();
      print('Sites fetched: count=${sites.length} ids=${sites.map((s) => s.id).toList()} names=${sites.map((s) => s.name).toList()}');

      // Try to fetch detailed live status for each site (controllers/tanks/pumps)
      final detailedSites = await Future.wait(sites.map((s) => _fetchDetailedSite(s)));

      // compute summary based only on controllers that have a serial (sn)
      int online = 0, offline = 0, tanks = 0;
      final List<Controller> controllersWithSn = [];
      for (var s in detailedSites) {
        tanks += s.tanks.length;
        for (var c in s.controllers) {
          if (c.sn != null && c.sn!.trim().isNotEmpty) {
            controllersWithSn.add(c);
            if (c.online == true && c.sn != null ) online++; else offline++;
            print("***debug");
            print (c.name + " " + c.online.toString() + " " );
          }
        }
      }

      if (mounted) {
        setState(() {
          _sites = detailedSites;
          _isLoading = false;
          _onlineControllers = online;
          _offlineControllers = offline;
          _totalTanks = tanks;
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

  // Try to fetch detailed live site status; fall back to the original site if the call fails
  Future<Site> _fetchDetailedSite(Site site) async {
    try {
      print('Fetching detailed status for site id=${site.id} name=${site.name}');
      if (site.id.trim().isEmpty) {
        print('  -> skipped (empty id)');
        return site;
      }
      final detailed = await _apiService.getSiteStatus(site.id);
      print('  -> detailed fetched for ${site.id}: name=${detailed.name} tanks=${detailed.tanks.length} pumps=${detailed.pumps.length} controllers=${detailed.controllers.length} lat=${detailed.latitude} lon=${detailed.longitude}');
      // Merge basic metadata with live details (prefer live values)
      return Site(
        id: detailed.id.isNotEmpty ? detailed.id : site.id,
        name: detailed.name.isNotEmpty ? detailed.name : site.name,
        code: detailed.code ?? site.code,
        address: detailed.address ?? site.address,
        city: detailed.city ?? site.city,
        zipCode: detailed.zipCode ?? site.zipCode,
        country: detailed.country ?? site.country,
        latitude: detailed.latitude ?? site.latitude,
        longitude: detailed.longitude ?? site.longitude,
        businessId: detailed.businessId ?? site.businessId,
        tanks: detailed.tanks.isNotEmpty ? detailed.tanks : site.tanks,
        pumps: detailed.pumps.isNotEmpty ? detailed.pumps : site.pumps,
        controllers: detailed.controllers.isNotEmpty ? detailed.controllers : site.controllers,
      );
    } catch (e) {
      print('Failed to fetch detailed site for ${site.id}: $e');
      return site;
    }
  }

  Future<void> _refreshSiteStatus(String siteId, int index) async {
    try {
      final liveSite = await _apiService.getSiteStatus(siteId);

      if (mounted) {
        setState(() {
          // merge live tanks/controllers/pumps into existing site object
          _sites[index] = Site(
            id: liveSite.id,
            name: liveSite.name,
            code: liveSite.code,
            address: liveSite.address,
            city: liveSite.city,
            zipCode: liveSite.zipCode,
            country: liveSite.country,
            latitude: liveSite.latitude,
            longitude: liveSite.longitude,
            businessId: liveSite.businessId,
            tanks: liveSite.tanks,
            pumps: liveSite.pumps,
            controllers: liveSite.controllers,
          );
        });
      }
    } catch (e) {
      print('Error refreshing site status: $e');
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
        padding: const EdgeInsets.all(12),
        itemCount: _sites.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // summary card
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Connections', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text('Controllers: $_onlineControllers online • $_offlineControllers offline', style: Theme.of(context).textTheme.bodyMedium),
                             // const SizedBox(height: 4),
                             // Text('Tanks: $_totalTanks', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          IconButton(
                            onPressed: _loadSites,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Refresh all',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Controllers list header (styled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text('Tank / Controller', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                            SizedBox(
                              width: 50,
                              child: Center(child: Text('Status', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                            ),
                            SizedBox(
                              width: 90,
                              child: Center(child: Text('Last seen', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Flatten controllers from all sites into a list (skip entries with no controller id)
                      ..._buildControllersSummary(context),
                    ],
                  ),
                ),
              ),
            );
          }

          final site = _sites[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: SiteCard(site: site, compact: true)),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      tooltip: 'Refresh live status',
                      onPressed: () => _refreshSiteStatus(site.id, index - 1),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}