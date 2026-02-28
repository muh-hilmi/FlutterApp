package postgres

import (
	"context"
	"crypto/rand"
	"database/sql"
	"fmt"
	"math/big"
	"time"

	"github.com/anigmaa/backend/internal/domain/ticket"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type ticketRepository struct {
	db *sqlx.DB
}

// NewTicketRepository creates a new ticket repository
func NewTicketRepository(db *sqlx.DB) ticket.Repository {
	return &ticketRepository{db: db}
}

// generateAttendanceCode generates a random 8-character alphanumeric code
func generateAttendanceCode() (string, error) {
	const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Excluded I, O, 0, 1 to avoid confusion
	code := make([]byte, 8)
	for i := range code {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(len(chars))))
		if err != nil {
			return "", err
		}
		code[i] = chars[n.Int64()]
	}
	return string(code), nil
}

// Create creates a new ticket
// Note: This should be called within a transaction if paired with CreateTransaction
func (r *ticketRepository) Create(ctx context.Context, t *ticket.Ticket) error {
	// Generate UUID if not provided
	if t.ID == uuid.Nil {
		t.ID = uuid.New()
	}

	// Generate attendance code if not provided
	if t.AttendanceCode == "" {
		// Try up to 5 times to generate a unique code
		for i := 0; i < 5; i++ {
			code, err := generateAttendanceCode()
			if err != nil {
				return fmt.Errorf("failed to generate attendance code: %w", err)
			}
			t.AttendanceCode = code

			// Check if code already exists
			var exists bool
			checkQuery := `SELECT EXISTS(SELECT 1 FROM tickets WHERE attendance_code = $1)`
			if err := r.db.GetContext(ctx, &exists, checkQuery, code); err != nil {
				return err
			}
			if !exists {
				break
			}
		}
	}

	// Set timestamp
	t.PurchasedAt = time.Now()

	query := `
		INSERT INTO tickets (id, user_id, event_id, attendance_code, price_paid, purchased_at, is_checked_in, status)
		VALUES ($1, $2, $3, $4, $5, $6, FALSE, $7)
	`

	_, err := r.db.ExecContext(ctx, query,
		t.ID, t.UserID, t.EventID, t.AttendanceCode, t.PricePaid, t.PurchasedAt, t.Status,
	)

	return err
}

// GetByID gets a ticket by ID
func (r *ticketRepository) GetByID(ctx context.Context, ticketID uuid.UUID) (*ticket.Ticket, error) {
	query := `
		SELECT id, user_id, event_id, attendance_code, price_paid, purchased_at,
		       is_checked_in, checked_in_at, status
		FROM tickets
		WHERE id = $1
	`

	var t ticket.Ticket
	err := r.db.GetContext(ctx, &t, query, ticketID)
	if err != nil {
		return nil, err
	}

	return &t, nil
}

// GetWithDetails gets a ticket with full details
func (r *ticketRepository) GetWithDetails(ctx context.Context, ticketID uuid.UUID) (*ticket.TicketWithDetails, error) {
	query := `
		SELECT
			t.id, t.user_id, t.event_id, t.attendance_code, t.price_paid, t.purchased_at,
			t.is_checked_in, t.checked_in_at, t.status,
			u.name as user_name, u.email as user_email, u.avatar_url as user_avatar_url,
			e.title as event_title, e.start_time as event_start_time, e.location_name as event_location
		FROM tickets t
		INNER JOIN users u ON t.user_id = u.id
		INNER JOIN events e ON t.event_id = e.id
		WHERE t.id = $1
	`

	var td ticket.TicketWithDetails
	err := r.db.GetContext(ctx, &td, query, ticketID)
	if err != nil {
		return nil, err
	}

	return &td, nil
}

// Update updates a ticket
func (r *ticketRepository) Update(ctx context.Context, t *ticket.Ticket) error {
	query := `
		UPDATE tickets
		SET status = $1, is_checked_in = $2, checked_in_at = $3
		WHERE id = $4
	`

	result, err := r.db.ExecContext(ctx, query, t.Status, t.IsCheckedIn, t.CheckedInAt, t.ID)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return sql.ErrNoRows
	}

	return nil
}

// Delete deletes a ticket
func (r *ticketRepository) Delete(ctx context.Context, ticketID uuid.UUID) error {
	query := `DELETE FROM tickets WHERE id = $1`

	result, err := r.db.ExecContext(ctx, query, ticketID)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return sql.ErrNoRows
	}

	return nil
}

// GetByUser gets tickets for a user
func (r *ticketRepository) GetByUser(ctx context.Context, userID uuid.UUID, limit, offset int) ([]ticket.TicketWithDetails, error) {
	query := `
		SELECT
			t.id, t.user_id, t.event_id, t.attendance_code, t.price_paid, t.purchased_at,
			t.is_checked_in, t.checked_in_at, t.status,
			u.name as user_name, u.email as user_email, u.avatar_url as user_avatar_url,
			e.title as event_title, e.start_time as event_start_time, e.location_name as event_location
		FROM tickets t
		INNER JOIN users u ON t.user_id = u.id
		INNER JOIN events e ON t.event_id = e.id
		WHERE t.user_id = $1
		ORDER BY t.purchased_at DESC
		LIMIT $2 OFFSET $3
	`

	var tickets []ticket.TicketWithDetails
	err := r.db.SelectContext(ctx, &tickets, query, userID, limit, offset)
	if err != nil {
		return nil, err
	}

	if tickets == nil {
		tickets = []ticket.TicketWithDetails{}
	}

	return tickets, nil
}

// GetByEvent gets tickets for an event
func (r *ticketRepository) GetByEvent(ctx context.Context, eventID uuid.UUID, limit, offset int) ([]ticket.TicketWithDetails, error) {
	query := `
		SELECT
			t.id, t.user_id, t.event_id, t.attendance_code, t.price_paid, t.purchased_at,
			t.is_checked_in, t.checked_in_at, t.status,
			u.name as user_name, u.email as user_email, u.avatar_url as user_avatar_url,
			e.title as event_title, e.start_time as event_start_time, e.location_name as event_location
		FROM tickets t
		INNER JOIN users u ON t.user_id = u.id
		INNER JOIN events e ON t.event_id = e.id
		WHERE t.event_id = $1
		ORDER BY t.purchased_at DESC
		LIMIT $2 OFFSET $3
	`

	var tickets []ticket.TicketWithDetails
	err := r.db.SelectContext(ctx, &tickets, query, eventID, limit, offset)
	if err != nil {
		return nil, err
	}

	if tickets == nil {
		tickets = []ticket.TicketWithDetails{}
	}

	return tickets, nil
}

// GetByAttendanceCode gets a ticket by attendance code
func (r *ticketRepository) GetByAttendanceCode(ctx context.Context, code string) (*ticket.Ticket, error) {
	query := `
		SELECT id, user_id, event_id, attendance_code, price_paid, purchased_at,
		       is_checked_in, checked_in_at, status
		FROM tickets
		WHERE attendance_code = $1
	`

	var t ticket.Ticket
	err := r.db.GetContext(ctx, &t, query, code)
	if err != nil {
		return nil, err
	}

	return &t, nil
}

// GetUserTicketForEvent gets a user's ticket for a specific event
func (r *ticketRepository) GetUserTicketForEvent(ctx context.Context, userID, eventID uuid.UUID) (*ticket.Ticket, error) {
	query := `
		SELECT id, user_id, event_id, attendance_code, price_paid, purchased_at,
		       is_checked_in, checked_in_at, status
		FROM tickets
		WHERE user_id = $1 AND event_id = $2
	`

	var t ticket.Ticket
	err := r.db.GetContext(ctx, &t, query, userID, eventID)
	if err != nil {
		return nil, err
	}

	return &t, nil
}

// CheckIn checks in a ticket
func (r *ticketRepository) CheckIn(ctx context.Context, ticketID uuid.UUID) error {
	now := time.Now()
	query := `
		UPDATE tickets
		SET is_checked_in = TRUE, checked_in_at = $1
		WHERE id = $2 AND is_checked_in = FALSE
	`

	result, err := r.db.ExecContext(ctx, query, now, ticketID)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return sql.ErrNoRows // Already checked in or ticket not found
	}

	return nil
}

// GetCheckedInCount gets the count of checked-in tickets for an event
func (r *ticketRepository) GetCheckedInCount(ctx context.Context, eventID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM tickets WHERE event_id = $1 AND is_checked_in = TRUE`

	var count int
	err := r.db.GetContext(ctx, &count, query, eventID)
	if err != nil {
		return 0, err
	}

	return count, nil
}

// CreateTransaction creates a new ticket transaction
func (r *ticketRepository) CreateTransaction(ctx context.Context, transaction *ticket.TicketTransaction) error {
	// Generate UUID if not provided
	if transaction.ID == uuid.Nil {
		transaction.ID = uuid.New()
	}

	// Set timestamp
	transaction.CreatedAt = time.Now()

	query := `
		INSERT INTO ticket_transactions (id, ticket_id, transaction_id, amount, payment_method, status, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`

	_, err := r.db.ExecContext(ctx, query,
		transaction.ID, transaction.TicketID, transaction.TransactionID, transaction.Amount,
		transaction.PaymentMethod, transaction.Status, transaction.CreatedAt,
	)

	return err
}

// GetTransaction gets a transaction by transaction_id (Midtrans ID)
func (r *ticketRepository) GetTransaction(ctx context.Context, transactionID string) (*ticket.TicketTransaction, error) {
	query := `
		SELECT id, ticket_id, transaction_id, amount, payment_method, status, created_at, completed_at
		FROM ticket_transactions
		WHERE transaction_id = $1
	`

	var t ticket.TicketTransaction
	err := r.db.GetContext(ctx, &t, query, transactionID)
	if err != nil {
		return nil, err
	}

	return &t, nil
}

// UpdateTransactionStatus updates a transaction status atomically.
//
// The WHERE clause includes AND status = 'pending' so that if two webhook
// deliveries race, only the first UPDATE wins (rowsAffected = 1) and the
// second gets rowsAffected = 0, returning ticket.ErrAlreadyProcessed.
// This makes the webhook handler idempotent at the database level without
// needing an application-level lock.
func (r *ticketRepository) UpdateTransactionStatus(ctx context.Context, transactionID string, status ticket.TransactionStatus) error {
	now := time.Now()
	var completedAt *time.Time
	if status == ticket.TransactionSuccess || status == ticket.TransactionRefunded {
		completedAt = &now
	}

	result, err := r.db.ExecContext(ctx, `
		UPDATE ticket_transactions
		SET status = $1, completed_at = $2
		WHERE transaction_id = $3
		  AND status = 'pending'
	`, status, completedAt, transactionID)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		// Either the transaction_id doesn't exist, or it was already processed
		// by a concurrent webhook delivery. Return the sentinel so callers can
		// distinguish this case from a genuine not-found.
		return ticket.ErrAlreadyProcessed
	}

	return nil
}

// GetByEventID gets all tickets for an event (for analytics)
func (r *ticketRepository) GetByEventID(ctx context.Context, eventID uuid.UUID) ([]ticket.Ticket, error) {
	query := `
		SELECT id, user_id, event_id, attendance_code, price_paid, purchased_at,
		       is_checked_in, checked_in_at, status
		FROM tickets
		WHERE event_id = $1
		ORDER BY purchased_at DESC
	`

	var tickets []ticket.Ticket
	err := r.db.SelectContext(ctx, &tickets, query, eventID)
	if err != nil {
		return nil, err
	}

	return tickets, nil
}

// GetTransactionsByTicketID gets all transactions for a ticket
func (r *ticketRepository) GetTransactionsByTicketID(ctx context.Context, ticketID uuid.UUID) ([]ticket.TicketTransaction, error) {
	query := `
		SELECT id, ticket_id, transaction_id, amount, payment_method,
		       status, created_at, completed_at
		FROM ticket_transactions
		WHERE ticket_id = $1
		ORDER BY created_at DESC
	`

	var transactions []ticket.TicketTransaction
	err := r.db.SelectContext(ctx, &transactions, query, ticketID)
	if err != nil {
		return nil, err
	}

	return transactions, nil
}

// CountUserTickets counts total tickets for a user
func (r *ticketRepository) CountUserTickets(ctx context.Context, userID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM tickets WHERE user_id = $1`
	var count int
	err := r.db.QueryRowContext(ctx, query, userID).Scan(&count)
	return count, err
}

// CountEventTickets counts total tickets for an event
func (r *ticketRepository) CountEventTickets(ctx context.Context, eventID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM tickets WHERE event_id = $1`
	var count int
	err := r.db.QueryRowContext(ctx, query, eventID).Scan(&count)
	return count, err
}

// AtomicPurchase creates a ticket inside a serialised DB transaction:
//  1. Locks the event row with SELECT … FOR UPDATE (blocks concurrent purchasers)
//  2. Checks capacity — returns ticket.ErrEventFull if sold out
//  3. INSERTs the ticket
//  4. Increments events.tickets_sold atomically in the same transaction
//
// This is the only correct way to sell tickets; the non-transactional Create
// must not be used for ticket purchases.
func (r *ticketRepository) AtomicPurchase(ctx context.Context, t *ticket.Ticket) error {
	if t.ID == uuid.Nil {
		t.ID = uuid.New()
	}

	if t.AttendanceCode == "" {
		code, err := generateAttendanceCode()
		if err != nil {
			return fmt.Errorf("failed to generate attendance code: %w", err)
		}
		t.AttendanceCode = code
	}

	t.PurchasedAt = time.Now()

	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback() //nolint:errcheck

	// Lock the event row so no other goroutine/instance can read-then-write
	// the capacity counter until this transaction commits or rolls back.
	var maxAttendees, ticketsSold int
	err = tx.QueryRowContext(ctx,
		`SELECT max_attendees, tickets_sold FROM events WHERE id = $1 FOR UPDATE`,
		t.EventID,
	).Scan(&maxAttendees, &ticketsSold)
	if err != nil {
		return fmt.Errorf("failed to lock event row: %w", err)
	}

	if ticketsSold >= maxAttendees {
		return ticket.ErrEventFull
	}

	// Insert the ticket.
	_, err = tx.ExecContext(ctx, `
		INSERT INTO tickets (id, user_id, event_id, attendance_code, price_paid, purchased_at, is_checked_in, status)
		VALUES ($1, $2, $3, $4, $5, $6, FALSE, $7)
	`, t.ID, t.UserID, t.EventID, t.AttendanceCode, t.PricePaid, t.PurchasedAt, t.Status)
	if err != nil {
		return fmt.Errorf("failed to insert ticket: %w", err)
	}

	// Increment the denormalized counter inside the same transaction.
	_, err = tx.ExecContext(ctx,
		`UPDATE events SET tickets_sold = tickets_sold + 1 WHERE id = $1`,
		t.EventID,
	)
	if err != nil {
		return fmt.Errorf("failed to increment tickets_sold: %w", err)
	}

	return tx.Commit()
}

// DecrementTicketsSold decrements events.tickets_sold by 1 (floor 0).
// Call this whenever a pending ticket is cancelled, failed, or expired so
// the capacity counter stays in sync with actual sellable spots.
func (r *ticketRepository) DecrementTicketsSold(ctx context.Context, eventID uuid.UUID) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE events SET tickets_sold = GREATEST(tickets_sold - 1, 0) WHERE id = $1`,
		eventID,
	)
	return err
}

// ExpirePendingTickets bulk-expires all tickets that are still 'pending' and
// were purchased before olderThan (i.e. the Midtrans snap token has lapsed).
// Returns the affected tickets so the caller can decrement tickets_sold.
func (r *ticketRepository) ExpirePendingTickets(ctx context.Context, olderThan time.Time) ([]ticket.Ticket, error) {
	rows, err := r.db.QueryContext(ctx, `
		UPDATE tickets
		SET status = 'expired'
		WHERE status = 'pending'
		  AND purchased_at < $1
		RETURNING id, user_id, event_id, attendance_code, price_paid, purchased_at,
		          is_checked_in, checked_in_at, status
	`, olderThan)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tickets []ticket.Ticket
	for rows.Next() {
		var t ticket.Ticket
		if err := rows.Scan(
			&t.ID, &t.UserID, &t.EventID, &t.AttendanceCode,
			&t.PricePaid, &t.PurchasedAt, &t.IsCheckedIn, &t.CheckedInAt, &t.Status,
		); err != nil {
			return nil, err
		}
		tickets = append(tickets, t)
	}
	return tickets, rows.Err()
}
