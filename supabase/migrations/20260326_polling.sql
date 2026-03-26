-- supabase/migrations/20260326_polling.sql

-- ─── Tabel polls ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS polls (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id uuid NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
  created_by   uuid NOT NULL REFERENCES profiles(id),
  title        text NOT NULL,
  description  text,
  starts_at    timestamptz NOT NULL,
  ends_at      timestamptz NOT NULL,
  status       text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
  created_at   timestamptz DEFAULT now()
);

-- ─── Tabel poll_votes ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS poll_votes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id     uuid NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
  resident_id uuid NOT NULL REFERENCES profiles(id),
  vote        boolean NOT NULL,  -- true = Ya, false = Tidak
  voted_at    timestamptz DEFAULT now(),
  UNIQUE (poll_id, resident_id)  -- satu warga satu vote per poll
);

-- ─── RLS polls ────────────────────────────────────────────────────────────────
ALTER TABLE polls ENABLE ROW LEVEL SECURITY;

-- Admin: full CRUD untuk community_id miliknya
CREATE POLICY "admin_polls_all" ON polls
  FOR ALL
  TO authenticated
  USING (
    community_id IN (
      SELECT community_id FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    community_id IN (
      SELECT community_id FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Resident: hanya SELECT untuk community_id miliknya
CREATE POLICY "resident_polls_select" ON polls
  FOR SELECT
  TO authenticated
  USING (
    community_id IN (
      SELECT community_id FROM profiles
      WHERE id = auth.uid() AND role = 'resident'
    )
  );

-- ─── RLS poll_votes ───────────────────────────────────────────────────────────
ALTER TABLE poll_votes ENABLE ROW LEVEL SECURITY;

-- Resident: INSERT dan SELECT vote milik sendiri
CREATE POLICY "resident_poll_votes_insert" ON poll_votes
  FOR INSERT
  TO authenticated
  WITH CHECK (resident_id = auth.uid());

CREATE POLICY "resident_poll_votes_select" ON poll_votes
  FOR SELECT
  TO authenticated
  USING (
    poll_id IN (
      SELECT p.id FROM polls p
      JOIN profiles pr ON pr.community_id = p.community_id
      WHERE pr.id = auth.uid()
    )
  );

-- Admin: SELECT semua votes di community-nya
CREATE POLICY "admin_poll_votes_select" ON poll_votes
  FOR SELECT
  TO authenticated
  USING (
    poll_id IN (
      SELECT p.id FROM polls p
      WHERE p.community_id IN (
        SELECT community_id FROM profiles
        WHERE id = auth.uid() AND role = 'admin'
      )
    )
  );
