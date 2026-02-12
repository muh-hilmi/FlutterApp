-- ============================================================================
-- EVENT SERVICE DATABASE SCHEMA
-- ============================================================================
-- This schema contains all event-related tables:
-- - events: Main event information
-- - event_images: Event photo gallery
-- - event_attendees: Event participants
-- - reviews: Event reviews and ratings
-- - event_qna: Event Q&A functionality
-- ============================================================================

-- Enable PostGIS extension for geolocation
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================================
-- ENUMS
-- ============================================================================

-- Create ENUM types only if they don't exist
DO $$
BEGIN
    -- Event status
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'event_status') THEN
        CREATE TYPE event_status AS ENUM ('upcoming', 'ongoing', 'ended', 'cancelled');
    END IF;

    -- Event privacy
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'event_privacy') THEN
        CREATE TYPE event_privacy AS ENUM ('public', 'private', 'friends_only');
    END IF;

    -- Event category
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'event_category') THEN
        CREATE TYPE event_category AS ENUM ('meetup', 'sports', 'workshop', 'networking', 'food', 'creative', 'outdoor', 'fitness', 'learning', 'social');
    END IF;

    -- Attendee status
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'attendee_status') THEN
        CREATE TYPE attendee_status AS ENUM ('pending', 'confirmed', 'cancelled');
    END IF;
END $$;

-- ============================================================================
-- EVENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_id UUID NOT NULL,  -- References users(id) from user service
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category event_category NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    location_name VARCHAR(255) NOT NULL,
    location_address TEXT NOT NULL,
    location_lat DECIMAL(10, 8) NOT NULL,
    location_lng DECIMAL(11, 8) NOT NULL,
    location_geom GEOGRAPHY(POINT, 4326),
    max_attendees INTEGER NOT NULL CHECK (max_attendees > 0),
    attendees_count INTEGER DEFAULT 0,
    price DECIMAL(10, 2) CHECK (price >= 0),
    is_free BOOLEAN DEFAULT TRUE,
    status event_status DEFAULT 'upcoming',
    privacy event_privacy DEFAULT 'public',
    requirements TEXT,
    ticketing_enabled BOOLEAN DEFAULT FALSE,
    tickets_sold INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CHECK (end_time > start_time)
);

-- ============================================================================
-- EVENT IMAGES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS event_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    order_index INTEGER NOT NULL DEFAULT 0
);

-- ============================================================================
-- EVENT ATTENDEES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS event_attendees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,  -- References users(id) from user service
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status attendee_status DEFAULT 'confirmed',
    UNIQUE(event_id, user_id)
);

-- ============================================================================
-- REVIEWS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL,  -- References users(id) from user service
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(event_id, reviewer_id)
);

-- ============================================================================
-- EVENT Q&A TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS event_qna (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,  -- References users(id) from user service
    question TEXT NOT NULL,
    answer TEXT,
    answered_by UUID,  -- References users(id) from user service
    answered_at TIMESTAMP WITH TIME ZONE,
    is_answered BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Events indexes
CREATE INDEX IF NOT EXISTS idx_events_host ON events(host_id);
CREATE INDEX IF NOT EXISTS idx_events_category ON events(category);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_events_start_time ON events(start_time);
CREATE INDEX IF NOT EXISTS idx_events_location_geom ON events USING GIST(location_geom);

-- Event images indexes
CREATE INDEX IF NOT EXISTS idx_event_images_event ON event_images(event_id);

-- Event attendees indexes
CREATE INDEX IF NOT EXISTS idx_event_attendees_event ON event_attendees(event_id);
CREATE INDEX IF NOT EXISTS idx_event_attendees_user ON event_attendees(user_id);

-- Reviews indexes
CREATE INDEX IF NOT EXISTS idx_reviews_event ON reviews(event_id);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewer ON reviews(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON reviews(rating);

-- Event Q&A indexes
CREATE INDEX IF NOT EXISTS idx_event_qna_event ON event_qna(event_id);
CREATE INDEX IF NOT EXISTS idx_event_qna_user ON event_qna(user_id);
CREATE INDEX IF NOT EXISTS idx_event_qna_is_answered ON event_qna(is_answered);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger to update location_geom from lat/lng
CREATE OR REPLACE FUNCTION update_location_geom()
RETURNS TRIGGER AS $$
BEGIN
    NEW.location_geom := ST_SetSRID(ST_MakePoint(NEW.location_lng, NEW.location_lat), 4326)::geography;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_events_location_geom ON events;
CREATE TRIGGER update_events_location_geom BEFORE INSERT OR UPDATE ON events
    FOR EACH ROW EXECUTE FUNCTION update_location_geom();

-- Trigger to update events updated_at
DROP TRIGGER IF EXISTS update_events_updated_at ON events;
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update reviews updated_at
DROP TRIGGER IF EXISTS update_reviews_updated_at ON reviews;
CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update event_qna updated_at
DROP TRIGGER IF EXISTS update_event_qna_updated_at ON event_qna;
CREATE TRIGGER update_event_qna_updated_at BEFORE UPDATE ON event_qna
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Created tables:
-- 1. events - Main event information with geolocation support
-- 2. event_images - Event photo gallery
-- 3. event_attendees - Event participants tracking
-- 4. reviews - Event reviews and ratings
-- 5. event_qna - Event Q&A functionality
--
-- Features:
-- - PostGIS integration for location-based queries
-- - Automatic geolocation point generation
-- - Event status and category management
-- - Review system with 1-5 star ratings
-- - Q&A functionality for events
-- - Comprehensive indexing including spatial indexes
-- ============================================================================
