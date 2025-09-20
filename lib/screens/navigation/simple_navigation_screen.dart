import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_app_state.dart';
import '../public/public_feed_screen.dart';
import '../donor/donor_dashboard_screen.dart';
import '../recipient/recipient_dashboard_screen.dart';
import '../auth/auth_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1; // Default to My Donations (index 1)

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseAppState>(
      builder: (context, appState, child) {
        // Check if user is logged in
        if (appState.loginState != ApplicationLoginState.loggedIn) {
          return const AuthScreen();
        }

        final userType = appState.currentUser?.userType ?? 'donor';

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _getScreensForUserType(userType),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey[600],
            items: _getBottomNavItemsForUserType(userType),
          ),
          appBar: AppBar(
            title: Text(_getAppBarTitle()),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => appState.signOut(),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _getScreensForUserType(String userType) {
    if (userType == 'donor') {
      return [
        const PublicFeedScreen(),
        const DonorDashboardScreen(),
      ];
    } else {
      return [
        const PublicFeedScreen(),
        const RecipientDashboardScreen(),
      ];
    }
  }

  List<BottomNavigationBarItem> _getBottomNavItemsForUserType(String userType) {
    if (userType == 'donor') {
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Explore',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.volunteer_activism),
          label: 'My Donations',
        ),
      ];
    } else {
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Explore',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.campaign),
          label: 'My Needs',
        ),
      ];
    }
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'AIDA - Explore';
      case 1:
        return 'AIDA - Dashboard';
      default:
        return 'AIDA';
    }
  }
}
