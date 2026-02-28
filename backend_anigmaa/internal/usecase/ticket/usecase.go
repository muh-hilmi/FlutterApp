package ticket

import (
	"context"
	"errors"
	"fmt"
	"log"
	"time"

	"github.com/anigmaa/backend/internal/domain/event"
	"github.com/anigmaa/backend/internal/domain/ticket"
	"github.com/anigmaa/backend/internal/domain/user"
	"github.com/anigmaa/backend/internal/infrastructure/payment"
	"github.com/anigmaa/backend/pkg/qrcode"
	"github.com/anigmaa/backend/pkg/utils"
	"github.com/google/uuid"
)

var (
	ErrTicketNotFound        = errors.New("ticket not found")
	ErrEventNotFound         = errors.New("event not found")
	ErrEventFull             = ticket.ErrEventFull // proxy to domain sentinel
	ErrAlreadyPurchased      = errors.New("already purchased ticket for this event")
	ErrInvalidAttendanceCode = errors.New("invalid attendance code")
	ErrAlreadyCheckedIn      = errors.New("ticket already checked in")
	ErrTicketNotActive       = errors.New("ticket is not active")
	ErrCannotRefund          = errors.New("ticket cannot be refunded")
	ErrEventStarted          = errors.New("event has already started")
	ErrUnauthorized          = errors.New("unauthorized")
)

// Usecase handles ticket business logic
type Usecase struct {
	ticketRepo     ticket.Repository
	eventRepo      event.Repository
	userRepo       user.Repository
	midtransClient *payment.MidtransClient
}

// NewUsecase creates a new ticket usecase
func NewUsecase(ticketRepo ticket.Repository, eventRepo event.Repository, userRepo user.Repository, midtransClient *payment.MidtransClient) *Usecase {
	return &Usecase{
		ticketRepo:     ticketRepo,
		eventRepo:      eventRepo,
		userRepo:       userRepo,
		midtransClient: midtransClient,
	}
}

// PurchaseTicket purchases a ticket for an event.
//
// Concurrency safety: stock check and ticket insertion are performed inside a
// single DB transaction with a row-level lock (SELECT … FOR UPDATE) via
// AtomicPurchase. This prevents overselling regardless of concurrent load.
func (uc *Usecase) PurchaseTicket(ctx context.Context, userID uuid.UUID, req *ticket.PurchaseTicketRequest) (*ticket.PurchaseTicketResponse, error) {
	// Get event details (read-only; the authoritative capacity check happens
	// inside AtomicPurchase under a row lock).
	evt, err := uc.eventRepo.GetByID(ctx, req.EventID)
	if err != nil {
		return nil, ErrEventNotFound
	}

	// Reject immediately if the event is visibly full — this is a fast-path
	// optimisation only; the real enforcement is inside AtomicPurchase.
	if evt.IsFull() {
		return nil, ErrEventFull
	}

	// Reject if user already holds a ticket for this event.
	existingTicket, err := uc.ticketRepo.GetUserTicketForEvent(ctx, userID, req.EventID)
	if err == nil && existingTicket != nil {
		return nil, ErrAlreadyPurchased
	}

	// Verify user exists.
	usr, err := uc.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, errors.New("user not found")
	}

	// Determine price and initial status.
	pricePaid := 0.0
	if !evt.IsFree && evt.Price != nil {
		pricePaid = *evt.Price
	}

	ticketStatus := ticket.StatusActive
	if !evt.IsFree && pricePaid > 0 {
		ticketStatus = ticket.StatusPending // awaiting payment confirmation
	}

	// Build the ticket record. AtomicPurchase will generate the attendance
	// code and set PurchasedAt inside the transaction.
	now := time.Now()
	newTicket := &ticket.Ticket{
		ID:          uuid.New(),
		UserID:      userID,
		EventID:     req.EventID,
		PricePaid:   pricePaid,
		PurchasedAt: now,
		IsCheckedIn: false,
		Status:      ticketStatus,
	}

	// --- ATOMIC INSERT: lock event row, check capacity, insert ticket,
	// increment events.tickets_sold — all in one transaction. ---
	if err := uc.ticketRepo.AtomicPurchase(ctx, newTicket); err != nil {
		if errors.Is(err, ticket.ErrEventFull) {
			return nil, ErrEventFull
		}
		return nil, err
	}

	// Prepare response.
	response := &ticket.PurchaseTicketResponse{
		Ticket: newTicket,
	}

	// For paid events: create a Midtrans Snap token so the user can pay.
	if !evt.IsFree && pricePaid > 0 {
		orderID := payment.GenerateOrderID(newTicket.ID.String())

		snapReq := &payment.SnapRequest{
			TransactionDetails: payment.TransactionDetails{
				OrderID:     orderID,
				GrossAmount: pricePaid,
			},
			CustomerDetails: payment.CustomerDetails{
				FirstName: usr.Name,
				Email:     usr.Email,
			},
			ItemDetails: []payment.ItemDetail{
				{
					ID:       evt.ID.String(),
					Name:     evt.Title,
					Price:    pricePaid,
					Quantity: 1,
				},
			},
		}

		snapResp, err := uc.midtransClient.CreateSnapToken(ctx, snapReq)
		if err != nil {
			// Roll back: delete the ticket and restore the counter.
			_ = uc.ticketRepo.Delete(ctx, newTicket.ID)
			_ = uc.ticketRepo.DecrementTicketsSold(ctx, newTicket.EventID)
			return nil, errors.New("failed to create payment: " + err.Error())
		}

		// Record the pending transaction.
		transaction := &ticket.TicketTransaction{
			ID:            uuid.New(),
			TicketID:      newTicket.ID,
			TransactionID: orderID,
			Amount:        pricePaid,
			PaymentMethod: "midtrans",
			Status:        ticket.TransactionPending,
			CreatedAt:     now,
		}
		if req.PaymentMethod != nil {
			transaction.PaymentMethod = *req.PaymentMethod
		}

		if err := uc.ticketRepo.CreateTransaction(ctx, transaction); err != nil {
			_ = uc.ticketRepo.Delete(ctx, newTicket.ID)
			_ = uc.ticketRepo.DecrementTicketsSold(ctx, newTicket.EventID)
			return nil, errors.New("failed to create transaction: " + err.Error())
		}

		response.PaymentToken = &snapResp.Token
		response.PaymentURL = &snapResp.RedirectURL
		// QR is NOT generated here — ticket is pending and not yet valid.
		// It will be available once the webhook confirms payment.
		return response, nil
	}

	// Free event: ticket is immediately active — register attendee and issue QR.
	attendee := &event.EventAttendee{
		ID:       uuid.New(),
		EventID:  req.EventID,
		UserID:   userID,
		JoinedAt: now,
		Status:   event.AttendeeConfirmed,
	}
	if err := uc.eventRepo.Join(ctx, attendee); err != nil {
		log.Printf("[TicketUsecase] failed to join event attendees: %v", err)
	}
	if err := uc.userRepo.IncrementEventsAttended(ctx, userID); err != nil {
		log.Printf("[TicketUsecase] failed to increment events_attended: %v", err)
	}

	qrCode, err := qrcode.GenerateTicketQR(newTicket.ID, newTicket.EventID, newTicket.UserID, newTicket.AttendanceCode)
	if err == nil {
		response.QRCode = &qrCode
	}

	return response, nil
}

// GetTicketByID gets a ticket by ID
func (uc *Usecase) GetTicketByID(ctx context.Context, ticketID uuid.UUID) (*ticket.Ticket, error) {
	t, err := uc.ticketRepo.GetByID(ctx, ticketID)
	if err != nil {
		return nil, ErrTicketNotFound
	}
	return t, nil
}

// GetTicketWithDetails gets a ticket with details
func (uc *Usecase) GetTicketWithDetails(ctx context.Context, ticketID, userID uuid.UUID) (*ticket.TicketWithDetails, error) {
	t, err := uc.ticketRepo.GetWithDetails(ctx, ticketID)
	if err != nil {
		return nil, ErrTicketNotFound
	}

	if t.UserID != userID {
		return nil, ErrUnauthorized
	}

	// Only generate QR for active (paid/confirmed) tickets.
	if t.Status == ticket.StatusActive {
		qrCode, err := qrcode.GenerateTicketQR(t.ID, t.EventID, t.UserID, t.AttendanceCode)
		if err == nil {
			t.QRCode = &qrCode
		}
	}

	return t, nil
}

// GetUserTickets gets all tickets for a user
func (uc *Usecase) GetUserTickets(ctx context.Context, userID uuid.UUID, limit, offset int) ([]ticket.TicketWithDetails, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	tickets, err := uc.ticketRepo.GetByUser(ctx, userID, limit, offset)
	if err != nil {
		return nil, err
	}

	for i := range tickets {
		if tickets[i].Status == ticket.StatusActive {
			qrCode, err := qrcode.GenerateTicketQR(tickets[i].ID, tickets[i].EventID, tickets[i].UserID, tickets[i].AttendanceCode)
			if err == nil {
				tickets[i].QRCode = &qrCode
			}
		}
	}

	return tickets, nil
}

// CountUserTickets counts total tickets for a user
func (uc *Usecase) CountUserTickets(ctx context.Context, userID uuid.UUID) (int, error) {
	return uc.ticketRepo.CountUserTickets(ctx, userID)
}

// CountEventTickets counts total tickets for an event
func (uc *Usecase) CountEventTickets(ctx context.Context, eventID uuid.UUID) (int, error) {
	return uc.ticketRepo.CountEventTickets(ctx, eventID)
}

// GetTicketsByEvent gets tickets for an event (public endpoint - no auth required)
func (uc *Usecase) GetTicketsByEvent(ctx context.Context, eventID uuid.UUID, limit, offset int) ([]ticket.TicketWithDetails, error) {
	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}

	return uc.ticketRepo.GetByEvent(ctx, eventID, limit, offset)
}

// GetEventTickets gets all tickets for an event (host only)
func (uc *Usecase) GetEventTickets(ctx context.Context, eventID, requestingUserID uuid.UUID, limit, offset int) ([]ticket.TicketWithDetails, error) {
	evt, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return nil, ErrEventNotFound
	}

	if evt.HostID != requestingUserID {
		return nil, ErrUnauthorized
	}

	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}

	tickets, err := uc.ticketRepo.GetByEvent(ctx, eventID, limit, offset)
	if err != nil {
		return nil, err
	}

	for i := range tickets {
		if tickets[i].Status == ticket.StatusActive {
			qrCode, err := qrcode.GenerateTicketQR(tickets[i].ID, tickets[i].EventID, tickets[i].UserID, tickets[i].AttendanceCode)
			if err == nil {
				tickets[i].QRCode = &qrCode
			}
		}
	}

	return tickets, nil
}

// CheckIn checks in a ticket using attendance code
func (uc *Usecase) CheckIn(ctx context.Context, eventID uuid.UUID, req *ticket.CheckInRequest) (*ticket.Ticket, error) {
	if !utils.ValidateAttendanceCode(req.AttendanceCode) {
		return nil, ErrInvalidAttendanceCode
	}

	t, err := uc.ticketRepo.GetByAttendanceCode(ctx, req.AttendanceCode)
	if err != nil {
		return nil, ErrTicketNotFound
	}

	if t.EventID != eventID {
		return nil, ErrTicketNotFound
	}

	if t.Status != ticket.StatusActive {
		return nil, ErrTicketNotActive
	}

	if t.IsCheckedIn {
		return nil, ErrAlreadyCheckedIn
	}

	if err := uc.ticketRepo.CheckIn(ctx, t.ID); err != nil {
		return nil, err
	}

	updatedTicket, err := uc.ticketRepo.GetByID(ctx, t.ID)
	if err != nil {
		return nil, err
	}

	return updatedTicket, nil
}

// CancelTicket cancels a ticket and issues refund (if applicable)
func (uc *Usecase) CancelTicket(ctx context.Context, ticketID, userID uuid.UUID) error {
	t, err := uc.ticketRepo.GetByID(ctx, ticketID)
	if err != nil {
		return ErrTicketNotFound
	}

	if t.UserID != userID {
		return ErrUnauthorized
	}

	if !t.CanBeRefunded() {
		return ErrCannotRefund
	}

	evt, err := uc.eventRepo.GetByID(ctx, t.EventID)
	if err != nil {
		return ErrEventNotFound
	}

	if evt.IsStartingSoon() || evt.IsOngoing() || evt.IsCompleted() {
		return ErrEventStarted
	}

	t.Status = ticket.StatusCancelled
	if err := uc.ticketRepo.Update(ctx, t); err != nil {
		return err
	}

	// Restore the capacity slot.
	if err := uc.ticketRepo.DecrementTicketsSold(ctx, t.EventID); err != nil {
		log.Printf("[TicketUsecase] failed to decrement tickets_sold on cancel: %v", err)
	}

	if err := uc.eventRepo.Leave(ctx, t.EventID, userID); err != nil {
		log.Printf("[TicketUsecase] failed to leave event: %v", err)
	}

	if t.PricePaid > 0 {
		refundTransaction := &ticket.TicketTransaction{
			ID:            uuid.New(),
			TicketID:      t.ID,
			TransactionID: uuid.New().String(),
			Amount:        t.PricePaid,
			PaymentMethod: "midtrans",
			Status:        ticket.TransactionRefunded,
			CreatedAt:     time.Now(),
		}
		if err := uc.ticketRepo.CreateTransaction(ctx, refundTransaction); err != nil {
			log.Printf("[TicketUsecase] failed to record refund transaction: %v", err)
		}
	}

	return nil
}

// GetCheckedInCount gets the number of checked-in attendees for an event
func (uc *Usecase) GetCheckedInCount(ctx context.Context, eventID, requestingUserID uuid.UUID) (int, error) {
	evt, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return 0, ErrEventNotFound
	}

	if evt.HostID != requestingUserID {
		return 0, ErrUnauthorized
	}

	return uc.ticketRepo.GetCheckedInCount(ctx, eventID)
}

// VerifyTicket verifies a ticket is valid for an event
func (uc *Usecase) VerifyTicket(ctx context.Context, ticketID, eventID uuid.UUID) (bool, error) {
	t, err := uc.ticketRepo.GetByID(ctx, ticketID)
	if err != nil {
		return false, ErrTicketNotFound
	}

	if t.EventID != eventID {
		return false, nil
	}

	return t.IsValid(), nil
}

// GetAttendanceCode gets the attendance code for a ticket (user must own the ticket)
func (uc *Usecase) GetAttendanceCode(ctx context.Context, ticketID, userID uuid.UUID) (string, error) {
	t, err := uc.ticketRepo.GetByID(ctx, ticketID)
	if err != nil {
		return "", ErrTicketNotFound
	}

	if t.UserID != userID {
		return "", ErrUnauthorized
	}

	return t.AttendanceCode, nil
}

// GetTransaction gets a transaction by transaction ID
func (uc *Usecase) GetTransaction(ctx context.Context, transactionID string, userID uuid.UUID) (*ticket.TicketTransaction, error) {
	transaction, err := uc.ticketRepo.GetTransaction(ctx, transactionID)
	if err != nil {
		return nil, errors.New("transaction not found")
	}

	t, err := uc.ticketRepo.GetByID(ctx, transaction.TicketID)
	if err != nil {
		return nil, ErrTicketNotFound
	}

	if t.UserID != userID {
		return nil, ErrUnauthorized
	}

	return transaction, nil
}

// ProcessPaymentCallback handles Midtrans webhook notifications.
//
// On success (settlement/capture):
//   - Validates gross_amount matches DB amount (prevents amount spoofing)
//   - Updates transaction → success  (DB-level idempotency: WHERE status='pending')
//   - Activates ticket (pending → active)
//   - Registers user as confirmed event attendee
//   - Increments user's events_attended stat
//
// On failure (deny/cancel/expire):
//   - Updates transaction → failed
//   - Cancels ticket
//   - Decrements events.tickets_sold to free the capacity slot
//
// grossAmountStr: the raw gross_amount string from the Midtrans webhook payload.
// Pass "" to skip amount validation (e.g. in tests).
func (uc *Usecase) ProcessPaymentCallback(ctx context.Context, transactionID string, status ticket.TransactionStatus, grossAmountStr string) error {
	transaction, err := uc.ticketRepo.GetTransaction(ctx, transactionID)
	if err != nil {
		return errors.New("transaction not found: " + transactionID)
	}

	// Fix 3: Validate that the amount Midtrans reports matches what we stored.
	// This prevents a fraud scenario where a spoofed webhook claims a different
	// amount was paid (e.g. 1 IDR instead of 100,000 IDR).
	if grossAmountStr != "" {
		var webhookAmount float64
		if _, err := fmt.Sscanf(grossAmountStr, "%f", &webhookAmount); err == nil {
			// Allow a 1-cent tolerance for floating-point representation differences.
			diff := webhookAmount - transaction.Amount
			if diff < 0 {
				diff = -diff
			}
			if diff > 0.01 {
				log.Printf("[PaymentCallback] AMOUNT MISMATCH order=%s db=%.2f webhook=%.2f — rejecting",
					transactionID, transaction.Amount, webhookAmount)
				return fmt.Errorf("amount mismatch: expected %.2f got %.2f", transaction.Amount, webhookAmount)
			}
		}
	}

	// Update transaction status with DB-level idempotency guard.
	// UpdateTransactionStatus only updates WHERE status='pending', so if a
	// concurrent webhook already processed this, ErrAlreadyProcessed is returned.
	if err := uc.ticketRepo.UpdateTransactionStatus(ctx, transactionID, status); err != nil {
		if errors.Is(err, ticket.ErrAlreadyProcessed) {
			log.Printf("[PaymentCallback] duplicate webhook for %s — skipping (already processed)", transactionID)
			return nil
		}
		return err
	}

	t, err := uc.ticketRepo.GetByID(ctx, transaction.TicketID)
	if err != nil {
		return ErrTicketNotFound
	}

	switch status {
	case ticket.TransactionSuccess:
		// Activate the ticket.
		t.Status = ticket.StatusActive
		if err := uc.ticketRepo.Update(ctx, t); err != nil {
			return err
		}

		// Register as confirmed attendee (same as free-event flow).
		attendee := &event.EventAttendee{
			ID:       uuid.New(),
			EventID:  t.EventID,
			UserID:   t.UserID,
			JoinedAt: time.Now(),
			Status:   event.AttendeeConfirmed,
		}
		if err := uc.eventRepo.Join(ctx, attendee); err != nil {
			log.Printf("[PaymentCallback] failed to join attendees for ticket %s: %v", t.ID, err)
		}

		if err := uc.userRepo.IncrementEventsAttended(ctx, t.UserID); err != nil {
			log.Printf("[PaymentCallback] failed to increment events_attended for user %s: %v", t.UserID, err)
		}

	case ticket.TransactionFailed:
		// Cancel the ticket and free the capacity slot.
		t.Status = ticket.StatusCancelled
		if err := uc.ticketRepo.Update(ctx, t); err != nil {
			return err
		}

		if err := uc.ticketRepo.DecrementTicketsSold(ctx, t.EventID); err != nil {
			log.Printf("[PaymentCallback] failed to decrement tickets_sold for event %s: %v", t.EventID, err)
		}

		if err := uc.eventRepo.Leave(ctx, t.EventID, t.UserID); err != nil {
			log.Printf("[PaymentCallback] failed to remove attendee for ticket %s: %v", t.ID, err)
		}
	}

	return nil
}

// ExpireStaleTickets is called by the background expiry worker.
// It bulk-expires pending tickets older than 1 hour and frees their capacity slots.
func (uc *Usecase) ExpireStaleTickets(ctx context.Context) error {
	cutoff := time.Now().Add(-1 * time.Hour)

	expired, err := uc.ticketRepo.ExpirePendingTickets(ctx, cutoff)
	if err != nil {
		return err
	}

	if len(expired) == 0 {
		return nil
	}

	log.Printf("[TicketExpiry] expiring %d stale pending tickets", len(expired))

	for _, t := range expired {
		if err := uc.ticketRepo.DecrementTicketsSold(ctx, t.EventID); err != nil {
			log.Printf("[TicketExpiry] failed to decrement tickets_sold for event %s: %v", t.EventID, err)
		}
	}

	return nil
}

// GetUpcomingTickets gets upcoming tickets for a user
func (uc *Usecase) GetUpcomingTickets(ctx context.Context, userID uuid.UUID, limit int) ([]ticket.TicketWithDetails, error) {
	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}

	tickets, err := uc.ticketRepo.GetByUser(ctx, userID, limit*2, 0)
	if err != nil {
		return nil, err
	}

	upcoming := make([]ticket.TicketWithDetails, 0)
	now := time.Now()
	for _, t := range tickets {
		if t.EventStartTime.After(now) && t.Status == ticket.StatusActive {
			upcoming = append(upcoming, t)
			if len(upcoming) >= limit {
				break
			}
		}
	}

	return upcoming, nil
}

// GetPastTickets gets past tickets for a user
func (uc *Usecase) GetPastTickets(ctx context.Context, userID uuid.UUID, limit int) ([]ticket.TicketWithDetails, error) {
	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}

	tickets, err := uc.ticketRepo.GetByUser(ctx, userID, limit*2, 0)
	if err != nil {
		return nil, err
	}

	past := make([]ticket.TicketWithDetails, 0)
	now := time.Now()
	for _, t := range tickets {
		if t.EventStartTime.Before(now) {
			past = append(past, t)
			if len(past) >= limit {
				break
			}
		}
	}

	return past, nil
}
