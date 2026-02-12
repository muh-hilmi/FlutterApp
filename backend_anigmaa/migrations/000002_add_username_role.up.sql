-- Add missing username and role columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user';

-- Create unique index on username after adding data
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username ON users(username) WHERE username IS NOT NULL;

-- Update existing users to have a username (generate from email)
UPDATE users
SET username = SUBSTRING(email FROM 1 FOR POSITION('@' IN email) - 1),
    role = COALESCE(role, 'user')
WHERE username IS NULL OR username = '';
