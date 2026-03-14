-- ============================================================
-- Self-service onboarding: community_code + pending status
-- ============================================================

-- 1. Add community_code column to communities
ALTER TABLE public.communities
  ADD COLUMN IF NOT EXISTS community_code text UNIQUE;

-- Generate 6-char codes for existing communities (based on their ID)
UPDATE public.communities
  SET community_code = upper(substring(md5(id::text) from 1 for 6))
  WHERE community_code IS NULL;

ALTER TABLE public.communities
  ALTER COLUMN community_code SET NOT NULL;

-- 2. Add email column to profiles (for self-registered users)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS email text;

-- 3. Update status constraint to include 'pending'
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_status_check;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_status_check
  CHECK (status IN ('active', 'inactive', 'pending'));

-- 4. RLS: Any authenticated user can read communities (needed to lookup by code)
DROP POLICY IF EXISTS "User terautentikasi dapat lihat data komunitas" ON public.communities;
CREATE POLICY "User terautentikasi dapat lihat data komunitas"
  ON public.communities FOR SELECT
  TO authenticated
  USING (true);

-- 5. RLS: User dapat insert komunitas baru (admin yang baru daftar)
DROP POLICY IF EXISTS "User terautentikasi dapat buat komunitas baru" ON public.communities;
CREATE POLICY "User terautentikasi dapat buat komunitas baru"
  ON public.communities FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- 6. RLS: User dapat insert profil sendiri saat registrasi mandiri
DROP POLICY IF EXISTS "User dapat insert profil sendiri" ON public.profiles;
CREATE POLICY "User dapat insert profil sendiri"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- ============================================================
-- SELESAI
-- ============================================================
