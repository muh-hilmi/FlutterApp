-- Rollback: Remove is_archived columns from events and posts tables
-- Description: Rollback soft delete support
-- Version: 09

-- Remove is_archived column from events table
ALTER TABLE events DROP COLUMN IF EXISTS is_archived;

-- Remove is_archived column from posts table
ALTER TABLE posts DROP COLUMN IF EXISTS is_archived;
