package ticket

import (
	"context"
	"time"

	"github.com/google/uuid"
)

// Repository defines the interface for ticket data access
type Repository interface {
	// AtomicPurchase creates a ticket inside a DB transaction that:
	//   1. Locks the event row (SELECT … FOR UPDATE)
	//   2. Verifies capacity (returns ErrEventFull if sold out)
	//   3. INSERTs the ticket
	//   4. Atomically increments events.tickets_sold
	// This prevents overselling under any concurrency level.
	AtomicPurchase(ctx context.Context, ticket *Ticket) error

	// DecrementTicketsSold decrements events.tickets_sold by 1 (floor 0).
	// Must be called whenever a pending ticket is cancelled or expired.
	DecrementTicketsSold(ctx context.Context, eventID uuid.UUID) error

	// ExpirePendingTickets sets status='expired' on all tickets whose status
	// is still 'pending' and whose purchased_at is older than olderThan.
	// Returns the affected tickets so callers can decrement tickets_sold.
	ExpirePendingTickets(ctx context.Context, olderThan time.Time) ([]Ticket, error)

	// Ticket CRUD
	Create(ctx context.Context, ticket *Ticket) error
	GetByID(ctx context.Context, ticketID uuid.UUID) (*Ticket, error)
	GetWithDetails(ctx context.Context, ticketID uuid.UUID) (*TicketWithDetails, error)
	Update(ctx context.Context, ticket *Ticket) error
	Delete(ctx context.Context, ticketID uuid.UUID) error

	// Ticket queries
	GetByUser(ctx context.Context, userID uuid.UUID, limit, offset int) ([]TicketWithDetails, error)
	GetByEvent(ctx context.Context, eventID uuid.UUID, limit, offset int) ([]TicketWithDetails, error)
	GetByAttendanceCode(ctx context.Context, code string) (*Ticket, error)
	GetUserTicketForEvent(ctx context.Context, userID, eventID uuid.UUID) (*Ticket, error)

	// Counting for pagination
	CountUserTickets(ctx context.Context, userID uuid.UUID) (int, error)
	CountEventTickets(ctx context.Context, eventID uuid.UUID) (int, error)

	// Check-in
	CheckIn(ctx context.Context, ticketID uuid.UUID) error
	GetCheckedInCount(ctx context.Context, eventID uuid.UUID) (int, error)

	// Transaction
	CreateTransaction(ctx context.Context, transaction *TicketTransaction) error
	GetTransaction(ctx context.Context, transactionID string) (*TicketTransaction, error)
	UpdateTransactionStatus(ctx context.Context, transactionID string, status TransactionStatus) error

	// Analytics - get tickets and transactions for analytics
	GetByEventID(ctx context.Context, eventID uuid.UUID) ([]Ticket, error)
	GetTransactionsByTicketID(ctx context.Context, ticketID uuid.UUID) ([]TicketTransaction, error)
}
