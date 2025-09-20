-- Complete database schema update to match all models
-- Run this in your Supabase SQL editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing tables if they exist (in correct order due to foreign keys)
DROP TABLE IF EXISTS public.matches CASCADE;
DROP TABLE IF EXISTS public.needs CASCADE;
DROP TABLE IF EXISTS public.donations CASCADE;

-- Create the donations table with all required fields
CREATE TABLE public.donations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    donor_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    item_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    context_description TEXT,
    tags TEXT[] DEFAULT '{}',
    image_url TEXT NOT NULL,
    city VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'available' CHECK (status IN ('available', 'pendingMatch', 'matchFound', 'readyForPickup', 'donationCompleted', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    matched_at TIMESTAMP WITH TIME ZONE,
    matched_recipient_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    matched_recipient_name VARCHAR(255)
);

-- Create the needs table
CREATE TABLE public.needs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    recipient_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    recipient_name VARCHAR(255) NOT NULL,
    recipient_type VARCHAR(50) NOT NULL CHECK (recipient_type IN ('ngo', 'individual')),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    required_tags TEXT[] DEFAULT '{}',
    city VARCHAR(255) NOT NULL,
    urgency VARCHAR(50) DEFAULT 'medium' CHECK (urgency IN ('low', 'medium', 'high', 'urgent')),
    status VARCHAR(50) DEFAULT 'unmet' CHECK (status IN ('unmet', 'partialMatch', 'fulfilled', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fulfilled_at TIMESTAMP WITH TIME ZONE,
    quantity INTEGER NOT NULL DEFAULT 1,
    fulfilled_quantity INTEGER DEFAULT 0
);

-- Create the matches table
CREATE TABLE public.matches (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    donation_id UUID REFERENCES public.donations(id) ON DELETE CASCADE NOT NULL,
    need_id UUID REFERENCES public.needs(id) ON DELETE CASCADE NOT NULL,
    donor_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    recipient_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    match_score DECIMAL(3,2) NOT NULL CHECK (match_score >= 0 AND match_score <= 1),
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'completed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    chat_id UUID
);

-- Create indexes for better performance
CREATE INDEX idx_donations_donor_id ON public.donations(donor_id);
CREATE INDEX idx_donations_status ON public.donations(status);
CREATE INDEX idx_donations_city ON public.donations(city);
CREATE INDEX idx_donations_created_at ON public.donations(created_at);
CREATE INDEX idx_donations_matched_recipient_id ON public.donations(matched_recipient_id);

CREATE INDEX idx_needs_recipient_id ON public.needs(recipient_id);
CREATE INDEX idx_needs_status ON public.needs(status);
CREATE INDEX idx_needs_city ON public.needs(city);
CREATE INDEX idx_needs_urgency ON public.needs(urgency);
CREATE INDEX idx_needs_created_at ON public.needs(created_at);

CREATE INDEX idx_matches_donation_id ON public.matches(donation_id);
CREATE INDEX idx_matches_need_id ON public.matches(need_id);
CREATE INDEX idx_matches_donor_id ON public.matches(donor_id);
CREATE INDEX idx_matches_recipient_id ON public.matches(recipient_id);
CREATE INDEX idx_matches_status ON public.matches(status);
CREATE INDEX idx_matches_created_at ON public.matches(created_at);

-- Enable Row Level Security
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.needs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

-- Create policies for donations table
CREATE POLICY "Users can view all donations" ON public.donations
    FOR SELECT USING (true);

CREATE POLICY "Users can create donations" ON public.donations
    FOR INSERT WITH CHECK (auth.uid() = donor_id);

CREATE POLICY "Donors can update their donations" ON public.donations
    FOR UPDATE USING (auth.uid() = donor_id);

CREATE POLICY "Recipients can update matched donations" ON public.donations
    FOR UPDATE USING (auth.uid() = matched_recipient_id);

-- Create policies for needs table
CREATE POLICY "Users can view all needs" ON public.needs
    FOR SELECT USING (true);

CREATE POLICY "Users can create needs" ON public.needs
    FOR INSERT WITH CHECK (auth.uid() = recipient_id);

CREATE POLICY "Recipients can update their needs" ON public.needs
    FOR UPDATE USING (auth.uid() = recipient_id);

-- Create policies for matches table
CREATE POLICY "Users can view their matches" ON public.matches
    FOR SELECT USING (auth.uid() = donor_id OR auth.uid() = recipient_id);

CREATE POLICY "System can create matches" ON public.matches
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their matches" ON public.matches
    FOR UPDATE USING (auth.uid() = donor_id OR auth.uid() = recipient_id);

-- Create trigger for updated_at functionality
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER handle_donations_updated_at
    BEFORE UPDATE ON public.donations
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_needs_updated_at
    BEFORE UPDATE ON public.needs
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_matches_updated_at
    BEFORE UPDATE ON public.matches
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
