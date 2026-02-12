-- ============================================================================
-- ROLLBACK: COMMUNITY SERVICE
-- ============================================================================

-- Drop triggers
DROP TRIGGER IF EXISTS update_communities_updated_at ON communities;
DROP TRIGGER IF EXISTS update_community_members_count_trigger ON community_members;

-- Drop functions
DROP FUNCTION IF EXISTS update_community_members_count();

-- Drop tables
DROP TABLE IF EXISTS community_members;
DROP TABLE IF EXISTS communities;

-- Drop enums
DROP TYPE IF EXISTS community_role;
DROP TYPE IF EXISTS community_privacy;
