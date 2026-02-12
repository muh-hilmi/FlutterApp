-- ============================================================================
-- USER SERVICE DATABASE SCHEMA
-- ============================================================================
-- This schema contains all user-related tables:
-- - users: Main user accounts
-- - user_settings: User preferences
-- - user_stats: User statistics and counters
-- - user_privacy: Privacy settings
-- - follows: Social connections
-- - invitations: User invitations
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ============================================================================
-- USERS TABLE
-- ============================================================================

-- Create users table only if it doesn't exist
-- If table exists, we'll add missing columns separately
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
        -- Table doesn't exist, create it with all columns including username
        CREATE TABLE users (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            email VARCHAR(255) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            name VARCHAR(255) NOT NULL,
            username VARCHAR(50) NOT NULL,
            bio TEXT,
            avatar_url VARCHAR(500),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            last_login_at TIMESTAMP WITH TIME ZONE,
            is_verified BOOLEAN DEFAULT FALSE,
            is_email_verified BOOLEAN DEFAULT FALSE,
            CONSTRAINT users_username_unique UNIQUE (username),
            CONSTRAINT users_username_format CHECK (username ~ '^[a-zA-Z0-9_-]{3,50}$')
        );
    ELSE
        -- Table exists, add missing columns if needed
        -- Add username column if missing (nullable to avoid constraint violations on existing data)
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'username'
        ) THEN
            ALTER TABLE users ADD COLUMN username VARCHAR(50);
            
            -- Add constraints only if they don't exist
            -- Use partial unique index for nullable username column
            IF NOT EXISTS (
                SELECT FROM pg_indexes WHERE indexname = 'users_username_unique'
            ) AND NOT EXISTS (
                SELECT FROM pg_constraint WHERE conname = 'users_username_unique'
            ) THEN
                CREATE UNIQUE INDEX users_username_unique ON users(username) 
                    WHERE username IS NOT NULL;
            END IF;
            
            IF NOT EXISTS (
                SELECT FROM pg_constraint WHERE conname = 'users_username_format'
            ) THEN
                ALTER TABLE users ADD CONSTRAINT users_username_format 
                    CHECK (username IS NULL OR username ~ '^[a-zA-Z0-9_-]{3,50}$');
            END IF;
        END IF;
        
        -- Add password_hash if missing
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'password_hash'
        ) THEN
            ALTER TABLE users ADD COLUMN password_hash VARCHAR(255);
        END IF;
        
        -- Add other columns if missing (for compatibility)
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'email'
        ) THEN
            ALTER TABLE users ADD COLUMN email VARCHAR(255);
            ALTER TABLE users ADD CONSTRAINT users_email_unique UNIQUE (email);
        END IF;
        
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'name'
        ) THEN
            ALTER TABLE users ADD COLUMN name VARCHAR(255);
        END IF;
        
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'bio'
        ) THEN
            ALTER TABLE users ADD COLUMN bio TEXT;
        END IF;
        
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'avatar_url'
        ) THEN
            ALTER TABLE users ADD COLUMN avatar_url VARCHAR(500);
        END IF;
        
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'created_at'
        ) THEN
            ALTER TABLE users ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
        END IF;
        
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'updated_at'
        ) THEN
            ALTER TABLE users ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
        END IF;
        
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'last_login_at'
        ) THEN
            ALTER TABLE users ADD COLUMN last_login_at TIMESTAMP WITH TIME ZONE;
        END IF;
        
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'is_verified'
        ) THEN
            ALTER TABLE users ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
        END IF;
        
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'is_email_verified'
        ) THEN
            ALTER TABLE users ADD COLUMN is_email_verified BOOLEAN DEFAULT FALSE;
        END IF;
    END IF;
END $$;

-- ============================================================================
-- USER SETTINGS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    push_notifications BOOLEAN DEFAULT TRUE,
    email_notifications BOOLEAN DEFAULT TRUE,
    dark_mode BOOLEAN DEFAULT FALSE,
    language VARCHAR(10) DEFAULT 'en',
    location_enabled BOOLEAN DEFAULT TRUE,
    show_online_status BOOLEAN DEFAULT TRUE
);

-- ============================================================================
-- USER STATS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_stats (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    events_attended INTEGER DEFAULT 0,
    events_created INTEGER DEFAULT 0,
    posts_count INTEGER DEFAULT 0,
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    reviews_given INTEGER DEFAULT 0,
    invites_successful_count INTEGER DEFAULT 0,
    average_rating DECIMAL(3, 2) DEFAULT 0.0
);

-- ============================================================================
-- USER PRIVACY TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_privacy (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    profile_visible BOOLEAN DEFAULT TRUE,
    events_visible BOOLEAN DEFAULT TRUE,
    allow_followers BOOLEAN DEFAULT TRUE,
    show_email BOOLEAN DEFAULT FALSE,
    show_location BOOLEAN DEFAULT TRUE
);

-- ============================================================================
-- FOLLOWS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(follower_id, following_id),
    CHECK (follower_id != following_id)
);

-- ============================================================================
-- INVITATIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inviter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    invitee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_id UUID,  -- Will be linked after event service is created
    status VARCHAR(20) DEFAULT 'pending',
    invited_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(inviter_id, invitee_id, event_id)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Create username index only if username column exists
DO $$
BEGIN
    IF EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'username'
    ) THEN
        CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
    END IF;
END $$;

-- Follows indexes
CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id);

-- Invitations indexes
CREATE INDEX IF NOT EXISTS idx_invitations_inviter ON invitations(inviter_id);
CREATE INDEX IF NOT EXISTS idx_invitations_invitee ON invitations(invitee_id);
CREATE INDEX IF NOT EXISTS idx_invitations_event ON invitations(event_id);
CREATE INDEX IF NOT EXISTS idx_invitations_status ON invitations(status);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update users updated_at on modification
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER FUNCTIONS FOR AUTO-UPDATING STATS
-- ============================================================================

-- Function to update posts count when post is created/deleted
CREATE OR REPLACE FUNCTION update_posts_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE user_stats
        SET posts_count = posts_count + 1
        WHERE user_id = NEW.author_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE user_stats
        SET posts_count = GREATEST(posts_count - 1, 0)
        WHERE user_id = OLD.author_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';

-- Function to update invites count when invitation is accepted
CREATE OR REPLACE FUNCTION update_invites_count()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status != 'accepted') THEN
        UPDATE user_stats
        SET invites_successful_count = invites_successful_count + 1
        WHERE user_id = NEW.inviter_id;
    ELSIF OLD.status = 'accepted' AND NEW.status != 'accepted' THEN
        UPDATE user_stats
        SET invites_successful_count = GREATEST(invites_successful_count - 1, 0)
        WHERE user_id = NEW.inviter_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- Create trigger for invitations
DROP TRIGGER IF EXISTS update_invites_count_trigger ON invitations;
CREATE TRIGGER update_invites_count_trigger
    AFTER INSERT OR UPDATE ON invitations
    FOR EACH ROW EXECUTE FUNCTION update_invites_count();

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Created tables:
-- 1. users - Main user accounts with username support
-- 2. user_settings - User preferences
-- 3. user_stats - User statistics with auto-updating counters
-- 4. user_privacy - Privacy settings
-- 5. follows - Social follow relationships
-- 6. invitations - User invitations tracking
--
-- Features:
-- - UUID primary keys
-- - Automatic timestamp updates
-- - Username validation (3-50 chars, alphanumeric + underscore/hyphen)
-- - Auto-updating statistics via triggers
-- - Comprehensive indexing for performance
-- ============================================================================
