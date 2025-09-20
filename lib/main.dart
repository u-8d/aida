import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/navigation/main_navigation_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'providers/supabase_app_state.dart';
import 'providers/admin_app_state.dart';
import 'providers/app_state.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kDebugMode) {
    print('Initializing AIDA app...');
    print('Flutter build mode: ${kReleaseMode ? 'Release' : 'Debug'}');
  }
  
  try {
    // Check if Supabase is configured before initializing
    if (SupabaseConfig.isConfigured) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        debug: kDebugMode,
      );
      
      if (kDebugMode) {
        print('Supabase initialized successfully');
        print('Supabase URL: ${SupabaseConfig.url}');
      }
    } else {
      if (kDebugMode) {
        print('⚠️  Supabase not configured - running in demo mode');
        print('Please update lib/config/supabase_config.dart with your credentials');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Supabase initialization error: $e');
      print('App will run in demo mode with sample data');
    }
    // Continue even if Supabase fails to initialize - we'll handle it in the UI
  }
  
  runApp(const AidaApp());
}

class AidaApp extends StatelessWidget {
  const AidaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SupabaseAppState()),
        ChangeNotifierProvider(create: (context) => AdminAppState()),
        ChangeNotifierProvider(create: (context) => AppState()),
      ],
      child: MaterialApp(
        title: 'AIDA - AI Donation Assistant',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32), // Green theme for donation app
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/admin/login': (context) => const AdminLoginScreen(),
          '/admin/dashboard': (context) => const AdminDashboardScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseAppState>(
      builder: (context, appState, _) {
        if (kDebugMode) {
          print('AuthWrapper: Current login state is ${appState.loginState}');
        }
        switch (appState.loginState) {
          case ApplicationLoginState.loggedIn:
            if (kDebugMode) {
              print('AuthWrapper: Navigating to MainNavigationScreen');
            }
            return const MainNavigationScreen();
          default:
            if (kDebugMode) {
              print('AuthWrapper: Showing AuthScreen');
            }
            return const AuthScreen();
        }
      },
    );
  }
}