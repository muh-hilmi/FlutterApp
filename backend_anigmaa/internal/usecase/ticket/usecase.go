package ticket

import (
	"context"
	"errors"
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
	ErrEventFull             = errors.New("event is full")
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

// PurchaseTicket purchases a ticket for an event
func (uc *Usecase) PurchaseTicket(ctx context.Context, userID uuid.UUID, req *ticket.PurchaseTicketRequest) (*ticket.PurchaseTicketResponse, error) {
	// Get event
	evt, err := uc.eventRepo.GetByID(ctx, req.EventID)
	if err != nil {
		return nil, ErrEventNotFound
	}

	// Check if event is full
	if evt.IsFull() {
		return nil, ErrEventFull
	}

	// Check if user already has a ticket for this event
	existingTicket, err := uc.ticketRepo.GetUserTicketForEvent(ctx, userID, req.EventID)
	if err == nil && existingTicket != nil {
		return nil, ErrAlreadyPurchased
	}

	// Verify user exists
	usr, err := uc.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, errors.New("user not found")
	}

	// Generate attendance code
	attendanceCode, err := utils.GenerateAttendanceCode()
	if err != nil {
		return nil, err
	}

	// Determine price
	pricePaid := 0.0
	if !evt.IsFree && evt.Price != nil {
		pricePaid = *evt.Price
	}

	// For paid events, ticket starts as pending until payment is confirmed
	// For free events, ticket is active immediately
	ticketStatus := ticket.StatusActive
	if !evt.IsFree && pricePaid > 0 {
		ticketStatus = ticket.StatusPending
	}

	// Create ticket
	now := time.Now()
	newTicket := &ticket.Ticket{
		ID:             uuid.New(),
		UserID:         userID,
		EventID:        req.EventID,
		AttendanceCode: attendanceCode,
		PricePaid:      pricePaid,
		PurchasedAt:    now,
		IsCheckedIn:    false,
		Status:         ticketStatus,
	}

	if err := uc.ticketRepo.Create(ctx, newTicket); err != nil {
		return nil, err
	}

	// Prepare response
	response := &ticket.PurchaseTicketResponse{
		Ticket: newTicket,
	}

	// For paid events, create Midtrans payment
	if !evt.IsFree && pricePaid > 0 {
		// Generate order ID
		orderID := payment.GenerateOrderID(newTicket.ID.String())

		// Create Snap payment request
		snapReq := &payment.SnapRequest{
			TransactionDetails: payment.TransactionDetails{
				OrderID:     orderID,
				GrossAmount: pricePaid,
			},
			CustomerDetails: payment.CustomerDetails{
				FirstName: usr.Name,
				Email:     usr.Email,
				Phone:     "", // Phone is optional, user entity doesn't have phone number
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

		// Call Midtrans Snap API to create payment token
		snapResp, err := uc.midtransClient.CreateSnapToken(ctx, snapReq)
		if err != nil {
			// If Midtrans API fails, delete the ticket and return error
			_ = uc.ticketRepo.Delete(ctx, newTicket.ID)
			return nil, errors.New("failed to create payment: " + err.Error())
		}

		// Create transaction record with pending status
		transaction := &ticket.TicketTransaction{
			ID:            uuid.New(),
			TicketID:      newTicket.ID,
			TransactionID: orderID,
			Amount:        pricePaid,
			PaymentMethod: "midtrans",
			Status:        ticket.TransactionPending,
			CreatedAt:     now,
			CompletedAt:   nil, // Will be set by webhook when payment is confirmed
		}

		if req.PaymentMethod != nil {
			transaction.PaymentMethod = *req.PaymentMethod
		}

		if err := uc.ticketRepo.CreateTransaction(ctx, transaction); err != nil {
			// If transaction creation fails, delete ticket and return error
			_ = uc.ticketRepo.Delete(ctx, newTicket.ID)
			return nil, errors.New("failed to create transaction: " + err.Error())
		}

		// Add payment info to response
		response.PaymentToken = &snapResp.Token
		response.PaymentURL = &snapResp.RedirectURL
	} else {
		// For free events, immediately join the event
		attendee := &event.EventAttendee{
			ID:       uuid.New(),
			EventID:  req.EventID,
			UserID:   userID,
			JoinedAt: now,
			Status:   event.AttendeeConfirmed,
		}
		if err := uc.eventRepo.Join(ctx, attendee); err != nil {
			// Log error but don't fail
		}

		// Increment events attended for user stats
		if err := uc.userRepo.IncrementEventsAttended(ctx, userID); err != nil {
			// Log error but don't fail
		}
	}

	// Generate QR code for the ticket
	qrCode, err := qrcode.GenerateTicketQR(newTicket.ID, newTicket.EventID, newTicket.UserID, newTicket.AttendanceCode)
	if err == nil {
		response.QRCode = &qrCode
	}
	// If QR generation fails, continue without it (don't fail the request)

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

	// Verify user owns this ticket
	if t.UserID != userID {
		return nil, ErrUnauthorized
	}

	// Generate QR code for the ticket
	qrCode, err := qrcode.GenerateTicketQR(t.ID, t.EventID, t.UserID, t.AttendanceCode)
	if err == nil {
		t.QRCode = &qrCode
	}
	// If QR generation fails, continue without it (don't fail the request)

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

	// Generate QR codes for all tickets
	for i := range tickets {
		qrCode, err := qrcode.GenerateTicketQR(tickets[i].ID, tickets[i].EventID, tickets[i].UserID, tickets[i].AttendanceCode)
		if err == nil {
			tickets[i].QRCode = &qrCode
		}
		// If QR generation fails for a ticket, continue without it
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
	// Get event
	evt, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return nil, ErrEventNotFound
	}

	// Check if requesting user is the host
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

	// Generate QR codes for all tickets
	for i := range tickets {
		qrCode, err := qrcode.GenerateTicketQR(tickets[i].ID, tickets[i].EventID, tickets[i].UserID, tickets[i].AttendanceCode)
		if err == nil {
			tickets[i].QRCode = &qrCode
		}
		// If QR generation fails for a ticket, continue without it
	}

	return tickets, nil
}

// CheckIn checks in a ticket using attendance code
func (uc *Usecase) CheckIn(ctx context.Context, eventID uuid.UUID, req *ticket.CheckInRequest) (*ticket.Ticket, error) {
	// Validate attendance code format
	if !utils.ValidateAttendanceCode(req.AttendanceCode) {
		return nil, ErrInvalidAttendanceCode
	}

	// Get ticket by attendance code
	t, err := uc.ticketRepo.GetByAttendanceCode(ctx, req.AttendanceCode)
	if err != nil {
		return nil, ErrTicketNotFound
	}

	// Verify ticket is for the correct event
	if t.EventID != eventID {
		return nil, ErrTicketNotFound
	}

	// Check if ticket is active
	if t.Status != ticket.StatusActive {
		return nil, ErrTicketNotActive
	}

	// Check if already checked in
	if t.IsCheckedIn {
		return nil, ErrAlreadyCheckedIn
	}

	// Perform check-in
	if err := uc.ticketRepo.CheckIn(ctx, t.ID); err != nil {
		return nil, err
	}

	// Get updated ticket
	updatedTicket, err := uc.ticketRepo.GetByID(ctx, t.ID)
	if err != nil {
		return nil, err
	}

	return updatedTicket, nil
}

// CancelTicket cancels a ticket and issues refund (if applicable)
func (uc *Usecase) CancelTicket(ctx context.Context, ticketID, userID uuid.UUID) error {
	// Get ticket
	t, err := uc.ticketRepo.GetByID(ctx, ticketID)
	if err != nil {
		return ErrTicketNotFound
	}

	// Verify user owns this ticket
	if t.UserID != userID {
		return ErrUnauthorized
	}

	// Check if ticket can be cancelled
	if !t.CanBeRefunded() {
		return ErrCannotRefund
	}

	// Get event to check timing
	evt, err := uc.eventRepo.GetByID(ctx, t.EventID)
	if err != nil {
		return ErrEventNotFound
	}

	// Check if event has already started
	if evt.IsStartingSoon() || evt.IsOngoing() || evt.IsCompleted() {
		return ErrEventStarted
	}

	// Update ticket status
	t.Status = ticket.StatusCancelled
	if err := uc.ticketRepo.Update(ctx, t); err != nil {
		return err
	}

	// Leave the event
	if err := uc.eventRepo.Leave(ctx, t.EventID, userID); err != nil {
		// Log error but don't fail
	}

	// For paid tickets, create refund transaction
	if t.PricePaid > 0 {
		// Get original transaction
		// In production, you would initiate actual refund through payment gateway
		refundTransaction := &ticket.TicketTransaction{
			ID:            uuid.New(),
			TicketID:      t.ID,
			TransactionID: uuid.New().String(), // Would be from payment gateway
			Amount:        t.PricePaid,
			PaymentMethod: "midtrans",
			Status:        ticket.TransactionRefunded,
			CreatedAt:     time.Now(),
			CompletedAt:   nil, // Completed when refund is processed
		}

		if err := uc.ticketRepo.CreateTransaction(ctx, refundTransaction); err != nil {
			// Log error but don't fail cancellation
		}
	}

	return nil
}

// GetCheckedInCount gets the number of checked-in attendees for an event
func (uc *Usecase) GetCheckedInCount(ctx context.Context, eventID, requestingUserID uuid.UUID) (int, error) {
	// Get event
	evt, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return 0, ErrEventNotFound
	}

	// Check if requesting user is the host
	if evt.HostID != requestingUserID {
		return 0, ErrUnauthorized
	}

	return uc.ticketRepo.GetCheckedInCount(ctx, eventID)
}

// VerifyTicket verifies a ticket is valid for an event
func (uc *Usecase) VerifyTicket(ctx context.Context, ticketID, eventID uuid.UUID) (bool, error) {
	// Get ticket
	t, err := uc.ticketRepo.GetByID(ctx, ticketID)
	if err != nil {
		return false, ErrTicketNotFound
	}

	// Check if ticket is for the correct event
	if t.EventID != eventID {
		return false, nil
	}

	// Check if ticket is valid
	return t.IsValid(), nil
}

// GetAttendanceCode gets the attendance code for a ticket (user must own the ticket)
func (uc *Usecase) GetAttendanceCode(ctx context.Context, ticketID, userID uuid.UUID) (string, error) {
	// Get ticket
	t, err := uc.ticketRepo.GetByID(ctx, ticketID)
	if err != nil {
		return "", ErrTicketNotFound
	}

	// Verify user owns this ticket
	if t.UserID != userID {
		return "", ErrUnauthorized
	}

	return t.AttendanceCode, nil
}

// GetTransaction gets a transaction by transaction ID
func (uc *Usecase) GetTransaction(ctx context.Context, transactionID string, userID uuid.UUID) (*ticket.TicketTransaction, error) {
	// Get transaction
	transaction, err := uc.ticketRepo.GetTransaction(ctx, transactionID)
	if err != nil {
		return nil, errors.New("transaction not found")
	}

	// Get ticket to verify ownership
	t, err := uc.ticketRepo.GetByID(ctx, transaction.TicketID)
	if err != nil {
		return nil, ErrTicketNotFound
	}

	// Verify user owns the ticket
	if t.UserID != userID {
		return nil, ErrUnauthorized
	}

	return transaction, nil
}

// ProcessPaymentCallback handles payment gateway callback
// This would be called by Midtrans webhook in production
func (uc *Usecase) ProcessPaymentCallback(ctx context.Context, transactionID string, status ticket.TransactionStatus) error {
	// Get transaction
	transaction, err := uc.ticketRepo.GetTransaction(ctx, transactionID)
	if err != nil {
		return errors.New("transaction not found")
	}

	// Update transaction status
	if err := uc.ticketRepo.UpdateTransactionStatus(ctx, transactionID, status); err != nil {
		return err
	}

	// If payment failed, cancel the ticket
	if status == ticket.TransactionFailed {
		t, err := uc.ticketRepo.GetByID(ctx, transaction.TicketID)
		if err != nil {
			return err
		}

		t.Status = ticket.StatusCancelled
		if err := uc.ticketRepo.Update(ctx, t); err != nil {
			return err
		}

		// Remove from event attendees
		if err := uc.eventRepo.Leave(ctx, t.EventID, t.UserID); err != nil {
			// Log error but don't fail
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

	// Get all user tickets and filter for upcoming events
	tickets, err := uc.ticketRepo.GetByUser(ctx, userID, limit*2, 0) // Get more to filter
	if err != nil {
		return nil, err
	}

	// Filter for upcoming events
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

	// Get all user tickets and filter for past events
	tickets, err := uc.ticketRepo.GetByUser(ctx, userID, limit*2, 0) // Get more to filter
	if err != nil {
		return nil, err
	}

	// Filter for past events
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
