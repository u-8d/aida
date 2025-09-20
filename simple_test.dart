import 'dart:convert';
import 'dart:io';

void main() async {
  const url = 'YOUR_SUPABASE_PROJECT_URL_HERE';
  const anonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
  
  final testEmail = 'test${DateTime.now().millisecondsSinceEpoch}@gmail.com';
  
  try {
    print('Testing Supabase registration with email: $testEmail');
    
    // Test 1: Sign up user
    final signUpResponse = await HttpClient().postUrl(
      Uri.parse('$url/auth/v1/signup'),
    ).then((request) {
      request.headers.set('apikey', anonKey);
      request.headers.set('Authorization', 'Bearer $anonKey');
      request.headers.set('Content-Type', 'application/json');
      
      final body = jsonEncode({
        'email': testEmail,
        'password': 'testpassword123',
      });
      
      request.write(body);
      return request.close();
    });
    
    final signUpData = await signUpResponse.transform(utf8.decoder).join();
    final signUpJson = jsonDecode(signUpData);
    print('Sign up status: ${signUpResponse.statusCode}');
    
    if (signUpResponse.statusCode == 200) {
      final userId = signUpJson['id'];
      print('User created with ID: $userId');
      
      if (userId != null) {
        
        // Test 2: Call create_user_profile function
        final profileResponse = await HttpClient().postUrl(
          Uri.parse('$url/rest/v1/rpc/create_user_profile'),
        ).then((request) {
          request.headers.set('apikey', anonKey);
          request.headers.set('Authorization', 'Bearer $anonKey');
          request.headers.set('Content-Type', 'application/json');
          
          final body = jsonEncode({
            'p_user_id': userId,
            'p_user_type': 'individual',
            'p_first_name': 'Test',
            'p_last_name': 'User',
            'p_email': testEmail,
            'p_phone': '+1234567890',
          });
          
          request.write(body);
          return request.close();
        });
        
        final profileData = await profileResponse.transform(utf8.decoder).join();
        print('Profile response: $profileData');
        print('Profile status: ${profileResponse.statusCode}');
        
        // Test 3: Check user_profiles table
        final queryResponse = await HttpClient().getUrl(
          Uri.parse('$url/rest/v1/user_profiles?id=eq.$userId'),
        ).then((request) {
          request.headers.set('apikey', anonKey);
          request.headers.set('Authorization', 'Bearer $anonKey');
          return request.close();
        });
        
        final queryData = await queryResponse.transform(utf8.decoder).join();
        print('Query response: $queryData');
        print('Query status: ${queryResponse.statusCode}');
      }
    }
    
  } catch (e) {
    print('Error: $e');
  }
  
  exit(0);
}
