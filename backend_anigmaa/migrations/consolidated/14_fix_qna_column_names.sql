-- +migrate Up
-- Fix QnA table column names to match backend code expectations
-- The backend code expects 'asked_by_id' and 'answered_by_id'
-- but the table has 'user_id' and 'answered_by'

-- Rename user_id to asked_by_id (what the backend expects)
-- Use IF EXISTS to handle already renamed columns
DO $$
BEGIN
    -- Only rename if user_id still exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'event_qna' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE event_qna RENAME COLUMN user_id TO asked_by_id;
    END IF;

    -- Only rename if answered_by still exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'event_qna' AND column_name = 'answered_by'
    ) THEN
        ALTER TABLE event_qna RENAME COLUMN answered_by TO answered_by_id;
    END IF;
END $$;

-- +migrate Down
-- Revert column name changes
DO $$
BEGIN
    -- Only rename back if asked_by_id exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'event_qna' AND column_name = 'asked_by_id'
    ) THEN
        ALTER TABLE event_qna RENAME COLUMN asked_by_id TO user_id;
    END IF;

    -- Only rename back if answered_by_id exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'event_qna' AND column_name = 'answered_by_id'
    ) THEN
        ALTER TABLE event_qna RENAME COLUMN answered_by_id TO answered_by;
    END IF;
END $$;
