class SupabaseConfig {
  // Supabase Configuration - Replace with your actual values
  // Get these from your Supabase dashboard: https://app.supabase.com
  
  static const String url = 'YOUR_SUPABASE_PROJECT_URL_HERE';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
  
  // Instructions to set up Supabase:
  // 1. Go to https://supabase.com and create an account
  // 2. Create a new project
  // 3. Go to Settings > API in your project dashboard
  // 4. Copy the Project URL and anon public key
  // 5. Replace the placeholder values above with your actual credentials
  // 6. Run the SQL schema from supabase_schema.sql file in your Supabase SQL editor
  
  // Check if Supabase is configured
  static bool get isConfigured => 
      url.isNotEmpty && 
      url != 'YOUR_SUPABASE_PROJECT_URL_HERE' &&
      anonKey.isNotEmpty &&
      anonKey != 'YOUR_SUPABASE_ANON_KEY_HERE';
}
