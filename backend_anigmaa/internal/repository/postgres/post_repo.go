package postgres

import (
	"context"
	"database/sql"
	"encoding/json"
	"time"

	"github.com/anigmaa/backend/internal/domain/post"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type postRepository struct {
	db *sqlx.DB
}

// NewPostRepository creates a new post repository
func NewPostRepository(db *sqlx.DB) post.Repository {
	return &postRepository{db: db}
}

// Create creates a new post
func (r *postRepository) Create(ctx context.Context, p *post.Post) error {
	// Generate UUID if not provided
	if p.ID == uuid.Nil {
		p.ID = uuid.New()
	}

	// Set timestamps
	now := time.Now()
	p.CreatedAt = now
	p.UpdatedAt = now

	query := `
		INSERT INTO posts (
			id, author_id, content, type, attached_event_id, original_post_id,
			visibility, created_at, updated_at, likes_count, comments_count,
			reposts_count, shares_count
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 0, 0, 0, 0)
	`

	_, err := r.db.ExecContext(ctx, query,
		p.ID, p.AuthorID, p.Content, p.Type, p.AttachedEventID, p.OriginalPostID,
		p.Visibility, p.CreatedAt, p.UpdatedAt,
	)

	return err
}

// GetByID gets a post by ID
func (r *postRepository) GetByID(ctx context.Context, postID uuid.UUID) (*post.Post, error) {
	query := `
		SELECT id, author_id, content, type, attached_event_id, original_post_id,
		       visibility, created_at, updated_at, likes_count, comments_count,
		       reposts_count, shares_count
		FROM posts
		WHERE id = $1
	`

	var p post.Post
	err := r.db.GetContext(ctx, &p, query, postID)
	if err != nil {
		return nil, err
	}

	return &p, nil
}

// GetWithDetails gets a post with full details
func (r *postRepository) GetWithDetails(ctx context.Context, postID, userID uuid.UUID) (*post.PostWithDetails, error) {
	query := `
		SELECT
			p.id, p.author_id, p.content, p.type, p.attached_event_id,
			p.original_post_id, p.visibility, p.created_at, p.updated_at,
			p.likes_count, p.comments_count, p.reposts_count, p.shares_count,
			u.name as author_name, u.avatar_url as author_avatar_url, u.is_verified as author_is_verified,
			EXISTS(SELECT 1 FROM likes WHERE user_id = $2 AND likeable_type = 'post' AND likeable_id = p.id) as is_liked_by_user,
			EXISTS(SELECT 1 FROM bookmarks WHERE user_id = $2 AND post_id = p.id) as is_bookmarked_by_user,
			EXISTS(SELECT 1 FROM reposts WHERE user_id = $2 AND post_id = p.id) as is_reposted_by_user,
			COALESCE(
				(SELECT json_agg(image_url ORDER BY order_index)
				 FROM post_images WHERE post_id = p.id), '[]'::json
			) as image_urls,
			e.id as event_id, e.title as event_title, e.description as event_description,
			e.category as event_category, e.start_time as event_start_time, e.end_time as event_end_time,
			e.location_name as event_location_name, e.location_address as event_location_address,
			e.location_lat as event_location_lat, e.location_lng as event_location_lng,
			e.host_id as event_host_id, eh.name as event_host_name, eh.avatar_url as event_host_avatar_url,
			e.max_attendees as event_max_attendees,
			(SELECT COUNT(*) FROM event_attendees WHERE event_id = e.id AND status = 'confirmed') as event_attendees_count,
			(SELECT COUNT(*) FROM event_interests WHERE event_id = e.id) as interests_count,
			e.price as event_price, e.is_free as event_is_free,
			e.status as event_status, e.privacy as event_privacy,
			COALESCE(
				(SELECT json_agg(image_url ORDER BY order_index)
				 FROM event_images WHERE event_id = e.id), '[]'::json
			) as event_image_urls
		FROM posts p
		INNER JOIN users u ON p.author_id = u.id
		LEFT JOIN events e ON p.attached_event_id = e.id
		LEFT JOIN users eh ON e.host_id = eh.id
		WHERE p.id = $1
	`

	var p post.PostWithDetails
	var imageURLs []byte
	var eventImageURLs []byte

	// Event fields (nullable)
	var eventID, eventHostID *uuid.UUID
	var eventTitle, eventDescription, eventCategory *string
	var eventStartTime, eventEndTime *time.Time
	var eventLocationName, eventLocationAddress *string
	var eventLocationLat, eventLocationLng *float64
	var eventHostName, eventHostAvatarURL *string
	var eventMaxAttendees *int
	var eventAttendeesCount *int
	var eventPrice *float64
	var eventIsFree *bool
	var eventStatus, eventPrivacy *string

	err := r.db.QueryRowxContext(ctx, query, postID, userID).Scan(
		&p.ID, &p.AuthorID, &p.Content, &p.Type, &p.AttachedEventID,
		&p.OriginalPostID, &p.Visibility, &p.CreatedAt, &p.UpdatedAt,
		&p.LikesCount, &p.CommentsCount, &p.RepostsCount, &p.SharesCount,
		&p.AuthorName, &p.AuthorAvatarURL, &p.AuthorIsVerified,
		&p.IsLikedByUser, &p.IsBookmarkedByUser, &p.IsRepostedByUser,
		&imageURLs,
		&eventID, &eventTitle, &eventDescription, &eventCategory,
		&eventStartTime, &eventEndTime,
		&eventLocationName, &eventLocationAddress, &eventLocationLat, &eventLocationLng,
		&eventHostID, &eventHostName, &eventHostAvatarURL,
		&eventMaxAttendees, &eventAttendeesCount, &eventPrice, &eventIsFree,
		&eventStatus, &eventPrivacy,
		&eventImageURLs,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, sql.ErrNoRows
		}
		return nil, err
	}

	// Parse image URLs from JSON
	if len(imageURLs) > 0 && string(imageURLs) != "[]" {
		if err := json.Unmarshal(imageURLs, &p.ImageURLs); err == nil {
			// Successfully unmarshaled
		}
	}

	// Populate attached event if exists
	if eventID != nil && eventTitle != nil {
		eventSummary := &post.EventSummary{
			ID:     *eventID,
			Title:  *eventTitle,
			IsFree: *eventIsFree,
		}

		// Set basic fields
		if eventCategory != nil {
			eventSummary.Category = *eventCategory
		}
		if eventDescription != nil {
			eventSummary.Description = *eventDescription
		}
		if eventStatus != nil {
			eventSummary.Status = *eventStatus
		}
		if eventPrivacy != nil {
			eventSummary.Privacy = *eventPrivacy
		}

		// Set time fields
		if eventStartTime != nil {
			eventSummary.StartTime = *eventStartTime
		}
		if eventEndTime != nil {
			eventSummary.EndTime = *eventEndTime
		}

		// Set location fields
		if eventLocationName != nil {
			eventSummary.Location = *eventLocationName
		}
		if eventLocationAddress != nil {
			eventSummary.LocationAddress = *eventLocationAddress
		}
		if eventLocationLat != nil {
			eventSummary.LocationLat = *eventLocationLat
		}
		if eventLocationLng != nil {
			eventSummary.LocationLng = *eventLocationLng
		}

		// Set host fields
		if eventHostID != nil {
			eventSummary.HostID = *eventHostID
		}
		if eventHostName != nil {
			eventSummary.HostName = *eventHostName
		}
		if eventHostAvatarURL != nil {
			eventSummary.HostAvatarURL = eventHostAvatarURL
		}

		// Set attendee fields
		if eventMaxAttendees != nil {
			eventSummary.MaxAttendees = *eventMaxAttendees
		}
		if eventAttendeesCount != nil {
			eventSummary.AttendeesCount = *eventAttendeesCount
		}

		// Set price
		if eventPrice != nil {
			eventSummary.Price = eventPrice
		}

		// Parse event image URLs
		if len(eventImageURLs) > 0 && string(eventImageURLs) != "[]" {
			if err := json.Unmarshal(eventImageURLs, &eventSummary.ImageURLs); err == nil {
				// Successfully unmarshaled
			}
		}

		p.AttachedEvent = eventSummary
	}

	return &p, nil
}

// Update updates a post
func (r *postRepository) Update(ctx context.Context, p *post.Post) error {
	p.UpdatedAt = time.Now()

	query := `
		UPDATE posts
		SET content = $1, visibility = $2, updated_at = $3
		WHERE id = $4
	`

	result, err := r.db.ExecContext(ctx, query, p.Content, p.Visibility, p.UpdatedAt, p.ID)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return sql.ErrNoRows
	}

	return nil
}

// Delete deletes a post (hard delete - cascades to related tables)
func (r *postRepository) Delete(ctx context.Context, postID uuid.UUID) error {
	query := `DELETE FROM posts WHERE id = $1`

	result, err := r.db.ExecContext(ctx, query, postID)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return sql.ErrNoRows
	}

	return nil
}

// List lists posts with filters
func (r *postRepository) List(ctx context.Context, filter *post.PostFilter, userID uuid.UUID) ([]post.PostWithDetails, error) {
	// TODO: implement
	return nil, nil
}

// GetFeed gets the feed for a user with random + engagement bias algorithm
// Algorithm: Random selection from top N recent posts, weighted by engagement score
// Engagement score = likes + (comments * 2) + (reposts * 3)
//
// CTO REVIEW: PERFORMANCE - Missing database index
// Issue: Query uses "WHERE p.visibility = 'public' ORDER BY p.created_at DESC"
// Without composite index on (visibility, created_at), this will be slow with many posts
// Recommendation: CREATE INDEX idx_posts_visibility_created ON posts(visibility, created_at DESC);
// Also: random() can be expensive on large datasets - consider pre-computed trending score
// Priority: MEDIUM - Will need optimization as post count grows
func (r *postRepository) GetFeed(ctx context.Context, userID uuid.UUID, limit, offset int) ([]post.PostWithDetails, error) {
	query := `
		WITH recent_posts AS (
			-- Get top 100 most recent public posts as candidate pool
			SELECT
				p.id, p.author_id, p.content, p.type, p.attached_event_id,
				p.original_post_id, p.visibility, p.created_at, p.updated_at,
				p.likes_count, p.comments_count, p.reposts_count, p.shares_count,
				u.name as author_name, u.avatar_url as author_avatar_url, u.is_verified as author_is_verified,
				EXISTS(SELECT 1 FROM likes WHERE user_id = $1 AND likeable_type = 'post' AND likeable_id = p.id) as is_liked_by_user,
				EXISTS(SELECT 1 FROM bookmarks WHERE user_id = $1 AND post_id = p.id) as is_bookmarked_by_user,
				EXISTS(SELECT 1 FROM reposts WHERE user_id = $1 AND post_id = p.id) as is_reposted_by_user,
				COALESCE(
					(SELECT json_agg(image_url ORDER BY order_index)
					 FROM post_images WHERE post_id = p.id), '[]'::json
				) as image_urls,
				e.id as event_id, e.title as event_title, e.description as event_description,
				e.category as event_category, e.start_time as event_start_time, e.end_time as event_end_time,
				e.location_name as event_location_name, e.location_address as event_location_address,
				e.location_lat as event_location_lat, e.location_lng as event_location_lng,
				e.host_id as event_host_id, eh.name as event_host_name, eh.avatar_url as event_host_avatar_url,
				e.max_attendees as event_max_attendees,
				(SELECT COUNT(*) FROM event_attendees WHERE event_id = e.id AND status = 'confirmed') as event_attendees_count,
				(SELECT COUNT(*) FROM event_interests WHERE event_id = e.id) as interests_count,
				EXISTS(SELECT 1 FROM event_interests WHERE event_id = e.id AND user_id = $1) as event_is_interested,
				e.price as event_price, e.is_free as event_is_free,
				e.status as event_status, e.privacy as event_privacy,
				COALESCE(
					(SELECT json_agg(image_url ORDER BY order_index)
					 FROM event_images WHERE event_id = e.id), '[]'::json
				) as event_image_urls
			FROM posts p
			INNER JOIN users u ON p.author_id = u.id
			LEFT JOIN events e ON p.attached_event_id = e.id
			LEFT JOIN users eh ON e.host_id = eh.id
			WHERE p.visibility = 'public'
			AND p.created_at >= NOW() - INTERVAL '7 days'
			ORDER BY p.created_at DESC
			LIMIT 100
		)
		SELECT *
		FROM recent_posts
		-- Random weighted by engagement score
		-- Formula: (likes + comments*2 + reposts*3 + 1) ensures minimum weight of 1
		-- Multiply by random() to add randomness with engagement bias
		ORDER BY (likes_count + comments_count * 2 + reposts_count * 3 + 1) * random() DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.db.QueryxContext(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var posts []post.PostWithDetails
	for rows.Next() {
		var p post.PostWithDetails
		var imageURLs []byte
		var eventImageURLs []byte

		// Event fields (nullable)
		var eventID, eventHostID *uuid.UUID
		var eventTitle, eventDescription, eventCategory *string
		var eventStartTime, eventEndTime *time.Time
		var eventLocationName, eventLocationAddress *string
		var eventLocationLat, eventLocationLng *float64
		var eventHostName, eventHostAvatarURL *string
		var eventMaxAttendees *int
		var eventAttendeesCount *int
		var eventInterestsCount *int
		var eventIsInterested *bool
		var eventPrice *float64
		var eventIsFree *bool
		var eventStatus, eventPrivacy *string

		err := rows.Scan(
			&p.ID, &p.AuthorID, &p.Content, &p.Type, &p.AttachedEventID,
			&p.OriginalPostID, &p.Visibility, &p.CreatedAt, &p.UpdatedAt,
			&p.LikesCount, &p.CommentsCount, &p.RepostsCount, &p.SharesCount,
			&p.AuthorName, &p.AuthorAvatarURL, &p.AuthorIsVerified,
			&p.IsLikedByUser, &p.IsBookmarkedByUser, &p.IsRepostedByUser,
			&imageURLs,
			&eventID, &eventTitle, &eventDescription, &eventCategory,
			&eventStartTime, &eventEndTime,
			&eventLocationName, &eventLocationAddress, &eventLocationLat, &eventLocationLng,
			&eventHostID, &eventHostName, &eventHostAvatarURL,
			&eventMaxAttendees, &eventAttendeesCount, &eventInterestsCount, &eventIsInterested, &eventPrice, &eventIsFree,
			&eventStatus, &eventPrivacy,
			&eventImageURLs,
		)
		if err != nil {
			return nil, err
		}

		// Parse image URLs from JSON
		if len(imageURLs) > 0 && string(imageURLs) != "[]" {
			if err := json.Unmarshal(imageURLs, &p.ImageURLs); err == nil {
				// Successfully unmarshaled
			}
		}

		// Populate attached event if exists
		if eventID != nil && eventTitle != nil {
			eventSummary := &post.EventSummary{
				ID:     *eventID,
				Title:  *eventTitle,
				IsFree: *eventIsFree,
			}

			// Set basic fields
			if eventCategory != nil {
				eventSummary.Category = *eventCategory
			}
			if eventDescription != nil {
				eventSummary.Description = *eventDescription
			}
			if eventStatus != nil {
				eventSummary.Status = *eventStatus
			}
			if eventPrivacy != nil {
				eventSummary.Privacy = *eventPrivacy
			}
			if eventMaxAttendees != nil {
				eventSummary.MaxAttendees = *eventMaxAttendees
			}
			if eventAttendeesCount != nil {
				eventSummary.AttendeesCount = *eventAttendeesCount
			}
			if eventInterestsCount != nil {
				eventSummary.InterestsCount = *eventInterestsCount
			}
			if eventIsInterested != nil {
				eventSummary.IsInterested = *eventIsInterested
			}

			// Set event times
			if eventStartTime != nil {
				eventSummary.StartTime = *eventStartTime
			}
			if eventEndTime != nil {
				eventSummary.EndTime = *eventEndTime
			}

			// Set location
			if eventLocationName != nil {
				eventSummary.Location = *eventLocationName
			}
			if eventLocationAddress != nil {
				eventSummary.LocationAddress = *eventLocationAddress
			}
			if eventLocationLat != nil {
				eventSummary.LocationLat = *eventLocationLat
			}
			if eventLocationLng != nil {
				eventSummary.LocationLng = *eventLocationLng
			}

			// Set price if not free
			if !*eventIsFree && eventPrice != nil {
				eventSummary.Price = eventPrice
			}

			// Parse event image URLs
			if len(eventImageURLs) > 0 && string(eventImageURLs) != "[]" {
				var imageUrls []string
				if err := json.Unmarshal(eventImageURLs, &imageUrls); err == nil {
					eventSummary.ImageURLs = imageUrls
				}
			}

			// Set host info
			if eventHostID != nil && eventHostName != nil {
				eventSummary.HostID = *eventHostID
				eventSummary.HostName = *eventHostName
				eventSummary.HostAvatarURL = eventHostAvatarURL
			}

			p.AttachedEvent = eventSummary
		}

		posts = append(posts, p)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return posts, nil
}

// GetUserPosts gets posts by a specific user
func (r *postRepository) GetUserPosts(ctx context.Context, authorID, viewerID uuid.UUID, limit, offset int) ([]post.PostWithDetails, error) {
	query := `
		SELECT
			p.id, p.author_id, p.content, p.type, p.attached_event_id,
			p.original_post_id, p.visibility, p.created_at, p.updated_at,
			p.likes_count, p.comments_count, p.reposts_count, p.shares_count,
			u.name as author_name, u.avatar_url as author_avatar_url, u.is_verified as author_is_verified,
			EXISTS(SELECT 1 FROM likes WHERE user_id = $2 AND likeable_type = 'post' AND likeable_id = p.id) as is_liked_by_user,
			EXISTS(SELECT 1 FROM bookmarks WHERE user_id = $2 AND post_id = p.id) as is_bookmarked_by_user,
			EXISTS(SELECT 1 FROM reposts WHERE user_id = $2 AND post_id = p.id) as is_reposted_by_user,
			COALESCE(
				(SELECT json_agg(image_url ORDER BY order_index)
				 FROM post_images WHERE post_id = p.id), '[]'::json
			) as image_urls,
			e.id as event_id, e.title as event_title, e.description as event_description,
			e.category as event_category, e.start_time as event_start_time, e.end_time as event_end_time,
			e.location_name as event_location_name, e.location_address as event_location_address,
			e.location_lat as event_location_lat, e.location_lng as event_location_lng,
			e.host_id as event_host_id, eh.name as event_host_name, eh.avatar_url as event_host_avatar_url,
			e.max_attendees as event_max_attendees,
			(SELECT COUNT(*) FROM event_attendees WHERE event_id = e.id AND status = 'confirmed') as event_attendees_count,
			(SELECT COUNT(*) FROM event_interests WHERE event_id = e.id) as interests_count,
			e.price as event_price, e.is_free as event_is_free,
			e.status as event_status, e.privacy as event_privacy,
			COALESCE(
				(SELECT json_agg(image_url ORDER BY order_index)
				 FROM event_images WHERE event_id = e.id), '[]'::json
			) as event_image_urls
		FROM posts p
		INNER JOIN users u ON p.author_id = u.id
		LEFT JOIN events e ON p.attached_event_id = e.id
		LEFT JOIN users eh ON e.host_id = eh.id
		WHERE p.author_id = $1 AND p.visibility IN ('public', 'followers')
		ORDER BY p.created_at DESC
		LIMIT $3 OFFSET $4
	`

	rows, err := r.db.QueryxContext(ctx, query, authorID, viewerID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var posts []post.PostWithDetails
	for rows.Next() {
		var p post.PostWithDetails
		var imageURLs []byte
		var eventImageURLs []byte

		// Event fields (nullable)
		var eventID, eventHostID *uuid.UUID
		var eventTitle, eventDescription, eventCategory *string
		var eventStartTime, eventEndTime *time.Time
		var eventLocationName, eventLocationAddress *string
		var eventLocationLat, eventLocationLng *float64
		var eventHostName, eventHostAvatarURL *string
		var eventMaxAttendees *int
		var eventAttendeesCount *int
		var eventInterestsCount *int
		var eventIsInterested *bool
		var eventPrice *float64
		var eventIsFree *bool
		var eventStatus, eventPrivacy *string

		err := rows.Scan(
			&p.ID, &p.AuthorID, &p.Content, &p.Type, &p.AttachedEventID,
			&p.OriginalPostID, &p.Visibility, &p.CreatedAt, &p.UpdatedAt,
			&p.LikesCount, &p.CommentsCount, &p.RepostsCount, &p.SharesCount,
			&p.AuthorName, &p.AuthorAvatarURL, &p.AuthorIsVerified,
			&p.IsLikedByUser, &p.IsBookmarkedByUser, &p.IsRepostedByUser,
			&imageURLs,
			&eventID, &eventTitle, &eventDescription, &eventCategory,
			&eventStartTime, &eventEndTime,
			&eventLocationName, &eventLocationAddress, &eventLocationLat, &eventLocationLng,
			&eventHostID, &eventHostName, &eventHostAvatarURL,
			&eventMaxAttendees, &eventAttendeesCount, &eventInterestsCount, &eventIsInterested, &eventPrice, &eventIsFree,
			&eventStatus, &eventPrivacy,
			&eventImageURLs,
		)
		if err != nil {
			return nil, err
		}

		// Parse image URLs from JSON
		if len(imageURLs) > 0 && string(imageURLs) != "[]" {
			if err := json.Unmarshal(imageURLs, &p.ImageURLs); err == nil {
				// Successfully unmarshaled
			}
		}

		// Populate attached event if exists
		if eventID != nil && eventTitle != nil {
			eventSummary := &post.EventSummary{
				ID:     *eventID,
				Title:  *eventTitle,
				IsFree: *eventIsFree,
			}

			// Set basic fields
			if eventCategory != nil {
				eventSummary.Category = *eventCategory
			}
			if eventDescription != nil {
				eventSummary.Description = *eventDescription
			}
			if eventStatus != nil {
				eventSummary.Status = *eventStatus
			}
			if eventPrivacy != nil {
				eventSummary.Privacy = *eventPrivacy
			}

			// Set time fields
			if eventStartTime != nil {
				eventSummary.StartTime = *eventStartTime
			}
			if eventEndTime != nil {
				eventSummary.EndTime = *eventEndTime
			}

			// Set location fields
			if eventLocationName != nil {
				eventSummary.Location = *eventLocationName
			}
			if eventLocationAddress != nil {
				eventSummary.LocationAddress = *eventLocationAddress
			}
			if eventLocationLat != nil {
				eventSummary.LocationLat = *eventLocationLat
			}
			if eventLocationLng != nil {
				eventSummary.LocationLng = *eventLocationLng
			}

			// Set host fields
			if eventHostID != nil {
				eventSummary.HostID = *eventHostID
			}
			if eventHostName != nil {
				eventSummary.HostName = *eventHostName
			}
			if eventHostAvatarURL != nil {
				eventSummary.HostAvatarURL = eventHostAvatarURL
			}

			// Set attendee fields
			if eventMaxAttendees != nil {
				eventSummary.MaxAttendees = *eventMaxAttendees
			}
			if eventAttendeesCount != nil {
				eventSummary.AttendeesCount = *eventAttendeesCount
			}
			if eventInterestsCount != nil {
				eventSummary.InterestsCount = *eventInterestsCount
			}
			if eventIsInterested != nil {
				eventSummary.IsInterested = *eventIsInterested
			}

			// Set price
			if eventPrice != nil {
				eventSummary.Price = eventPrice
			}

			// Parse event image URLs
			if len(eventImageURLs) > 0 && string(eventImageURLs) != "[]" {
				if err := json.Unmarshal(eventImageURLs, &eventSummary.ImageURLs); err == nil {
					// Successfully unmarshaled
				}
			}

			p.AttachedEvent = eventSummary
		}

		posts = append(posts, p)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return posts, nil
}

// AddImages adds images to a post
func (r *postRepository) AddImages(ctx context.Context, images []post.PostImage) error {
	if len(images) == 0 {
		return nil
	}

	// Start transaction
	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	query := `
		INSERT INTO post_images (id, post_id, image_url, order_index)
		VALUES ($1, $2, $3, $4)
	`

	for i, img := range images {
		if img.ID == uuid.Nil {
			img.ID = uuid.New()
		}
		img.Order = i

		_, err := tx.ExecContext(ctx, query, img.ID, img.PostID, img.ImageURL, img.Order)
		if err != nil {
			return err
		}
	}

	return tx.Commit()
}

// GetImages gets images for a post
func (r *postRepository) GetImages(ctx context.Context, postID uuid.UUID) ([]string, error) {
	query := `
		SELECT image_url
		FROM post_images
		WHERE post_id = $1
		ORDER BY order_index ASC
	`

	var imageURLs []string
	err := r.db.SelectContext(ctx, &imageURLs, query, postID)
	if err != nil {
		return nil, err
	}

	return imageURLs, nil
}

// IncrementLikes increments the likes count
func (r *postRepository) IncrementLikes(ctx context.Context, postID uuid.UUID) error {
	query := `UPDATE posts SET likes_count = likes_count + 1 WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, postID)
	return err
}

// DecrementLikes decrements the likes count
func (r *postRepository) DecrementLikes(ctx context.Context, postID uuid.UUID) error {
	query := `UPDATE posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, postID)
	return err
}

// IncrementComments increments the comments count
func (r *postRepository) IncrementComments(ctx context.Context, postID uuid.UUID) error {
	query := `UPDATE posts SET comments_count = comments_count + 1 WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, postID)
	return err
}

// DecrementComments decrements the comments count
func (r *postRepository) DecrementComments(ctx context.Context, postID uuid.UUID) error {
	query := `UPDATE posts SET comments_count = GREATEST(comments_count - 1, 0) WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, postID)
	return err
}

// IncrementReposts increments the reposts count
func (r *postRepository) IncrementReposts(ctx context.Context, postID uuid.UUID) error {
	query := `UPDATE posts SET reposts_count = reposts_count + 1 WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, postID)
	return err
}

// DecrementReposts decrements the reposts count
func (r *postRepository) DecrementReposts(ctx context.Context, postID uuid.UUID) error {
	query := `UPDATE posts SET reposts_count = GREATEST(reposts_count - 1, 0) WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, postID)
	return err
}

// IncrementShares increments the shares count
func (r *postRepository) IncrementShares(ctx context.Context, postID uuid.UUID) error {
	query := `UPDATE posts SET shares_count = shares_count + 1 WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, postID)
	return err
}

// CountFeed counts the total number of posts in a user's feed
func (r *postRepository) CountFeed(ctx context.Context, userID uuid.UUID) (int, error) {
	query := `
		SELECT COUNT(*)
		FROM posts p
		WHERE p.visibility = 'public'
		AND p.created_at >= NOW() - INTERVAL '7 days'
	`
	var count int
	err := r.db.QueryRowContext(ctx, query).Scan(&count)
	return count, err
}

// CountUserPosts counts the total number of posts by a specific author
func (r *postRepository) CountUserPosts(ctx context.Context, authorID uuid.UUID) (int, error) {
	query := `
		SELECT COUNT(*)
		FROM posts p
		WHERE p.author_id = $1
	`
	var count int
	err := r.db.QueryRowContext(ctx, query, authorID).Scan(&count)
	return count, err
}
