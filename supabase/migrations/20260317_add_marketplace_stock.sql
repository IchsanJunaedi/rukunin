-- supabase/migrations/20260317_add_marketplace_stock.sql
ALTER TABLE public.marketplace_listings
  ADD COLUMN IF NOT EXISTS stock INTEGER NOT NULL DEFAULT 1;
