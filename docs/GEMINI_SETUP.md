# Gemini AI Setup Guide

This app uses Google's Gemini AI for intelligent image analysis of donation items. Follow these steps to enable AI functionality:

## 1. Get Your Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated API key

## 2. Configure the API Key

1. Open `lib/config/api_config.dart`
2. Replace `YOUR_GEMINI_API_KEY_HERE` with your actual API key:

```dart
static const String geminiApiKey = 'your_actual_api_key_here';
```

## 3. Test the Setup

1. Run the app: `flutter run`
2. Go to donation upload screen
3. Take a photo or select an image
4. Tap "Analyze with AI"
5. You should see accurate analysis results

## Features Enabled with AI

- **Automatic Item Recognition**: AI identifies what you're donating
- **Smart Tagging**: Generates relevant tags for better matching
- **Category Classification**: Automatically categorizes items
- **Condition Assessment**: Evaluates item condition from photos
- **Target Audience Detection**: Suggests who would benefit most

## Troubleshooting

### "API key not configured" error
- Make sure you've replaced the placeholder in `api_config.dart`
- Check that there are no extra spaces or quotes

### "quota exceeded" error
- You've reached the free tier limit
- Wait 24 hours or upgrade to a paid plan

### "invalid request" error
- Check your internet connection
- Verify the API key is correct and active

### AI returns "winter coat" for everything
- This was the old mock data behavior
- With proper API key setup, you'll get accurate analysis

## API Usage Notes

- The free tier includes generous limits for testing
- Each image analysis counts as one API call
- Larger images may take longer to process
- The app works offline but without AI analysis

## Without API Key

If you don't configure an API key:
- The app will still work normally
- AI analysis will be disabled
- Users can manually enter item details
- All other features remain functional
