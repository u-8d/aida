import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserStorageService {
  static const String _userKey = 'aida_current_user';
  static const String _isLoggedInKey = 'aida_is_logged_in';
  static const String _welcomeSeenKey = 'aida_welcome_seen';

  /// Save user data to local storage
  static Future<bool> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert user to JSON and save
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);
      await prefs.setBool(_isLoggedInKey, true);
      
      return true;
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  /// Load user data from local storage
  static Future<User?> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user is logged in
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      if (!isLoggedIn) {
        return null;
      }
      
      // Get user JSON data
      final userJson = prefs.getString(_userKey);
      if (userJson == null) {
        return null;
      }
      
      // Parse JSON and create appropriate user type
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      final userType = UserType.values.firstWhere(
        (type) => type.toString() == 'UserType.${userData['userType']}',
        orElse: () => UserType.donor,
      );
      
      // Create the appropriate user object based on type
      switch (userType) {
        case UserType.donor:
          return User.fromJson(userData);
        case UserType.ngo:
          return NGO.fromJson(userData);
        case UserType.individual:
          return Individual.fromJson(userData);
        case UserType.admin:
          return User.fromJson(userData);
      }
    } catch (e) {
      print('Error loading user: $e');
      return null;
    }
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  /// Clear user data (logout)
  static Future<bool> clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.setBool(_isLoggedInKey, false);
      return true;
    } catch (e) {
      print('Error clearing user: $e');
      return false;
    }
  }

  /// Update stored user data
  static Future<bool> updateUser(User user) async {
    // Same as saveUser, but semantically clearer for updates
    return await saveUser(user);
  }

  /// Check if user has seen welcome screen
  static Future<bool> hasSeenWelcome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_welcomeSeenKey) ?? false;
    } catch (e) {
      print('Error checking welcome status: $e');
      return false;
    }
  }

  /// Mark welcome screen as seen
  static Future<bool> setWelcomeSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_welcomeSeenKey, true);
      return true;
    } catch (e) {
      print('Error setting welcome seen: $e');
      return false;
    }
  }
}
