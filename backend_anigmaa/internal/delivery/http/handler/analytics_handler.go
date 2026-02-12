package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/anigmaa/backend/internal/delivery/http/middleware"
	analyticsUsecase "github.com/anigmaa/backend/internal/usecase/analytics"
	"github.com/anigmaa/backend/pkg/response"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AnalyticsHandler handles analytics-related HTTP requests
type AnalyticsHandler struct {
	analyticsUsecase *analyticsUsecase.Usecase
}

// NewAnalyticsHandler creates a new analytics handler
func NewAnalyticsHandler(analyticsUsecase *analyticsUsecase.Usecase) *AnalyticsHandler {
	return &AnalyticsHandler{
		analyticsUsecase: analyticsUsecase,
	}
}

// GetEventAnalytics godoc
// @Summary Get event analytics
// @Description Get comprehensive analytics for a specific event (host only)
// @Tags analytics
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Event ID" format(uuid)
// @Success 200 {object} response.Response{data=analytics.EventAnalytics}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /analytics/events/{id} [get]
func (h *AnalyticsHandler) GetEventAnalytics(c *gin.Context) {
	// Get user ID from context
	hostIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	hostID, err := uuid.Parse(hostIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	// Call usecase
	analytics, err := h.analyticsUsecase.GetEventAnalytics(c.Request.Context(), eventID, hostID)
	if err != nil {
		if err == analyticsUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		if err == analyticsUsecase.ErrUnauthorized {
			response.Forbidden(c, "Only the event host can view analytics")
			return
		}
		response.InternalError(c, "Failed to get event analytics", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Event analytics retrieved successfully", analytics)
}

// GetEventTransactions godoc
// @Summary Get event transactions
// @Description Get detailed transaction list for a specific event (host only)
// @Tags analytics
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Event ID" format(uuid)
// @Param status query string false "Filter by transaction status (pending, success, failed, refunded)"
// @Param limit query int false "Limit" default(50)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]analytics.TransactionDetail}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /analytics/events/{id}/transactions [get]
func (h *AnalyticsHandler) GetEventTransactions(c *gin.Context) {
	// Get user ID from context
	hostIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	hostID, err := uuid.Parse(hostIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	// Parse query parameters
	status := c.Query("status")
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Get total count for pagination
	total, err := h.analyticsUsecase.CountEventTransactions(c.Request.Context(), eventID, hostID, status)
	if err != nil {
		// If count fails, default to 0 but continue
		total = 0
	}

	// Get transactions
	transactions, err := h.analyticsUsecase.GetEventTransactions(c.Request.Context(), eventID, hostID, status, limit, offset)
	if err != nil {
		if err == analyticsUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		if err == analyticsUsecase.ErrUnauthorized {
			response.Forbidden(c, "Only the event host can view transactions")
			return
		}
		response.InternalError(c, "Failed to get event transactions", err.Error())
		return
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, limit, offset, len(transactions))
	response.Paginated(c, http.StatusOK, "Event transactions retrieved successfully", transactions, meta)
}

// GetHostRevenueSummary godoc
// @Summary Get host revenue summary
// @Description Get comprehensive revenue summary for all events created by the host
// @Tags analytics
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param period query string false "Time period (all, this_month, last_month, this_year)" default(all)
// @Success 200 {object} response.Response{data=analytics.HostRevenueSummary}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /analytics/host/revenue [get]
func (h *AnalyticsHandler) GetHostRevenueSummary(c *gin.Context) {
	// Get user ID from context
	hostIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	hostID, err := uuid.Parse(hostIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Parse query parameters
	period := c.DefaultQuery("period", "all")

	// Validate period
	validPeriods := map[string]bool{
		"all":        true,
		"this_month": true,
		"last_month": true,
		"this_year":  true,
	}

	if !validPeriods[period] {
		response.BadRequest(c, "Invalid period parameter", "Valid values: all, this_month, last_month, this_year")
		return
	}

	// Calculate date range based on period
	var startDate, endDate *time.Time
	now := time.Now()

	switch period {
	case "this_month":
		start := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
		startDate = &start
	case "last_month":
		start := time.Date(now.Year(), now.Month()-1, 1, 0, 0, 0, 0, now.Location())
		end := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location()).Add(-time.Second)
		startDate = &start
		endDate = &end
	case "this_year":
		start := time.Date(now.Year(), 1, 1, 0, 0, 0, 0, now.Location())
		startDate = &start
	}

	// Call usecase
	summary, err := h.analyticsUsecase.GetHostRevenueSummary(c.Request.Context(), hostID, startDate, endDate)
	if err != nil {
		response.InternalError(c, "Failed to get revenue summary", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Revenue summary retrieved successfully", summary)
}

// GetHostEventsList godoc
// @Summary Get host events with revenue
// @Description Get list of all events created by host with revenue information
// @Tags analytics
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param status query string false "Filter by event status (upcoming, ongoing, completed, cancelled)"
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]analytics.EventRevenueSummary}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /analytics/host/events [get]
func (h *AnalyticsHandler) GetHostEventsList(c *gin.Context) {
	// Get user ID from context
	hostIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	hostID, err := uuid.Parse(hostIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Parse query parameters
	status := c.Query("status")
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Get total count for pagination
	total, err := h.analyticsUsecase.CountHostEventsList(c.Request.Context(), hostID, status)
	if err != nil {
		// If count fails, default to 0 but continue
		total = 0
	}

	// Get events
	events, err := h.analyticsUsecase.GetHostEventsList(c.Request.Context(), hostID, status, limit, offset)
	if err != nil {
		response.InternalError(c, "Failed to get host events list", err.Error())
		return
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, limit, offset, len(events))
	response.Paginated(c, http.StatusOK, "Host events retrieved successfully", events, meta)
}
