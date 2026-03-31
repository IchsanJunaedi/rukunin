-- ============================================================
-- Izinkan warga membaca data komunitas mereka sendiri
-- Diperlukan untuk: download PDF surat, tampilan nama komunitas di resident screens
-- ============================================================

CREATE POLICY "Warga dapat lihat komunitas sendiri"
  ON public.communities FOR SELECT
  USING (id = my_community_id());
