package ticket

import (
	"context"

	"github.com/google/uuid"
)

// Repository defines the interface for ticket data access
type Repository interface {
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
