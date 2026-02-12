-- +migrate Up
-- Alter event_qna table to add new columns
-- Note: user_id is kept as-is for backward compatibility (represents asked_by)
ALTER TABLE event_qna
ADD COLUMN IF NOT EXISTS upvotes INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS asked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Update answered_by to answered_by_id for consistency (if column exists with different name)
-- Note: answered_by already exists, so we keep it as-is

-- Create qna_upvotes table for tracking upvotes
CREATE TABLE IF NOT EXISTS qna_upvotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    qna_id UUID NOT NULL REFERENCES event_qna(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,  -- References users(id)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(qna_id, user_id)
);

-- Create indexes if not exists
CREATE INDEX IF NOT EXISTS idx_event_qna_upvotes ON event_qna(upvotes DESC);
CREATE INDEX IF NOT EXISTS idx_qna_upvotes_qna_id ON qna_upvotes(qna_id);
CREATE INDEX IF NOT EXISTS idx_qna_upvotes_user_id ON qna_upvotes(user_id);

-- +migrate Down
-- Drop indexes
DROP INDEX IF EXISTS idx_qna_upvotes_user_id;
DROP INDEX IF EXISTS idx_qna_upvotes_qna_id;
DROP INDEX IF EXISTS idx_event_qna_upvotes;

-- Drop columns
ALTER TABLE event_qna DROP COLUMN IF EXISTS upvotes;
ALTER TABLE event_qna DROP COLUMN IF EXISTS asked_at;

-- Drop tables
DROP TABLE IF EXISTS qna_upvotes;
