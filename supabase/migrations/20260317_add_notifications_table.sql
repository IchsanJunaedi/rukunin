-- supabase/migrations/20260317_add_notifications_table.sql
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id UUID REFERENCES public.communities(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('payment', 'announcement', 'join_request', 'join_approved', 'join_rejected')),
  title TEXT NOT NULL,
  body TEXT,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_read_own_notifications" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_insert_community_notifications" ON public.notifications
  FOR INSERT WITH CHECK (
    community_id = (SELECT community_id FROM public.profiles WHERE id = auth.uid())
  );

CREATE POLICY "user_update_own_notifications" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id);
