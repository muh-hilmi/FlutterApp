package handler

import (
	"net/http"
	"strconv"

	"github.com/anigmaa/backend/internal/delivery/http/middleware"
	"github.com/anigmaa/backend/internal/domain/event"
	eventUsecase "github.com/anigmaa/backend/internal/usecase/event"
	ticketUsecase "github.com/anigmaa/backend/internal/usecase/ticket"
	"github.com/anigmaa/backend/pkg/response"
	"github.com/anigmaa/backend/pkg/validator"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// EventHandler handles event-related HTTP requests
type EventHandler struct {
	eventUsecase  *eventUsecase.Usecase
	ticketUsecase *ticketUsecase.Usecase
	validator     *validator.Validator
}

// NewEventHandler creates a new event handler
func NewEventHandler(eventUsecase *eventUsecase.Usecase, ticketUsecase *ticketUsecase.Usecase, validator *validator.Validator) *EventHandler {
	return &EventHandler{
		eventUsecase:  eventUsecase,
		ticketUsecase: ticketUsecase,
		validator:     validator,
	}
}

// CreateEvent godoc
// @Summary Create a new event
// @Description Create a new hangout event
// @Tags events
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body event.CreateEventRequest true "Event creation data"
// @Success 201 {object} response.Response{data=event.Event}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events [post]
func (h *EventHandler) CreateEvent(c *gin.Context) {
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

	var req event.CreateEventRequest

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
	newEvent, err := h.eventUsecase.CreateEvent(c.Request.Context(), hostID, &req)
	if err != nil {
		if err == eventUsecase.ErrInvalidTimeRange {
			response.BadRequest(c, "End time must be after start time", err.Error())
			return
		}
		if err == eventUsecase.ErrPastEvent {
			response.BadRequest(c, "Cannot create event in the past", err.Error())
			return
		}
		response.InternalError(c, "Failed to create event", err.Error())
		return
	}

	response.Success(c, http.StatusCreated, "Event created successfully", newEvent)
}

// GetEvents godoc
// @Summary Get events list
// @Description Get a list of events with optional filters
// @Tags events
// @Accept json
// @Produce json
// @Param category query string false "Event category"
// @Param is_free query bool false "Filter free events"
// @Param status query string false "Event status"
// @Param mode query string false "Discovery mode: trending (popular events), for_you (personalized), chill (intimate/small events)"
// @Param lat query number false "Latitude for location-based search"
// @Param lng query number false "Longitude for location-based search"
// @Param radius query number false "Search radius in kilometers"
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]event.EventWithDetails}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events [get]
func (h *EventHandler) GetEvents(c *gin.Context) {
	// Build filter from query parameters
	var filter event.EventFilter
	if err := c.ShouldBindQuery(&filter); err != nil {
		response.BadRequest(c, "Invalid query parameters", err.Error())
		return
	}

	// Set defaults
	if filter.Limit == 0 {
		filter.Limit = 20
	}

	// Store original limit and offset for pagination
	originalLimit := filter.Limit
	originalOffset := filter.Offset

	// Get total count for pagination
	total, err := h.eventUsecase.CountEvents(c.Request.Context(), &filter)
	if err != nil {
		// If count fails, default to 0 but continue
		total = 0
	}

	// Get user ID from context (optional, for checking interest status)
	userIDStr, _ := middleware.GetUserID(c)
	userID, _ := uuid.Parse(userIDStr)

	// Call usecase
	events, err := h.eventUsecase.ListEvents(c.Request.Context(), &filter, userID)
	if err != nil {
		response.InternalError(c, "Failed to get events", err.Error())
		return
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, originalLimit, originalOffset, len(events))
	response.Paginated(c, http.StatusOK, "Events retrieved successfully", events, meta)
}

// GetEventByID godoc
// @Summary Get event by ID
// @Description Get detailed information about a specific event
// @Tags events
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Event ID" format(uuid)
// @Success 200 {object} response.Response{data=event.EventWithDetails}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/{id} [get]
func (h *EventHandler) GetEventByID(c *gin.Context) {
	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	// Get user ID from context (optional, for checking attendance status)
	userIDStr, _ := middleware.GetUserID(c)
	userID, _ := uuid.Parse(userIDStr)

	// Call usecase
	evt, err := h.eventUsecase.GetEventWithDetails(c.Request.Context(), eventID, userID)
	if err != nil {
		if err == eventUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		response.InternalError(c, "Failed to get event", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Event retrieved successfully", evt)
}

// UpdateEvent godoc
// @Summary Update event
// @Description Update an existing event (host only)
// @Tags events
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Event ID" format(uuid)
// @Param request body event.UpdateEventRequest true "Event update data"
// @Success 200 {object} response.Response{data=event.Event}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/{id} [put]
func (h *EventHandler) UpdateEvent(c *gin.Context) {
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

	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	var req event.UpdateEventRequest

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
	updatedEvent, err := h.eventUsecase.UpdateEvent(c.Request.Context(), eventID, userID, &req)
	if err != nil {
		if err == eventUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		if err == eventUsecase.ErrUnauthorized {
			response.Forbidden(c, "Only the event host can update this event")
			return
		}
		if err == eventUsecase.ErrInvalidTimeRange {
			response.BadRequest(c, "End time must be after start time", err.Error())
			return
		}
		response.InternalError(c, "Failed to update event", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Event updated successfully", updatedEvent)
}

// DeleteEvent godoc
// @Summary Delete event
// @Description Delete an event (host only)
// @Tags events
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Event ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/{id} [delete]
func (h *EventHandler) DeleteEvent(c *gin.Context) {
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

	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	// Call usecase
	if err := h.eventUsecase.DeleteEvent(c.Request.Context(), eventID, userID); err != nil {
		if err == eventUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		if err == eventUsecase.ErrUnauthorized {
			response.Forbidden(c, "Only the event host can delete this event")
			return
		}
		response.InternalError(c, "Failed to delete event", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Event deleted successfully", nil)
}

// JoinEvent godoc
// @Summary Join an event
// @Description Join an event as an attendee
// @Tags events
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Event ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 409 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/{id}/join [post]
func (h *EventHandler) JoinEvent(c *gin.Context) {
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

	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	// Call usecase
	if err := h.eventUsecase.JoinEvent(c.Request.Context(), eventID, userID); err != nil {
		if err == eventUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		if err == eventUsecase.ErrEventFull {
			response.Conflict(c, "Event is full", err.Error())
			return
		}
		if err == eventUsecase.ErrAlreadyJoined {
			response.Conflict(c, "Already joined this event", err.Error())
			return
		}
		response.InternalError(c, "Failed to join event", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Joined event successfully", nil)
}

// LeaveEvent godoc
// @Summary Leave an event
// @Description Leave an event you have joined
// @Tags events
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Event ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/{id}/leave [post]
func (h *EventHandler) LeaveEvent(c *gin.Context) {
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

	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	// Call usecase
	if err := h.eventUsecase.LeaveEvent(c.Request.Context(), eventID, userID); err != nil {
		if err == eventUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		if err == eventUsecase.ErrCannotLeaveAsHost {
			response.Forbidden(c, "Event host cannot leave their own event")
			return
		}
		if err == eventUsecase.ErrNotJoined {
			response.BadRequest(c, "Not joined this event", err.Error())
			return
		}
		response.InternalError(c, "Failed to leave event", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Left event successfully", nil)
}

// GetNearbyEvents godoc
// @Summary Get nearby events
// @Description Get events near a specific location
// @Tags events
// @Accept json
// @Produce json
// @Param lat query number true "Latitude"
// @Param lng query number true "Longitude"
// @Param radius query number false "Radius in kilometers" default(10)
// @Param limit query int false "Limit" default(20)
// @Success 200 {object} response.Response{data=[]event.EventWithDetails}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/nearby [get]
func (h *EventHandler) GetNearbyEvents(c *gin.Context) {
	// Parse query parameters - accept both lat/lng and latitude/longitude
	latStr := c.Query("lat")
	if latStr == "" {
		latStr = c.Query("latitude")
	}
	lngStr := c.Query("lng")
	if lngStr == "" {
		lngStr = c.Query("longitude")
	}

	if latStr == "" || lngStr == "" {
		response.BadRequest(c, "Latitude and longitude are required", "")
		return
	}

	lat, err := strconv.ParseFloat(latStr, 64)
	if err != nil {
		response.BadRequest(c, "Invalid latitude", err.Error())
		return
	}

	lng, err := strconv.ParseFloat(lngStr, 64)
	if err != nil {
		response.BadRequest(c, "Invalid longitude", err.Error())
		return
	}

	radiusStr := c.DefaultQuery("radius", "10")
	radius, err := strconv.ParseFloat(radiusStr, 64)
	if err != nil {
		response.BadRequest(c, "Invalid radius", err.Error())
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Request limit+1 to check if there are more results
	events, err := h.eventUsecase.GetNearbyEvents(c.Request.Context(), lat, lng, radius, limit+1)
	if err != nil {
		response.InternalError(c, "Failed to get nearby events", err.Error())
		return
	}

	// Check if there are more results
	hasNext := len(events) > limit
	if hasNext {
		events = events[:limit] // Trim to requested limit
	}

	// Create pagination metadata
	meta := response.NewPaginationMeta(offset+len(events), limit, offset, len(events))
	response.Paginated(c, http.StatusOK, "Nearby events retrieved successfully", events, meta)
}

// GetMyEvents godoc
// @Summary Get my events
// @Description Get events created by the current user
// @Tags events
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]event.EventWithDetails}
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/my [get]
func (h *EventHandler) GetMyEvents(c *gin.Context) {
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

	// Request limit+1 to check if there are more results
	events, err := h.eventUsecase.GetEventsByHost(c.Request.Context(), userID, limit+1, offset)
	if err != nil {
		response.InternalError(c, "Failed to get events", err.Error())
		return
	}

	// Check if there are more results
	hasNext := len(events) > limit
	if hasNext {
		events = events[:limit] // Trim to requested limit
	}

	// Create pagination metadata
	meta := response.NewPaginationMeta(offset+len(events), limit, offset, len(events))
	response.Paginated(c, http.StatusOK, "Events retrieved successfully", events, meta)
}

// GetHostedEvents godoc
// @Summary Get hosted events
// @Description Get events hosted/created by the current user
// @Tags events
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]event.EventWithDetails}
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/hosted [get]
func (h *EventHandler) GetHostedEvents(c *gin.Context) {
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
	total, err := h.eventUsecase.CountHostedEvents(c.Request.Context(), userID)
	if err != nil {
		// If count fails, default to 0 but continue
		total = 0
	}

	// Get hosted events
	events, err := h.eventUsecase.GetByHost(c.Request.Context(), userID, limit, offset)
	if err != nil {
		response.InternalError(c, "Failed to get hosted events", err.Error())
		return
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, limit, offset, len(events))
	response.Paginated(c, http.StatusOK, "Hosted events retrieved successfully", events, meta)
}

// GetJoinedEvents godoc
// @Summary Get joined events
// @Description Get events that the current user has joined
// @Tags events
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]event.EventWithDetails}
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/joined [get]
func (h *EventHandler) GetJoinedEvents(c *gin.Context) {
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
	total, err := h.eventUsecase.CountJoinedEvents(c.Request.Context(), userID)
	if err != nil {
		// If count fails, default to 0 but continue
		total = 0
	}

	// Get joined events
	events, err := h.eventUsecase.GetJoinedEvents(c.Request.Context(), userID, limit, offset)
	if err != nil {
		response.InternalError(c, "Failed to get joined events", err.Error())
		return
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, limit, offset, len(events))
	response.Paginated(c, http.StatusOK, "Joined events retrieved successfully", events, meta)
}

// GetEventAttendees godoc
// @Summary Get event attendees
// @Description Get list of attendees for an event (both paid tickets and free event attendees)
// @Tags events
// @Accept json
// @Produce json
// @Param id path string true "Event ID" format(uuid)
// @Param limit query int false "Limit" default(50)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]map[string]interface{}}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/{id}/attendees [get]
func (h *EventHandler) GetEventAttendees(c *gin.Context) {
	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	// Parse query parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	allAttendees := make([]map[string]interface{}, 0)

	// Get paid event attendees from tickets table
	tickets, err := h.ticketUsecase.GetTicketsByEvent(c.Request.Context(), eventID, limit+offset, 0)
	if err == nil {
		for _, t := range tickets {
			checkedInAt := (*string)(nil)
			if t.CheckedInAt != nil {
				formatted := t.CheckedInAt.Format("2006-01-02T15:04:05Z07:00")
				checkedInAt = &formatted
			}
			attendee := map[string]interface{}{
				"id":            t.UserID.String(),
				"name":          t.UserName,
				"avatar":        t.UserAvatarURL,
				"ticket_type":   "General",
				"ticket_id":     t.ID.String(),
				"checked_in":    t.IsCheckedIn,
				"checked_in_at": checkedInAt,
				"purchased_at":  t.PurchasedAt.Format("2006-01-02T15:04:05Z07:00"),
			}
			allAttendees = append(allAttendees, attendee)
		}
	}

	// Get free event attendees from event_attendees table
	freeAttendees, freeCount, err := h.eventUsecase.GetAttendeesWithDetails(c.Request.Context(), eventID, limit+offset, 0)
	if err == nil {
		// Convert to map format
		for _, fa := range freeAttendees {
			attendee := map[string]interface{}{
				"id":            fa.ID.String(), // This is user_id from AttendeeWithDetails
				"name":          fa.Name,
				"avatar":        fa.Avatar,
				"ticket_type":   "Free",
				"ticket_id":     fa.TicketID,
				"checked_in":    fa.CheckedIn,
				"checked_in_at": fa.CheckedInAt,
				"purchased_at":  fa.PurchasedAt,
			}
			allAttendees = append(allAttendees, attendee)
		}
	}

	// Get total count (combine both sources)
	ticketCount, _ := h.ticketUsecase.CountEventTickets(c.Request.Context(), eventID)
	totalCount := ticketCount + freeCount

	// Apply pagination to merged results
	start := offset
	end := offset + limit
	if start > len(allAttendees) {
		start = len(allAttendees)
	}
	if end > len(allAttendees) {
		end = len(allAttendees)
	}
	paginatedAttendees := allAttendees[start:end]

	// Create pagination metadata
	meta := response.NewPaginationMeta(totalCount, limit, offset, len(paginatedAttendees))
	response.Paginated(c, http.StatusOK, "Attendees retrieved successfully", paginatedAttendees, meta)
}

// GetEventTickets godoc
// @Summary Get event tickets
// @Description Get all tickets for an event (host only)
// @Tags events
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Event ID" format(uuid)
// @Param limit query int false "Limit" default(50)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/{id}/tickets [get]
func (h *EventHandler) GetEventTickets(c *gin.Context) {
	// Get user ID from context
	userIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	_, err := uuid.Parse(userIDStr)
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
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Note: This would call a ticket usecase method
	// For now, return a placeholder response
	response.Success(c, http.StatusOK, "Event tickets endpoint (to be implemented with ticket usecase)", gin.H{
		"event_id": eventID,
		"limit":    limit,
		"offset":   offset,
	})
}

// AddEventImages godoc
// @Summary Add images to event
// @Description Add one or more images to an existing event (host only)
// @Tags events
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Event ID" format(uuid)
// @Param request body object{image_urls=[]string} true "Image URLs to add"
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/{id}/images [post]
func (h *EventHandler) AddEventImages(c *gin.Context) {
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

	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	var req struct {
		ImageURLs []string `json:"image_urls" binding:"required,min=1"`
	}

	// Parse request body
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request body", err.Error())
		return
	}

	// Call usecase
	if err := h.eventUsecase.AddEventImages(c.Request.Context(), eventID, userID, req.ImageURLs); err != nil {
		if err == eventUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		if err == eventUsecase.ErrUnauthorized {
			response.Forbidden(c, "Only the event host can add images")
			return
		}
		response.InternalError(c, "Failed to add images", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Images added successfully", nil)
}

// DeleteEventImage godoc
// @Summary Delete event image
// @Description Delete a specific image from an event (host only)
// @Tags events
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Event ID" format(uuid)
// @Param imageId path string true "Image ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/{id}/images/{imageId} [delete]
func (h *EventHandler) DeleteEventImage(c *gin.Context) {
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

	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	// Parse image ID from path
	imageIDStr := c.Param("imageId")
	imageID, err := uuid.Parse(imageIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid image ID", err.Error())
		return
	}

	// Call usecase
	if err := h.eventUsecase.DeleteEventImage(c.Request.Context(), eventID, imageID, userID); err != nil {
		if err == eventUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		if err == eventUsecase.ErrUnauthorized {
			response.Forbidden(c, "Only the event host can delete images")
			return
		}
		response.InternalError(c, "Failed to delete image", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Image deleted successfully", nil)
}

// ToggleEventInterest godoc
// @Summary Toggle interest in event
// @Description Toggle (like/unlike) an event for the authenticated user
// @Tags events
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Event ID" format(uuid)
// @Success 200 {object} response.Response{data=map[string]interface{}}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/{id}/interest [post]
func (h *EventHandler) ToggleEventInterest(c *gin.Context) {
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

	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	// Toggle interest
	isInterested, err := h.eventUsecase.ToggleInterest(c.Request.Context(), eventID, userID)
	if err != nil {
		if err == eventUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		response.InternalError(c, "Failed to toggle interest", err.Error())
		return
	}

	// Get current interest count
	interestCount, _ := h.eventUsecase.GetInterestsCount(c.Request.Context(), eventID)

	// Return response
	data := map[string]interface{}{
		"is_interested":  isInterested,
		"interest_count": interestCount,
	}

	response.Success(c, http.StatusOK, "Interest toggled successfully", data)
}

// GetEventInterestStatus godoc
// @Summary Get user's interest status for event
// @Description Check if the authenticated user is interested in an event
// @Tags events
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Event ID" format(uuid)
// @Success 200 {object} response.Response{data=map[string]interface{}}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/{id}/interest/status [get]
func (h *EventHandler) GetEventInterestStatus(c *gin.Context) {
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

	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	// Check interest status
	isInterested, err := h.eventUsecase.IsInterested(c.Request.Context(), eventID, userID)
	if err != nil {
		if err == eventUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		response.InternalError(c, "Failed to check interest status", err.Error())
		return
	}

	// Get current interest count
	interestCount, _ := h.eventUsecase.GetInterestsCount(c.Request.Context(), eventID)

	// Return response
	data := map[string]interface{}{
		"is_interested":  isInterested,
		"interest_count": interestCount,
	}

	response.Success(c, http.StatusOK, "Interest status retrieved successfully", data)
}

// GetEventInterestCount godoc
// @Summary Get total interest count for event
// @Description Get the total number of users interested in an event
// @Tags events
// @Accept json
// @Produce json
// @Param id path string true "Event ID" format(uuid)
// @Success 200 {object} response.Response{data=map[string]interface{}}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/{id}/interest/count [get]
func (h *EventHandler) GetEventInterestCount(c *gin.Context) {
	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	// Get interest count
	interestCount, err := h.eventUsecase.GetInterestsCount(c.Request.Context(), eventID)
	if err != nil {
		if err == eventUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		response.InternalError(c, "Failed to get interest count", err.Error())
		return
	}

	// Return response
	data := map[string]interface{}{
		"interest_count": interestCount,
	}

	response.Success(c, http.StatusOK, "Interest count retrieved successfully", data)
}

// ArchiveEvent godoc
// @Summary Archive an event
// @Description Archive an event (host only)
// @Tags events
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Event ID" format(uuid)
// @Success 200 {object} response.Response{data=event.Event}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/{id}/archive [patch]
func (h *EventHandler) ArchiveEvent(c *gin.Context) {
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

	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	// Call usecase to archive event
	updatedEvent, err := h.eventUsecase.ArchiveEvent(c.Request.Context(), eventID, userID)
	if err != nil {
		if err == eventUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		if err == eventUsecase.ErrUnauthorized {
			response.Forbidden(c, "Only the event host can archive this event")
			return
		}
		response.InternalError(c, "Failed to archive event", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Event archived successfully", updatedEvent)
}

// UnarchiveEvent godoc
// @Summary Unarchive an event
// @Description Unarchive an event (host only)
// @Tags events
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Event ID" format(uuid)
// @Success 200 {object} response.Response{data=event.Event}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/{id}/unarchive [patch]
func (h *EventHandler) UnarchiveEvent(c *gin.Context) {
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

	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	// Call usecase to unarchive event
	updatedEvent, err := h.eventUsecase.UnarchiveEvent(c.Request.Context(), eventID, userID)
	if err != nil {
		if err == eventUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		if err == eventUsecase.ErrUnauthorized {
			response.Forbidden(c, "Only the event host can unarchive this event")
			return
		}
		response.InternalError(c, "Failed to unarchive event", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Event unarchived successfully", updatedEvent)
}
