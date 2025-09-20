-- Execute this SQL in your Supabase dashboard SQL editor
-- Go to: https://supabase.com/dashboard/project/YOUR_SUPABASE_PROJECT_ID/sql/new

-- Fix: Update user_type constraint to include 'admin'
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_user_type_check;
ALTER TABLE public.users ADD CONSTRAINT users_user_type_check 
    CHECK (user_type IN ('donor', 'ngo', 'individual', 'admin'));

-- Verify the fix
SELECT 'SUCCESS: User type constraint updated to include admin!' as result;
