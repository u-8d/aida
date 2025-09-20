# 🔧 Database Fix Required - Admin User Type Constraint

## Problem
The app is throwing this error when trying to register users:
```
PostgrestException: new row for relation "users" violates check constraint "users_user_type_check"
```

## Root Cause
The database constraint `users_user_type_check` only allows `('donor', 'ngo', 'individual')` but the app now supports `'admin'` user type after implementing the admin panel.

## Solution
You need to update the database constraint to include the new `'admin'` user type.

## Steps to Fix

### 1. Open Supabase Dashboard
1. Go to: https://supabase.com/dashboard
2. Select your project: `YOUR_SUPABASE_PROJECT_ID`
3. Navigate to **SQL Editor** in the left sidebar
4. Click **New Query**

### 2. Run the Fix
Copy and paste this SQL command:

```sql
-- Fix: Update user_type constraint to include 'admin'
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_user_type_check;
ALTER TABLE public.users ADD CONSTRAINT users_user_type_check 
    CHECK (user_type IN ('donor', 'ngo', 'individual', 'admin'));

-- Verify the fix
SELECT 'SUCCESS: User type constraint updated to include admin!' as result;
```

### 3. Execute the Query
1. Click **RUN** button
2. You should see: `SUCCESS: User type constraint updated to include admin!`

### 4. Test the App
1. Go back to your Flutter app
2. Try registering a new user
3. The registration should now work successfully!

## Alternative: Use the SQL File
You can also use the prepared SQL file:
1. Open `APPLY_DATABASE_FIX.sql` in this project
2. Copy the contents
3. Run it in Supabase SQL Editor

## Verification
After applying the fix, you can verify it worked by running:
```sql
SELECT pg_get_constraintdef(oid) as constraint_definition 
FROM pg_constraint 
WHERE conname = 'users_user_type_check';
```

This should show the constraint now includes `'admin'`.

---
**Note**: This is a one-time fix required after adding the admin user type to the application.
