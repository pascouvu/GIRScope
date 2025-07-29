import 'package:flutter/material.dart';
import 'package:girscope/theme.dart';
import 'package:girscope/views/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:girscope/secret.dart';
import 'package:girscope/services/supabase_service.dart';
import 'package:girscope/views/sync_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseCredentials.SUPABASE_URL,
    anonKey: SupabaseCredentials.SUPABASE_ANON_KEY,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GIRViewer',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const SyncScreen(),
    );
  }
}
