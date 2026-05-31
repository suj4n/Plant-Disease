-- ============================================
-- PlantDoc Supabase Database Schema
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. User Profiles (linked to Supabase Auth)
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- 2. Scan Results (plant disease predictions)
CREATE TABLE IF NOT EXISTS scans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  
  disease_name TEXT NOT NULL,
  confidence FLOAT NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
  is_healthy BOOLEAN DEFAULT false,
  recommendations TEXT,
  
  image_url TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- 3. Disease Information (reference/catalog)
CREATE TABLE IF NOT EXISTS disease_info (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  symptoms TEXT,
  treatment TEXT,
  prevention TEXT,
  created_at TIMESTAMP DEFAULT now()
);

-- 4. Favorites (user-disease associations)
CREATE TABLE IF NOT EXISTS favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  disease_id INT NOT NULL REFERENCES disease_info(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT now(),
  UNIQUE(user_id, disease_id)
);

-- ============================================
-- Row Level Security (RLS) Policies
-- ============================================

-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE disease_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

-- User Profiles Policies
CREATE POLICY "Users can read own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Scans Policies
CREATE POLICY "Users can read own scans" ON scans
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own scans" ON scans
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own scans" ON scans
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own scans" ON scans
  FOR DELETE USING (auth.uid() = user_id);

-- Disease Info Policies (public read-only)
CREATE POLICY "Anyone can read disease info" ON disease_info
  FOR SELECT USING (true);

-- Favorites Policies
CREATE POLICY "Users can read own favorites" ON favorites
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own favorites" ON favorites
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own favorites" ON favorites
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- Indexes for Performance
-- ============================================

CREATE INDEX IF NOT EXISTS idx_scans_user_id ON scans(user_id);
CREATE INDEX IF NOT EXISTS idx_scans_created_at ON scans(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_disease_name ON disease_info(name);

-- ============================================
-- Storage Buckets (Set up manually in dashboard)
-- ============================================

-- Via Supabase Dashboard:
-- 1. Go to Storage → Create new bucket
-- 2. Name: "scan-images"
-- 3. Public: Yes
-- 4. Run these policies:

CREATE POLICY "Users can upload their own scan images" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'scan-images' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can read their own images" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'scan-images' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete their own images" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'scan-images' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Public can read scan images" ON storage.objects
  FOR SELECT USING (bucket_id = 'scan-images');

-- ============================================
-- Seed Data (Optional)
-- ============================================

INSERT INTO disease_info (name, description, symptoms, treatment, prevention)
VALUES
  ('Early Blight', 'Fungal disease affecting tomato and potato plants', 'Brown spots with concentric rings on lower leaves', 'Remove infected leaves, apply fungicide', 'Improve air circulation, avoid overhead watering'),
  ('Late Blight', 'Serious fungal disease of potatoes and tomatoes', 'Water-soaked spots, white mold on leaf undersides', 'Apply copper fungicide, remove infected plants', 'Use resistant varieties, maintain proper spacing'),
  ('Leaf Spot', 'Common fungal disease on various crops', 'Circular brown spots with yellow halos', 'Remove affected leaves, apply fungicide', 'Improve drainage, avoid wetting foliage'),
  ('Powdery Mildew', 'White powdery coating on leaves', 'White powder on upper and lower leaf surfaces', 'Spray with sulfur or neem oil', 'Ensure good air circulation'),
  ('Healthy', 'No disease detected', 'None', 'Continue regular maintenance', 'Maintain good plant health')
ON CONFLICT (name) DO NOTHING;
