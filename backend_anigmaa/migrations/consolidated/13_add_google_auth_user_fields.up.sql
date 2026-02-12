-- ============================================================================
-- MIGRATION: Google Auth Only - Remove username/password, Add Enhanced Profile Fields
-- ============================================================================
-- This migration makes the app Google OAuth only:
-- 1. Drops username and password_hash columns (no traditional auth)
-- 2. Adds essential user profile fields: phone, date_of_birth, gender, location, interests
-- 3. Updates constraints and indexes
-- ============================================================================

-- ============================================================================
-- MODIFY USERS TABLE
-- ============================================================================

-- Drop username and password_hash columns (Google Auth only)
ALTER TABLE users DROP COLUMN IF EXISTS username CASCADE;
ALTER TABLE users DROP COLUMN IF EXISTS password_hash CASCADE;

-- Add new profile fields
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS location VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS interests TEXT[];

-- Add check constraints for new fields (only if they don't exist)
DO $$
BEGIN
    -- Add phone format constraint
    IF NOT EXISTS (
        SELECT FROM pg_constraint WHERE conname = 'users_phone_format'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT users_phone_format
            CHECK (phone IS NULL OR phone ~ '^[0-9]{10,15}$');
    END IF;

    -- Add gender values constraint
    IF NOT EXISTS (
        SELECT FROM pg_constraint WHERE conname = 'users_gender_values'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT users_gender_values
            CHECK (gender IS NULL OR gender IN ('Laki-laki', 'Perempuan', 'Lainnya', 'Prefer not to say'));
    END IF;
END $$;

-- ============================================================================
-- CREATE INDEXES FOR NEW FIELDS
-- ============================================================================

-- Index for location-based queries
CREATE INDEX IF NOT EXISTS idx_users_location ON users(location) WHERE location IS NOT NULL;

-- Index for date of birth (for age-based filtering)
CREATE INDEX IF NOT EXISTS idx_users_date_of_birth ON users(date_of_birth) WHERE date_of_birth IS NOT NULL;

-- Index for gender-based filtering
CREATE INDEX IF NOT EXISTS idx_users_gender ON users(gender) WHERE gender IS NOT NULL;

-- GIN index for interests array (for array search)
CREATE INDEX IF NOT EXISTS idx_users_interests ON users USING GIN(interests) WHERE interests IS NOT NULL;

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Changes made:
-- 1. DROPPED username and password_hash columns (Google Auth only!)
-- 2. Added phone, date_of_birth, gender, location, interests fields
-- 3. Added validation constraints for phone and gender
-- 4. Created indexes for efficient querying on new fields
-- ============================================================================
