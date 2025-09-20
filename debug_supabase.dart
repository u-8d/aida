import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const url = 'YOUR_SUPABASE_PROJECT_URL_HERE';
  const anonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
  
  print('=== Supabase Debug Test ===');
  
  // Test 1: Check if we can connect to Supabase
  print('\n1. Testing connection to Supabase...');
  try {
    final response = await http.get(
      Uri.parse('$url/rest/v1/'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      },
    );
    print('   Connection status: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('   Error: ${response.body}');
    }
  } catch (e) {
    print('   Connection failed: $e');
  }
  
  // Test 2: Check if users table exists
  print('\n2. Testing users table access...');
  try {
    final response = await http.get(
      Uri.parse('$url/rest/v1/users?select=id&limit=1'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      },
    );
    print('   Users table status: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('   Error: ${response.body}');
    } else {
      print('   Users table accessible');
    }
  } catch (e) {
    print('   Users table test failed: $e');
  }
  
  // Test 3: Check if create_user_profile function exists
  print('\n3. Testing create_user_profile function...');
  try {
    final response = await http.post(
      Uri.parse('$url/rest/v1/rpc/create_user_profile'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': '00000000-0000-0000-0000-000000000000',
        'user_email': 'test@example.com',
        'user_name': 'Test User',
        'user_type': 'individual',
      }),
    );
    print('   Function status: ${response.statusCode}');
    print('   Function response: ${response.body}');
  } catch (e) {
    print('   Function test failed: $e');
  }
  
  // Test 4: Test user signup via auth
  print('\n4. Testing auth signup...');
  final testEmail = 'debug_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
  try {
    final response = await http.post(
      Uri.parse('$url/auth/v1/signup'),
      headers: {
        'apikey': anonKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': testEmail,
        'password': 'testpassword123',
      }),
    );
    print('   Auth signup status: ${response.statusCode}');
    final responseData = jsonDecode(response.body);
    print('   Auth response: $responseData');
    
    if (responseData['user'] != null) {
      print('   User ID: ${responseData['user']['id']}');
      print('   User email confirmed: ${responseData['user']['email_confirmed_at']}');
    }
  } catch (e) {
    print('   Auth signup failed: $e');
  }
  
  print('\n=== Debug Test Complete ===');
}
