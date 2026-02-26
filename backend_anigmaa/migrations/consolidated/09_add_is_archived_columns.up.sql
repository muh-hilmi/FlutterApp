-- Migration: Add is_archived columns to events and posts tables
-- Description: Soft delete support for events and posts
-- Version: 09

-- Add is_archived column to events table
ALTER TABLE events ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE;

-- Add is_archived column to posts table
ALTER TABLE posts ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE;
