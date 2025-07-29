import 'package:flutter/material.dart';
import 'package:girscope/services/api_service.dart';

class ConnectionTestWidget extends StatefulWidget {
  const ConnectionTestWidget({super.key});

  @override
  State<ConnectionTestWidget> createState() => _ConnectionTestWidgetState();
}

class _ConnectionTestWidgetState extends State<ConnectionTestWidget> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _result;

  Future<void> _runConnectionTest() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      print('=== Starting Connection Test ===');
      final isConnected = await _apiService.testConnection();
      
      setState(() {
        _isLoading = false;
        _result = isConnected 
          ? 'Connection test successful! ✅\nCheck console for detailed logs.' 
          : 'Connection test failed! ❌\nCheck console for error details.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = 'Connection test error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'HTTP Connection Diagnostics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'API Endpoint: ${ApiService.baseUrl}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Testing connection...'),
                ],
              )
            else ...[
              ElevatedButton(
                onPressed: _runConnectionTest,
                child: const Text('Test API Connection'),
              ),
              if (_result != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _result!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}