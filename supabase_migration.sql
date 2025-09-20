-- AIDA Database Migration Script
-- Run this in your Supabase SQL editor to fix existing schema issues

-- Step 1: Drop existing policies that might be causing issues
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Service role can insert users" ON public.users;
DROP POLICY IF EXISTS "Enable insert for authenticated users during signup" ON public.users;

-- Step 2: Update user_type constraint to include 'ngo' and 'individual'
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_user_type_check;
ALTER TABLE public.users ADD CONSTRAINT users_user_type_check 
    CHECK (user_type IN ('donor', 'ngo', 'individual'));

-- Step 3: Create new RLS policy for user insertion
CREATE POLICY "Enable insert for authenticated users during signup" ON public.users
    FOR INSERT WITH CHECK (
        auth.uid() = id OR 
        auth.jwt() ->> 'role' = 'service_role' OR
        auth.role() = 'authenticated'
    );

-- Step 4: Ensure all users can read their own data
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
CREATE POLICY "Users can view their own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

-- Step 5: Ensure users can update their own data  
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
CREATE POLICY "Users can update their own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Step 6: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated;

-- Step 7: Refresh the schema cache
NOTIFY pgrst, 'reload schema';
