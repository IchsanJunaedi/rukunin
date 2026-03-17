-- Trigger: auto-create profile dari user_metadata saat user baru daftar.
-- Dipakai oleh registerResident() agar tidak perlu session aktif untuk insert profile.
-- registerAdmin() tidak pakai ini karena perlu insert communities dulu.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Hanya buat profile kalau ada community_id di user_metadata (resident self-register)
  IF NEW.raw_user_meta_data->>'community_id' IS NOT NULL THEN
    INSERT INTO public.profiles (
      id,
      community_id,
      full_name,
      phone,
      email,
      nik,
      unit_number,
      block,
      rt_number,
      role,
      status
    ) VALUES (
      NEW.id,
      (NEW.raw_user_meta_data->>'community_id')::uuid,
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'phone',
      NEW.email,
      NULLIF(NEW.raw_user_meta_data->>'nik', ''),
      NULLIF(NEW.raw_user_meta_data->>'unit_number', ''),
      NULLIF(NEW.raw_user_meta_data->>'block', ''),
      COALESCE((NEW.raw_user_meta_data->>'rt_number')::int, 1),
      'resident',
      'pending'
    ) ON CONFLICT (id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
