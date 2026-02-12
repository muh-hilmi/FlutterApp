-- ============================================================================
-- COMMUNITY SERVICE DATABASE SCHEMA
-- ============================================================================
-- This schema contains all community-related tables:
-- - communities: User communities/groups
-- - community_members: Community membership tracking
-- ============================================================================

-- ============================================================================
-- ENUMS
-- ============================================================================

-- Create ENUM types only if they don't exist
DO $$
BEGIN
    -- Community privacy
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'community_privacy') THEN
        CREATE TYPE community_privacy AS ENUM ('public', 'private', 'secret');
    END IF;

    -- Community role
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'community_role') THEN
        CREATE TYPE community_role AS ENUM ('owner', 'admin', 'moderator', 'member');
    END IF;

    -- Community category (aligned with event categories)
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'community_category') THEN
        CREATE TYPE community_category AS ENUM ('meetup', 'sports', 'workshop', 'networking', 'food', 'creative', 'outdoor', 'fitness', 'learning', 'social');
    END IF;
END $$;

-- ============================================================================
-- COMMUNITIES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS communities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    category community_category NOT NULL DEFAULT 'social',
    avatar_url VARCHAR(500),
    cover_url VARCHAR(500),
    creator_id UUID NOT NULL,  -- References users(id)
    privacy community_privacy DEFAULT 'public',
    members_count INTEGER DEFAULT 0,
    posts_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT communities_slug_format CHECK (slug ~ '^[a-z0-9-]+$')
);

-- ============================================================================
-- COMMUNITY MEMBERS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS community_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    community_id UUID NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,  -- References users(id)
    role community_role DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(community_id, user_id)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Communities indexes
CREATE INDEX IF NOT EXISTS idx_communities_creator ON communities(creator_id);
CREATE INDEX IF NOT EXISTS idx_communities_slug ON communities(slug);
CREATE INDEX IF NOT EXISTS idx_communities_privacy ON communities(privacy);
CREATE INDEX IF NOT EXISTS idx_communities_category ON communities(category);

-- Community members indexes
CREATE INDEX IF NOT EXISTS idx_community_members_community ON community_members(community_id);
CREATE INDEX IF NOT EXISTS idx_community_members_user ON community_members(user_id);
CREATE INDEX IF NOT EXISTS idx_community_members_role ON community_members(role);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger to update communities updated_at
DROP TRIGGER IF EXISTS update_communities_updated_at ON communities;
CREATE TRIGGER update_communities_updated_at BEFORE UPDATE ON communities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER FUNCTIONS FOR AUTO-UPDATING COUNTERS
-- ============================================================================

-- Function to update community members count
CREATE OR REPLACE FUNCTION update_community_members_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE communities
        SET members_count = members_count + 1
        WHERE id = NEW.community_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE communities
        SET members_count = GREATEST(members_count - 1, 0)
        WHERE id = OLD.community_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';

-- Create trigger for community members count
DROP TRIGGER IF EXISTS update_community_members_count_trigger ON community_members;
CREATE TRIGGER update_community_members_count_trigger
    AFTER INSERT OR DELETE ON community_members
    FOR EACH ROW EXECUTE FUNCTION update_community_members_count();

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Created tables:
-- 1. communities - User communities/groups
-- 2. community_members - Membership tracking with roles
--
-- Features:
-- - Community privacy levels (public, private, secret)
-- - Role-based access (owner, admin, moderator, member)
-- - Auto-updating member counts
-- - Optimized indexes for queries
-- - Slug validation (lowercase alphanumeric + hyphens)
-- ============================================================================
