package interaction

import (
	"time"

	"github.com/google/uuid"
)

// LikeableType represents the type of content that can be liked
type LikeableType string

const (
	LikeablePost    LikeableType = "post"
	LikeableComment LikeableType = "comment"
)

// Like represents a like on a post or comment
type Like struct {
	ID           uuid.UUID    `json:"id" db:"id"`
	UserID       uuid.UUID    `json:"user_id" db:"user_id"`
	LikeableType LikeableType `json:"likeable_type" db:"likeable_type"`
	LikeableID   uuid.UUID    `json:"likeable_id" db:"likeable_id"`
	CreatedAt    time.Time    `json:"created_at" db:"created_at"`
}

// Repost represents a repost of a post
type Repost struct {
	ID           uuid.UUID `json:"id" db:"id"`
	UserID       uuid.UUID `json:"user_id" db:"user_id"`
	PostID       uuid.UUID `json:"post_id" db:"post_id"`
	QuoteContent *string   `json:"quote_content,omitempty" db:"quote_content"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
}

// Bookmark represents a bookmarked post
type Bookmark struct {
	ID        uuid.UUID `json:"id" db:"id"`
	UserID    uuid.UUID `json:"user_id" db:"user_id"`
	PostID    uuid.UUID `json:"post_id" db:"post_id"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// Share represents a post share
type Share struct {
	ID        uuid.UUID `json:"id" db:"id"`
	UserID    uuid.UUID `json:"user_id" db:"user_id"`
	PostID    uuid.UUID `json:"post_id" db:"post_id"`
	Platform  *string   `json:"platform,omitempty" db:"platform"` // whatsapp, instagram, etc
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}
