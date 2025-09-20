import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/supabase_user.dart';

class SupabaseAuthService {
  static final _supabase = Supabase.instance.client;

  // Sign up user
  static Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String userType,
    String? city,
    String? phone,
  }) async {
    try {
      if (kDebugMode) {
        print('Attempting to sign up user: $email');
        print('Network connection check...');
      }

      // Basic connectivity check
      try {
        await _supabase.from('users').select('count').limit(1);
        if (kDebugMode) {
          print('Network connectivity: OK');
        }
      } catch (connectivityError) {
        if (kDebugMode) {
          print('Network connectivity issue: $connectivityError');
        }
        return 'Network connection error. Please check your internet connection and try again.';
      }

      // Create auth user with proper email confirmation
      // For development, we'll disable email confirmation to make testing easier
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        // Don't require email confirmation in development
        emailRedirectTo: kDebugMode ? null : 'https://YOUR_SUPABASE_PROJECT_URL_HERE/auth/v1/callback',
      );

      if (authResponse.user == null) {
        return 'Failed to create account';
      }

      if (kDebugMode) {
        print('Auth user created: ${authResponse.user!.id}');
        if (authResponse.session?.accessToken != null) {
          print('Auth session: ${authResponse.session!.accessToken.substring(0, 20)}...');
        }
      }

      // Wait a moment for the auth session to be fully established
      await Future.delayed(const Duration(milliseconds: 1000));

      if (kDebugMode) {
        print('Creating user profile for: ${authResponse.user!.id}');
        print('Current user ID: ${_supabase.auth.currentUser?.id}');
      }

      // Try multiple approaches to create user profile
      try {
        // Wait for auth session to be fully established
        await Future.delayed(const Duration(milliseconds: 500));

        // Approach 1: Direct insert (simpler and more reliable)
        final userProfile = {
          'id': authResponse.user!.id,
          'email': email,
          'name': name,
          'user_type': userType,
          'city': city,
          'phone': phone,
        };

        final profileResponse = await _supabase
            .from('users')
            .insert(userProfile)
            .select()
            .single();

        if (kDebugMode) {
          print('User profile created successfully: $profileResponse');
        }
      } catch (directError) {
        if (kDebugMode) {
          print('Direct insert failed: $directError');
          print('Trying function approach...');
        }

        // Approach 2: Try using the custom function as fallback
        try {
          final functionResult = await _supabase.rpc('create_user_profile', params: {
            'user_id': authResponse.user!.id,
            'user_email': email,
            'user_name': name,
            'user_type': userType,
            'user_city': city,
            'user_phone': phone,
          });

          if (kDebugMode) {
            print('Function result: $functionResult');
          }

          // Check if function returned an error
          if (functionResult != null && functionResult['error'] != null) {
            throw Exception('Function error: ${functionResult['error']}');
          }

          if (kDebugMode) {
            print('User profile created successfully via function');
          }
        } catch (functionError) {
          if (kDebugMode) {
            print('Both approaches failed: $functionError');
          }
          // If profile creation fails, sign out the auth user to maintain consistency
          await _supabase.auth.signOut();
          return 'Failed to create user profile. Please try again or contact support.';
        }
      }

      return null; // Success
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('Auth error during sign up: ${e.message}');
      }
      return e.message;
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during sign up: $e');
        print('Error type: ${e.runtimeType}');
      }
      
      // Handle specific network-related errors
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection failed') ||
          e.toString().contains('Network is unreachable')) {
        return 'Network connection error. Please check your internet connection and try again.';
      }
      
      return 'An unexpected error occurred: $e';
    }
  }

  // Sign in user
  static Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('Attempting to sign in user: $email');
        print('Network connection check...');
      }

      // Basic connectivity check
      try {
        await _supabase.from('users').select('count').limit(1);
        if (kDebugMode) {
          print('Network connectivity: OK');
        }
      } catch (connectivityError) {
        if (kDebugMode) {
          print('Network connectivity issue: $connectivityError');
        }
        return 'Network connection error. Please check your internet connection and try again.';
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Check if email is confirmed or if we're in debug mode (skip confirmation)
      if (response.user != null && (response.user!.emailConfirmedAt != null || kDebugMode)) {
        if (kDebugMode) {
          print('Sign in successful (confirmed: ${response.user!.emailConfirmedAt != null})');
        }
        return null; // Success
      } else if (response.user != null && response.user!.emailConfirmedAt == null && !kDebugMode) {
        if (kDebugMode) {
          print('Email not confirmed in production mode');
        }
        return 'Please check your email and click the confirmation link before signing in.';
      }

      return 'Sign in failed';
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('Auth error during sign in: ${e.message}');
      }
      
      // Handle specific email confirmation error
      if (e.message.contains('Email not confirmed') || 
          e.message.contains('email_not_confirmed')) {
        return 'Please check your email and click the confirmation link before signing in.';
      }
      
      return e.message;
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during sign in: $e');
        print('Error type: ${e.runtimeType}');
      }
      
      // Handle specific network-related errors
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection failed') ||
          e.toString().contains('Network is unreachable')) {
        return 'Network connection error. Please check your internet connection and try again.';
      }
      
      return 'An unexpected error occurred: $e';
    }
  }

  // Sign out user
  static Future<void> signOut() async {
    try {
      // Sign out from Supabase
      await _supabase.auth.signOut();
      
      if (kDebugMode) {
        print('User signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
    }
  }

  // Resend email confirmation
  static Future<String?> resendEmailConfirmation(String email) async {
    try {
      if (kDebugMode) {
        print('Resending email confirmation to: $email');
      }

      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );

      if (kDebugMode) {
        print('Email confirmation resent successfully');
      }

      return null; // Success
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('Error resending email confirmation: ${e.message}');
      }
      return e.message;
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error resending email confirmation: $e');
      }
      return 'An unexpected error occurred: $e';
    }
  }

  // Get current user
  static User? get currentUser => _supabase.auth.currentUser;

  // Get user profile
  static Future<SupabaseUser?> getUserProfile(String userId) async {
    try {
      if (kDebugMode) {
        print('Fetching user profile for: $userId');
      }

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      if (kDebugMode) {
        print('User profile fetched successfully');
      }

      return SupabaseUser.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }
      return null;
    }
  }

  // Auth state stream
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;
}
