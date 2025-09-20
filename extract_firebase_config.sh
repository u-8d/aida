#!/bin/bash

# Firebase Configuration Extractor
# This script extracts Firebase configuration values from google-services.json

JSON_FILE="android/app/google-services.json"
CONFIG_FILE="lib/config/firebase_config.dart"

echo "🔥 Firebase Configuration Extractor"
echo "=================================="

# Check if google-services.json exists
if [ ! -f "$JSON_FILE" ]; then
    echo "❌ Error: $JSON_FILE not found!"
    echo ""
    echo "📋 To get this file:"
    echo "1. Go to Firebase Console: https://console.firebase.google.com/"
    echo "2. Select your project (or create new project: 'aida-donation-app')"
    echo "3. Click gear icon → Project settings"
    echo "4. Scroll to 'Your apps' section"
    echo "5. Click 'Add app' → Android"
    echo "6. Enter package name: com.example.aida2"
    echo "7. Download google-services.json"
    echo "8. Place it in android/app/ directory"
    echo ""
    exit 1
fi

# Check if jq is installed (JSON parser)
if ! command -v jq &> /dev/null; then
    echo "⚠️  Installing jq (JSON parser)..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y jq
    elif command -v yum &> /dev/null; then
        sudo yum install -y jq
    elif command -v pacman &> /dev/null; then
        sudo pacman -S jq
    else
        echo "❌ Please install jq manually: https://stedolan.github.io/jq/download/"
        exit 1
    fi
fi

echo "✅ Found $JSON_FILE"
echo ""

# Extract values from google-services.json
API_KEY=$(cat $JSON_FILE | jq -r '.client[0].api_key[0].current_key')
APP_ID=$(cat $JSON_FILE | jq -r '.client[0].client_info.mobilesdk_app_id')
SENDER_ID=$(cat $JSON_FILE | jq -r '.project_info.project_number')
PROJECT_ID=$(cat $JSON_FILE | jq -r '.project_info.project_id')
STORAGE_BUCKET=$(cat $JSON_FILE | jq -r '.project_info.storage_bucket')

echo "📊 Extracted Configuration:"
echo "-------------------------"
echo "API Key: $API_KEY"
echo "App ID: $APP_ID"
echo "Sender ID: $SENDER_ID"
echo "Project ID: $PROJECT_ID"
echo "Storage Bucket: $STORAGE_BUCKET"
echo ""

# Ask for database region
echo "🌍 Database Region Setup:"
echo "Choose your Realtime Database region:"
echo "1. us-central1 (Iowa, USA) - Default"
echo "2. europe-west1 (Belgium, Europe)"
echo "3. asia-southeast1 (Singapore, Asia) - Recommended for India"
echo ""
read -p "Enter choice (1-3) [3]: " region_choice

case $region_choice in
    1) REGION="us-central1" ;;
    2) REGION="europe-west1" ;;
    3|"") REGION="asia-southeast1" ;;
    *) REGION="asia-southeast1" ;;
esac

DATABASE_URL="https://$PROJECT_ID-default-rtdb.$REGION.firebasedatabase.app"

echo ""
echo "📍 Selected region: $REGION"
echo "🔗 Database URL: $DATABASE_URL"
echo ""

# Generate the configuration
CONFIG_CONTENT="import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// \`\`\`dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// \`\`\`
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '$API_KEY',
    appId: '1:$SENDER_ID:web:REPLACE_WITH_WEB_APP_ID',
    messagingSenderId: '$SENDER_ID',
    projectId: '$PROJECT_ID',
    authDomain: '$PROJECT_ID.firebaseapp.com',
    databaseURL: '$DATABASE_URL',
    storageBucket: '$STORAGE_BUCKET',
    measurementId: 'G-XXXXXXXXXX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '$API_KEY',
    appId: '$APP_ID',
    messagingSenderId: '$SENDER_ID',
    projectId: '$PROJECT_ID',
    databaseURL: '$DATABASE_URL',
    storageBucket: '$STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: '1:$SENDER_ID:ios:REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '$SENDER_ID',
    projectId: '$PROJECT_ID',
    databaseURL: '$DATABASE_URL',
    storageBucket: '$STORAGE_BUCKET',
    iosBundleId: 'com.example.aida2',
  );
}"

# Write to config file
echo "$CONFIG_CONTENT" > "$CONFIG_FILE"

echo "🎉 Success! Firebase configuration updated!"
echo ""
echo "📁 Updated file: $CONFIG_FILE"
echo ""
echo "📋 Next Steps:"
echo "1. ✅ Android configuration is complete"
echo "2. 🌐 For Web: Add web app in Firebase Console and update web app ID"
echo "3. 🍎 For iOS: Add iOS app in Firebase Console and update iOS values"
echo "4. 🔥 Create Realtime Database in Firebase Console with region: $REGION"
echo "5. 🏃 Run: flutter pub get"
echo "6. 🚀 Test: flutter run"
echo ""
echo "🔗 Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID"
