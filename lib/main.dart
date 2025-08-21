import 'package:flutter/material.dart';
import 'package:girscope/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:girscope/secret.dart';
import 'package:girscope/views/auth/login_screen.dart';
import 'package:girscope/views/startup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('*** DEBUG: Initializing Supabase');

  await Supabase.initialize(
    url: SupabaseCredentials.SUPABASE_URL,
    anonKey: SupabaseCredentials.SUPABASE_ANON_KEY,
  );
  print('*** DEBUG: Supabase initialized');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GIRScope',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    print('*** DEBUG: AuthWrapper build called');
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        print('*** DEBUG: AuthWrapper stream builder called');
        print('*** DEBUG: AuthWrapper: snapshot hasData: ${snapshot.hasData}');
        if (snapshot.hasData) {
          final session = snapshot.data!.session;
          print('*** AuthWrapper: session is null: ${session == null}');
          if (session != null) {
            // User is authenticated, go to startup screen
            print('*** AuthWrapper: User is authenticated, going to StartupScreen');
            return const StartupScreen();
          }
        }
        // User is not authenticated, show login screen
        print('*** AuthWrapper: User is not authenticated, showing LoginScreen');
        return const LoginScreen();
      },
    );
  }
}
