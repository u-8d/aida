-- Fix the donation status enum constraint
-- Run this in your Supabase SQL editor

-- First, drop the existing constraint
ALTER TABLE public.donations DROP CONSTRAINT IF EXISTS donations_status_check;

-- Add the correct constraint with proper spelling
ALTER TABLE public.donations ADD CONSTRAINT donations_status_check 
CHECK (status IN ('available', 'pendingMatch', 'matchFound', 'readyForPickup', 'donationCompleted', 'cancelled'));

-- Also fix the default value to make sure it's correct
ALTER TABLE public.donations ALTER COLUMN status SET DEFAULT 'available';
