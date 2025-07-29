import 'package:flutter/material.dart';
import 'package:girscope/views/sites_tab.dart';
import 'package:girscope/views/drivers_tab.dart';
import 'package:girscope/views/vehicles_tab.dart';
import 'package:girscope/views/anomalies_tab.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(
                Icons.local_gas_station,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'GIRViewer',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.location_on), text: 'Sites'),
              Tab(icon: Icon(Icons.people), text: 'Drivers'),
              Tab(icon: Icon(Icons.directions_car), text: 'Vehicles'),
              Tab(icon: Icon(Icons.warning), text: 'Anomalies'),
            ],
            indicatorColor: Theme.of(context).colorScheme.secondary,
            labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
          ),
        ),
        body: const TabBarView(
          children: [
            SitesTab(),
            DriversTab(),
            VehiclesTab(),
            AnomaliesTab(),
          ],
        ),
      ),
    );
  }
}