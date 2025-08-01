import 'package:flutter/material.dart';
import 'package:girscope/services/terms_service.dart';
import 'package:girscope/views/terms_acceptance_screen.dart';
import 'package:girscope/views/sync_screen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _checkTermsAcceptance();
  }

  Future<void> _checkTermsAcceptance() async {
    // Small delay to show the splash screen briefly
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;

    try {
      final hasAccepted = await TermsService.hasAcceptedTerms();
      
      if (mounted) {
        if (hasAccepted) {
          // User has accepted terms, go to sync screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SyncScreen()),
          );
        } else {
          // User needs to accept terms first
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const TermsAcceptanceScreen()),
          );
        }
      }
    } catch (e) {
      // If there's an error checking terms, show terms acceptance to be safe
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TermsAcceptanceScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                  width: 120,
                ),
                const SizedBox(height: 24),
                Text(
                  'GIRScope',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fuel Management System',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'Initializing...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}