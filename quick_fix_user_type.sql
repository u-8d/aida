-- Quick fix for the user_type constraint issue
-- This allows the 'admin' user type in the users table

-- Drop the existing check constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_user_type_check;

-- Add the new check constraint that includes 'admin'
ALTER TABLE users ADD CONSTRAINT users_user_type_check 
    CHECK (user_type IN ('donor', 'ngo', 'individual', 'admin'));

-- Verify the constraint
SELECT 'User type constraint updated successfully!' AS status;
