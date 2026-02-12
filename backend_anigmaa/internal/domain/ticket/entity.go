package ticket

import (
	"time"

	"github.com/google/uuid"
)

// TransactionStatus represents the status of a payment transaction
type TransactionStatus string

const (
	TransactionPending   TransactionStatus = "pending"
	TransactionSuccess   TransactionStatus = "success"
	TransactionFailed    TransactionStatus = "failed"
	TransactionRefunded  TransactionStatus = "refunded"
	TransactionExpired   TransactionStatus = "expired"
)

// TicketStatus represents the status of a ticket
type TicketStatus string

const (
	StatusPending   TicketStatus = "pending"   // Awaiting payment
	StatusActive    TicketStatus = "active"    // Paid/confirmed
	StatusCancelled TicketStatus = "cancelled" // Cancelled by user or system
	StatusRefunded  TicketStatus = "refunded"  // Payment refunded
	StatusExpired   TicketStatus = "expired"   // Ticket expired
)

// Ticket represents an event ticket
type Ticket struct {
	ID             uuid.UUID    `json:"id" db:"id"`
	UserID         uuid.UUID    `json:"user_id" db:"user_id"`
	EventID        uuid.UUID    `json:"event_id" db:"event_id"`
	AttendanceCode string       `json:"attendance_code" db:"attendance_code"`
	PricePaid      float64      `json:"price_paid" db:"price_paid"`
	PurchasedAt    time.Time    `json:"purchased_at" db:"purchased_at"`
	IsCheckedIn    bool         `json:"is_checked_in" db:"is_checked_in"`
	CheckedInAt    *time.Time   `json:"checked_in_at,omitempty" db:"checked_in_at"`
	Status         TicketStatus `json:"status" db:"status"`
}

// Order represents a payment transaction for tickets
type Order struct {
	ID              uuid.UUID  `json:"id" db:"id"`
	UserID          uuid.UUID  `json:"user_id" db:"user_id"`
	EventID         uuid.UUID  `json:"event_id" db:"event_id"`
	TotalAmount     int64      `json:"total_amount" db:"total_amount"`
	Status          string     `json:"status" db:"status"` // PENDING, PAID, FAILED
	MidtransOrderID *string    `json:"midtrans_order_id,omitempty" db:"midtrans_order_id"`
	SnapToken       *string    `json:"snap_token,omitempty" db:"snap_token"`
	CreatedAt       time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at" db:"updated_at"`
}

// TicketWithDetails includes additional ticket information
type TicketWithDetails struct {
	Ticket
	EventTitle     string    `json:"event_title" db:"event_title"`
	EventStartTime time.Time `json:"event_start_time" db:"event_start_time"`
	EventLocation  string    `json:"event_location" db:"event_location"`
	UserName       string    `json:"user_name" db:"user_name"`
	UserEmail      string    `json:"user_email" db:"user_email"`
	UserAvatarURL  *string   `json:"user_avatar_url,omitempty" db:"user_avatar_url"`
	QRCode         *string   `json:"qr_code,omitempty" db:"qr_code"`
}

// PurchaseTicketRequest represents ticket purchase data
type PurchaseTicketRequest struct {
	EventID       uuid.UUID `json:"event_id" binding:"required"`
	PaymentMethod *string   `json:"payment_method,omitempty"` // null for free events
}

// CheckInRequest represents check-in data
type CheckInRequest struct {
	AttendanceCode string `json:"attendance_code" binding:"required,len=4"`
}

// PurchaseTicketResponse represents the response after purchasing a ticket
type PurchaseTicketResponse struct {
	Ticket       *Ticket `json:"ticket"`
	PaymentToken *string `json:"payment_token,omitempty"` // Snap token for paid events
	PaymentURL   *string `json:"payment_url,omitempty"`   // Redirect URL for payment
	QRCode       *string `json:"qr_code,omitempty"`       // Base64-encoded QR code PNG
}

// TicketTransaction represents a payment transaction for a ticket
type TicketTransaction struct {
	ID             uuid.UUID        `json:"id" db:"id"`
	TicketID       uuid.UUID        `json:"ticket_id" db:"ticket_id"`
	TransactionID  string           `json:"transaction_id" db:"transaction_id"` // Midtrans transaction ID
	Amount         float64          `json:"amount" db:"amount"`
	PaymentMethod  string           `json:"payment_method" db:"payment_method"`
	Status         TransactionStatus `json:"status" db:"status"`
	CreatedAt      time.Time        `json:"created_at" db:"created_at"`
	CompletedAt    *time.Time       `json:"completed_at,omitempty" db:"completed_at"`
}

// Business logic methods
func (t *Ticket) IsFree() bool {
	return t.PricePaid == 0
}

func (t *Ticket) IsValid() bool {
	return t.Status == StatusActive && !t.IsCheckedIn
}

func (t *Ticket) CanBeRefunded() bool {
	return t.Status == StatusActive && !t.IsCheckedIn
}
