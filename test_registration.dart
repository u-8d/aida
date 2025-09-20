import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_PROJECT_URL_HERE',
    anonKey: 'YOUR_SUPABASE_ANON_KEY_HERE',
  );

  final supabase = Supabase.instance.client;

  try {
    print('Testing user registration...');
    
    // Test 1: Try to sign up a user
    final authResponse = await supabase.auth.signUp(
      email: 'test@example.com',
      password: 'testpassword123',
    );
    
    print('Auth response: ${authResponse.user?.id}');
    print('Auth session: ${authResponse.session?.accessToken != null}');
    
    if (authResponse.user != null) {
      print('User created with ID: ${authResponse.user!.id}');
      
      // Test 2: Try to create user profile
      try {
        final profileResponse = await supabase.rpc('create_user_profile', params: {
          'p_user_id': authResponse.user!.id,
          'p_user_type': 'individual',
          'p_first_name': 'Test',
          'p_last_name': 'User',
          'p_email': 'test@example.com',
          'p_phone': '+1234567890',
        });
        
        print('Profile creation response: $profileResponse');
      } catch (e) {
        print('Profile creation error: $e');
      }
      
      // Test 3: Check if user exists in profiles table
      try {
        final existingProfile = await supabase
            .from('user_profiles')
            .select()
            .eq('id', authResponse.user!.id)
            .maybeSingle();
        
        print('Existing profile: $existingProfile');
      } catch (e) {
        print('Profile query error: $e');
      }
    }
    
  } catch (e) {
    print('Registration error: $e');
  }
}
