-- Fix marketplace status constraint: rename 'available' → 'active'
-- Old constraint only allowed 'available' | 'sold'
-- New constraint allows 'active' | 'sold'

ALTER TABLE marketplace_listings
  DROP CONSTRAINT IF EXISTS marketplace_listings_status_check;

ALTER TABLE marketplace_listings
  ADD CONSTRAINT marketplace_listings_status_check
  CHECK (status IN ('active', 'sold'));

-- Migrate existing data
UPDATE marketplace_listings SET status = 'active' WHERE status = 'available';
