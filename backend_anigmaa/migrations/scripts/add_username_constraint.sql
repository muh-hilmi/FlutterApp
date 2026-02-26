-- Add username format constraint if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_constraint
        WHERE conname = 'users_username_format'
    ) THEN
        ALTER TABLE users
        ADD CONSTRAINT users_username_format
        CHECK (username IS NULL OR username ~ '^[a-zA-Z0-9_-]{3,50}$');
    END IF;
END $$;
