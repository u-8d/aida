-- Storage bucket policies for AIDA app
-- Run this in your Supabase SQL editor AFTER creating the 'donations' bucket

-- Create bucket if it doesn't exist (do this in Supabase Storage UI first)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('donations', 'donations', true);

-- Enable RLS on storage objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to upload files to donations bucket
CREATE POLICY "Allow authenticated users to upload donation images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'donations' AND
        auth.role() = 'authenticated'
    );

-- Allow users to view all donation images (public read)
CREATE POLICY "Allow public to view donation images" ON storage.objects
    FOR SELECT USING (bucket_id = 'donations');

-- Allow users to update their own uploaded files
CREATE POLICY "Allow users to update their own donation images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'donations' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow users to delete their own uploaded files
CREATE POLICY "Allow users to delete their own donation images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'donations' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );
