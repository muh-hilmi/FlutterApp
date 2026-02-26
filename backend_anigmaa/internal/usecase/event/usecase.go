package event

import (
	"context"
	"errors"
	"time"

	"github.com/anigmaa/backend/internal/domain/event"
	"github.com/anigmaa/backend/internal/domain/user"
	"github.com/google/uuid"
)

var (
	ErrEventNotFound     = errors.New("event not found")
	ErrUnauthorized      = errors.New("unauthorized - not event host")
	ErrEventFull         = errors.New("event is full")
	ErrAlreadyJoined     = errors.New("already joined this event")
	ErrNotJoined         = errors.New("not joined this event")
	ErrInvalidTimeRange  = errors.New("end time must be after start time")
	ErrPastEvent         = errors.New("cannot create event in the past")
	ErrCannotLeaveAsHost = errors.New("host cannot leave their own event")
	ErrCannotCancelPast  = errors.New("cannot cancel past event")
)

// Usecase handles event business logic
type Usecase struct {
	eventRepo event.Repository
	userRepo  user.Repository
}

// NewUsecase creates a new event usecase
func NewUsecase(eventRepo event.Repository, userRepo user.Repository) *Usecase {
	return &Usecase{
		eventRepo: eventRepo,
		userRepo:  userRepo,
	}
}

// CreateEvent creates a new event
func (uc *Usecase) CreateEvent(ctx context.Context, hostID uuid.UUID, req *event.CreateEventRequest) (*event.Event, error) {
	// Validate time range
	if !req.EndTime.After(req.StartTime) {
		return nil, ErrInvalidTimeRange
	}

	// Check if event is in the past (use UTC for comparison)
	if req.StartTime.UTC().Before(time.Now().UTC()) {
		return nil, ErrPastEvent
	}

	// Verify host exists
	_, err := uc.userRepo.GetByID(ctx, hostID)
	if err != nil {
		return nil, errors.New("host user not found")
	}

	// Create event
	now := time.Now()
	newEvent := &event.Event{
		ID:               uuid.New(),
		HostID:           hostID,
		Title:            req.Title,
		Description:      req.Description,
		Category:         req.Category,
		// IMPORTANT: Convert to UTC for storage (best practice for global apps)
		StartTime:        req.StartTime.UTC(),
		EndTime:          req.EndTime.UTC(),
		LocationName:     req.LocationName,
		LocationAddress:  req.LocationAddress,
		LocationLat:      req.LocationLat,
		LocationLng:      req.LocationLng,
		MaxAttendees:     req.MaxAttendees,
		Price:            req.Price,
		IsFree:           req.IsFree,
		Status:           event.StatusUpcoming,
		Privacy:          req.Privacy,
		Requirements:     req.Requirements,
		TicketingEnabled: req.TicketingEnabled,
		TicketsSold:      0,
		CreatedAt:        now.UTC(),
		UpdatedAt:        now.UTC(),
	}

	// Validate pricing
	if !newEvent.IsFree && (newEvent.Price == nil || *newEvent.Price <= 0) {
		return nil, errors.New("price must be set for paid events")
	}

	if err := uc.eventRepo.Create(ctx, newEvent); err != nil {
		return nil, err
	}

	// Add images if provided
	if len(req.ImageURLs) > 0 {
		images := make([]event.EventImage, len(req.ImageURLs))
		for i, url := range req.ImageURLs {
			images[i] = event.EventImage{
				ID:       uuid.New(),
				EventID:  newEvent.ID,
				ImageURL: url,
				Order:    i,
			}
		}
		if err := uc.eventRepo.AddImages(ctx, images); err != nil {
			// Log error but don't fail event creation
		}
	}

	// Increment events created for user stats
	if err := uc.userRepo.IncrementEventsCreated(ctx, hostID); err != nil {
		// Log error but don't fail
	}

	return newEvent, nil
}

// GetEventByID gets an event by ID
func (uc *Usecase) GetEventByID(ctx context.Context, eventID uuid.UUID) (*event.Event, error) {
	evt, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return nil, ErrEventNotFound
	}
	return evt, nil
}

// GetEventWithDetails gets an event with all details for a specific user
func (uc *Usecase) GetEventWithDetails(ctx context.Context, eventID, userID uuid.UUID) (*event.EventWithDetails, error) {
	evt, err := uc.eventRepo.GetWithDetails(ctx, eventID, userID)
	if err != nil {
		return nil, ErrEventNotFound
	}
	return evt, nil
}

// UpdateEvent updates an event
func (uc *Usecase) UpdateEvent(ctx context.Context, eventID, userID uuid.UUID, req *event.UpdateEventRequest) (*event.Event, error) {
	// Get existing event
	existingEvent, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return nil, ErrEventNotFound
	}

	// Check if user is the host
	if existingEvent.HostID != userID {
		return nil, ErrUnauthorized
	}

	// Update fields if provided
	if req.Title != nil {
		existingEvent.Title = *req.Title
	}
	if req.Description != nil {
		existingEvent.Description = *req.Description
	}
	if req.Category != nil {
		existingEvent.Category = *req.Category
	}
	if req.StartTime != nil {
		existingEvent.StartTime = req.StartTime.UTC()
	}
	if req.EndTime != nil {
		existingEvent.EndTime = req.EndTime.UTC()
	}
	if req.LocationName != nil {
		existingEvent.LocationName = *req.LocationName
	}
	if req.LocationAddress != nil {
		existingEvent.LocationAddress = *req.LocationAddress
	}
	if req.LocationLat != nil {
		existingEvent.LocationLat = *req.LocationLat
	}
	if req.LocationLng != nil {
		existingEvent.LocationLng = *req.LocationLng
	}
	if req.MaxAttendees != nil {
		existingEvent.MaxAttendees = *req.MaxAttendees
	}
	if req.Price != nil {
		existingEvent.Price = req.Price
	}
	if req.Privacy != nil {
		existingEvent.Privacy = *req.Privacy
	}
	if req.Requirements != nil {
		existingEvent.Requirements = req.Requirements
	}
	if req.Status != nil {
		existingEvent.Status = *req.Status
	}

	// Validate time range
	if !existingEvent.EndTime.After(existingEvent.StartTime) {
		return nil, ErrInvalidTimeRange
	}

	existingEvent.UpdatedAt = time.Now().UTC()

	// Save changes
	if err := uc.eventRepo.Update(ctx, existingEvent); err != nil {
		return nil, err
	}

	// Handle image updates if provided
	if req.ImageURLs != nil {
		// Delete all existing images
		if err := uc.eventRepo.DeleteAllImages(ctx, eventID); err != nil {
			return nil, err
		}

		// Add new images if any
		if len(*req.ImageURLs) > 0 {
			images := make([]event.EventImage, len(*req.ImageURLs))
			for i, url := range *req.ImageURLs {
				images[i] = event.EventImage{
					EventID:  eventID,
					ImageURL: url,
					Order:    i,
				}
			}
			if err := uc.eventRepo.AddImages(ctx, images); err != nil {
				return nil, err
			}
		}
	}

	return existingEvent, nil
}

// DeleteEvent deletes an event
func (uc *Usecase) DeleteEvent(ctx context.Context, eventID, userID uuid.UUID) error {
	// Get existing event
	existingEvent, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return ErrEventNotFound
	}

	// Check if user is the host
	if existingEvent.HostID != userID {
		return ErrUnauthorized
	}

	return uc.eventRepo.Delete(ctx, eventID)
}

// ListEvents lists events with filters
func (uc *Usecase) ListEvents(ctx context.Context, filter *event.EventFilter, userID uuid.UUID) ([]event.EventWithDetails, error) {
	// Set default limits
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}

	return uc.eventRepo.List(ctx, filter, userID)
}

// GetByHost gets events created by a host
func (uc *Usecase) GetByHost(ctx context.Context, hostID uuid.UUID, limit, offset int) ([]event.EventWithDetails, error) {
	return uc.GetEventsByHost(ctx, hostID, limit, offset)
}

// GetEventsByHost gets events created by a host
func (uc *Usecase) GetEventsByHost(ctx context.Context, hostID uuid.UUID, limit, offset int) ([]event.EventWithDetails, error) {
	// Verify host exists
	_, err := uc.userRepo.GetByID(ctx, hostID)
	if err != nil {
		return nil, errors.New("host user not found")
	}

	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	return uc.eventRepo.GetByHost(ctx, hostID, limit, offset)
}

// GetJoinedEvents gets events a user has joined
func (uc *Usecase) GetJoinedEvents(ctx context.Context, userID uuid.UUID, limit, offset int) ([]event.EventWithDetails, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	return uc.eventRepo.GetJoinedEvents(ctx, userID, limit, offset)
}

// GetNearbyEvents gets events near a location
func (uc *Usecase) GetNearbyEvents(ctx context.Context, lat, lng, radiusKm float64, limit int) ([]event.EventWithDetails, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	return uc.eventRepo.GetNearby(ctx, lat, lng, radiusKm, limit)
}

// CountEvents counts total events matching filter
func (uc *Usecase) CountEvents(ctx context.Context, filter *event.EventFilter) (int, error) {
	return uc.eventRepo.CountEvents(ctx, filter)
}

// CountHostedEvents counts total events by a host
func (uc *Usecase) CountHostedEvents(ctx context.Context, hostID uuid.UUID) (int, error) {
	return uc.eventRepo.CountHostedEvents(ctx, hostID)
}

// CountJoinedEvents counts total events a user has joined
func (uc *Usecase) CountJoinedEvents(ctx context.Context, userID uuid.UUID) (int, error) {
	return uc.eventRepo.CountJoinedEvents(ctx, userID)
}

// CountAttendees counts total attendees for an event
func (uc *Usecase) CountAttendees(ctx context.Context, eventID uuid.UUID) (int, error) {
	return uc.eventRepo.CountAttendees(ctx, eventID)
}

// JoinEvent joins an event
func (uc *Usecase) JoinEvent(ctx context.Context, eventID, userID uuid.UUID) error {
	// Get event
	evt, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return ErrEventNotFound
	}

	// Check if event is full
	if evt.IsFull() {
		return ErrEventFull
	}

	// Check if already joined
	isAttending, err := uc.eventRepo.IsAttending(ctx, eventID, userID)
	if err != nil {
		return err
	}
	if isAttending {
		return ErrAlreadyJoined
	}

	// Create attendee record
	attendee := &event.EventAttendee{
		ID:       uuid.New(),
		EventID:  eventID,
		UserID:   userID,
		JoinedAt: time.Now(),
		Status:   event.AttendeeConfirmed,
	}

	return uc.eventRepo.Join(ctx, attendee)
}

// LeaveEvent leaves an event
func (uc *Usecase) LeaveEvent(ctx context.Context, eventID, userID uuid.UUID) error {
	// Get event
	evt, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return ErrEventNotFound
	}

	// Check if user is the host
	if evt.HostID == userID {
		return ErrCannotLeaveAsHost
	}

	// Check if joined
	isAttending, err := uc.eventRepo.IsAttending(ctx, eventID, userID)
	if err != nil {
		return err
	}
	if !isAttending {
		return ErrNotJoined
	}

	return uc.eventRepo.Leave(ctx, eventID, userID)
}

// GetAttendees gets event attendees
func (uc *Usecase) GetAttendees(ctx context.Context, eventID uuid.UUID, limit, offset int) ([]event.EventAttendee, error) {
	// Check if event exists
	_, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return nil, ErrEventNotFound
	}

	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}

	return uc.eventRepo.GetAttendees(ctx, eventID, limit, offset)
}

// IsAttending checks if a user is attending an event
func (uc *Usecase) IsAttending(ctx context.Context, eventID, userID uuid.UUID) (bool, error) {
	return uc.eventRepo.IsAttending(ctx, eventID, userID)
}

// CancelEvent cancels an event
func (uc *Usecase) CancelEvent(ctx context.Context, eventID, userID uuid.UUID) error {
	// Get existing event
	existingEvent, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return ErrEventNotFound
	}

	// Check if user is the host
	if existingEvent.HostID != userID {
		return ErrUnauthorized
	}

	// Check if event is already past
	if existingEvent.IsCompleted() {
		return ErrCannotCancelPast
	}

	// Update status to cancelled
	return uc.eventRepo.UpdateStatus(ctx, eventID, event.StatusCancelled)
}

// GetUpcomingEvents gets upcoming events
func (uc *Usecase) GetUpcomingEvents(ctx context.Context, limit int) ([]event.EventWithDetails, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	return uc.eventRepo.GetUpcomingEvents(ctx, limit)
}

// GetLiveEvents gets currently ongoing events
func (uc *Usecase) GetLiveEvents(ctx context.Context, limit int) ([]event.EventWithDetails, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	return uc.eventRepo.GetLiveEvents(ctx, limit)
}

// UpdateEventStatus updates the status of events based on time
// This should be called periodically by a background job
func (uc *Usecase) UpdateEventStatus(ctx context.Context, eventID uuid.UUID) error {
	evt, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return ErrEventNotFound
	}

	var newStatus event.EventStatus
	now := time.Now()

	switch {
	case evt.Status == event.StatusCancelled:
		// Keep cancelled status
		return nil
	case now.After(evt.EndTime):
		newStatus = event.StatusEnded
	case now.After(evt.StartTime) && now.Before(evt.EndTime):
		newStatus = event.StatusOngoing
	case now.Before(evt.StartTime):
		newStatus = event.StatusUpcoming
	default:
		return nil
	}

	if newStatus != evt.Status {
		return uc.eventRepo.UpdateStatus(ctx, eventID, newStatus)
	}

	return nil
}

// AddEventImages adds images to an existing event
func (uc *Usecase) AddEventImages(ctx context.Context, eventID, userID uuid.UUID, imageURLs []string) error {
	// Get existing event
	existingEvent, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return ErrEventNotFound
	}

	// Check if user is the host
	if existingEvent.HostID != userID {
		return ErrUnauthorized
	}

	// Get current images to determine the next order index
	currentImages, err := uc.eventRepo.GetImages(ctx, eventID)
	if err != nil {
		return err
	}

	// Create new image records starting from the next order index
	images := make([]event.EventImage, len(imageURLs))
	startOrder := len(currentImages)
	for i, url := range imageURLs {
		images[i] = event.EventImage{
			EventID:  eventID,
			ImageURL: url,
			Order:    startOrder + i,
		}
	}

	return uc.eventRepo.AddImages(ctx, images)
}

// DeleteEventImage deletes a specific image from an event
func (uc *Usecase) DeleteEventImage(ctx context.Context, eventID, imageID, userID uuid.UUID) error {
	// Get existing event
	existingEvent, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return ErrEventNotFound
	}

	// Check if user is the host
	if existingEvent.HostID != userID {
		return ErrUnauthorized
	}

	// Delete the image
	return uc.eventRepo.DeleteImage(ctx, imageID)
}

// ToggleInterest toggles a user's interest in an event
// Returns true if user is now interested, false if uninterested
func (uc *Usecase) ToggleInterest(ctx context.Context, eventID, userID uuid.UUID) (bool, error) {
	// Check if event exists
	_, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return false, ErrEventNotFound
	}

	// Toggle interest
	return uc.eventRepo.ToggleInterest(ctx, eventID, userID)
}

// IsInterested checks if a user is interested in an event
func (uc *Usecase) IsInterested(ctx context.Context, eventID, userID uuid.UUID) (bool, error) {
	// Check if event exists
	_, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return false, ErrEventNotFound
	}

	return uc.eventRepo.IsInterested(ctx, eventID, userID)
}

// GetInterestsCount gets the total number of interests for an event
func (uc *Usecase) GetInterestsCount(ctx context.Context, eventID uuid.UUID) (int, error) {
	// Check if event exists
	_, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return 0, ErrEventNotFound
	}

	return uc.eventRepo.GetInterestsCount(ctx, eventID)
}

// GetInterestedUsers gets a list of user IDs who are interested in an event
func (uc *Usecase) GetInterestedUsers(ctx context.Context, eventID, userID uuid.UUID, limit, offset int) ([]uuid.UUID, error) {
	// Check if event exists and user is the host
	event, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return nil, ErrEventNotFound
	}

	if event.HostID != userID {
		return nil, ErrUnauthorized
	}

	return uc.eventRepo.GetInterestedUsers(ctx, eventID, limit, offset)
}

// AttendeeWithDetails represents an attendee with user information
type AttendeeWithDetails struct {
	ID           uuid.UUID  `json:"id"`
	Name         string     `json:"name"`
	Avatar       *string    `json:"avatar"`
	TicketType   string     `json:"ticket_type"`
	TicketID     string     `json:"ticket_id"`
	CheckedIn    bool       `json:"checked_in"`
	CheckedInAt  *string    `json:"checked_in_at"`
	PurchasedAt  string     `json:"purchased_at"`
}

// GetAttendeesWithDetails gets all attendees (both paid tickets and free event attendees)
func (uc *Usecase) GetAttendeesWithDetails(ctx context.Context, eventID uuid.UUID, limit, offset int) ([]AttendeeWithDetails, int, error) {
	// Check if event exists
	_, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return nil, 0, ErrEventNotFound
	}

	allAttendees := make([]AttendeeWithDetails, 0)

	// Get paid event attendees from tickets table (these will be handled by ticket usecase in handler)
	// For now, just get free event attendees from event_attendees table
	freeAttendees, err := uc.eventRepo.GetAttendeesWithDetails(ctx, eventID, limit, offset)
	if err != nil {
		return nil, 0, err
	}

	for _, fa := range freeAttendees {
		checkedInAt := (*string)(nil)
		attendee := AttendeeWithDetails{
			ID:          fa.UserID,
			Name:        fa.Name,
			Avatar:      fa.AvatarURL,
			TicketType:  "Free",
			TicketID:    fa.ID.String(),
			CheckedIn:   false, // Free events don't have check-in yet
			CheckedInAt: checkedInAt,
			PurchasedAt: fa.JoinedAt.Format(time.RFC3339),
		}
		allAttendees = append(allAttendees, attendee)
	}

	// Get count for pagination
	count, err := uc.eventRepo.CountAttendeesWithDetails(ctx, eventID)
	if err != nil {
		return nil, 0, err
	}

	return allAttendees, count, nil
}

// ArchiveEvent archives an event (host only)
func (uc *Usecase) ArchiveEvent(ctx context.Context, eventID, userID uuid.UUID) (*event.Event, error) {
	// Get existing event
	existingEvent, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return nil, ErrEventNotFound
	}

	// Check if user is the host
	if existingEvent.HostID != userID {
		return nil, ErrUnauthorized
	}

	// Archive the event
	existingEvent.IsArchived = true
	existingEvent.UpdatedAt = time.Now().UTC()

	if err := uc.eventRepo.Update(ctx, existingEvent); err != nil {
		return nil, err
	}

	return existingEvent, nil
}

// UnarchiveEvent unarchives an event (host only)
func (uc *Usecase) UnarchiveEvent(ctx context.Context, eventID, userID uuid.UUID) (*event.Event, error) {
	// Get existing event
	existingEvent, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return nil, ErrEventNotFound
	}

	// Check if user is the host
	if existingEvent.HostID != userID {
		return nil, ErrUnauthorized
	}

	// Unarchive the event
	existingEvent.IsArchived = false
	existingEvent.UpdatedAt = time.Now().UTC()

	if err := uc.eventRepo.Update(ctx, existingEvent); err != nil {
		return nil, err
	}

	return existingEvent, nil
}
