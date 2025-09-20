#!/bin/bash

# AIDA Configuration Setup Script
echo "🚀 AIDA Configuration Setup"
echo "=========================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

echo "✅ Flutter found"

# Create .env.example if it doesn't exist
if [ ! -f ".env.example" ]; then
    echo "📝 Creating .env.example..."
    cat > .env.example << EOL
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# Gemini AI Configuration
GEMINI_API_KEY=your_gemini_api_key_here

# Firebase Configuration (optional)
FIREBASE_API_KEY=your_firebase_api_key_here
FIREBASE_PROJECT_ID=your_firebase_project_id_here
EOL
fi

# Prompt for configuration
echo ""
echo "🔧 Configuration Options:"
echo "1. Set up environment variables (.env file)"
echo "2. Configure directly in Dart files"
echo "3. Skip configuration (app will run in demo mode)"
echo ""

read -p "Choose an option (1-3): " choice

case $choice in
    1)
        echo ""
        echo "📁 Creating .env file..."
        
        read -p "Enter your Supabase URL: " supabase_url
        read -p "Enter your Supabase Anon Key: " supabase_key
        read -p "Enter your Gemini API Key: " gemini_key
        
        cat > .env << EOL
SUPABASE_URL=$supabase_url
SUPABASE_ANON_KEY=$supabase_key
GEMINI_API_KEY=$gemini_key
EOL
        
        echo "✅ .env file created successfully!"
        echo "⚠️  Remember to add flutter_dotenv to your pubspec.yaml"
        ;;
    2)
        echo ""
        echo "📝 Please manually edit the following files:"
        echo "   - lib/config/supabase_config.dart"
        echo "   - lib/config/api_config.dart"
        echo ""
        echo "Replace the placeholder values with your actual credentials."
        ;;
    3)
        echo ""
        echo "✅ Skipping configuration. App will run in demo mode."
        ;;
    *)
        echo "❌ Invalid option. Exiting."
        exit 1
        ;;
esac

echo ""
echo "📦 Installing Flutter dependencies..."
flutter pub get

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📖 Next steps:"
echo "   1. Run: flutter run"
echo "   2. Check the README.md for detailed setup instructions"
echo "   3. Run database migrations if using Supabase"
echo ""
