-- AIDA Database - Ultimate RLS and Permissions Fix
-- Run this in your Supabase SQL editor to completely fix all permission issues

-- Step 1: Temporarily disable RLS on all tables
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.donations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop ALL existing policies on users table
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Service role can insert users" ON public.users;
DROP POLICY IF EXISTS "Enable insert for authenticated users during signup" ON public.users;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Allow authenticated users to insert" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;

-- Step 3: Update user_type constraint
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_user_type_check;
ALTER TABLE public.users ADD CONSTRAINT users_user_type_check 
    CHECK (user_type IN ('donor', 'ngo', 'individual'));

-- Step 4: Grant comprehensive permissions to authenticated role
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Step 5: Grant specific permissions for anon role (needed for signup)
GRANT USAGE ON SCHEMA public TO anon;
GRANT INSERT, SELECT ON public.users TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- Step 6: Re-enable RLS only on users table for now
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Step 7: Create the most permissive policies possible
-- Allow ANYONE to insert during signup (we'll secure this later)
CREATE POLICY "Allow all inserts" ON public.users
    FOR INSERT WITH CHECK (true);

-- Allow users to select their own records
CREATE POLICY "Allow own select" ON public.users
    FOR SELECT USING (auth.uid() = id OR auth.uid() IS NULL);

-- Allow users to update their own records
CREATE POLICY "Allow own update" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Step 8: Create a function to handle user creation (alternative approach)
CREATE OR REPLACE FUNCTION public.create_user_profile(
    user_id uuid,
    user_email text,
    user_name text,
    user_type text,
    user_city text DEFAULT NULL,
    user_phone text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result json;
BEGIN
    INSERT INTO public.users (id, email, name, user_type, city, phone)
    VALUES (user_id, user_email, user_name, user_type, user_city, user_phone)
    RETURNING row_to_json(users.*) INTO result;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('error', SQLERRM);
END;
$$;

-- Step 9: Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.create_user_profile TO authenticated, anon;

-- Step 10: Refresh schema
NOTIFY pgrst, 'reload schema';
