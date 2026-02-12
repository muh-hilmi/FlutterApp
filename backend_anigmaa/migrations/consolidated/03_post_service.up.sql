-- ============================================================================
-- POST SERVICE DATABASE SCHEMA
-- ============================================================================
-- This schema contains all post and interaction-related tables:
-- - posts: Main posts/feeds
-- - post_images: Post image attachments
-- - comments: Post comments
-- - likes: Likes for posts and comments
-- - reposts: Repost/share functionality
-- - bookmarks: Saved posts
-- - shares: External sharing tracking
-- ============================================================================

-- ============================================================================
-- ENUMS
-- ============================================================================

-- Create ENUM types only if they don't exist
DO $$
BEGIN
    -- Post type
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'post_type') THEN
        CREATE TYPE post_type AS ENUM ('text', 'text_with_images', 'text_with_event', 'poll', 'repost');
    END IF;

    -- Post visibility
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'post_visibility') THEN
        CREATE TYPE post_visibility AS ENUM ('public', 'followers', 'private');
    END IF;

    -- Likeable type
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'likeable_type') THEN
        CREATE TYPE likeable_type AS ENUM ('post', 'comment');
    END IF;
END $$;

-- ============================================================================
-- POSTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID NOT NULL,  -- References users(id) from user service
    content TEXT NOT NULL,
    type post_type NOT NULL,
    attached_event_id UUID,  -- References events(id) from event service
    original_post_id UUID REFERENCES posts(id) ON DELETE SET NULL,
    visibility post_visibility DEFAULT 'public',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    reposts_count INTEGER DEFAULT 0,
    shares_count INTEGER DEFAULT 0
);

-- ============================================================================
-- POST IMAGES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS post_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    order_index INTEGER NOT NULL DEFAULT 0
);

-- ============================================================================
-- COMMENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL,  -- References users(id) from user service
    parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    likes_count INTEGER DEFAULT 0
);

-- ============================================================================
-- LIKES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,  -- References users(id) from user service
    likeable_type likeable_type NOT NULL,
    likeable_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, likeable_type, likeable_id)
);

-- ============================================================================
-- REPOSTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS reposts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,  -- References users(id) from user service
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    quote_content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, post_id)
);

-- ============================================================================
-- BOOKMARKS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,  -- References users(id) from user service
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, post_id)
);

-- ============================================================================
-- SHARES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS shares (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,  -- References users(id) from user service
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    platform VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Posts indexes
CREATE INDEX IF NOT EXISTS idx_posts_author ON posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_type ON posts(type);
CREATE INDEX IF NOT EXISTS idx_posts_visibility ON posts(visibility);
CREATE INDEX IF NOT EXISTS idx_posts_attached_event ON posts(attached_event_id);

-- Post images indexes
CREATE INDEX IF NOT EXISTS idx_post_images_post ON post_images(post_id);

-- Comments indexes
CREATE INDEX IF NOT EXISTS idx_comments_post ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_author ON comments(author_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent ON comments(parent_comment_id);

-- Likes indexes
CREATE INDEX IF NOT EXISTS idx_likes_user ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_likeable ON likes(likeable_type, likeable_id);

-- Reposts indexes
CREATE INDEX IF NOT EXISTS idx_reposts_user ON reposts(user_id);
CREATE INDEX IF NOT EXISTS idx_reposts_post ON reposts(post_id);

-- Bookmarks indexes
CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_post ON bookmarks(post_id);

-- Shares indexes
CREATE INDEX IF NOT EXISTS idx_shares_post ON shares(post_id);
CREATE INDEX IF NOT EXISTS idx_shares_user ON shares(user_id);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger to update posts updated_at
DROP TRIGGER IF EXISTS update_posts_updated_at ON posts;
CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update comments updated_at
DROP TRIGGER IF EXISTS update_comments_updated_at ON comments;
CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER FUNCTIONS FOR AUTO-UPDATING COUNTERS
-- ============================================================================

-- Function to update likes count
CREATE OR REPLACE FUNCTION update_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.likeable_type = 'post' THEN
            UPDATE posts SET likes_count = likes_count + 1 WHERE id = NEW.likeable_id;
        ELSIF NEW.likeable_type = 'comment' THEN
            UPDATE comments SET likes_count = likes_count + 1 WHERE id = NEW.likeable_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.likeable_type = 'post' THEN
            UPDATE posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.likeable_id;
        ELSIF OLD.likeable_type = 'comment' THEN
            UPDATE comments SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.likeable_id;
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';

-- Function to update comments count
CREATE OR REPLACE FUNCTION update_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET comments_count = GREATEST(comments_count - 1, 0) WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';

-- Function to update reposts count
CREATE OR REPLACE FUNCTION update_reposts_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET reposts_count = reposts_count + 1 WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET reposts_count = GREATEST(reposts_count - 1, 0) WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';

-- Function to update shares count
CREATE OR REPLACE FUNCTION update_shares_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET shares_count = shares_count + 1 WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET shares_count = GREATEST(shares_count - 1, 0) WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';

-- Create triggers for auto-updating counters
DROP TRIGGER IF EXISTS update_likes_count_trigger ON likes;
CREATE TRIGGER update_likes_count_trigger
    AFTER INSERT OR DELETE ON likes
    FOR EACH ROW EXECUTE FUNCTION update_likes_count();

DROP TRIGGER IF EXISTS update_comments_count_trigger ON comments;
CREATE TRIGGER update_comments_count_trigger
    AFTER INSERT OR DELETE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_comments_count();

DROP TRIGGER IF EXISTS update_reposts_count_trigger ON reposts;
CREATE TRIGGER update_reposts_count_trigger
    AFTER INSERT OR DELETE ON reposts
    FOR EACH ROW EXECUTE FUNCTION update_reposts_count();

DROP TRIGGER IF EXISTS update_shares_count_trigger ON shares;
CREATE TRIGGER update_shares_count_trigger
    AFTER INSERT OR DELETE ON shares
    FOR EACH ROW EXECUTE FUNCTION update_shares_count();

-- Note: The update_posts_count trigger is defined in user_service
-- since it updates user_stats table
DROP TRIGGER IF EXISTS update_posts_count_trigger ON posts;
CREATE TRIGGER update_posts_count_trigger
    AFTER INSERT OR DELETE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_posts_count();

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Created tables:
-- 1. posts - Main posts/feeds with counters
-- 2. post_images - Post image attachments
-- 3. comments - Nested comment support
-- 4. likes - Universal like system for posts and comments
-- 5. reposts - Repost/quote functionality
-- 6. bookmarks - Saved posts
-- 7. shares - External sharing tracking
--
-- Features:
-- - Auto-updating counters via triggers
-- - Support for nested comments
-- - Multiple post types (text, images, events, polls, reposts)
-- - Visibility controls (public, followers, private)
-- - Comprehensive interaction tracking
-- - Optimized indexes for feed queries
-- ============================================================================
