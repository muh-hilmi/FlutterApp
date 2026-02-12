package postgres

import (
	"context"
	"database/sql"
	"time"

	"github.com/anigmaa/backend/internal/domain/interaction"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/lib/pq"
)

type interactionRepository struct {
	db *sqlx.DB
}

// NewInteractionRepository creates a new interaction repository
func NewInteractionRepository(db *sqlx.DB) interaction.Repository {
	return &interactionRepository{db: db}
}

// Like creates a new like
// Note: likes_count is automatically updated via database trigger (update_likes_count_trigger)
func (r *interactionRepository) Like(ctx context.Context, like *interaction.Like) error {
	// Generate UUID if not provided
	if like.ID == uuid.Nil {
		like.ID = uuid.New()
	}

	// Set timestamp
	like.CreatedAt = time.Now()

	query := `
		INSERT INTO likes (id, user_id, likeable_type, likeable_id, created_at)
		VALUES ($1, $2, $3, $4, $5)
	`

	_, err := r.db.ExecContext(ctx, query,
		like.ID, like.UserID, like.LikeableType, like.LikeableID, like.CreatedAt,
	)

	// Check for unique constraint violation (user already liked)
	if err != nil {
		if pqErr, ok := err.(*pq.Error); ok {
			if pqErr.Code == "23505" { // unique_violation
				return sql.ErrNoRows // Or define custom error like ErrAlreadyLiked
			}
		}
		return err
	}

	return nil
}

// Unlike removes a like
// Note: likes_count is automatically decremented via database trigger (update_likes_count_trigger)
func (r *interactionRepository) Unlike(ctx context.Context, userID uuid.UUID, likeableType interaction.LikeableType, likeableID uuid.UUID) error {
	query := `
		DELETE FROM likes
		WHERE user_id = $1 AND likeable_type = $2 AND likeable_id = $3
	`

	result, err := r.db.ExecContext(ctx, query, userID, likeableType, likeableID)
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

// IsLiked checks if a user has liked something
func (r *interactionRepository) IsLiked(ctx context.Context, userID uuid.UUID, likeableType interaction.LikeableType, likeableID uuid.UUID) (bool, error) {
	query := `
		SELECT EXISTS(
			SELECT 1 FROM likes
			WHERE user_id = $1 AND likeable_type = $2 AND likeable_id = $3
		)
	`

	var exists bool
	err := r.db.GetContext(ctx, &exists, query, userID, likeableType, likeableID)
	if err != nil {
		return false, err
	}

	return exists, nil
}

// GetLikes gets likes for a likeable item
func (r *interactionRepository) GetLikes(ctx context.Context, likeableType interaction.LikeableType, likeableID uuid.UUID, limit, offset int) ([]interaction.Like, error) {
	query := `
		SELECT id, user_id, likeable_type, likeable_id, created_at
		FROM likes
		WHERE likeable_type = $1 AND likeable_id = $2
		ORDER BY created_at DESC
		LIMIT $3 OFFSET $4
	`

	var likes []interaction.Like
	err := r.db.SelectContext(ctx, &likes, query, likeableType, likeableID, limit, offset)
	if err != nil {
		return nil, err
	}

	if likes == nil {
		likes = []interaction.Like{}
	}

	return likes, nil
}

// Repost creates a new repost
// Note: reposts_count is automatically updated via database trigger (update_reposts_count_trigger)
func (r *interactionRepository) Repost(ctx context.Context, repost *interaction.Repost) error {
	// Generate UUID if not provided
	if repost.ID == uuid.Nil {
		repost.ID = uuid.New()
	}

	// Set timestamp
	repost.CreatedAt = time.Now()

	query := `
		INSERT INTO reposts (id, user_id, post_id, quote_content, created_at)
		VALUES ($1, $2, $3, $4, $5)
	`

	_, err := r.db.ExecContext(ctx, query,
		repost.ID, repost.UserID, repost.PostID, repost.QuoteContent, repost.CreatedAt,
	)

	// Check for unique constraint violation (user already reposted)
	if err != nil {
		if pqErr, ok := err.(*pq.Error); ok {
			if pqErr.Code == "23505" { // unique_violation
				return sql.ErrNoRows
			}
		}
		return err
	}

	return nil
}

// UndoRepost removes a repost
// Note: reposts_count is automatically decremented via database trigger (update_reposts_count_trigger)
func (r *interactionRepository) UndoRepost(ctx context.Context, userID, postID uuid.UUID) error {
	query := `
		DELETE FROM reposts
		WHERE user_id = $1 AND post_id = $2
	`

	result, err := r.db.ExecContext(ctx, query, userID, postID)
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

// IsReposted checks if a user has reposted a post
func (r *interactionRepository) IsReposted(ctx context.Context, userID, postID uuid.UUID) (bool, error) {
	query := `
		SELECT EXISTS(
			SELECT 1 FROM reposts
			WHERE user_id = $1 AND post_id = $2
		)
	`

	var exists bool
	err := r.db.GetContext(ctx, &exists, query, userID, postID)
	if err != nil {
		return false, err
	}

	return exists, nil
}

// GetReposts gets reposts for a post
func (r *interactionRepository) GetReposts(ctx context.Context, postID uuid.UUID, limit, offset int) ([]interaction.Repost, error) {
	query := `
		SELECT id, user_id, post_id, quote_content, created_at
		FROM reposts
		WHERE post_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`

	var reposts []interaction.Repost
	err := r.db.SelectContext(ctx, &reposts, query, postID, limit, offset)
	if err != nil {
		return nil, err
	}

	if reposts == nil {
		reposts = []interaction.Repost{}
	}

	return reposts, nil
}

// Bookmark creates a new bookmark
func (r *interactionRepository) Bookmark(ctx context.Context, bookmark *interaction.Bookmark) error {
	// Generate UUID if not provided
	if bookmark.ID == uuid.Nil {
		bookmark.ID = uuid.New()
	}

	// Set timestamp
	bookmark.CreatedAt = time.Now()

	query := `
		INSERT INTO bookmarks (id, user_id, post_id, created_at)
		VALUES ($1, $2, $3, $4)
	`

	_, err := r.db.ExecContext(ctx, query,
		bookmark.ID, bookmark.UserID, bookmark.PostID, bookmark.CreatedAt,
	)

	// Check for unique constraint violation (user already bookmarked)
	if err != nil {
		if pqErr, ok := err.(*pq.Error); ok {
			if pqErr.Code == "23505" { // unique_violation
				return sql.ErrNoRows
			}
		}
		return err
	}

	return nil
}

// RemoveBookmark removes a bookmark
func (r *interactionRepository) RemoveBookmark(ctx context.Context, userID, postID uuid.UUID) error {
	query := `
		DELETE FROM bookmarks
		WHERE user_id = $1 AND post_id = $2
	`

	result, err := r.db.ExecContext(ctx, query, userID, postID)
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

// IsBookmarked checks if a user has bookmarked a post
func (r *interactionRepository) IsBookmarked(ctx context.Context, userID, postID uuid.UUID) (bool, error) {
	query := `
		SELECT EXISTS(
			SELECT 1 FROM bookmarks
			WHERE user_id = $1 AND post_id = $2
		)
	`

	var exists bool
	err := r.db.GetContext(ctx, &exists, query, userID, postID)
	if err != nil {
		return false, err
	}

	return exists, nil
}

// GetBookmarks gets bookmarks for a user
func (r *interactionRepository) GetBookmarks(ctx context.Context, userID uuid.UUID, limit, offset int) ([]interaction.Bookmark, error) {
	query := `
		SELECT id, user_id, post_id, created_at
		FROM bookmarks
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`

	var bookmarks []interaction.Bookmark
	err := r.db.SelectContext(ctx, &bookmarks, query, userID, limit, offset)
	if err != nil {
		return nil, err
	}

	if bookmarks == nil {
		bookmarks = []interaction.Bookmark{}
	}

	return bookmarks, nil
}

// Share creates a new share
// Note: shares_count is automatically updated via database trigger (update_shares_count_trigger)
func (r *interactionRepository) Share(ctx context.Context, share *interaction.Share) error {
	// Generate UUID if not provided
	if share.ID == uuid.Nil {
		share.ID = uuid.New()
	}

	// Set timestamp
	share.CreatedAt = time.Now()

	query := `
		INSERT INTO shares (id, user_id, post_id, platform, created_at)
		VALUES ($1, $2, $3, $4, $5)
	`

	_, err := r.db.ExecContext(ctx, query,
		share.ID, share.UserID, share.PostID, share.Platform, share.CreatedAt,
	)

	return err
}

// GetShareCount gets the count of shares for a post
func (r *interactionRepository) GetShareCount(ctx context.Context, postID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM shares WHERE post_id = $1`

	var count int
	err := r.db.GetContext(ctx, &count, query, postID)
	if err != nil {
		return 0, err
	}

	return count, nil
}

// CountBookmarks counts total bookmarks for a user
func (r *interactionRepository) CountBookmarks(ctx context.Context, userID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM bookmarks WHERE user_id = $1`

	var count int
	err := r.db.QueryRowContext(ctx, query, userID).Scan(&count)
	return count, err
}
