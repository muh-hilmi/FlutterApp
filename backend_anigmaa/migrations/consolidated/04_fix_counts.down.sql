-- Down migration for count fix
-- This operation cannot be easily reversed as it corrects data corruption
-- To "undo", you would need to restore from a pre-migration backup

-- If you need to revert, restore from database backup taken before running this migration
-- Example: psql -U postgres -d anigmaa < backup_before_fix_counts.sql

-- No automatic rollback available for data correction operations
