-- ============================================================================
-- REMOVE EVENT INTERESTS FEATURE
-- ============================================================================

-- Drop the event_interests table
DROP TABLE IF EXISTS event_interests;

-- Remove interests_count column from events table if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='events' AND column_name='interests_count'
    ) THEN
        ALTER TABLE events DROP COLUMN interests_count;
    END IF;
END $$;