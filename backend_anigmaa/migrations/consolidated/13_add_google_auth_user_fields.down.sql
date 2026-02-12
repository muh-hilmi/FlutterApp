-- ============================================================================
-- ROLLBACK: Restore username/password (NOT RECOMMENDED - app is Google-only now)
-- ============================================================================
-- This migration rolls back the changes made in 13_add_google_auth_user_fields.up.sql
-- WARNING: This will restore username/password columns but the app no longer supports
-- traditional authentication. Only use this for emergency rollback.
-- ============================================================================

-- Drop new indexes
DROP INDEX IF EXISTS idx_users_interests;
DROP INDEX IF EXISTS idx_users_gender;
DROP INDEX IF EXISTS idx_users_date_of_birth;
DROP INDEX IF EXISTS idx_users_location;

-- Drop new constraints
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_gender_values;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_phone_format;

-- Remove new columns
ALTER TABLE users DROP COLUMN IF EXISTS interests;
ALTER TABLE users DROP COLUMN IF EXISTS location;
ALTER TABLE users DROP COLUMN IF EXISTS gender;
ALTER TABLE users DROP COLUMN IF EXISTS date_of_birth;
ALTER TABLE users DROP COLUMN IF EXISTS phone;

-- Restore username and password_hash columns (nullable to handle existing data)
ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);

-- Add back username constraints
CREATE UNIQUE INDEX IF NOT EXISTS users_username_unique_idx ON users(username) WHERE username IS NOT NULL;
ALTER TABLE users ADD CONSTRAINT users_username_format
    CHECK (username IS NULL OR username ~ '^[a-zA-Z0-9_-]{3,50}$');
