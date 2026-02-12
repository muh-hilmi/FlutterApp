package comment

import (
	"context"

	"github.com/google/uuid"
)

// Repository defines the interface for comment data access
type Repository interface {
	// Comment CRUD
	Create(ctx context.Context, comment *Comment) error
	GetByID(ctx context.Context, commentID uuid.UUID) (*Comment, error)
	GetWithDetails(ctx context.Context, commentID, userID uuid.UUID) (*CommentWithDetails, error)
	Update(ctx context.Context, comment *Comment) error
	Delete(ctx context.Context, commentID uuid.UUID) error

	// Comment queries
	GetByPost(ctx context.Context, postID, userID uuid.UUID, limit, offset int) ([]CommentWithDetails, error)
	GetReplies(ctx context.Context, parentCommentID, userID uuid.UUID, limit, offset int) ([]CommentWithDetails, error)
	GetCount(ctx context.Context, postID uuid.UUID) (int, error)

	// Engagement
	IncrementLikes(ctx context.Context, commentID uuid.UUID) error
	DecrementLikes(ctx context.Context, commentID uuid.UUID) error
}
