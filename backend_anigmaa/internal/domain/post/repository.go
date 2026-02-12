package post

import (
	"context"

	"github.com/google/uuid"
)

// Repository defines the interface for post data access
type Repository interface {
	// Post CRUD
	Create(ctx context.Context, post *Post) error
	GetByID(ctx context.Context, postID uuid.UUID) (*Post, error)
	GetWithDetails(ctx context.Context, postID, userID uuid.UUID) (*PostWithDetails, error)
	Update(ctx context.Context, post *Post) error
	Delete(ctx context.Context, postID uuid.UUID) error

	// Post queries
	List(ctx context.Context, filter *PostFilter, userID uuid.UUID) ([]PostWithDetails, error)
	GetFeed(ctx context.Context, userID uuid.UUID, limit, offset int) ([]PostWithDetails, error)
	GetUserPosts(ctx context.Context, authorID, viewerID uuid.UUID, limit, offset int) ([]PostWithDetails, error)

	// Counting for pagination
	CountFeed(ctx context.Context, userID uuid.UUID) (int, error)
	CountUserPosts(ctx context.Context, authorID uuid.UUID) (int, error)

	// Image management
	AddImages(ctx context.Context, images []PostImage) error
	GetImages(ctx context.Context, postID uuid.UUID) ([]string, error)

	// Engagement
	IncrementLikes(ctx context.Context, postID uuid.UUID) error
	DecrementLikes(ctx context.Context, postID uuid.UUID) error
	IncrementComments(ctx context.Context, postID uuid.UUID) error
	DecrementComments(ctx context.Context, postID uuid.UUID) error
	IncrementReposts(ctx context.Context, postID uuid.UUID) error
	DecrementReposts(ctx context.Context, postID uuid.UUID) error
	IncrementShares(ctx context.Context, postID uuid.UUID) error
}
