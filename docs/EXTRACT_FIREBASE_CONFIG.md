# How to Extract Firebase Configuration Values

## From google-services.json

Once you download `google-services.json`, it will look like this:

```json
{
  "project_info": {
    "project_number": "123456789012",
    "project_id": "aida-donation-app",
    "storage_bucket": "aida-donation-app.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789012:android:abcdef1234567890",
        "android_client_info": {
          "package_name": "com.example.aida2"
        }
      },
      "oauth_client": [
        {
          "client_id": "123456789012-abcdefghijklmnop.apps.googleusercontent.com",
          "client_type": 3
        }
      ],
      "api_key": [
        {
          "current_key": "AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz1234567"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

## Mapping to Firebase Configuration

Extract these values from `google-services.json`:

| Firebase Config Field | JSON Path | Example Value |
|----------------------|-----------|---------------|
| `apiKey` | `client[0].api_key[0].current_key` | `AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz1234567` |
| `appId` | `client[0].client_info.mobilesdk_app_id` | `1:123456789012:android:abcdef1234567890` |
| `messagingSenderId` | `project_info.project_number` | `123456789012` |
| `projectId` | `project_info.project_id` | `aida-donation-app` |
| `storageBucket` | `project_info.storage_bucket` | `aida-donation-app.appspot.com` |

## Database URL

The `databaseURL` is not in `google-services.json`. You get it when you create the Realtime Database:

1. Go to Firebase Console → Realtime Database
2. Click "Create database"
3. Choose location (e.g., `asia-southeast1` for India)
4. The URL will be: `https://PROJECT_ID-default-rtdb.REGION.firebasedatabase.app`

Example: `https://aida-donation-app-default-rtdb.asia-southeast1.firebasedatabase.app`

## Automatic Extraction Script

You can create a script to automatically extract values:

```bash
#!/bin/bash
# extract_firebase_config.sh

JSON_FILE="android/app/google-services.json"

if [ -f "$JSON_FILE" ]; then
    echo "Extracting Firebase configuration from $JSON_FILE"
    
    API_KEY=$(cat $JSON_FILE | jq -r '.client[0].api_key[0].current_key')
    APP_ID=$(cat $JSON_FILE | jq -r '.client[0].client_info.mobilesdk_app_id')
    SENDER_ID=$(cat $JSON_FILE | jq -r '.project_info.project_number')
    PROJECT_ID=$(cat $JSON_FILE | jq -r '.project_info.project_id')
    STORAGE_BUCKET=$(cat $JSON_FILE | jq -r '.project_info.storage_bucket')
    
    echo "API Key: $API_KEY"
    echo "App ID: $APP_ID"
    echo "Sender ID: $SENDER_ID"
    echo "Project ID: $PROJECT_ID"
    echo "Storage Bucket: $STORAGE_BUCKET"
    echo "Database URL: https://$PROJECT_ID-default-rtdb.asia-southeast1.firebasedatabase.app"
else
    echo "google-services.json not found. Please download it from Firebase Console."
fi
```

Run with: `chmod +x extract_firebase_config.sh && ./extract_firebase_config.sh`
