package post

import (
	"time"

	"github.com/google/uuid"
)

// PostType represents the type of post
type PostType string

const (
	TypeText           PostType = "text"
	TypeTextWithImages PostType = "text_with_images"
	TypeTextWithEvent  PostType = "text_with_event"
	TypePoll           PostType = "poll"
	TypeRepost         PostType = "repost"
)

// PostVisibility represents the visibility level of a post
type PostVisibility string

const (
	VisibilityPublic    PostVisibility = "public"
	VisibilityFollowers PostVisibility = "followers"
	VisibilityPrivate   PostVisibility = "private"
)

// Post represents a social media post
type Post struct {
	ID              uuid.UUID      `json:"id" db:"id"`
	AuthorID        uuid.UUID      `json:"author_id" db:"author_id"`
	Content         string         `json:"content" db:"content"`
	Type            PostType       `json:"type" db:"type"`
	AttachedEventID uuid.UUID      `json:"attached_event_id" db:"attached_event_id"`
	OriginalPostID  *uuid.UUID     `json:"original_post_id,omitempty" db:"original_post_id"`
	Visibility      PostVisibility `json:"visibility" db:"visibility"`
	IsArchived      bool           `json:"is_archived" db:"is_archived"`
	CreatedAt       time.Time      `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at" db:"updated_at"`
	LikesCount      int            `json:"likes_count" db:"likes_count"`
	CommentsCount   int            `json:"comments_count" db:"comments_count"`
	RepostsCount    int            `json:"reposts_count" db:"reposts_count"`
	SharesCount     int            `json:"shares_count" db:"shares_count"`
}

// PostWithDetails includes additional post information
type PostWithDetails struct {
	Post
	AuthorName         string         `json:"author_name"`
	AuthorAvatarURL    *string        `json:"author_avatar_url"`
	AuthorIsVerified   bool           `json:"author_is_verified"`
	ImageURLs          []string       `json:"image_urls,omitempty"`
	AttachedEvent      *EventSummary  `json:"attached_event,omitempty"`
	OriginalPost       *Post          `json:"original_post,omitempty"`
	OriginalPostAuthor *AuthorSummary `json:"original_post_author,omitempty"`
	IsLikedByUser      bool           `json:"is_liked_by_user"`
	IsRepostedByUser   bool           `json:"is_reposted_by_user"`
	IsBookmarkedByUser bool           `json:"is_bookmarked_by_user"`
	Hashtags           []string       `json:"hashtags,omitempty"`
	Mentions           []string       `json:"mentions,omitempty"`
}

// AuthorSummary represents basic author information
type AuthorSummary struct {
	ID         uuid.UUID `json:"id"`
	Name       string    `json:"name"`
	AvatarURL  *string   `json:"avatar_url"`
	IsVerified bool      `json:"is_verified"`
}

// EventSummary represents basic event information attached to a post
type EventSummary struct {
	ID              uuid.UUID `json:"id"`
	Title           string    `json:"title"`
	Description     string    `json:"description,omitempty"`
	Category        string    `json:"category"`
	StartTime       time.Time `json:"start_time"`
	EndTime         time.Time `json:"end_time,omitempty"`
	Location        string    `json:"location_name"`
	LocationAddress string    `json:"location_address,omitempty"`
	LocationLat     float64   `json:"location_lat,omitempty"`
	LocationLng     float64   `json:"location_lng,omitempty"`
	HostID          uuid.UUID `json:"host_id"`
	HostName        string    `json:"host_name"`
	HostAvatarURL   *string   `json:"host_avatar_url,omitempty"`
	MaxAttendees    int       `json:"max_attendees,omitempty"`
	AttendeesCount  int       `json:"attendees_count"`
	InterestsCount  int       `json:"interests_count"`
	IsInterested    bool      `json:"is_interested"`
	IsFree          bool      `json:"is_free"`
	Price           *float64  `json:"price,omitempty"`
	Status          string    `json:"status,omitempty"`
	Privacy         string    `json:"privacy,omitempty"`
	ImageURLs       []string  `json:"image_urls,omitempty"`
}

// PostImage represents an image attached to a post
type PostImage struct {
	ID       uuid.UUID `json:"id" db:"id"`
	PostID   uuid.UUID `json:"post_id" db:"post_id"`
	ImageURL string    `json:"image_url" db:"image_url"`
	Order    int       `json:"order" db:"order_index"`
}

// REVIEW: CRITICAL API CONTRACT MISMATCH - AttachedEventID is marked as required but frontend allows creating regular text posts without events.
// This binding:"required" validation will cause ALL text-only posts from Flutter to fail with 400 Bad Request.
// The field should be: AttachedEventID *uuid.UUID `json:"attached_event_id,omitempty" binding:"omitempty,uuid"`
// Make it a pointer (*uuid.UUID) and omitempty to allow nil values for text posts that don't reference events.
// Only TypeTextWithEvent posts should require this field - add business logic validation in the usecase layer instead.
// CreatePostRequest represents post creation data
type CreatePostRequest struct {
	Content         string         `json:"content" binding:"required,max=5000"`
	Type            PostType       `json:"type" binding:"required"`
	ImageURLs       []string       `json:"image_urls,omitempty" binding:"omitempty,max=4"`
	AttachedEventID *uuid.UUID     `json:"attached_event_id,omitempty"` // Only required for TypeTextWithEvent
	Visibility      PostVisibility `json:"visibility" binding:"required"`
	Hashtags        []string       `json:"hashtags,omitempty"`
	Mentions        []string       `json:"mentions,omitempty"`
}

// UpdatePostRequest represents post update data
type UpdatePostRequest struct {
	Content    *string         `json:"content,omitempty" binding:"omitempty,max=5000"`
	Visibility *PostVisibility `json:"visibility,omitempty"`
}

// RepostRequest represents repost data
type RepostRequest struct {
	PostID       uuid.UUID `json:"post_id" binding:"required"`
	QuoteContent *string   `json:"quote_content,omitempty" binding:"omitempty,max=280"`
}

// PostFilter represents post filtering options
type PostFilter struct {
	AuthorID   *uuid.UUID      `form:"author_id"`
	Type       *PostType       `form:"type"`
	Visibility *PostVisibility `form:"visibility"`
	Limit      int             `form:"limit"`
	Offset     int             `form:"offset"`
}

// PostResponse represents the API response format for posts (Flutter-compatible)
type PostResponse struct {
	ID                 uuid.UUID      `json:"id"`
	Author             AuthorSummary  `json:"author"`
	Content            string         `json:"content"`
	Type               PostType       `json:"type"`
	ImageURLs          []string       `json:"image_urls,omitempty"`
	AttachedEvent      *EventSummary  `json:"attached_event,omitempty"`
	OriginalPost       *Post          `json:"original_post,omitempty"`
	OriginalPostAuthor *AuthorSummary `json:"original_post_author,omitempty"`
	Visibility         PostVisibility `json:"visibility"`
	IsArchived         bool           `json:"is_archived"`
	CreatedAt          time.Time      `json:"created_at"`
	UpdatedAt          time.Time      `json:"updated_at"`
	LikesCount         int            `json:"likes_count"`
	CommentsCount      int            `json:"comments_count"`
	RepostsCount       int            `json:"reposts_count"`
	SharesCount        int            `json:"shares_count"`
	IsLikedByUser      bool           `json:"is_liked_by_current_user"`
	IsRepostedByUser   bool           `json:"is_reposted_by_current_user"`
	IsBookmarked       bool           `json:"is_bookmarked"`
	Hashtags           []string       `json:"hashtags,omitempty"`
	Mentions           []string       `json:"mentions,omitempty"`
}

// ToResponse converts PostWithDetails to Flutter-compatible response format
func (p *PostWithDetails) ToResponse() PostResponse {
	return PostResponse{
		ID: p.ID,
		Author: AuthorSummary{
			ID:         p.AuthorID,
			Name:       p.AuthorName,
			AvatarURL:  p.AuthorAvatarURL,
			IsVerified: p.AuthorIsVerified,
		},
		Content:            p.Content,
		Type:               p.Type,
		ImageURLs:          p.ImageURLs,
		AttachedEvent:      p.AttachedEvent,
		OriginalPost:       p.OriginalPost,
		OriginalPostAuthor: p.OriginalPostAuthor,
		Visibility:         p.Visibility,
		IsArchived:         p.IsArchived,
		CreatedAt:          p.CreatedAt,
		UpdatedAt:          p.UpdatedAt,
		LikesCount:         p.LikesCount,
		CommentsCount:      p.CommentsCount,
		RepostsCount:       p.RepostsCount,
		SharesCount:        p.SharesCount,
		IsLikedByUser:      p.IsLikedByUser,
		IsRepostedByUser:   p.IsRepostedByUser,
		IsBookmarked:       p.IsBookmarkedByUser,
		Hashtags:           p.Hashtags,
		Mentions:           p.Mentions,
	}
}
