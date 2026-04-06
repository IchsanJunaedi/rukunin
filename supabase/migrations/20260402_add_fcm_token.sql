-- Migration: tambah kolom fcm_token ke tabel profiles
-- Digunakan untuk mengirim push notification FCM ke device spesifik

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Index untuk lookup cepat saat broadcast (opsional tapi direkomendasikan)
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token
  ON profiles (fcm_token)
  WHERE fcm_token IS NOT NULL;
