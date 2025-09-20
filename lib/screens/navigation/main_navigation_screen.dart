import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_app_state.dart';
import '../../providers/admin_app_state.dart';
import '../public/public_feed_screen.dart';
import '../donor/donor_dashboard_screen.dart';
import '../recipient/recipient_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../chat/chat_screen.dart';
import '../account/account_screen.dart';

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
        final userType = appState.currentUser?.userType ?? 'donor';

        // Handle admin users differently
        if (userType == 'admin') {
          return Consumer<AdminAppState>(
            builder: (context, adminState, child) {
              if (adminState.authState == AdminAuthState.loggedIn) {
                return const AdminDashboardScreen();
              } else {
                // Redirect to admin login
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pushReplacementNamed('/admin/login');
                });
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          );
        }

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
        );
      },
    );
  }

  List<Widget> _getScreensForUserType(String userType) {
    if (userType == 'donor') {
      return [
        PublicFeedScreen(),
        const DonorDashboardScreen(),
        const ChatScreen(),
        const AccountScreen(),
      ];
    } else {
      // For NGO and Individual users, show recipient dashboard
      return [
        PublicFeedScreen(),
        const RecipientDashboardScreen(),
        const ChatScreen(),
        const AccountScreen(),
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
        const BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Account',
        ),
      ];
    } else {
      // For NGO and Individual users
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Explore',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.campaign),
          label: 'My Needs',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Account',
        ),
      ];
    }
  }
}
