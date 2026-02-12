-- ============================================================================
-- ROLLBACK TICKET SERVICE DATABASE SCHEMA
-- ============================================================================

-- Drop indexes
DROP INDEX IF EXISTS idx_ticket_transactions_status;
DROP INDEX IF EXISTS idx_ticket_transactions_transaction_id;
DROP INDEX IF EXISTS idx_ticket_transactions_ticket;
DROP INDEX IF EXISTS idx_tickets_status;
DROP INDEX IF EXISTS idx_tickets_attendance_code;
DROP INDEX IF EXISTS idx_tickets_event;
DROP INDEX IF EXISTS idx_tickets_user;

-- Drop tables
DROP TABLE IF EXISTS ticket_transactions CASCADE;
DROP TABLE IF EXISTS tickets CASCADE;

-- Drop types
DROP TYPE IF EXISTS transaction_status;
DROP TYPE IF EXISTS ticket_status;
