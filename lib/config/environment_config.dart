// Environment Configuration Template
// This file shows how to set up environment-based configuration
// For production, consider using flutter_dotenv or similar packages

class EnvironmentConfig {
  // Environment type
  static const String environment = 'development'; // development, staging, production
  
  // Supabase Configuration
  // Get these from your Supabase project dashboard
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
  
  // Gemini API Configuration
  // Get your API key from Google AI Studio
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
  
  // Firebase Configuration (if needed)
  static const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY_HERE';
  static const String firebaseProjectId = 'YOUR_FIREBASE_PROJECT_ID_HERE';
  
  // Feature flags
  static const bool enableAIFeatures = true;
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = false;
  
  // Configuration validation
  static bool get isSupabaseConfigured => 
      supabaseUrl.isNotEmpty && 
      supabaseUrl != 'YOUR_SUPABASE_URL_HERE' &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY_HERE';
      
  static bool get isGeminiConfigured => 
      geminiApiKey.isNotEmpty && 
      geminiApiKey != 'YOUR_GEMINI_API_KEY_HERE';
      
  static bool get isFirebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseApiKey != 'YOUR_FIREBASE_API_KEY_HERE';
}

// Instructions for setup:
// 1. Copy this file to environment_config.dart
// 2. Replace all placeholder values with your actual configuration
// 3. Add environment_config.dart to .gitignore to keep credentials secure
// 4. For production, consider using flutter_dotenv or similar packages