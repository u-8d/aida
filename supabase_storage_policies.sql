-- Storage policies for donations bucket

-- Policy for users to upload their own files
CREATE POLICY "Users can upload donation images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'donations' AND 
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy for anyone to view donation images (public read)
CREATE POLICY "Anyone can view donation images" ON storage.objects
FOR SELECT USING (bucket_id = 'donations');

-- Policy for users to update their own files
CREATE POLICY "Users can update their donation images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'donations' AND
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy for users to delete their own files
CREATE POLICY "Users can delete their donation images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'donations' AND
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
