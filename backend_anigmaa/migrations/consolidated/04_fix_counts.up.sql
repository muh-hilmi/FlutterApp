-- Fix all counts by recalculating from actual data
-- This migration corrects stored counts that may have been doubled or otherwise corrupted

-- Recalculate likes_count from actual likes table
-- Recalculate comments_count from actual comments table
-- Recalculate reposts_count from actual reposts table
-- Recalculate shares_count from actual shares table

UPDATE posts p
SET
    likes_count = COALESCE((SELECT COUNT(*) FROM likes WHERE likeable_type = 'post' AND likeable_id = p.id), 0),
    comments_count = COALESCE((SELECT COUNT(*) FROM comments WHERE post_id = p.id), 0),
    reposts_count = COALESCE((SELECT COUNT(*) FROM reposts WHERE post_id = p.id), 0),
    shares_count = COALESCE((SELECT COUNT(*) FROM shares WHERE post_id = p.id), 0);

-- Verify the fix (optional, for debugging)
-- The following query can be run manually to verify counts are correct:
-- SELECT id, likes_count, comments_count, reposts_count, shares_count
-- FROM posts
-- ORDER BY id;
