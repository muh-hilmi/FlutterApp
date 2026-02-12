-- ============================================================================
-- ROLLBACK EVENT SERVICE DATABASE SCHEMA
-- ============================================================================

-- Drop triggers
DROP TRIGGER IF EXISTS update_event_qna_updated_at ON event_qna;
DROP TRIGGER IF EXISTS update_reviews_updated_at ON reviews;
DROP TRIGGER IF EXISTS update_events_updated_at ON events;
DROP TRIGGER IF EXISTS update_events_location_geom ON events;

-- Drop functions
DROP FUNCTION IF EXISTS update_location_geom();

-- Drop indexes
DROP INDEX IF EXISTS idx_event_qna_is_answered;
DROP INDEX IF EXISTS idx_event_qna_user;
DROP INDEX IF EXISTS idx_event_qna_event;
DROP INDEX IF EXISTS idx_reviews_rating;
DROP INDEX IF EXISTS idx_reviews_reviewer;
DROP INDEX IF EXISTS idx_reviews_event;
DROP INDEX IF EXISTS idx_event_attendees_user;
DROP INDEX IF EXISTS idx_event_attendees_event;
DROP INDEX IF EXISTS idx_event_images_event;
DROP INDEX IF EXISTS idx_events_location_geom;
DROP INDEX IF EXISTS idx_events_start_time;
DROP INDEX IF EXISTS idx_events_status;
DROP INDEX IF EXISTS idx_events_category;
DROP INDEX IF EXISTS idx_events_host;

-- Drop tables
DROP TABLE IF EXISTS event_qna CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS event_attendees CASCADE;
DROP TABLE IF EXISTS event_images CASCADE;
DROP TABLE IF EXISTS events CASCADE;

-- Drop types
DROP TYPE IF EXISTS attendee_status;
DROP TYPE IF EXISTS event_category;
DROP TYPE IF EXISTS event_privacy;
DROP TYPE IF EXISTS event_status;
