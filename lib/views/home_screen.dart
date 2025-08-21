import 'package:flutter/material.dart';
import 'package:girscope/views/drivers_tab.dart';
import 'package:girscope/views/vehicles_tab.dart';
import 'package:girscope/views/anomalies_tab.dart';
import 'package:girscope/views/profile_screen.dart';
import 'package:girscope/views/sites_tab.dart';
import 'package:girscope/widgets/responsive_wrapper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    print('*** HomePage: initState called');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: ResponsiveScaffold(
        appBar: ResponsiveAppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 40,
                width: 40,
              ),
              const SizedBox(width: 8),
              Text(
                'GIRScope',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              tooltip: 'Profile',
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.place), text: 'Sites'),
              Tab(icon: Icon(Icons.people), text: 'Drivers'),
              Tab(icon: Icon(Icons.directions_car), text: 'Vehicles'),
              Tab(icon: Icon(Icons.warning), text: 'Anomalies'),
            ],
            indicatorColor: Theme.of(context).colorScheme.secondary,
            labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
          ),
        ),
        body: TabBarView(
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
