-- ============================================================================
-- ROLLBACK POST SERVICE DATABASE SCHEMA
-- ============================================================================

-- Drop triggers
DROP TRIGGER IF EXISTS update_posts_count_trigger ON posts;
DROP TRIGGER IF EXISTS update_shares_count_trigger ON shares;
DROP TRIGGER IF EXISTS update_reposts_count_trigger ON reposts;
DROP TRIGGER IF EXISTS update_comments_count_trigger ON comments;
DROP TRIGGER IF EXISTS update_likes_count_trigger ON likes;
DROP TRIGGER IF EXISTS update_comments_updated_at ON comments;
DROP TRIGGER IF EXISTS update_posts_updated_at ON posts;

-- Drop functions
DROP FUNCTION IF EXISTS update_shares_count();
DROP FUNCTION IF EXISTS update_reposts_count();
DROP FUNCTION IF EXISTS update_comments_count();
DROP FUNCTION IF EXISTS update_likes_count();

-- Drop indexes
DROP INDEX IF EXISTS idx_shares_user;
DROP INDEX IF EXISTS idx_shares_post;
DROP INDEX IF EXISTS idx_bookmarks_post;
DROP INDEX IF EXISTS idx_bookmarks_user;
DROP INDEX IF EXISTS idx_reposts_post;
DROP INDEX IF EXISTS idx_reposts_user;
DROP INDEX IF EXISTS idx_likes_likeable;
DROP INDEX IF EXISTS idx_likes_user;
DROP INDEX IF EXISTS idx_comments_parent;
DROP INDEX IF EXISTS idx_comments_author;
DROP INDEX IF EXISTS idx_comments_post;
DROP INDEX IF EXISTS idx_post_images_post;
DROP INDEX IF EXISTS idx_posts_attached_event;
DROP INDEX IF EXISTS idx_posts_visibility;
DROP INDEX IF EXISTS idx_posts_type;
DROP INDEX IF EXISTS idx_posts_created_at;
DROP INDEX IF EXISTS idx_posts_author;

-- Drop tables
DROP TABLE IF EXISTS shares CASCADE;
DROP TABLE IF EXISTS bookmarks CASCADE;
DROP TABLE IF EXISTS reposts CASCADE;
DROP TABLE IF EXISTS likes CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS post_images CASCADE;
DROP TABLE IF EXISTS posts CASCADE;

-- Drop types
DROP TYPE IF EXISTS likeable_type;
DROP TYPE IF EXISTS post_visibility;
DROP TYPE IF EXISTS post_type;
