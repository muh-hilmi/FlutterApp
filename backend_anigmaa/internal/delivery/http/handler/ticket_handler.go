package handler

import (
	"net/http"
	"strconv"

	"github.com/anigmaa/backend/internal/delivery/http/middleware"
	"github.com/anigmaa/backend/internal/domain/ticket"
	ticketUsecase "github.com/anigmaa/backend/internal/usecase/ticket"
	"github.com/anigmaa/backend/pkg/response"
	"github.com/anigmaa/backend/pkg/validator"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// TicketHandler handles ticket-related HTTP requests
type TicketHandler struct {
	ticketUsecase *ticketUsecase.Usecase
	validator     *validator.Validator
}

// NewTicketHandler creates a new ticket handler
func NewTicketHandler(ticketUsecase *ticketUsecase.Usecase, validator *validator.Validator) *TicketHandler {
	return &TicketHandler{
		ticketUsecase: ticketUsecase,
		validator:     validator,
	}
}

// PurchaseTicket godoc
// @Summary Purchase ticket
// @Description Purchase a ticket for an event. For paid events, returns payment URL.
// @Tags tickets
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body ticket.PurchaseTicketRequest true "Ticket purchase data"
// @Success 201 {object} response.Response{data=ticket.PurchaseTicketResponse}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 409 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /tickets/purchase [post]
func (h *TicketHandler) PurchaseTicket(c *gin.Context) {
	// Get user ID from context
	userIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	var req ticket.PurchaseTicketRequest

	// Parse request body
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := h.validator.Validate(&req); err != nil {
		response.BadRequest(c, "Validation failed", err.Error())
		return
	}

	// Call usecase
	purchaseResponse, err := h.ticketUsecase.PurchaseTicket(c.Request.Context(), userID, &req)
	if err != nil {
		if err == ticketUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		if err == ticketUsecase.ErrEventFull {
			response.Conflict(c, "Event is full", err.Error())
			return
		}
		if err == ticketUsecase.ErrAlreadyPurchased {
			response.Conflict(c, "Already purchased ticket for this event", err.Error())
			return
		}
		response.InternalError(c, "Failed to purchase ticket", err.Error())
		return
	}

	// Different messages for free vs paid events
	message := "Ticket purchased successfully"
	if purchaseResponse.PaymentURL != nil {
		message = "Ticket created. Please complete payment to activate."
	}

	response.Success(c, http.StatusCreated, message, purchaseResponse)
}

// GetMyTickets godoc
// @Summary Get my tickets
// @Description Get all tickets for the current user
// @Tags tickets
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]ticket.TicketWithDetails}
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /tickets/my [get]
func (h *TicketHandler) GetMyTickets(c *gin.Context) {
	// Get user ID from context
	userIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Parse query parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Get total count for pagination
	total, err := h.ticketUsecase.CountUserTickets(c.Request.Context(), userID)
	if err != nil {
		// If count fails, default to 0 but continue
		total = 0
	}

	// Get user tickets
	tickets, err := h.ticketUsecase.GetUserTickets(c.Request.Context(), userID, limit, offset)
	if err != nil {
		response.InternalError(c, "Failed to get tickets", err.Error())
		return
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, limit, offset, len(tickets))
	response.Paginated(c, http.StatusOK, "Tickets retrieved successfully", tickets, meta)
}

// GetTicketByID godoc
// @Summary Get ticket by ID
// @Description Get detailed information about a specific ticket
// @Tags tickets
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Ticket ID" format(uuid)
// @Success 200 {object} response.Response{data=ticket.TicketWithDetails}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /tickets/{id} [get]
func (h *TicketHandler) GetTicketByID(c *gin.Context) {
	// Get user ID from context
	userIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Parse ticket ID from path
	ticketIDStr := c.Param("id")
	ticketID, err := uuid.Parse(ticketIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid ticket ID", err.Error())
		return
	}

	// Call usecase
	ticketDetails, err := h.ticketUsecase.GetTicketWithDetails(c.Request.Context(), ticketID, userID)
	if err != nil {
		if err == ticketUsecase.ErrTicketNotFound {
			response.NotFound(c, "Ticket not found")
			return
		}
		if err == ticketUsecase.ErrUnauthorized {
			response.Forbidden(c, "You don't have access to this ticket")
			return
		}
		response.InternalError(c, "Failed to get ticket", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Ticket retrieved successfully", ticketDetails)
}

// CheckIn godoc
// @Summary Check in with ticket
// @Description Check in to an event using attendance code
// @Tags tickets
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param event_id path string true "Event ID" format(uuid)
// @Param request body ticket.CheckInRequest true "Check-in data"
// @Success 200 {object} response.Response{data=ticket.Ticket}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 409 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /tickets/events/{event_id}/checkin [post]
func (h *TicketHandler) CheckIn(c *gin.Context) {
	var req ticket.CheckInRequest

	// Parse request body
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := h.validator.Validate(&req); err != nil {
		response.BadRequest(c, "Validation failed", err.Error())
		return
	}

	// Parse event ID from request body
	eventID, err := uuid.Parse(req.EventID)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	// Call usecase
	checkedInTicket, err := h.ticketUsecase.CheckIn(c.Request.Context(), eventID, &req)
	if err != nil {
		if err == ticketUsecase.ErrTicketNotFound {
			response.NotFound(c, "Ticket not found")
			return
		}
		if err == ticketUsecase.ErrInvalidAttendanceCode {
			response.BadRequest(c, "Invalid attendance code", err.Error())
			return
		}
		if err == ticketUsecase.ErrAlreadyCheckedIn {
			response.Conflict(c, "Ticket already checked in", err.Error())
			return
		}
		if err == ticketUsecase.ErrTicketNotActive {
			response.BadRequest(c, "Ticket is not active", err.Error())
			return
		}
		response.InternalError(c, "Failed to check in", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Checked in successfully", checkedInTicket)
}

// CancelTicket godoc
// @Summary Cancel ticket
// @Description Cancel a ticket and request refund
// @Tags tickets
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Ticket ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /tickets/{id}/cancel [post]
func (h *TicketHandler) CancelTicket(c *gin.Context) {
	// Get user ID from context
	userIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Parse ticket ID from path
	ticketIDStr := c.Param("id")
	ticketID, err := uuid.Parse(ticketIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid ticket ID", err.Error())
		return
	}

	// Call usecase
	if err := h.ticketUsecase.CancelTicket(c.Request.Context(), ticketID, userID); err != nil {
		if err == ticketUsecase.ErrTicketNotFound {
			response.NotFound(c, "Ticket not found")
			return
		}
		if err == ticketUsecase.ErrUnauthorized {
			response.Forbidden(c, "You don't have access to this ticket")
			return
		}
		if err == ticketUsecase.ErrCannotRefund {
			response.BadRequest(c, "Ticket cannot be refunded", err.Error())
			return
		}
		if err == ticketUsecase.ErrEventStarted {
			response.BadRequest(c, "Cannot cancel ticket - event has already started", err.Error())
			return
		}
		response.InternalError(c, "Failed to cancel ticket", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Ticket cancelled successfully", nil)
}

// GetAttendanceCode godoc
// @Summary Get attendance code
// @Description Get the attendance code for a ticket
// @Tags tickets
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Ticket ID" format(uuid)
// @Success 200 {object} response.Response{data=map[string]string}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /tickets/{id}/attendance-code [get]
func (h *TicketHandler) GetAttendanceCode(c *gin.Context) {
	// Get user ID from context
	userIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Parse ticket ID from path
	ticketIDStr := c.Param("id")
	ticketID, err := uuid.Parse(ticketIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid ticket ID", err.Error())
		return
	}

	// Call usecase
	attendanceCode, err := h.ticketUsecase.GetAttendanceCode(c.Request.Context(), ticketID, userID)
	if err != nil {
		if err == ticketUsecase.ErrTicketNotFound {
			response.NotFound(c, "Ticket not found")
			return
		}
		if err == ticketUsecase.ErrUnauthorized {
			response.Forbidden(c, "You don't have access to this ticket")
			return
		}
		response.InternalError(c, "Failed to get attendance code", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Attendance code retrieved successfully", gin.H{
		"attendance_code": attendanceCode,
	})
}

// GetUpcomingTickets godoc
// @Summary Get upcoming tickets
// @Description Get user's upcoming event tickets
// @Tags tickets
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param limit query int false "Limit" default(10)
// @Success 200 {object} response.Response{data=[]ticket.TicketWithDetails}
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /tickets/upcoming [get]
func (h *TicketHandler) GetUpcomingTickets(c *gin.Context) {
	// Get user ID from context
	userIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Parse query parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	// Call usecase
	tickets, err := h.ticketUsecase.GetUpcomingTickets(c.Request.Context(), userID, limit)
	if err != nil {
		response.InternalError(c, "Failed to get upcoming tickets", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Upcoming tickets retrieved successfully", tickets)
}

// GetPastTickets godoc
// @Summary Get past tickets
// @Description Get user's past event tickets
// @Tags tickets
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param limit query int false "Limit" default(10)
// @Success 200 {object} response.Response{data=[]ticket.TicketWithDetails}
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /tickets/past [get]
func (h *TicketHandler) GetPastTickets(c *gin.Context) {
	// Get user ID from context
	userIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Parse query parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	// Call usecase
	tickets, err := h.ticketUsecase.GetPastTickets(c.Request.Context(), userID, limit)
	if err != nil {
		response.InternalError(c, "Failed to get past tickets", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Past tickets retrieved successfully", tickets)
}

// VerifyTicket godoc
// @Summary Verify ticket
// @Description Verify a ticket is valid for an event
// @Tags tickets
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param ticket_id path string true "Ticket ID" format(uuid)
// @Param event_id path string true "Event ID" format(uuid)
// @Success 200 {object} response.Response{data=map[string]bool}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /tickets/{ticket_id}/verify/{event_id} [get]
func (h *TicketHandler) VerifyTicket(c *gin.Context) {
	// Parse ticket ID from path
	ticketIDStr := c.Param("ticket_id")
	ticketID, err := uuid.Parse(ticketIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid ticket ID", err.Error())
		return
	}

	// Parse event ID from path
	eventIDStr := c.Param("event_id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	// Call usecase
	isValid, err := h.ticketUsecase.VerifyTicket(c.Request.Context(), ticketID, eventID)
	if err != nil {
		if err == ticketUsecase.ErrTicketNotFound {
			response.NotFound(c, "Ticket not found")
			return
		}
		response.InternalError(c, "Failed to verify ticket", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Ticket verification completed", gin.H{
		"is_valid": isValid,
	})
}

// GetTransaction godoc
// @Summary Get transaction details
// @Description Get details of a specific ticket transaction
// @Tags tickets
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Transaction ID"
// @Success 200 {object} response.Response{data=ticket.TicketTransaction}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /tickets/transactions/{id} [get]
func (h *TicketHandler) GetTransaction(c *gin.Context) {
	// Get user ID from context
	userIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Parse transaction ID from path
	transactionID := c.Param("id")
	if transactionID == "" {
		response.BadRequest(c, "Transaction ID is required", "")
		return
	}

	// Call usecase
	transaction, err := h.ticketUsecase.GetTransaction(c.Request.Context(), transactionID, userID)
	if err != nil {
		if err == ticketUsecase.ErrTicketNotFound {
			response.NotFound(c, "Transaction not found")
			return
		}
		if err == ticketUsecase.ErrUnauthorized {
			response.Forbidden(c, "You don't have access to this transaction")
			return
		}
		if err.Error() == "transaction not found" {
			response.NotFound(c, "Transaction not found")
			return
		}
		response.InternalError(c, "Failed to get transaction", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Transaction retrieved successfully", transaction)
}
