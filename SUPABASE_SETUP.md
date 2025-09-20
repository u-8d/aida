# Supabase Migration Setup Guide

## Step 1: Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Click "Start your project"
3. Sign up/Login with GitHub or email
4. Click "New project"
5. Choose your organization
6. Fill in project details:
   - **Name**: AIDA (or any name you prefer)
   - **Database Password**: Choose a strong password (save this!)
   - **Region**: Choose closest to your location
7. Click "Create new project"
8. Wait for project creation (2-3 minutes)

## Step 2: Get Project Credentials

1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy the following values:
   - **Project URL** (e.g., `https://your-project-id.supabase.co`)
   - **anon public key** (the `anon` key, not the `service_role` key)

## Step 3: Update Configuration

Replace the placeholder values in `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String url = 'https://your-actual-project-id.supabase.co';
  static const String anonKey = 'your-actual-anon-key-here';
}
```

## Step 4: Set Up Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Click "New query"
3. Copy the entire content from `supabase_schema.sql` file
4. Paste it into the SQL editor
5. Click "Run" to execute the schema

This will create:
- `users` table with proper authentication integration
- `donations` table for future donation management
- `chat_sessions` and `chat_messages` tables for AI chat feature
- Row Level Security (RLS) policies for data protection
- Proper indexes for performance

## Step 5: Test the Application

1. Update your Supabase credentials in the config file
2. Run the app: `flutter run`
3. Try creating a new account
4. Try logging in with the created account
5. Verify that authentication works properly

## Step 6: Migration Complete!

Your app is now using Supabase instead of Firebase. The key changes made:

### Backend Changes:
- ✅ Replaced Firebase Auth with Supabase Auth
- ✅ Replaced Firebase Firestore with Supabase Database
- ✅ Created proper database schema with RLS
- ✅ Maintained existing user data structure

### Frontend Changes:
- ✅ Updated `main.dart` to initialize Supabase
- ✅ Created `SupabaseAppState` to replace `FirebaseAppState`
- ✅ Updated auth screens to use new state management
- ✅ Preserved all existing UI components and design

### What's Preserved:
- ✅ All existing screens and UI design
- ✅ User registration and login flows
- ✅ Provider state management pattern
- ✅ App navigation structure

## Troubleshooting

### Common Issues:

1. **"Invalid API key"**: Make sure you copied the `anon` key, not `service_role`
2. **"Project not found"**: Verify the project URL is correct
3. **Database errors**: Ensure the schema was executed successfully
4. **Auth not working**: Check if email confirmation is required in Supabase Auth settings

### Database Verification:

After running the schema, verify in Supabase dashboard:
1. Go to **Table Editor**
2. You should see: `users`, `donations`, `chat_sessions`, `chat_messages`
3. Click on `users` table to see the structure

### Authentication Settings:

In Supabase dashboard → **Authentication** → **Settings**:
- **Enable email confirmations**: Disable for testing (enable for production)
- **Site URL**: Add your app URL (for email confirmations)

## Next Steps (Optional)

1. **Email Templates**: Customize auth email templates in Supabase dashboard
2. **Storage**: Set up Supabase Storage if your app needs file uploads
3. **Real-time**: Enable real-time features for live chat/updates
4. **Database Functions**: Add custom database functions if needed

## Security Notes

- Never commit your Supabase keys to version control
- Consider using environment variables for production
- The anon key is safe for client-side use (it's public)
- RLS policies protect your data even with public keys
