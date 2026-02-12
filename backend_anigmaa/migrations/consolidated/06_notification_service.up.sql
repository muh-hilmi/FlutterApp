-- ============================================================================
-- NOTIFICATION SERVICE DATABASE SCHEMA
-- ============================================================================
-- This schema contains all notification-related tables:
-- - notifications: User notifications
-- ============================================================================

-- ============================================================================
-- ENUMS
-- ============================================================================

-- Create ENUM type only if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
        CREATE TYPE notification_type AS ENUM (
            'like_post',
            'comment_post',
            'mention',
            'follow',
            'event_invitation',
            'event_reminder',
            'event_update',
            'community_invitation',
            'community_post',
            'system'
        );
    END IF;
END $$;

-- ============================================================================
-- NOTIFICATIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,  -- References users(id) - recipient
    actor_id UUID,  -- References users(id) - who triggered the notification
    type notification_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    link VARCHAR(500),  -- Deep link to the content
    metadata JSONB,  -- Additional data (post_id, event_id, etc.)
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Notifications indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_actor ON notifications(actor_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = false;

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Created tables:
-- 1. notifications - User notification system
--
-- Features:
-- - Multiple notification types (likes, comments, follows, events, communities, system)
-- - Actor tracking (who triggered the notification)
-- - Rich metadata support via JSONB
-- - Deep linking support
-- - Read/unread status tracking
-- - Optimized indexes for unread notifications query
-- ============================================================================
