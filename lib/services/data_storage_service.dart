import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/donation.dart';
import '../models/need.dart';

class DataStorageService {
  static const String _donationsKey = 'aida_donations';
  static const String _needsKey = 'aida_needs';

  /// Save donations to local storage
  static Future<bool> saveDonations(List<Donation> donations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final donationsJson = donations.map((d) => d.toJson()).toList();
      final jsonString = jsonEncode(donationsJson);
      await prefs.setString(_donationsKey, jsonString);
      return true;
    } catch (e) {
      print('Error saving donations: $e');
      return false;
    }
  }

  /// Load donations from local storage
  static Future<List<Donation>> loadDonations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_donationsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Donation.fromJson(json)).toList();
    } catch (e) {
      print('Error loading donations: $e');
      return [];
    }
  }

  /// Save needs to local storage
  static Future<bool> saveNeeds(List<Need> needs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final needsJson = needs.map((n) => n.toJson()).toList();
      final jsonString = jsonEncode(needsJson);
      await prefs.setString(_needsKey, jsonString);
      return true;
    } catch (e) {
      print('Error saving needs: $e');
      return false;
    }
  }

  /// Load needs from local storage
  static Future<List<Need>> loadNeeds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_needsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Need.fromJson(json)).toList();
    } catch (e) {
      print('Error loading needs: $e');
      return [];
    }
  }

  /// Clear all stored data
  static Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_donationsKey);
      await prefs.remove(_needsKey);
      return true;
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }
}
