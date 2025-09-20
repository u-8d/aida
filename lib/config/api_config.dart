class ApiConfig {
  // Gemini API Configuration
  // To get your API key:
  // 1. Go to https://makersuite.google.com/app/apikey
  // 2. Create a new API key
  // 3. Replace the placeholder below with your actual key
  
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
  
  // Check if API key is configured
  static bool get isGeminiConfigured => 
      geminiApiKey.isNotEmpty && 
      geminiApiKey != 'YOUR_GEMINI_API_KEY_HERE';
  
  // Base URLs
  static const String geminiBaseUrl = 
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';
}
