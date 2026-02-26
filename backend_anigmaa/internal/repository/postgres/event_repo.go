package postgres

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/anigmaa/backend/internal/domain/event"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type eventRepository struct {
	db *sqlx.DB
}

func NewEventRepository(db *sqlx.DB) event.Repository {
	return &eventRepository{db: db}
}

func (r *eventRepository) Create(ctx context.Context, e *event.Event) error {
	query := `
		INSERT INTO events (id, host_id, title, description, category, start_time, end_time,
			location_name, location_address, location_lat, location_lng, location_geom,
			max_attendees, price, is_free, status, privacy, requirements, ticketing_enabled,
			tickets_sold, is_archived, created_at, updated_at)
		VALUES ($1::uuid, $2::uuid, $3, $4, $5::event_category, $6::timestamp with time zone, $7::timestamp with time zone,
			$8, $9, $10::numeric, $11::numeric, ST_SetSRID(ST_MakePoint($11::numeric, $10::numeric), 4326),
			$12::integer, $13::numeric, $14, $15::event_status, $16::event_privacy, $17,
			$18, $19::integer, $20, $21::timestamp with time zone, $22::timestamp with time zone)
	`

	e.ID = uuid.New()
	e.CreatedAt = time.Now().UTC()
	e.UpdatedAt = time.Now().UTC()
	e.Status = event.StatusUpcoming
	e.TicketsSold = 0
	e.IsArchived = false

	_, err := r.db.ExecContext(ctx, query,
		e.ID, e.HostID, e.Title, e.Description, e.Category, e.StartTime, e.EndTime,
		e.LocationName, e.LocationAddress, e.LocationLat, e.LocationLng,
		e.MaxAttendees, e.Price, e.IsFree, e.Status, e.Privacy, e.Requirements,
		e.TicketingEnabled, e.TicketsSold, e.IsArchived, e.CreatedAt, e.UpdatedAt,
	)

	return err
}

func (r *eventRepository) GetByID(ctx context.Context, id uuid.UUID) (*event.Event, error) {
	var e event.Event
	query := `SELECT id, host_id, title, description, category, start_time, end_time,
		location_name, location_address, ST_Y(location_geom::geometry) as location_lat, ST_X(location_geom::geometry) as location_lng, max_attendees,
		price, is_free, status, privacy, requirements, ticketing_enabled, tickets_sold, is_archived,
		created_at, updated_at FROM events WHERE id = $1`

	err := r.db.GetContext(ctx, &e, query, id)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("event not found")
	}

	return &e, err
}

func (r *eventRepository) GetWithDetails(ctx context.Context, eventID, userID uuid.UUID) (*event.EventWithDetails, error) {
	query := `
		SELECT e.id, e.host_id, e.title, e.description, e.category, e.start_time, e.end_time,
			e.location_name, e.location_address, ST_Y(e.location_geom::geometry) as location_lat, ST_X(e.location_geom::geometry) as location_lng,
			e.max_attendees, e.price, e.is_free, e.status, e.privacy, e.requirements,
			e.ticketing_enabled, e.tickets_sold, e.is_archived, e.created_at, e.updated_at,
			(SELECT COUNT(*) FROM event_interests WHERE event_id = e.id) as interests_count,
			u.name as host_name, u.avatar_url as host_avatar_url,
			(SELECT COUNT(*) FROM event_attendees WHERE event_id = e.id AND status = 'confirmed') as attendees_count,
			EXISTS(SELECT 1 FROM event_attendees WHERE event_id = e.id AND user_id = $2 AND status = 'confirmed') as is_user_attending,
			EXISTS(SELECT 1 FROM event_interests WHERE event_id = e.id AND user_id = $2) as is_user_interested,
			(e.host_id = $2) as is_user_host
		FROM events e
		INNER JOIN users u ON e.host_id = u.id
		WHERE e.id = $1
	`

	var details event.EventWithDetails
	err := r.db.GetContext(ctx, &details, query, eventID, userID)
	if err != nil {
		return nil, err
	}

	images, _ := r.GetImages(ctx, eventID)
	details.ImageURLs = images

	// Fetch interested user IDs (limit to first 100 for performance)
	interestedUsers, _ := r.GetInterestedUsers(ctx, eventID, 100, 0)
	details.InterestedUserIDs = interestedUsers

	return &details, nil
}

func (r *eventRepository) Update(ctx context.Context, e *event.Event) error {
	query := `
		UPDATE events SET title = $1, description = $2, category = $3, start_time = $4,
			end_time = $5, location_name = $6, location_address = $7, location_lat = $8,
			location_lng = $9, location_geom = ST_SetSRID(ST_MakePoint($9, $8), 4326),
			max_attendees = $10, price = $11, privacy = $12, requirements = $13,
			status = $14, is_archived = $15, updated_at = $16
		WHERE id = $17
	`

	e.UpdatedAt = time.Now()
	_, err := r.db.ExecContext(ctx, query,
		e.Title, e.Description, e.Category, e.StartTime, e.EndTime,
		e.LocationName, e.LocationAddress, e.LocationLat, e.LocationLng,
		e.MaxAttendees, e.Price, e.Privacy, e.Requirements, e.Status,
		e.IsArchived, e.UpdatedAt, e.ID,
	)

	return err
}

func (r *eventRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM events WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	return err
}

func (r *eventRepository) List(ctx context.Context, filter *event.EventFilter, userID uuid.UUID) ([]event.EventWithDetails, error) {
	query := `
		SELECT e.id, e.host_id, e.title, e.description, e.category, e.start_time, e.end_time,
			e.location_name, e.location_address, ST_Y(e.location_geom::geometry) as location_lat, ST_X(e.location_geom::geometry) as location_lng,
			e.max_attendees, e.price, e.is_free, e.status, e.privacy, e.requirements,
			e.ticketing_enabled, e.tickets_sold, e.is_archived, e.created_at, e.updated_at,
			(SELECT COUNT(*) FROM event_interests WHERE event_id = e.id) as interests_count,
			u.name as host_name, u.avatar_url as host_avatar_url,
			(SELECT COUNT(*) FROM event_attendees WHERE event_id = e.id AND status = 'confirmed') as attendees_count,
			EXISTS(SELECT 1 FROM event_interests WHERE event_id = e.id AND user_id = $1) as is_user_interested,
		EXISTS(SELECT 1 FROM event_attendees WHERE event_id = e.id AND user_id = $1 AND status = 'confirmed') as is_user_attending,
		(e.host_id = $1) as is_user_host
		FROM events e
		INNER JOIN users u ON e.host_id = u.id
		WHERE 1=1
	`

	args := []interface{}{userID}
	argCount := 2

	// Strict filtering: Only show active events
	// Exclude events that are: ended, cancelled, or have passed their end time
	if filter.Status == nil {
		// Show only upcoming and ongoing events that haven't ended yet
		query += " AND e.status IN ('upcoming', 'ongoing')"
		query += " AND e.end_time >= NOW()"
	}

	// Hide events older than 3 months (90 days) - only applies to discovery
	// This ensures we don't show very old upcoming events
	if filter.Status == nil {
		query += fmt.Sprintf(" AND e.created_at >= $%d", argCount)
		args = append(args, time.Now().AddDate(0, -3, 0)) // 3 months ago
		argCount++
	}

	if filter.Category != nil {
		query += fmt.Sprintf(" AND e.category = $%d", argCount)
		args = append(args, *filter.Category)
		argCount++
	}

	if filter.IsFree != nil {
		query += fmt.Sprintf(" AND e.is_free = $%d", argCount)
		args = append(args, *filter.IsFree)
		argCount++
	}

	if filter.Status != nil {
		query += fmt.Sprintf(" AND e.status = $%d", argCount)
		args = append(args, *filter.Status)
		argCount++
	}

	// CTO REVIEW: Discovery mode algorithms need improvement
	// All modes are missing the completed event filter (see line 126 comment)
	// "chill" mode should also filter by price/free status and max_attendees < 30
	// "for_you" has BROKEN MATH - see below

	// Apply different sorting based on discovery mode
	switch filter.Mode {
	case "trending":
		// CTO REVIEW: Algorithm is OK but needs status filter
		// Trending: Popular/new events - prioritize engagement + recency
		// Combine attendees count with how recent the event is
		query += ` ORDER BY
			(SELECT COUNT(*) FROM event_attendees WHERE event_id = e.id AND status = 'confirmed') DESC,
			e.created_at DESC,
			random()`

	case "for_you":
		// For You: Personalized mix - balance popularity with discovery
		// Recency bonus: newer events get higher scores (max +9 for brand new)
		// - Event created today: GREATEST(30 - 0, 0) * 0.3 = 9.0 (max bonus)
		// - Event created 15 days ago: GREATEST(30 - 15, 0) * 0.3 = 4.5 (medium bonus)
		// - Event created 30+ days ago: GREATEST(30 - 30, 0) * 0.3 = 0 (no bonus)
		query += ` ORDER BY
			((SELECT COUNT(*) FROM event_attendees WHERE event_id = e.id AND status = 'confirmed') * 0.5 +
			 GREATEST(30 - EXTRACT(DAY FROM (NOW() - e.created_at)), 0) * 0.3) +
			random() * 10 DESC`

	case "chill":
		// Chill: Small, intimate, budget-friendly events
		// Filter for small capacity (<50) AND (free OR low price <200000)
		query += ` AND (e.max_attendees < 50)
			AND (e.is_free = true OR e.price < 200000)
			ORDER BY
			e.max_attendees ASC,
			(SELECT COUNT(*) FROM event_attendees WHERE event_id = e.id AND status = 'confirmed') ASC,
			random()`

	default:
		// Default: Simple chronological with some randomness
		query += ` ORDER BY
			e.created_at DESC,
			random()`
	}

	if filter.Limit > 0 {
		query += fmt.Sprintf(" LIMIT $%d", argCount)
		args = append(args, filter.Limit)
		argCount++
	}

	if filter.Offset > 0 {
		query += fmt.Sprintf(" OFFSET $%d", argCount)
		args = append(args, filter.Offset)
	}

	var events []event.EventWithDetails
	err := r.db.SelectContext(ctx, &events, query, args...)
	if err != nil {
		return nil, err
	}

	// Populate image URLs and interested user IDs for each event
	for i := range events {
		images, _ := r.GetImages(ctx, events[i].ID)
		events[i].ImageURLs = images
		// Fetch interested user IDs (limit to first 20 for performance in list view)
		interestedUsers, _ := r.GetInterestedUsers(ctx, events[i].ID, 20, 0)
		events[i].InterestedUserIDs = interestedUsers
	}

	return events, nil
}

func (r *eventRepository) GetByHost(ctx context.Context, hostID uuid.UUID, limit, offset int) ([]event.EventWithDetails, error) {
	query := `
		SELECT e.id, e.host_id, e.title, e.description, e.category, e.start_time, e.end_time,
			e.location_name, e.location_address, ST_Y(e.location_geom::geometry) as location_lat, ST_X(e.location_geom::geometry) as location_lng,
			e.max_attendees, e.price, e.is_free, e.status, e.privacy, e.requirements,
			e.ticketing_enabled, e.tickets_sold, e.is_archived, e.created_at, e.updated_at,
			(SELECT COUNT(*) FROM event_interests WHERE event_id = e.id) as interests_count,
			u.name as host_name, u.avatar_url as host_avatar_url,
			(SELECT COUNT(*) FROM event_attendees WHERE event_id = e.id AND status = 'confirmed') as attendees_count
		FROM events e
		INNER JOIN users u ON e.host_id = u.id
		WHERE e.host_id = $1
		ORDER BY e.created_at DESC
		LIMIT $2 OFFSET $3
	`

	var events []event.EventWithDetails
	err := r.db.SelectContext(ctx, &events, query, hostID, limit, offset)
	if err != nil {
		return nil, err
	}

	// Populate image URLs and interested user IDs for each event
	for i := range events {
		images, _ := r.GetImages(ctx, events[i].ID)
		events[i].ImageURLs = images
		interestedUsers, _ := r.GetInterestedUsers(ctx, events[i].ID, 20, 0)
		events[i].InterestedUserIDs = interestedUsers
	}

	return events, nil
}

func (r *eventRepository) GetJoinedEvents(ctx context.Context, userID uuid.UUID, limit, offset int) ([]event.EventWithDetails, error) {
	query := `
		SELECT e.id, e.host_id, e.title, e.description, e.category, e.start_time, e.end_time,
			e.location_name, e.location_address, ST_Y(e.location_geom::geometry) as location_lat, ST_X(e.location_geom::geometry) as location_lng,
			e.max_attendees, e.price, e.is_free, e.status, e.privacy, e.requirements,
			e.ticketing_enabled, e.tickets_sold, e.is_archived, e.created_at, e.updated_at,
			(SELECT COUNT(*) FROM event_interests WHERE event_id = e.id) as interests_count,
			u.name as host_name, u.avatar_url as host_avatar_url,
			(SELECT COUNT(*) FROM event_attendees WHERE event_id = e.id AND status = 'confirmed') as attendees_count,
			true as is_user_attending
		FROM events e
		INNER JOIN users u ON e.host_id = u.id
		INNER JOIN event_attendees ea ON e.id = ea.event_id
		WHERE ea.user_id = $1 AND ea.status = 'confirmed'
		ORDER BY e.start_time ASC
		LIMIT $2 OFFSET $3
	`

	var events []event.EventWithDetails
	err := r.db.SelectContext(ctx, &events, query, userID, limit, offset)
	if err != nil {
		return nil, err
	}

	// Populate interested user IDs for each event
	for i := range events {
		interestedUsers, _ := r.GetInterestedUsers(ctx, events[i].ID, 20, 0)
		events[i].InterestedUserIDs = interestedUsers
	}

	return events, nil
}

func (r *eventRepository) GetNearby(ctx context.Context, lat, lng, radiusKm float64, limit int) ([]event.EventWithDetails, error) {
	query := `
		SELECT e.id, e.host_id, e.title, e.description, e.category, e.start_time, e.end_time,
			e.location_name, e.location_address, ST_Y(e.location_geom::geometry) as location_lat, ST_X(e.location_geom::geometry) as location_lng,
			e.max_attendees, e.price, e.is_free, e.status, e.privacy, e.requirements,
			e.ticketing_enabled, e.tickets_sold, e.is_archived, e.created_at, e.updated_at,
			(SELECT COUNT(*) FROM event_interests WHERE event_id = e.id) as interests_count,
			u.name as host_name, u.avatar_url as host_avatar_url,
			(SELECT COUNT(*) FROM event_attendees WHERE event_id = e.id AND status = 'confirmed') as attendees_count,
			ST_Distance(e.location_geom::geography, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography) / 1000 as distance
		FROM events e
		INNER JOIN users u ON e.host_id = u.id
		WHERE ST_DWithin(e.location_geom::geography, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography, $3 * 1000)
			AND e.status IN ('upcoming', 'ongoing')
			AND e.end_time >= NOW()
			AND e.created_at >= $5
		ORDER BY (
			(SELECT COUNT(*) FROM event_attendees WHERE event_id = e.id AND status = 'confirmed') + 1
		) * random() DESC
		LIMIT $4
	`

	var events []event.EventWithDetails
	err := r.db.SelectContext(ctx, &events, query, lat, lng, radiusKm, limit, time.Now().AddDate(0, -3, 0))
	if err != nil {
		return nil, err
	}

	// Populate interested user IDs for each event
	for i := range events {
		interestedUsers, _ := r.GetInterestedUsers(ctx, events[i].ID, 20, 0)
		events[i].InterestedUserIDs = interestedUsers
	}

	return events, nil
}

func (r *eventRepository) Join(ctx context.Context, attendee *event.EventAttendee) error {
	query := `
		INSERT INTO event_attendees (id, event_id, user_id, joined_at, status)
		VALUES ($1, $2, $3, $4, $5)
	`

	attendee.ID = uuid.New()
	attendee.JoinedAt = time.Now()
	attendee.Status = event.AttendeeConfirmed

	_, err := r.db.ExecContext(ctx, query, attendee.ID, attendee.EventID, attendee.UserID, attendee.JoinedAt, attendee.Status)
	return err
}

func (r *eventRepository) Leave(ctx context.Context, eventID, userID uuid.UUID) error {
	query := `DELETE FROM event_attendees WHERE event_id = $1 AND user_id = $2`
	_, err := r.db.ExecContext(ctx, query, eventID, userID)
	return err
}

func (r *eventRepository) GetAttendees(ctx context.Context, eventID uuid.UUID, limit, offset int) ([]event.EventAttendee, error) {
	query := `
		SELECT * FROM event_attendees
		WHERE event_id = $1 AND status = 'confirmed'
		ORDER BY joined_at DESC
		LIMIT $2 OFFSET $3
	`

	var attendees []event.EventAttendee
	err := r.db.SelectContext(ctx, &attendees, query, eventID, limit, offset)
	return attendees, err
}

func (r *eventRepository) IsAttending(ctx context.Context, eventID, userID uuid.UUID) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM event_attendees WHERE event_id = $1 AND user_id = $2 AND status = 'confirmed')`
	var exists bool
	err := r.db.GetContext(ctx, &exists, query, eventID, userID)
	return exists, err
}

func (r *eventRepository) GetAttendeesCount(ctx context.Context, eventID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM event_attendees WHERE event_id = $1 AND status = 'confirmed'`
	var count int
	err := r.db.GetContext(ctx, &count, query, eventID)
	return count, err
}

func (r *eventRepository) AddImages(ctx context.Context, images []event.EventImage) error {
	query := `INSERT INTO event_images (id, event_id, image_url, order_index) VALUES ($1, $2, $3, $4)`

	for _, img := range images {
		img.ID = uuid.New()
		_, err := r.db.ExecContext(ctx, query, img.ID, img.EventID, img.ImageURL, img.Order)
		if err != nil {
			return err
		}
	}

	return nil
}

func (r *eventRepository) GetImages(ctx context.Context, eventID uuid.UUID) ([]string, error) {
	query := `SELECT image_url FROM event_images WHERE event_id = $1 ORDER BY order_index ASC`

	var images []string
	err := r.db.SelectContext(ctx, &images, query, eventID)
	return images, err
}

func (r *eventRepository) DeleteImage(ctx context.Context, imageID uuid.UUID) error {
	query := `DELETE FROM event_images WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, imageID)
	return err
}

func (r *eventRepository) DeleteAllImages(ctx context.Context, eventID uuid.UUID) error {
	query := `DELETE FROM event_images WHERE event_id = $1`
	_, err := r.db.ExecContext(ctx, query, eventID)
	return err
}

func (r *eventRepository) UpdateStatus(ctx context.Context, eventID uuid.UUID, status event.EventStatus) error {
	query := `UPDATE events SET status = $1, updated_at = $2 WHERE id = $3`
	_, err := r.db.ExecContext(ctx, query, status, time.Now(), eventID)
	return err
}

func (r *eventRepository) GetUpcomingEvents(ctx context.Context, limit int) ([]event.EventWithDetails, error) {
	query := `
		SELECT e.id, e.host_id, e.title, e.description, e.category, e.start_time, e.end_time,
			e.location_name, e.location_address, ST_Y(e.location_geom::geometry) as location_lat, ST_X(e.location_geom::geometry) as location_lng,
			e.max_attendees, e.price, e.is_free, e.status, e.privacy, e.requirements,
			e.ticketing_enabled, e.tickets_sold, e.is_archived, e.created_at, e.updated_at,
			(SELECT COUNT(*) FROM event_interests WHERE event_id = e.id) as interests_count,
			u.name as host_name, u.avatar_url as host_avatar_url,
			(SELECT COUNT(*) FROM event_attendees WHERE event_id = e.id AND status = 'confirmed') as attendees_count
		FROM events e
		INNER JOIN users u ON e.host_id = u.id
		WHERE e.status IN ('upcoming', 'ongoing')
			AND e.end_time >= NOW()
			AND e.created_at >= $2
		ORDER BY (
			(SELECT COUNT(*) FROM event_attendees WHERE event_id = e.id AND status = 'confirmed') + 1
		) * random() DESC
		LIMIT $1
	`

	var events []event.EventWithDetails
	err := r.db.SelectContext(ctx, &events, query, limit, time.Now().AddDate(0, -3, 0))
	if err != nil {
		return nil, err
	}

	// Populate interested user IDs for each event
	for i := range events {
		interestedUsers, _ := r.GetInterestedUsers(ctx, events[i].ID, 20, 0)
		events[i].InterestedUserIDs = interestedUsers
	}

	return events, nil
}

func (r *eventRepository) GetLiveEvents(ctx context.Context, limit int) ([]event.EventWithDetails, error) {
	query := `
		SELECT e.id, e.host_id, e.title, e.description, e.category, e.start_time, e.end_time,
			e.location_name, e.location_address, ST_Y(e.location_geom::geometry) as location_lat, ST_X(e.location_geom::geometry) as location_lng,
			e.max_attendees, e.price, e.is_free, e.status, e.privacy, e.requirements,
			e.ticketing_enabled, e.tickets_sold, e.is_archived, e.created_at, e.updated_at,
			(SELECT COUNT(*) FROM event_interests WHERE event_id = e.id) as interests_count,
			u.name as host_name, u.avatar_url as host_avatar_url,
			(SELECT COUNT(*) FROM event_attendees WHERE event_id = e.id AND status = 'confirmed') as attendees_count
		FROM events e
		INNER JOIN users u ON e.host_id = u.id
		WHERE e.status = 'ongoing'
			AND e.start_time <= NOW()
			AND e.end_time >= NOW()
			AND e.created_at >= $2
		ORDER BY (
			(SELECT COUNT(*) FROM event_attendees WHERE event_id = e.id AND status = 'confirmed') + 1
		) * random() DESC
		LIMIT $1
	`

	var events []event.EventWithDetails
	err := r.db.SelectContext(ctx, &events, query, limit, time.Now().AddDate(0, -3, 0))
	if err != nil {
		return nil, err
	}

	// Populate interested user IDs for each event
	for i := range events {
		interestedUsers, _ := r.GetInterestedUsers(ctx, events[i].ID, 20, 0)
		events[i].InterestedUserIDs = interestedUsers
	}

	return events, nil
}

// GetByHostID gets all events created by a host (for analytics)
func (r *eventRepository) GetByHostID(ctx context.Context, hostID uuid.UUID) ([]event.Event, error) {
	query := `
		SELECT id, host_id, title, description, category, start_time, end_time,
			location_name, location_address, ST_Y(location_geom::geometry) as location_lat, ST_X(location_geom::geometry) as location_lng,
			max_attendees, price, is_free, status, privacy, requirements,
			ticketing_enabled, tickets_sold, is_archived, created_at, updated_at
		FROM events
		WHERE host_id = $1
		ORDER BY start_time DESC
	`

	var events []event.Event
	err := r.db.SelectContext(ctx, &events, query, hostID)
	if err != nil {
		return nil, err
	}

	return events, nil
}

// CountEvents counts total events matching filter
func (r *eventRepository) CountEvents(ctx context.Context, filter *event.EventFilter) (int, error) {
	query := `SELECT COUNT(*) FROM events WHERE 1=1`
	args := []interface{}{}
	argCount := 1

	// Strict filtering: Only show active events
	// Exclude events that are: ended, cancelled, or have passed their end time
	if filter.Status == nil {
		// Show only upcoming and ongoing events that haven't ended yet
		query += " AND status IN ('upcoming', 'ongoing')"
		query += " AND end_time >= NOW()"
	}

	// Hide events older than 3 months (90 days) - only applies to discovery
	// This ensures we don't show very old upcoming events
	if filter.Status == nil {
		query += fmt.Sprintf(" AND created_at >= $%d", argCount)
		args = append(args, time.Now().AddDate(0, -3, 0)) // 3 months ago
		argCount++
	}

	if filter.Category != nil {
		query += fmt.Sprintf(" AND category = $%d", argCount)
		args = append(args, *filter.Category)
		argCount++
	}
	if filter.Status != nil {
		query += fmt.Sprintf(" AND status = $%d", argCount)
		args = append(args, *filter.Status)
		argCount++
	}
	if filter.IsFree != nil {
		query += fmt.Sprintf(" AND is_free = $%d", argCount)
		args = append(args, *filter.IsFree)
		argCount++
	}
	if filter.StartDate != nil {
		query += fmt.Sprintf(" AND start_time >= $%d", argCount)
		args = append(args, *filter.StartDate)
		argCount++
	}
	if filter.EndDate != nil {
		query += fmt.Sprintf(" AND end_time <= $%d", argCount)
		args = append(args, *filter.EndDate)
		argCount++
	}

	var count int
	err := r.db.QueryRowContext(ctx, query, args...).Scan(&count)
	return count, err
}

// CountHostedEvents counts total events by a host
func (r *eventRepository) CountHostedEvents(ctx context.Context, hostID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM events WHERE host_id = $1`
	var count int
	err := r.db.QueryRowContext(ctx, query, hostID).Scan(&count)
	return count, err
}

// CountJoinedEvents counts total events a user has joined
func (r *eventRepository) CountJoinedEvents(ctx context.Context, userID uuid.UUID) (int, error) {
	query := `
		SELECT COUNT(*)
		FROM event_attendees ea
		WHERE ea.user_id = $1 AND ea.status = 'confirmed'
	`
	var count int
	err := r.db.QueryRowContext(ctx, query, userID).Scan(&count)
	return count, err
}

// CountAttendees counts total attendees for an event
func (r *eventRepository) CountAttendees(ctx context.Context, eventID uuid.UUID) (int, error) {
	query := `
		SELECT COUNT(*)
		FROM event_attendees
		WHERE event_id = $1 AND status = 'confirmed'
	`
	var count int
	err := r.db.QueryRowContext(ctx, query, eventID).Scan(&count)
	return count, err
}

// ToggleInterest toggles a user's interest in an event
// Returns true if user is now interested, false if uninterested
func (r *eventRepository) ToggleInterest(ctx context.Context, eventID, userID uuid.UUID) (bool, error) {
	// Check if user is already interested
	var exists bool
	checkQuery := `SELECT EXISTS(SELECT 1 FROM event_interests WHERE event_id = $1 AND user_id = $2)`
	err := r.db.GetContext(ctx, &exists, checkQuery, eventID, userID)
	if err != nil {
		return false, err
	}

	if exists {
		// Remove interest
		deleteQuery := `DELETE FROM event_interests WHERE event_id = $1 AND user_id = $2`
		_, err = r.db.ExecContext(ctx, deleteQuery, eventID, userID)
		if err != nil {
			return false, err
		}

		// Decrement interests count
		updateQuery := `UPDATE events SET interests_count = interests_count - 1 WHERE id = $1 AND interests_count > 0`
		_, err = r.db.ExecContext(ctx, updateQuery, eventID)
		if err != nil {
			return false, err
		}

		return false, nil
	} else {
		// Add interest
		interest := &event.EventInterest{
			ID:        uuid.New(),
			EventID:   eventID,
			UserID:    userID,
			CreatedAt: time.Now(),
		}

		insertQuery := `INSERT INTO event_interests (id, event_id, user_id, created_at) VALUES ($1, $2, $3, $4)`
		_, err = r.db.ExecContext(ctx, insertQuery, interest.ID, interest.EventID, interest.UserID, interest.CreatedAt)
		if err != nil {
			return false, err
		}

		// Increment interests count
		updateQuery := `UPDATE events SET interests_count = interests_count + 1 WHERE id = $1`
		_, err = r.db.ExecContext(ctx, updateQuery, eventID)
		if err != nil {
			return false, err
		}

		return true, nil
	}
}

// IsInterested checks if a user is interested in an event
func (r *eventRepository) IsInterested(ctx context.Context, eventID, userID uuid.UUID) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM event_interests WHERE event_id = $1 AND user_id = $2)`
	var exists bool
	err := r.db.GetContext(ctx, &exists, query, eventID, userID)
	return exists, err
}

// GetInterestsCount gets the total number of interests for an event
func (r *eventRepository) GetInterestsCount(ctx context.Context, eventID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM event_interests WHERE event_id = $1`
	var count int
	err := r.db.GetContext(ctx, &count, query, eventID)
	return count, err
}

// GetInterestedUsers gets a list of user IDs who are interested in an event
func (r *eventRepository) GetInterestedUsers(ctx context.Context, eventID uuid.UUID, limit, offset int) ([]uuid.UUID, error) {
	query := `
		SELECT user_id
		FROM event_interests
		WHERE event_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`
	rows, err := r.db.QueryxContext(ctx, query, eventID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var userIDs []uuid.UUID
	for rows.Next() {
		var userID uuid.UUID
		if err := rows.Scan(&userID); err != nil {
			return nil, err
		}
		userIDs = append(userIDs, userID)
	}

	return userIDs, nil
}

// GetAttendeesWithDetails gets event attendees with user details (for free events)
func (r *eventRepository) GetAttendeesWithDetails(ctx context.Context, eventID uuid.UUID, limit, offset int) ([]struct {
	ID           uuid.UUID  `db:"id"`
	UserID       uuid.UUID  `db:"user_id"`
	EventID      uuid.UUID  `db:"event_id"`
	Name         string     `db:"name"`
	AvatarURL    *string    `db:"avatar_url"`
	JoinedAt     time.Time  `db:"joined_at"`
}, error) {
	query := `
		SELECT ea.id, ea.user_id, ea.event_id, u.name, u.avatar_url, ea.joined_at
		FROM event_attendees ea
		INNER JOIN users u ON ea.user_id = u.id
		WHERE ea.event_id = $1 AND ea.status = 'confirmed'
		ORDER BY ea.joined_at DESC
		LIMIT $2 OFFSET $3
	`

	var attendees []struct {
		ID        uuid.UUID `db:"id"`
		UserID    uuid.UUID `db:"user_id"`
		EventID   uuid.UUID `db:"event_id"`
		Name      string    `db:"name"`
		AvatarURL *string   `db:"avatar_url"`
		JoinedAt  time.Time `db:"joined_at"`
	}
	err := r.db.SelectContext(ctx, &attendees, query, eventID, limit, offset)
	if err != nil {
		return nil, err
	}

	if attendees == nil {
		attendees = []struct {
			ID        uuid.UUID `db:"id"`
			UserID    uuid.UUID `db:"user_id"`
			EventID   uuid.UUID `db:"event_id"`
			Name      string    `db:"name"`
			AvatarURL *string   `db:"avatar_url"`
			JoinedAt  time.Time `db:"joined_at"`
		}{}
	}

	return attendees, nil
}

// CountAttendeesWithDetails counts total attendees from event_attendees table
func (r *eventRepository) CountAttendeesWithDetails(ctx context.Context, eventID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM event_attendees WHERE event_id = $1 AND status = 'confirmed'`
	var count int
	err := r.db.GetContext(ctx, &count, query, eventID)
	return count, err
}
