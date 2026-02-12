-- Fix schema_migrations table to match Go application's migration system expectations
-- This script should be run once before migrations
-- The Go app expects: id, filename, executed_at columns

-- Check if schema_migrations table exists and has the wrong structure
DO $$
BEGIN
    -- Check if table exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'schema_migrations') THEN
        -- Check if it has the wrong structure (has 'version' column from golang-migrate instead of 'filename')
        IF EXISTS (
            SELECT FROM information_schema.columns
            WHERE table_name = 'schema_migrations'
            AND column_name = 'version'
        ) THEN
            -- Table exists with golang-migrate structure, drop it
            DROP TABLE schema_migrations CASCADE;
            RAISE NOTICE 'Dropped existing schema_migrations table with golang-migrate structure';
        ELSIF EXISTS (
            SELECT FROM information_schema.columns
            WHERE table_name = 'schema_migrations'
            AND column_name = 'filename'
        ) THEN
            -- Table exists with correct structure, do nothing
            RAISE NOTICE 'schema_migrations table already has correct structure';
            RETURN;
        END IF;
    END IF;

    -- Create the schema_migrations table with the structure expected by Go application
    CREATE TABLE schema_migrations (
        id SERIAL PRIMARY KEY,
        filename VARCHAR(255) UNIQUE NOT NULL,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    RAISE NOTICE 'Created schema_migrations table with Go application structure';
END $$;
