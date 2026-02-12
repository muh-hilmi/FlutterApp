package analytics

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/anigmaa/backend/internal/domain/event"
	"github.com/anigmaa/backend/internal/domain/ticket"
	"github.com/google/uuid"
)

var (
	ErrEventNotFound = errors.New("event not found")
	ErrUnauthorized  = errors.New("unauthorized")
)

// Usecase represents the analytics use case
type Usecase struct {
	eventRepo  event.Repository
	ticketRepo ticket.Repository
}

// NewUsecase creates a new analytics usecase
func NewUsecase(eventRepo event.Repository, ticketRepo ticket.Repository) *Usecase {
	return &Usecase{
		eventRepo:  eventRepo,
		ticketRepo: ticketRepo,
	}
}

// EventAnalytics represents comprehensive analytics for a single event
type EventAnalytics struct {
	EventID          uuid.UUID            `json:"event_id"`
	EventTitle       string               `json:"event_title"`
	EventStatus      string               `json:"event_status"`
	StartTime        time.Time            `json:"start_time"`
	EndTime          time.Time            `json:"end_time"`
	Price            *float64             `json:"price"`
	IsFree           bool                 `json:"is_free"`
	MaxAttendees     int                  `json:"max_attendees"`
	TicketsSold      int                  `json:"tickets_sold"`
	TicketsCheckedIn int                  `json:"tickets_checked_in"`
	Revenue          RevenueStats         `json:"revenue"`
	Transactions     TransactionStats     `json:"transactions"`
	AttendanceRate   float64              `json:"attendance_rate"` // Percentage of tickets sold vs max attendees
	CheckInRate      float64              `json:"check_in_rate"`   // Percentage of checked in vs tickets sold
	PaymentMethods   []PaymentMethodStats `json:"payment_methods"`
	TimelineStats    []TimelineStats      `json:"timeline_stats"` // Sales over time (daily)
}

// RevenueStats represents revenue statistics
type RevenueStats struct {
	TotalRevenue    float64 `json:"total_revenue"`    // Total successful payments
	PendingRevenue  float64 `json:"pending_revenue"`  // Pending payments
	RefundedRevenue float64 `json:"refunded_revenue"` // Total refunds
	ExpectedRevenue float64 `json:"expected_revenue"` // If all tickets sold
	NetRevenue      float64 `json:"net_revenue"`      // Total - Refunded
}

// TransactionStats represents transaction statistics
type TransactionStats struct {
	TotalTransactions      int `json:"total_transactions"`
	SuccessfulTransactions int `json:"successful_transactions"`
	PendingTransactions    int `json:"pending_transactions"`
	FailedTransactions     int `json:"failed_transactions"`
	RefundedTransactions   int `json:"refunded_transactions"`
}

// PaymentMethodStats represents payment method breakdown
type PaymentMethodStats struct {
	Method      string  `json:"method"`
	Count       int     `json:"count"`
	TotalAmount float64 `json:"total_amount"`
	Percentage  float64 `json:"percentage"` // Percentage of total transactions
}

// TimelineStats represents sales statistics over time
type TimelineStats struct {
	Date         time.Time `json:"date"`
	TicketsSold  int       `json:"tickets_sold"`
	Revenue      float64   `json:"revenue"`
	Transactions int       `json:"transactions"`
}

// TransactionDetail represents detailed transaction information
type TransactionDetail struct {
	TransactionID string     `json:"transaction_id"`
	TicketID      uuid.UUID  `json:"ticket_id"`
	BuyerName     string     `json:"buyer_name"`  // Anonymized: "John D."
	BuyerEmail    string     `json:"buyer_email"` // Anonymized: "j***@example.com"
	Amount        float64    `json:"amount"`
	PaymentMethod string     `json:"payment_method"`
	Status        string     `json:"status"`
	PurchasedAt   time.Time  `json:"purchased_at"`
	CompletedAt   *time.Time `json:"completed_at"`
	IsCheckedIn   bool       `json:"is_checked_in"`
	CheckedInAt   *time.Time `json:"checked_in_at"`
}

// HostRevenueSummary represents overall revenue summary for a host
type HostRevenueSummary struct {
	HostID             uuid.UUID            `json:"host_id"`
	TotalEvents        int                  `json:"total_events"`
	CompletedEvents    int                  `json:"completed_events"`
	UpcomingEvents     int                  `json:"upcoming_events"`
	TotalTicketsSold   int                  `json:"total_tickets_sold"`
	TotalRevenue       float64              `json:"total_revenue"`
	TotalRefunded      float64              `json:"total_refunded"`
	NetRevenue         float64              `json:"net_revenue"`
	AverageTicketPrice float64              `json:"average_ticket_price"`
	TopEvent           *EventRevenueSummary `json:"top_event"` // Highest revenue event
	RevenueByMonth     []MonthlyRevenue     `json:"revenue_by_month"`
	RevenueByCategory  []CategoryRevenue    `json:"revenue_by_category"`
}

// EventRevenueSummary represents summary of an event with revenue
type EventRevenueSummary struct {
	EventID        uuid.UUID `json:"event_id"`
	Title          string    `json:"title"`
	Category       string    `json:"category"`
	Status         string    `json:"status"`
	StartTime      time.Time `json:"start_time"`
	Price          *float64  `json:"price"`
	IsFree         bool      `json:"is_free"`
	MaxAttendees   int       `json:"max_attendees"`
	TicketsSold    int       `json:"tickets_sold"`
	Revenue        float64   `json:"revenue"`
	RefundedAmount float64   `json:"refunded_amount"`
	NetRevenue     float64   `json:"net_revenue"`
	FillRate       float64   `json:"fill_rate"` // Percentage of capacity filled
}

// MonthlyRevenue represents revenue for a specific month
type MonthlyRevenue struct {
	Year        int     `json:"year"`
	Month       int     `json:"month"`
	EventsCount int     `json:"events_count"`
	TicketsSold int     `json:"tickets_sold"`
	Revenue     float64 `json:"revenue"`
}

// CategoryRevenue represents revenue by event category
type CategoryRevenue struct {
	Category    string  `json:"category"`
	EventsCount int     `json:"events_count"`
	TicketsSold int     `json:"tickets_sold"`
	Revenue     float64 `json:"revenue"`
}

// GetEventAnalytics retrieves comprehensive analytics for an event
func (uc *Usecase) GetEventAnalytics(ctx context.Context, eventID, hostID uuid.UUID) (*EventAnalytics, error) {
	// Get event and verify host ownership
	evt, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return nil, ErrEventNotFound
	}

	if evt.HostID != hostID {
		return nil, ErrUnauthorized
	}

	// Get all tickets for the event
	tickets, err := uc.ticketRepo.GetByEventID(ctx, eventID)
	if err != nil {
		return nil, err
	}

	// Initialize analytics
	analytics := &EventAnalytics{
		EventID:        evt.ID,
		EventTitle:     evt.Title,
		EventStatus:    string(evt.Status),
		StartTime:      evt.StartTime,
		EndTime:        evt.EndTime,
		Price:          evt.Price,
		IsFree:         evt.IsFree,
		MaxAttendees:   evt.MaxAttendees,
		TicketsSold:    evt.TicketsSold,
		Revenue:        RevenueStats{},
		Transactions:   TransactionStats{},
		PaymentMethods: []PaymentMethodStats{},
		TimelineStats:  []TimelineStats{},
	}

	// Calculate statistics
	var checkedInCount int
	paymentMethodMap := make(map[string]*PaymentMethodStats)
	timelineMap := make(map[string]*TimelineStats)

	for _, tkt := range tickets {
		if tkt.IsCheckedIn {
			checkedInCount++
		}

		// Get transactions for this ticket
		transactions, err := uc.ticketRepo.GetTransactionsByTicketID(ctx, tkt.ID)
		if err != nil {
			continue
		}

		for _, txn := range transactions {
			analytics.Transactions.TotalTransactions++

			switch txn.Status {
			case ticket.TransactionSuccess:
				analytics.Transactions.SuccessfulTransactions++
				analytics.Revenue.TotalRevenue += txn.Amount
			case ticket.TransactionPending:
				analytics.Transactions.PendingTransactions++
				analytics.Revenue.PendingRevenue += txn.Amount
			case ticket.TransactionFailed:
				analytics.Transactions.FailedTransactions++
			case ticket.TransactionRefunded:
				analytics.Transactions.RefundedTransactions++
				analytics.Revenue.RefundedRevenue += txn.Amount
			}

			// Track payment methods (only for successful transactions)
			if txn.Status == ticket.TransactionSuccess {
				if _, exists := paymentMethodMap[txn.PaymentMethod]; !exists {
					paymentMethodMap[txn.PaymentMethod] = &PaymentMethodStats{
						Method: txn.PaymentMethod,
					}
				}
				paymentMethodMap[txn.PaymentMethod].Count++
				paymentMethodMap[txn.PaymentMethod].TotalAmount += txn.Amount
			}

			// Track timeline (group by date)
			if txn.CompletedAt != nil && txn.Status == ticket.TransactionSuccess {
				dateKey := txn.CompletedAt.Format("2006-01-02")
				if _, exists := timelineMap[dateKey]; !exists {
					timelineMap[dateKey] = &TimelineStats{
						Date: time.Date(txn.CompletedAt.Year(), txn.CompletedAt.Month(), txn.CompletedAt.Day(), 0, 0, 0, 0, txn.CompletedAt.Location()),
					}
				}
				timelineMap[dateKey].TicketsSold++
				timelineMap[dateKey].Revenue += txn.Amount
				timelineMap[dateKey].Transactions++
			}
		}
	}

	analytics.TicketsCheckedIn = checkedInCount

	// Calculate rates
	if evt.MaxAttendees > 0 {
		analytics.AttendanceRate = float64(evt.TicketsSold) / float64(evt.MaxAttendees) * 100
	}
	if evt.TicketsSold > 0 {
		analytics.CheckInRate = float64(checkedInCount) / float64(evt.TicketsSold) * 100
	}

	// Calculate net revenue
	analytics.Revenue.NetRevenue = analytics.Revenue.TotalRevenue - analytics.Revenue.RefundedRevenue

	// Calculate expected revenue
	if evt.Price != nil && evt.MaxAttendees > 0 {
		analytics.Revenue.ExpectedRevenue = *evt.Price * float64(evt.MaxAttendees)
	}

	// Convert payment method map to slice and calculate percentages
	totalSuccessful := analytics.Transactions.SuccessfulTransactions
	for _, pm := range paymentMethodMap {
		if totalSuccessful > 0 {
			pm.Percentage = float64(pm.Count) / float64(totalSuccessful) * 100
		}
		analytics.PaymentMethods = append(analytics.PaymentMethods, *pm)
	}

	// Convert timeline map to slice and sort
	for _, tl := range timelineMap {
		analytics.TimelineStats = append(analytics.TimelineStats, *tl)
	}

	return analytics, nil
}

// GetEventTransactions retrieves detailed transaction list for an event
func (uc *Usecase) GetEventTransactions(ctx context.Context, eventID, hostID uuid.UUID, statusFilter string, limit, offset int) ([]TransactionDetail, error) {
	// Get event and verify host ownership
	evt, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return nil, ErrEventNotFound
	}

	if evt.HostID != hostID {
		return nil, ErrUnauthorized
	}

	// Get all tickets for the event
	tickets, err := uc.ticketRepo.GetByEventID(ctx, eventID)
	if err != nil {
		return nil, err
	}

	var transactions []TransactionDetail

	for _, tkt := range tickets {
		// Get transactions for this ticket
		txns, err := uc.ticketRepo.GetTransactionsByTicketID(ctx, tkt.ID)
		if err != nil {
			continue
		}

		for _, txn := range txns {
			// Apply status filter
			if statusFilter != "" && string(txn.Status) != statusFilter {
				continue
			}

			// Anonymize buyer information for privacy
			// This would require fetching user data, but for now we'll use placeholder
			// In production, you'd fetch user info and anonymize it
			detail := TransactionDetail{
				TransactionID: txn.TransactionID,
				TicketID:      tkt.ID,
				BuyerName:     anonymizeName("User"),              // Would fetch from user table
				BuyerEmail:    anonymizeEmail("user@example.com"), // Would fetch from user table
				Amount:        txn.Amount,
				PaymentMethod: txn.PaymentMethod,
				Status:        string(txn.Status),
				PurchasedAt:   txn.CreatedAt,
				CompletedAt:   txn.CompletedAt,
				IsCheckedIn:   tkt.IsCheckedIn,
				CheckedInAt:   tkt.CheckedInAt,
			}

			transactions = append(transactions, detail)
		}
	}

	// Apply pagination
	start := offset
	end := offset + limit
	if start > len(transactions) {
		return []TransactionDetail{}, nil
	}
	if end > len(transactions) {
		end = len(transactions)
	}

	return transactions[start:end], nil
}

// CountEventTransactions counts total transactions for an event with optional status filter
func (uc *Usecase) CountEventTransactions(ctx context.Context, eventID, hostID uuid.UUID, statusFilter string) (int, error) {
	// Get event and verify host ownership
	evt, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return 0, ErrEventNotFound
	}

	if evt.HostID != hostID {
		return 0, ErrUnauthorized
	}

	// Get all tickets for the event
	tickets, err := uc.ticketRepo.GetByEventID(ctx, eventID)
	if err != nil {
		return 0, err
	}

	count := 0

	for _, tkt := range tickets {
		// Get transactions for this ticket
		txns, err := uc.ticketRepo.GetTransactionsByTicketID(ctx, tkt.ID)
		if err != nil {
			continue
		}

		for _, txn := range txns {
			// Apply status filter
			if statusFilter != "" && string(txn.Status) != statusFilter {
				continue
			}
			count++
		}
	}

	return count, nil
}

// GetHostRevenueSummary retrieves comprehensive revenue summary for a host
func (uc *Usecase) GetHostRevenueSummary(ctx context.Context, hostID uuid.UUID, startDate, endDate *time.Time) (*HostRevenueSummary, error) {
	// Get all events by host
	events, err := uc.eventRepo.GetByHostID(ctx, hostID)
	if err != nil {
		return nil, err
	}

	summary := &HostRevenueSummary{
		HostID:            hostID,
		RevenueByMonth:    []MonthlyRevenue{},
		RevenueByCategory: []CategoryRevenue{},
	}

	monthlyMap := make(map[string]*MonthlyRevenue)
	categoryMap := make(map[string]*CategoryRevenue)
	var topEvent *EventRevenueSummary
	var maxRevenue float64

	for _, evt := range events {
		// Apply date filter if provided
		if startDate != nil && evt.StartTime.Before(*startDate) {
			continue
		}
		if endDate != nil && evt.StartTime.After(*endDate) {
			continue
		}

		summary.TotalEvents++

		// Count event status
		switch evt.Status {
		case event.StatusEnded:
			summary.CompletedEvents++
		case event.StatusUpcoming, event.StatusOngoing:
			summary.UpcomingEvents++
		}

		summary.TotalTicketsSold += evt.TicketsSold

		// Get tickets and calculate revenue for this event
		tickets, err := uc.ticketRepo.GetByEventID(ctx, evt.ID)
		if err != nil {
			continue
		}

		var eventRevenue float64
		var eventRefunded float64

		for _, tkt := range tickets {
			transactions, err := uc.ticketRepo.GetTransactionsByTicketID(ctx, tkt.ID)
			if err != nil {
				continue
			}

			for _, txn := range transactions {
				if txn.Status == ticket.TransactionSuccess {
					eventRevenue += txn.Amount
				} else if txn.Status == ticket.TransactionRefunded {
					eventRefunded += txn.Amount
				}
			}
		}

		summary.TotalRevenue += eventRevenue
		summary.TotalRefunded += eventRefunded

		// Track top event
		if eventRevenue > maxRevenue {
			maxRevenue = eventRevenue
			topEvent = &EventRevenueSummary{
				EventID:        evt.ID,
				Title:          evt.Title,
				Category:       string(evt.Category),
				Status:         string(evt.Status),
				StartTime:      evt.StartTime,
				Price:          evt.Price,
				IsFree:         evt.IsFree,
				MaxAttendees:   evt.MaxAttendees,
				TicketsSold:    evt.TicketsSold,
				Revenue:        eventRevenue,
				RefundedAmount: eventRefunded,
				NetRevenue:     eventRevenue - eventRefunded,
			}
			if evt.MaxAttendees > 0 {
				topEvent.FillRate = float64(evt.TicketsSold) / float64(evt.MaxAttendees) * 100
			}
		}

		// Track monthly revenue
		monthKey := evt.StartTime.Format("2006-01")
		if _, exists := monthlyMap[monthKey]; !exists {
			monthlyMap[monthKey] = &MonthlyRevenue{
				Year:  evt.StartTime.Year(),
				Month: int(evt.StartTime.Month()),
			}
		}
		monthlyMap[monthKey].EventsCount++
		monthlyMap[monthKey].TicketsSold += evt.TicketsSold
		monthlyMap[monthKey].Revenue += eventRevenue

		// Track category revenue
		categoryKey := string(evt.Category)
		if _, exists := categoryMap[categoryKey]; !exists {
			categoryMap[categoryKey] = &CategoryRevenue{
				Category: categoryKey,
			}
		}
		categoryMap[categoryKey].EventsCount++
		categoryMap[categoryKey].TicketsSold += evt.TicketsSold
		categoryMap[categoryKey].Revenue += eventRevenue
	}

	summary.NetRevenue = summary.TotalRevenue - summary.TotalRefunded

	// Calculate average ticket price
	if summary.TotalTicketsSold > 0 {
		summary.AverageTicketPrice = summary.TotalRevenue / float64(summary.TotalTicketsSold)
	}

	summary.TopEvent = topEvent

	// Convert maps to slices
	for _, mr := range monthlyMap {
		summary.RevenueByMonth = append(summary.RevenueByMonth, *mr)
	}
	for _, cr := range categoryMap {
		summary.RevenueByCategory = append(summary.RevenueByCategory, *cr)
	}

	return summary, nil
}

// GetHostEventsList retrieves list of events with revenue information
func (uc *Usecase) GetHostEventsList(ctx context.Context, hostID uuid.UUID, statusFilter string, limit, offset int) ([]EventRevenueSummary, error) {
	// Get all events by host
	events, err := uc.eventRepo.GetByHostID(ctx, hostID)
	if err != nil {
		return nil, err
	}

	var eventSummaries []EventRevenueSummary

	for _, evt := range events {
		// Apply status filter
		if statusFilter != "" && string(evt.Status) != statusFilter {
			continue
		}

		// Get tickets and calculate revenue for this event
		tickets, err := uc.ticketRepo.GetByEventID(ctx, evt.ID)
		if err != nil {
			continue
		}

		var eventRevenue float64
		var eventRefunded float64

		for _, tkt := range tickets {
			transactions, err := uc.ticketRepo.GetTransactionsByTicketID(ctx, tkt.ID)
			if err != nil {
				continue
			}

			for _, txn := range transactions {
				if txn.Status == ticket.TransactionSuccess {
					eventRevenue += txn.Amount
				} else if txn.Status == ticket.TransactionRefunded {
					eventRefunded += txn.Amount
				}
			}
		}

		summary := EventRevenueSummary{
			EventID:        evt.ID,
			Title:          evt.Title,
			Category:       string(evt.Category),
			Status:         string(evt.Status),
			StartTime:      evt.StartTime,
			Price:          evt.Price,
			IsFree:         evt.IsFree,
			MaxAttendees:   evt.MaxAttendees,
			TicketsSold:    evt.TicketsSold,
			Revenue:        eventRevenue,
			RefundedAmount: eventRefunded,
			NetRevenue:     eventRevenue - eventRefunded,
		}

		if evt.MaxAttendees > 0 {
			summary.FillRate = float64(evt.TicketsSold) / float64(evt.MaxAttendees) * 100
		}

		eventSummaries = append(eventSummaries, summary)
	}

	// Apply pagination
	start := offset
	end := offset + limit
	if start > len(eventSummaries) {
		return []EventRevenueSummary{}, nil
	}
	if end > len(eventSummaries) {
		end = len(eventSummaries)
	}

	return eventSummaries[start:end], nil
}

// CountHostEventsList counts total events for a host with optional status filter
func (uc *Usecase) CountHostEventsList(ctx context.Context, hostID uuid.UUID, statusFilter string) (int, error) {
	// Get all events by host
	events, err := uc.eventRepo.GetByHostID(ctx, hostID)
	if err != nil {
		return 0, err
	}

	count := 0

	for _, evt := range events {
		// Apply status filter
		if statusFilter != "" && string(evt.Status) != statusFilter {
			continue
		}
		count++
	}

	return count, nil
}

// Helper functions for anonymization

// anonymizeName anonymizes a full name (e.g., "John Doe" -> "John D.")
func anonymizeName(name string) string {
	parts := strings.Split(name, " ")
	if len(parts) < 2 {
		return name
	}
	return parts[0] + " " + string(parts[1][0]) + "."
}

// anonymizeEmail anonymizes an email address (e.g., "john@example.com" -> "j***@example.com")
func anonymizeEmail(email string) string {
	parts := strings.Split(email, "@")
	if len(parts) != 2 {
		return email
	}

	localPart := parts[0]
	if len(localPart) == 0 {
		return email
	}

	anonymized := string(localPart[0]) + "***@" + parts[1]
	return anonymized
}
