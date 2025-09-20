-- Migration to add 'admin' user type to the existing check constraint
-- This fixes the PostgrestException: new row for relation "users" violates check constraint "users_user_type_check"

-- First, let's see the current constraint
-- SELECT conname, consrc FROM pg_constraint WHERE conname = 'users_user_type_check';

-- Drop the existing check constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_user_type_check;

-- Add the new check constraint that includes 'admin'
ALTER TABLE users ADD CONSTRAINT users_user_type_check 
    CHECK (user_type IN ('donor', 'ngo', 'individual', 'admin'));

-- Verify the constraint was added successfully
-- SELECT conname, pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'users_user_type_check';

-- Optional: Update any existing admin users if they exist with a different type
-- UPDATE users SET user_type = 'admin' WHERE email LIKE '%admin%' OR id IN (
--     SELECT user_id FROM admin_users
-- );

-- Create admin_users table if it doesn't exist (for the admin system)
CREATE TABLE IF NOT EXISTS admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('super-admin', 'disaster-coordinator', 'crisis-moderator', 'analytics-viewer', 'user-support')),
    permissions JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE
);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_admin_users_user_id ON admin_users(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_users_role ON admin_users(role);

-- Enable RLS (Row Level Security) for admin_users table
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Create policy for admin_users (only allow access to authenticated users)
DROP POLICY IF EXISTS "Admin users can view admin_users" ON admin_users;
CREATE POLICY "Admin users can view admin_users" ON admin_users
    FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admin users can insert admin_users" ON admin_users;
CREATE POLICY "Admin users can insert admin_users" ON admin_users
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admin users can update admin_users" ON admin_users;
CREATE POLICY "Admin users can update admin_users" ON admin_users
    FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Create disaster_campaigns table for disaster response management
CREATE TABLE IF NOT EXISTS disaster_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    disaster_type TEXT NOT NULL,
    affected_areas JSONB DEFAULT '[]',
    priority_level TEXT NOT NULL CHECK (priority_level IN ('low', 'medium', 'high', 'critical')),
    status TEXT NOT NULL CHECK (status IN ('planning', 'active', 'winding_down', 'completed', 'cancelled')),
    target_amount DECIMAL(12,2),
    raised_amount DECIMAL(12,2) DEFAULT 0,
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_crisis_mode BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_disaster_campaigns_status ON disaster_campaigns(status);
CREATE INDEX IF NOT EXISTS idx_disaster_campaigns_priority ON disaster_campaigns(priority_level);
CREATE INDEX IF NOT EXISTS idx_disaster_campaigns_disaster_type ON disaster_campaigns(disaster_type);
CREATE INDEX IF NOT EXISTS idx_disaster_campaigns_crisis_mode ON disaster_campaigns(is_crisis_mode);

-- Enable RLS for disaster_campaigns
ALTER TABLE disaster_campaigns ENABLE ROW LEVEL SECURITY;

-- Create policies for disaster_campaigns
DROP POLICY IF EXISTS "Public can view active disaster campaigns" ON disaster_campaigns;
CREATE POLICY "Public can view active disaster campaigns" ON disaster_campaigns
    FOR SELECT USING (status = 'active');

DROP POLICY IF EXISTS "Admin users can manage disaster campaigns" ON disaster_campaigns;
CREATE POLICY "Admin users can manage disaster campaigns" ON disaster_campaigns
    FOR ALL USING (auth.uid() IN (SELECT user_id FROM admin_users WHERE is_active = TRUE));

-- Create a function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_admin_users_updated_at ON admin_users;
CREATE TRIGGER update_admin_users_updated_at
    BEFORE UPDATE ON admin_users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_disaster_campaigns_updated_at ON disaster_campaigns;
CREATE TRIGGER update_disaster_campaigns_updated_at
    BEFORE UPDATE ON disaster_campaigns
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert a sample super admin user for testing (optional)
-- First create a regular user, then make them an admin
-- INSERT INTO users (id, name, email, phone, city, user_type, created_at, is_verified)
-- VALUES (
--     gen_random_uuid(),
--     'System Administrator',
--     'admin@aida.com',
--     '+1234567890',
--     'Global',
--     'admin',
--     NOW(),
--     TRUE
-- ) ON CONFLICT (email) DO NOTHING;

-- Then create the admin_users entry
-- INSERT INTO admin_users (user_id, role, permissions, is_active)
-- SELECT u.id, 'super-admin', '{"all": true}', TRUE
-- FROM users u
-- WHERE u.email = 'admin@aida.com'
-- ON CONFLICT DO NOTHING;

-- Success message
SELECT 'Database migration completed successfully! Admin user type and admin tables created.' AS status;
