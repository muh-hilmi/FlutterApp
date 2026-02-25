package interaction

import (
	"context"

	"github.com/google/uuid"
)

// Repository defines the interface for interaction data access
type Repository interface {
	// Like management
	Like(ctx context.Context, like *Like) error
	Unlike(ctx context.Context, userID uuid.UUID, likeableType LikeableType, likeableID uuid.UUID) error
	IsLiked(ctx context.Context, userID uuid.UUID, likeableType LikeableType, likeableID uuid.UUID) (bool, error)
	GetLikes(ctx context.Context, likeableType LikeableType, likeableID uuid.UUID, limit, offset int) ([]Like, error)
	// GetLikedByUserForPosts returns a list of post IDs that the user has liked
	// This is a batch query for performance - checks multiple posts at once
	GetLikedByUserForPosts(ctx context.Context, userID uuid.UUID, postIDs []uuid.UUID) ([]uuid.UUID, error)

	// Repost management
	Repost(ctx context.Context, repost *Repost) error
	UndoRepost(ctx context.Context, userID, postID uuid.UUID) error
	IsReposted(ctx context.Context, userID, postID uuid.UUID) (bool, error)
	GetReposts(ctx context.Context, postID uuid.UUID, limit, offset int) ([]Repost, error)

	// Bookmark management
	Bookmark(ctx context.Context, bookmark *Bookmark) error
	RemoveBookmark(ctx context.Context, userID, postID uuid.UUID) error
	IsBookmarked(ctx context.Context, userID, postID uuid.UUID) (bool, error)
	GetBookmarks(ctx context.Context, userID uuid.UUID, limit, offset int) ([]Bookmark, error)

	// Share tracking
	Share(ctx context.Context, share *Share) error
	GetShareCount(ctx context.Context, postID uuid.UUID) (int, error)

	// Counting for pagination
	CountBookmarks(ctx context.Context, userID uuid.UUID) (int, error)
}
