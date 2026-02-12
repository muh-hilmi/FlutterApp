-- ============================================================================
-- ROLLBACK USER SERVICE DATABASE SCHEMA
-- ============================================================================

-- Drop triggers
DROP TRIGGER IF EXISTS update_invites_count_trigger ON invitations;
DROP TRIGGER IF EXISTS update_users_updated_at ON users;

-- Drop functions
DROP FUNCTION IF EXISTS update_invites_count();
DROP FUNCTION IF EXISTS update_posts_count();
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Drop indexes
DROP INDEX IF EXISTS idx_invitations_status;
DROP INDEX IF EXISTS idx_invitations_event;
DROP INDEX IF EXISTS idx_invitations_invitee;
DROP INDEX IF EXISTS idx_invitations_inviter;
DROP INDEX IF EXISTS idx_follows_following;
DROP INDEX IF EXISTS idx_follows_follower;
DROP INDEX IF EXISTS idx_users_username;
DROP INDEX IF EXISTS idx_users_email;

-- Drop tables
DROP TABLE IF EXISTS invitations CASCADE;
DROP TABLE IF EXISTS follows CASCADE;
DROP TABLE IF EXISTS user_privacy CASCADE;
DROP TABLE IF EXISTS user_stats CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS users CASCADE;
