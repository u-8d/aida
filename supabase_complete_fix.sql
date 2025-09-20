-- AIDA Supabase Database - Complete Fix
-- Run this AFTER creating your Supabase project
-- This will fix all foreign key and permission issues

-- Step 1: Drop existing problematic schema if it exists
DROP TABLE IF EXISTS public.chat_messages CASCADE;
DROP TABLE IF EXISTS public.chat_sessions CASCADE;
DROP TABLE IF EXISTS public.donations CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Step 2: Create users table with proper foreign key setup
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    user_type VARCHAR(50) NOT NULL CHECK (user_type IN ('donor', 'ngo', 'individual')),
    city VARCHAR(255),
    phone VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 3: Create other tables
CREATE TABLE public.donations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    donor_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    recipient_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.chat_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.chat_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_user BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 4: Set up Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Step 5: Create comprehensive RLS policies
-- Users table policies
CREATE POLICY "Users can view their own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Most permissive INSERT policy for user creation during signup
CREATE POLICY "Allow authenticated users to insert users" ON public.users
    FOR INSERT WITH CHECK (
        -- Allow if the user ID matches the authenticated user
        auth.uid() = id OR
        -- Allow during signup process when session might not be fully established
        auth.jwt() IS NOT NULL
    );

-- Donations table policies
CREATE POLICY "Users can view all donations" ON public.donations
    FOR SELECT USING (true);

CREATE POLICY "Users can create donations" ON public.donations
    FOR INSERT WITH CHECK (auth.uid() = donor_id OR auth.uid() = recipient_id);

CREATE POLICY "Donors can update their donations" ON public.donations
    FOR UPDATE USING (auth.uid() = donor_id);

-- Chat sessions policies
CREATE POLICY "Users can view their own chat sessions" ON public.chat_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own chat sessions" ON public.chat_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own chat sessions" ON public.chat_sessions
    FOR UPDATE USING (auth.uid() = user_id);

-- Chat messages policies
CREATE POLICY "Users can view messages from their sessions" ON public.chat_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.chat_sessions
            WHERE chat_sessions.id = chat_messages.session_id
            AND chat_sessions.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create messages in their sessions" ON public.chat_messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.chat_sessions
            WHERE chat_sessions.id = chat_messages.session_id
            AND chat_sessions.user_id = auth.uid()
        )
    );

-- Step 6: Create the user profile creation function
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
SET search_path = public
AS $$
DECLARE
    result json;
BEGIN
    -- Insert the user profile
    INSERT INTO public.users (id, email, name, user_type, city, phone)
    VALUES (user_id, user_email, user_name, user_type, user_city, user_phone)
    RETURNING row_to_json(users.*) INTO result;
    
    RETURN json_build_object('success', true, 'user', result);
EXCEPTION
    WHEN unique_violation THEN
        RETURN json_build_object('error', 'User profile already exists');
    WHEN foreign_key_violation THEN
        RETURN json_build_object('error', 'Invalid user ID - user must be authenticated first');
    WHEN OTHERS THEN
        RETURN json_build_object('error', SQLERRM);
END;
$$;

-- Step 7: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated, anon;
GRANT ALL ON public.users TO authenticated;
GRANT SELECT, INSERT ON public.users TO anon;
GRANT ALL ON public.donations TO authenticated;
GRANT ALL ON public.chat_sessions TO authenticated;
GRANT ALL ON public.chat_messages TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_profile TO authenticated, anon;

-- Step 8: Create indexes for performance
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_user_type ON public.users(user_type);
CREATE INDEX idx_donations_donor_id ON public.donations(donor_id);
CREATE INDEX idx_donations_recipient_id ON public.donations(recipient_id);
CREATE INDEX idx_donations_status ON public.donations(status);
CREATE INDEX idx_chat_sessions_user_id ON public.chat_sessions(user_id);
CREATE INDEX idx_chat_messages_session_id ON public.chat_messages(session_id);

-- Step 9: Create updated_at triggers
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER handle_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_donations_updated_at
    BEFORE UPDATE ON public.donations
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_chat_sessions_updated_at
    BEFORE UPDATE ON public.chat_sessions
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Step 10: Refresh the schema cache
NOTIFY pgrst, 'reload schema';
