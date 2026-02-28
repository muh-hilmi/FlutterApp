-- ============================================================================
-- P0 FIX: Add 'pending' status to ticket_status enum
-- ============================================================================
-- The Go domain defines StatusPending = "pending" for paid tickets awaiting
-- payment confirmation, but the DB enum was missing this value, causing every
-- paid ticket purchase to crash with:
--   ERROR: invalid input value for enum ticket_status: "pending"
-- ============================================================================

ALTER TYPE ticket_status ADD VALUE IF NOT EXISTS 'pending';
