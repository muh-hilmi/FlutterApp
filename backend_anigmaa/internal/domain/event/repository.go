package event

import (
	"context"
	"time"

	"github.com/google/uuid"
)

// Repository defines the interface for event data access
type Repository interface {
	// Event CRUD
	Create(ctx context.Context, event *Event) error
	GetByID(ctx context.Context, id uuid.UUID) (*Event, error)
	GetWithDetails(ctx context.Context, eventID, userID uuid.UUID) (*EventWithDetails, error)
	Update(ctx context.Context, event *Event) error
	Delete(ctx context.Context, id uuid.UUID) error

	// Event queries
	List(ctx context.Context, filter *EventFilter, userID uuid.UUID) ([]EventWithDetails, error)
	GetByHost(ctx context.Context, hostID uuid.UUID, limit, offset int) ([]EventWithDetails, error)
	GetJoinedEvents(ctx context.Context, userID uuid.UUID, limit, offset int) ([]EventWithDetails, error)
	GetNearby(ctx context.Context, lat, lng, radiusKm float64, limit int) ([]EventWithDetails, error)

	// Counting for pagination
	CountEvents(ctx context.Context, filter *EventFilter) (int, error)
	CountHostedEvents(ctx context.Context, hostID uuid.UUID) (int, error)
	CountJoinedEvents(ctx context.Context, userID uuid.UUID) (int, error)
	CountAttendees(ctx context.Context, eventID uuid.UUID) (int, error)

	// Attendee management
	Join(ctx context.Context, attendee *EventAttendee) error
	Leave(ctx context.Context, eventID, userID uuid.UUID) error
	GetAttendees(ctx context.Context, eventID uuid.UUID, limit, offset int) ([]EventAttendee, error)
	IsAttending(ctx context.Context, eventID, userID uuid.UUID) (bool, error)
	GetAttendeesCount(ctx context.Context, eventID uuid.UUID) (int, error)

	// Image management
	AddImages(ctx context.Context, images []EventImage) error
	GetImages(ctx context.Context, eventID uuid.UUID) ([]string, error)
	DeleteImage(ctx context.Context, imageID uuid.UUID) error
	DeleteAllImages(ctx context.Context, eventID uuid.UUID) error

	// Status management
	UpdateStatus(ctx context.Context, eventID uuid.UUID, status EventStatus) error
	GetUpcomingEvents(ctx context.Context, limit int) ([]EventWithDetails, error)
	GetLiveEvents(ctx context.Context, limit int) ([]EventWithDetails, error)

	// Analytics - get all events by host for revenue calculation
	GetByHostID(ctx context.Context, hostID uuid.UUID) ([]Event, error)

	// Interest/Like management
	ToggleInterest(ctx context.Context, eventID, userID uuid.UUID) (isInterested bool, err error)
	IsInterested(ctx context.Context, eventID, userID uuid.UUID) (bool, error)
	GetInterestsCount(ctx context.Context, eventID uuid.UUID) (int, error)
	GetInterestedUsers(ctx context.Context, eventID uuid.UUID, limit, offset int) ([]uuid.UUID, error)

	// Attendees with user details (for free events)
	GetAttendeesWithDetails(ctx context.Context, eventID uuid.UUID, limit, offset int) ([]struct {
		ID        uuid.UUID `db:"id"`
		UserID    uuid.UUID `db:"user_id"`
		EventID   uuid.UUID `db:"event_id"`
		Name      string    `db:"name"`
		AvatarURL *string   `db:"avatar_url"`
		JoinedAt  time.Time `db:"joined_at"`
	}, error)
	CountAttendeesWithDetails(ctx context.Context, eventID uuid.UUID) (int, error)
}
