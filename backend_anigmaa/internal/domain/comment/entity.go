package comment

import (
	"time"

	"github.com/google/uuid"
)

// Comment represents a comment on a post
type Comment struct {
	ID              uuid.UUID  `json:"id" db:"id"`
	PostID          uuid.UUID  `json:"post_id" db:"post_id"`
	AuthorID        uuid.UUID  `json:"author_id" db:"author_id"`
	ParentCommentID *uuid.UUID `json:"parent_comment_id,omitempty" db:"parent_comment_id"`
	Content         string     `json:"content" db:"content"`
	CreatedAt       time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at" db:"updated_at"`
	LikesCount      int        `json:"likes_count" db:"likes_count"`
}

// CommentWithDetails includes additional comment information
type CommentWithDetails struct {
	Comment
	AuthorName       string               `json:"author_name" db:"author_name"`
	AuthorAvatarURL  *string              `json:"author_avatar_url" db:"author_avatar_url"`
	AuthorIsVerified bool                 `json:"author_is_verified" db:"author_is_verified"`
	IsLikedByUser    bool                 `json:"is_liked_by_user" db:"is_liked_by_user"`
	RepliesCount     int                  `json:"replies_count" db:"replies_count"`
	Replies          []CommentWithDetails `json:"replies,omitempty" db:"-"`
}

// CreateCommentRequest represents comment creation data
type CreateCommentRequest struct {
	PostID          uuid.UUID  `json:"post_id" binding:"required"`
	ParentCommentID *uuid.UUID `json:"parent_comment_id,omitempty"`
	Content         string     `json:"content" binding:"required,min=1,max=1000"`
}

// UpdateCommentRequest represents comment update data
type UpdateCommentRequest struct {
	Content string `json:"content" binding:"required,min=1,max=1000"`
}
