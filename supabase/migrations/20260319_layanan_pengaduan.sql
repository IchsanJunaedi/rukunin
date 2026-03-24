-- ============================================================
-- Layanan & Pengaduan
-- ============================================================

-- 1. Tabel permohonan surat dari warga
CREATE TABLE public.letter_requests (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  community_id  uuid NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  resident_id   uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  letter_type   text NOT NULL,
  purpose       text,
  notes         text,
  status        text NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending','in_progress','ready','completed','rejected')),
  admin_notes   text,
  letter_id     uuid REFERENCES public.letters(id) ON DELETE SET NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- 2. Tabel pengaduan warga
CREATE TABLE public.complaints (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  community_id  uuid NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  resident_id   uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title         text NOT NULL,
  description   text NOT NULL,
  category      text NOT NULL DEFAULT 'lainnya'
                CHECK (category IN ('infrastruktur','keamanan','kebersihan','sosial','lainnya')),
  status        text NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending','in_progress','resolved','rejected')),
  admin_notes   text,
  photo_url     text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- 3. Enable RLS
ALTER TABLE public.letter_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;

-- 4. RLS letter_requests
CREATE POLICY "Admin dapat kelola semua permohonan surat"
  ON public.letter_requests FOR ALL
  USING (is_admin_of(community_id));

CREATE POLICY "Warga dapat lihat permohonan sendiri"
  ON public.letter_requests FOR SELECT
  USING (resident_id = auth.uid());

CREATE POLICY "Warga dapat buat permohonan"
  ON public.letter_requests FOR INSERT
  WITH CHECK (resident_id = auth.uid() AND community_id = my_community_id());

-- 5. RLS complaints
CREATE POLICY "Admin dapat kelola semua pengaduan"
  ON public.complaints FOR ALL
  USING (is_admin_of(community_id));

CREATE POLICY "Warga dapat lihat pengaduan sendiri"
  ON public.complaints FOR SELECT
  USING (resident_id = auth.uid());

CREATE POLICY "Warga dapat buat pengaduan"
  ON public.complaints FOR INSERT
  WITH CHECK (resident_id = auth.uid() AND community_id = my_community_id());

-- 6. Extend notifications.type CHECK agar bisa terima tipe baru
ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type IN ('payment','announcement','join_request','join_approved','join_rejected','letter_request','complaint'));
