-- ============================================================================
-- TICKET SERVICE DATABASE SCHEMA
-- ============================================================================
-- This schema contains all ticketing and payment-related tables:
-- - tickets: Event tickets
-- - ticket_transactions: Payment transactions
-- ============================================================================

-- ============================================================================
-- ENUMS
-- ============================================================================

-- Create ENUM types only if they don't exist
DO $$
BEGIN
    -- Ticket status
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ticket_status') THEN
        CREATE TYPE ticket_status AS ENUM ('active', 'cancelled', 'refunded', 'expired');
    END IF;

    -- Transaction status
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'transaction_status') THEN
        CREATE TYPE transaction_status AS ENUM ('pending', 'success', 'failed', 'refunded');
    END IF;
END $$;

-- ============================================================================
-- TICKETS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,  -- References users(id) from user service
    event_id UUID NOT NULL,  -- References events(id) from event service
    attendance_code VARCHAR(4) UNIQUE NOT NULL,
    price_paid DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (price_paid >= 0),
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_checked_in BOOLEAN DEFAULT FALSE,
    checked_in_at TIMESTAMP WITH TIME ZONE,
    status ticket_status DEFAULT 'active',
    UNIQUE(user_id, event_id)
);

-- ============================================================================
-- TICKET TRANSACTIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS ticket_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    transaction_id VARCHAR(255) UNIQUE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount >= 0),
    payment_method VARCHAR(50) NOT NULL,
    status transaction_status DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Tickets indexes
CREATE INDEX IF NOT EXISTS idx_tickets_user ON tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_tickets_event ON tickets(event_id);
CREATE INDEX IF NOT EXISTS idx_tickets_attendance_code ON tickets(attendance_code);
CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);

-- Ticket transactions indexes
CREATE INDEX IF NOT EXISTS idx_ticket_transactions_ticket ON ticket_transactions(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_transactions_transaction_id ON ticket_transactions(transaction_id);
CREATE INDEX IF NOT EXISTS idx_ticket_transactions_status ON ticket_transactions(status);

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Created tables:
-- 1. tickets - Event tickets with check-in tracking
-- 2. ticket_transactions - Payment transaction records
--
-- Features:
-- - Unique attendance codes for check-in
-- - Transaction status tracking
-- - Support for refunds and cancellations
-- - Payment method tracking
-- - One ticket per user per event constraint
-- ============================================================================
