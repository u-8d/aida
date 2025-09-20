-- Profile System Migration for AIDA
-- Run this in your Supabase SQL editor to add profile viewing, endorsements, and verification

-- Add new columns to users table for profile system
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT,
ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS bio TEXT,
ADD COLUMN IF NOT EXISTS endorsement_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS report_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Create user_endorsements table (like/endorse functionality)
CREATE TABLE IF NOT EXISTS public.user_endorsements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    endorser_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    endorsed_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(endorser_id, endorsed_user_id)
);

-- Create user_reports table (report functionality)
CREATE TABLE IF NOT EXISTS public.user_reports (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    reporter_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    reported_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    reason VARCHAR(100) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE,
    admin_notes TEXT
);

-- Update existing donations table to include more detailed information
ALTER TABLE public.donations 
ADD COLUMN IF NOT EXISTS item_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS tags TEXT[],
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS context_description TEXT,
ADD COLUMN IF NOT EXISTS matched_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS matched_recipient_id UUID REFERENCES public.users(id),
ADD COLUMN IF NOT EXISTS matched_recipient_name VARCHAR(255);

-- Create needs table for robust architecture
CREATE TABLE IF NOT EXISTS public.needs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    recipient_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    recipient_name VARCHAR(255) NOT NULL,
    recipient_type VARCHAR(50) NOT NULL CHECK (recipient_type IN ('ngo', 'individual')),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    required_tags TEXT[],
    city VARCHAR(255) NOT NULL,
    urgency VARCHAR(50) DEFAULT 'medium' CHECK (urgency IN ('low', 'medium', 'high', 'urgent')),
    status VARCHAR(50) DEFAULT 'unmet' CHECK (status IN ('unmet', 'partial_match', 'fulfilled', 'cancelled')),
    quantity INTEGER DEFAULT 1,
    fulfilled_quantity INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fulfilled_at TIMESTAMP WITH TIME ZONE
);

-- Create matches table for donation-need matching
CREATE TABLE IF NOT EXISTS public.matches (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    donation_id UUID REFERENCES public.donations(id) ON DELETE CASCADE,
    need_id UUID REFERENCES public.needs(id) ON DELETE CASCADE,
    donor_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    recipient_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    match_score DECIMAL(3,2) CHECK (match_score >= 0 AND match_score <= 1),
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Function to update endorsement count automatically
CREATE OR REPLACE FUNCTION update_endorsement_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.users 
        SET endorsement_count = endorsement_count + 1 
        WHERE id = NEW.endorsed_user_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.users 
        SET endorsement_count = GREATEST(endorsement_count - 1, 0) 
        WHERE id = OLD.endorsed_user_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to update report count automatically
CREATE OR REPLACE FUNCTION update_report_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.users 
        SET report_count = report_count + 1 
        WHERE id = NEW.reported_user_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.users 
        SET report_count = GREATEST(report_count - 1, 0) 
        WHERE id = OLD.reported_user_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to auto-verify user when profile picture is uploaded
CREATE OR REPLACE FUNCTION auto_verify_with_profile_picture()
RETURNS TRIGGER AS $$
BEGIN
    -- If profile picture is added and user wasn't verified before
    IF NEW.profile_picture_url IS NOT NULL AND OLD.profile_picture_url IS NULL THEN
        NEW.is_verified = true;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER endorsement_count_trigger
    AFTER INSERT OR DELETE ON public.user_endorsements
    FOR EACH ROW
    EXECUTE FUNCTION update_endorsement_count();

CREATE TRIGGER report_count_trigger
    AFTER INSERT OR DELETE ON public.user_reports
    FOR EACH ROW
    EXECUTE FUNCTION update_report_count();

CREATE TRIGGER auto_verify_trigger
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION auto_verify_with_profile_picture();

-- Create triggers for new tables
CREATE TRIGGER handle_needs_updated_at
    BEFORE UPDATE ON public.needs
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Set up Row Level Security for new tables
ALTER TABLE public.user_endorsements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.needs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

-- Policies for user_endorsements
CREATE POLICY "Anyone can view endorsements" ON public.user_endorsements
    FOR SELECT USING (true);

CREATE POLICY "Users can endorse others" ON public.user_endorsements
    FOR INSERT WITH CHECK (auth.uid() = endorser_id);

CREATE POLICY "Users can remove their own endorsements" ON public.user_endorsements
    FOR DELETE USING (auth.uid() = endorser_id);

-- Policies for user_reports
CREATE POLICY "Users can view their own reports" ON public.user_reports
    FOR SELECT USING (auth.uid() = reporter_id OR auth.uid() = reported_user_id);

CREATE POLICY "Users can create reports" ON public.user_reports
    FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- Policies for needs
CREATE POLICY "Anyone can view needs" ON public.needs
    FOR SELECT USING (true);

CREATE POLICY "Recipients can create needs" ON public.needs
    FOR INSERT WITH CHECK (auth.uid() = recipient_id);

CREATE POLICY "Recipients can update their needs" ON public.needs
    FOR UPDATE USING (auth.uid() = recipient_id);

-- Policies for matches
CREATE POLICY "Involved users can view matches" ON public.matches
    FOR SELECT USING (auth.uid() = donor_id OR auth.uid() = recipient_id);

CREATE POLICY "System can create matches" ON public.matches
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Involved users can update match status" ON public.matches
    FOR UPDATE USING (auth.uid() = donor_id OR auth.uid() = recipient_id);

-- Update users policies to allow profile viewing
CREATE POLICY "Anyone can view user profiles" ON public.users
    FOR SELECT USING (true);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_endorsements_endorsed_user ON public.user_endorsements(endorsed_user_id);
CREATE INDEX IF NOT EXISTS idx_user_endorsements_endorser ON public.user_endorsements(endorser_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_reported_user ON public.user_reports(reported_user_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_reporter ON public.user_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_status ON public.user_reports(status);
CREATE INDEX IF NOT EXISTS idx_needs_recipient_id ON public.needs(recipient_id);
CREATE INDEX IF NOT EXISTS idx_needs_status ON public.needs(status);
CREATE INDEX IF NOT EXISTS idx_needs_urgency ON public.needs(urgency);
CREATE INDEX IF NOT EXISTS idx_matches_donation_id ON public.matches(donation_id);
CREATE INDEX IF NOT EXISTS idx_matches_need_id ON public.matches(need_id);
CREATE INDEX IF NOT EXISTS idx_matches_status ON public.matches(status);
CREATE INDEX IF NOT EXISTS idx_users_verification ON public.users(is_verified);
CREATE INDEX IF NOT EXISTS idx_users_active ON public.users(is_active);

-- Create storage bucket for profile pictures
INSERT INTO storage.buckets (id, name, public) VALUES ('profile-pictures', 'profile-pictures', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policy for profile pictures
CREATE POLICY "Anyone can view profile pictures" ON storage.objects
    FOR SELECT USING (bucket_id = 'profile-pictures');

CREATE POLICY "Users can upload their own profile pictures" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'profile-pictures' AND 
        (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can update their own profile pictures" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'profile-pictures' AND 
        (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can delete their own profile pictures" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'profile-pictures' AND 
        (storage.foldername(name))[1] = auth.uid()::text
    );
