import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase_user.dart';
import '../models/user_endorsement.dart';
import '../models/user_report.dart';

class ProfileService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get user profile by ID
  static Future<SupabaseUser> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return SupabaseUser.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  // Update user profile
  static Future<void> updateUserProfile(SupabaseUser user) async {
    try {
      await _supabase
          .from('users')
          .update(user.toJson())
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }

  // Upload profile picture to Supabase Storage
  static Future<String> uploadProfilePicture(String userId, Uint8List fileBytes, String fileName) async {
    try {
      final fileExtension = fileName.split('.').last;
      final storagePath = '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await _supabase.storage
          .from('profile-pictures')
          .uploadBinary(storagePath, fileBytes);

      final publicUrl = _supabase.storage
          .from('profile-pictures')
          .getPublicUrl(storagePath);

      // Update user profile with new picture URL
      await _supabase
          .from('users')
          .update({'profile_picture_url': publicUrl})
          .eq('id', userId);

      return publicUrl;
    } catch (e) {
      throw Exception('Error uploading profile picture: $e');
    }
  }

  // Check if user has endorsed another user
  static Future<bool> hasUserEndorsed(String endorserId, String endorsedUserId) async {
    try {
      final response = await _supabase
          .from('user_endorsements')
          .select('id')
          .eq('endorser_id', endorserId)
          .eq('endorsed_user_id', endorsedUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Add endorsement
  static Future<void> addEndorsement(String endorserId, String endorsedUserId) async {
    try {
      await _supabase
          .from('user_endorsements')
          .insert({
            'endorser_id': endorserId,
            'endorsed_user_id': endorsedUserId,
          });
    } catch (e) {
      throw Exception('Error adding endorsement: $e');
    }
  }

  // Remove endorsement
  static Future<void> removeEndorsement(String endorserId, String endorsedUserId) async {
    try {
      await _supabase
          .from('user_endorsements')
          .delete()
          .eq('endorser_id', endorserId)
          .eq('endorsed_user_id', endorsedUserId);
    } catch (e) {
      throw Exception('Error removing endorsement: $e');
    }
  }

  // Get user endorsements
  static Future<List<UserEndorsement>> getUserEndorsements(String userId) async {
    try {
      final response = await _supabase
          .from('user_endorsements')
          .select()
          .eq('endorsed_user_id', userId)
          .order('created_at', ascending: false);

      return response.map<UserEndorsement>((json) => UserEndorsement.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error fetching endorsements: $e');
    }
  }

  // Report user
  static Future<void> reportUser(
    String reporterId,
    String reportedUserId,
    String reason,
    String? description,
  ) async {
    try {
      await _supabase
          .from('user_reports')
          .insert({
            'reporter_id': reporterId,
            'reported_user_id': reportedUserId,
            'reason': reason,
            'description': description,
            'status': 'pending',
          });
    } catch (e) {
      throw Exception('Error reporting user: $e');
    }
  }

  // Get user reports (for admins)
  static Future<List<UserReport>> getUserReports(String userId) async {
    try {
      final response = await _supabase
          .from('user_reports')
          .select()
          .eq('reported_user_id', userId)
          .order('created_at', ascending: false);

      return response.map<UserReport>((json) => UserReport.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error fetching reports: $e');
    }
  }

  // Search users
  static Future<List<SupabaseUser>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .or('name.ilike.%$query%,email.ilike.%$query%,city.ilike.%$query%')
          .eq('is_active', true)
          .order('endorsement_count', ascending: false)
          .limit(20);

      return response.map<SupabaseUser>((json) => SupabaseUser.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  // Get user donations count
  static Future<int> getUserDonationsCount(String userId) async {
    try {
      final response = await _supabase
          .from('donations')
          .select('id')
          .eq('donor_id', userId);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // Get user needs count
  static Future<int> getUserNeedsCount(String userId) async {
    try {
      final response = await _supabase
          .from('needs')
          .select('id')
          .eq('recipient_id', userId);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // Update verification status (for profile picture upload)
  static Future<void> updateVerificationStatus(String userId, bool isVerified) async {
    try {
      await _supabase
          .from('users')
          .update({'is_verified': isVerified})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Error updating verification status: $e');
    }
  }
}
