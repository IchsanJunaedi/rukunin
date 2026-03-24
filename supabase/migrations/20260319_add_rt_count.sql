-- Add rt_count to communities so warga can only pick valid RT numbers
ALTER TABLE public.communities
  ADD COLUMN IF NOT EXISTS rt_count integer NOT NULL DEFAULT 1
  CHECK (rt_count BETWEEN 1 AND 20);
