# 🔧 Complete Supabase Setup Instructions for AIDA2

## ⚠️ Current Issue
Your Supabase database has schema/foreign key constraint issues that are preventing user registration from working properly. Follow these steps to fix it completely.

## 🛠️ Step-by-Step Fix

### **Step 1: Access Your Supabase Dashboard**
1. Go to [https://supabase.com](https://supabase.com)
2. Sign in to your account
3. Open your project: **YOUR_SUPABASE_PROJECT_ID**
4. You should see your project dashboard

### **Step 2: Apply the Database Fix**
1. **In the Supabase dashboard**, click **"SQL Editor"** in the left sidebar
2. Click **"New query"**
3. **Copy the ENTIRE contents** of the file `supabase_complete_fix.sql`
4. **Paste it** into the SQL editor
5. Click **"Run"** (the play button)
6. **Wait for it to complete** - you should see "Success" messages

**What this does:**
- Drops any existing problematic tables
- Creates properly structured tables with correct foreign keys
- Sets up Row Level Security (RLS) policies
- Creates the `create_user_profile` function
- Grants necessary permissions

### **Step 3: Verify the Fix Works**
Run this test to confirm everything is working:

```bash
cd /home/aditya/Projects/aida2
dart debug_supabase.dart
```

**Expected Output:**
```
=== Supabase Debug Test ===

1. Testing connection to Supabase...
   Connection status: 200

2. Testing users table access...
   Users table status: 200
   Users table accessible

3. Testing create_user_profile function...
   Function status: 200
   Function response: {"success": true, "user": {...}}

4. Testing auth signup...
   Auth signup status: 200
   User ID: [some-uuid-here]
```

### **Step 4: Test Your App**
1. **Run your Flutter app:**
   ```bash
   flutter run
   ```

2. **Test Registration:**
   - Try creating a new account
   - Email/password authentication should work
   - Check that users appear in your Supabase dashboard

3. **Verify in Dashboard:**
   - Go to **Table Editor** in Supabase
   - Click **"users"** table
   - You should see your test users

## 🎯 Additional Configuration (Optional)

### **Configure Email Confirmations (Recommended for Production)**
1. In Supabase Dashboard → **Authentication** → **Settings**
2. **Enable email confirmations**: Turn ON for production (leave OFF for testing)
3. **Site URL**: Add your app's URL for email redirects
4. **Email Templates**: Customize confirmation emails if needed

## ✅ Verification Checklist

After completing the setup, verify these work:

- [ ] **Database connection** - No more foreign key errors
- [ ] **User registration** - New accounts can be created
- [ ] **User login** - Existing users can sign in
- [ ] **Profile creation** - User profiles are saved to database
- [ ] **Google Sign-In** - Works if provider is configured

## 🐛 Troubleshooting

### **If you still get errors:**

1. **"foreign key constraint violation"**
   - The database fix wasn't applied properly
   - Re-run the `supabase_complete_fix.sql` script

2. **"function does not exist"**
   - The `create_user_profile` function wasn't created
   - Check the SQL execution logs for errors

3. **"permission denied"**
   - RLS policies aren't set up correctly
   - Verify the GRANT statements were executed

4. **"user not found"**
   - The auth user was created but profile creation failed
   - Check Supabase logs in Dashboard → **Logs**

### **Check Supabase Logs:**
1. Go to **Logs** in your Supabase dashboard
2. Look for recent error messages
3. Filter by **Database** or **Auth** to see specific issues

## 🔐 Security Notes

- **Your anon key is safe to use client-side** (it's designed for that)
- **RLS policies protect your data** even with public keys
- **Never expose your service_role key** (keep it server-side only)
- **Email confirmation is disabled** for testing (enable for production)

## 🚀 You're Ready!

Once the database fix is applied, your AIDA2 app should work perfectly with:
- ✅ **User Registration & Login**
- ✅ **Profile Management**
- ✅ **Secure Database Access**

The core functionality will be fully operational and ready for development!
