-- ============================================================================
-- EVENT INTERESTS TABLE
-- ============================================================================
-- This table tracks user interest/likes for events
-- One user can only express interest once per event

CREATE TABLE IF NOT EXISTS event_interests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(event_id, user_id)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Index for checking if user is interested in an event
CREATE INDEX IF NOT EXISTS idx_event_interests_event_user ON event_interests(event_id, user_id);

-- Index for counting interests on an event
CREATE INDEX IF NOT EXISTS idx_event_interests_event ON event_interests(event_id);

-- Index for finding all events a user is interested in
CREATE INDEX IF NOT EXISTS idx_event_interests_user ON event_interests(user_id);

-- ============================================================================
-- UPDATE EVENTS TABLE TO INCLUDE INTERESTS COUNT
-- ============================================================================

-- Add interests_count column to events table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='events' AND column_name='interests_count'
    ) THEN
        ALTER TABLE events ADD COLUMN interests_count INTEGER DEFAULT 0;
    END IF;
END $$;