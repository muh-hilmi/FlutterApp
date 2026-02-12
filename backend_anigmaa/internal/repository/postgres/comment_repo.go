package postgres

import (
	"context"
	"database/sql"
	"time"

	"github.com/anigmaa/backend/internal/domain/comment"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type commentRepository struct {
	db *sqlx.DB
}

// NewCommentRepository creates a new comment repository
func NewCommentRepository(db *sqlx.DB) comment.Repository {
	return &commentRepository{db: db}
}

// Create creates a new comment
// Note: comments_count is automatically updated via database trigger (update_comments_count_trigger)
func (r *commentRepository) Create(ctx context.Context, c *comment.Comment) error {
	// Generate UUID if not provided
	if c.ID == uuid.Nil {
		c.ID = uuid.New()
	}

	// Set timestamps
	now := time.Now()
	c.CreatedAt = now
	c.UpdatedAt = now

	query := `
		INSERT INTO comments (id, post_id, author_id, parent_comment_id, content, created_at, updated_at, likes_count)
		VALUES ($1, $2, $3, $4, $5, $6, $7, 0)
	`

	_, err := r.db.ExecContext(ctx, query,
		c.ID, c.PostID, c.AuthorID, c.ParentCommentID, c.Content, c.CreatedAt, c.UpdatedAt,
	)

	return err
}

// GetByID gets a comment by ID
func (r *commentRepository) GetByID(ctx context.Context, commentID uuid.UUID) (*comment.Comment, error) {
	query := `
		SELECT id, post_id, author_id, parent_comment_id, content, created_at, updated_at, likes_count
		FROM comments
		WHERE id = $1
	`

	var c comment.Comment
	err := r.db.GetContext(ctx, &c, query, commentID)
	if err != nil {
		return nil, err
	}

	return &c, nil
}

// GetWithDetails gets a comment with full details
func (r *commentRepository) GetWithDetails(ctx context.Context, commentID, userID uuid.UUID) (*comment.CommentWithDetails, error) {
	query := `
		SELECT
			c.id,
			c.post_id,
			c.author_id,
			c.parent_comment_id,
			c.content,
			c.likes_count,
			c.created_at,
			c.updated_at,
			u.name as author_name,
			u.avatar_url as author_avatar_url,
			u.is_verified as author_is_verified,
			COALESCE(
				(SELECT COUNT(*) FROM likes
				 WHERE likeable_id = c.id
				 AND likeable_type = 'comment'
				 AND user_id = $2),
				0
			) > 0 as is_liked_by_user,
			COALESCE(
				(SELECT COUNT(*) FROM comments WHERE parent_comment_id = c.id),
				0
			) as replies_count
		FROM comments c
		INNER JOIN users u ON c.author_id = u.id
		WHERE c.id = $1
	`

	var c comment.CommentWithDetails
	err := r.db.GetContext(ctx, &c, query, commentID, userID)
	if err != nil {
		return nil, err
	}

	return &c, nil
}

// Update updates a comment
func (r *commentRepository) Update(ctx context.Context, c *comment.Comment) error {
	c.UpdatedAt = time.Now()

	query := `
		UPDATE comments
		SET content = $1, updated_at = $2
		WHERE id = $3
	`

	result, err := r.db.ExecContext(ctx, query, c.Content, c.UpdatedAt, c.ID)
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

// Delete deletes a comment
// Note: comments_count is automatically decremented via database trigger (update_comments_count_trigger)
func (r *commentRepository) Delete(ctx context.Context, commentID uuid.UUID) error {
	query := `DELETE FROM comments WHERE id = $1`

	result, err := r.db.ExecContext(ctx, query, commentID)
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

// GetByPost gets comments for a post
func (r *commentRepository) GetByPost(ctx context.Context, postID, userID uuid.UUID, limit, offset int) ([]comment.CommentWithDetails, error) {
	query := `
		SELECT
			c.id,
			c.post_id,
			c.author_id,
			c.parent_comment_id,
			c.content,
			c.likes_count,
			c.created_at,
			c.updated_at,
			u.name as author_name,
			u.avatar_url as author_avatar_url,
			u.is_verified as author_is_verified,
			COALESCE(
				(SELECT COUNT(*) FROM likes
				 WHERE likeable_id = c.id
				 AND likeable_type = 'comment'
				 AND user_id = $1),
				0
			) > 0 as is_liked_by_user
		FROM comments c
		INNER JOIN users u ON c.author_id = u.id
		WHERE c.post_id = $2
		ORDER BY c.likes_count DESC, c.created_at DESC
		LIMIT $3 OFFSET $4
	`

	rows, err := r.db.QueryxContext(ctx, query, userID, postID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var comments []comment.CommentWithDetails
	for rows.Next() {
		var c comment.CommentWithDetails

		err := rows.Scan(
			&c.ID,
			&c.PostID,
			&c.AuthorID,
			&c.ParentCommentID,
			&c.Content,
			&c.LikesCount,
			&c.CreatedAt,
			&c.UpdatedAt,
			&c.AuthorName,
			&c.AuthorAvatarURL,
			&c.AuthorIsVerified,
			&c.IsLikedByUser,
		)
		if err != nil {
			return nil, err
		}

		comments = append(comments, c)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	if comments == nil {
		comments = []comment.CommentWithDetails{}
	}

	return comments, nil
}

// GetReplies gets replies to a comment
func (r *commentRepository) GetReplies(ctx context.Context, parentCommentID, userID uuid.UUID, limit, offset int) ([]comment.CommentWithDetails, error) {
	query := `
		SELECT
			c.id,
			c.post_id,
			c.author_id,
			c.parent_comment_id,
			c.content,
			c.likes_count,
			c.created_at,
			c.updated_at,
			u.name as author_name,
			u.avatar_url as author_avatar_url,
			u.is_verified as author_is_verified,
			COALESCE(
				(SELECT COUNT(*) FROM likes
				 WHERE likeable_id = c.id
				 AND likeable_type = 'comment'
				 AND user_id = $1),
				0
			) > 0 as is_liked_by_user
		FROM comments c
		INNER JOIN users u ON c.author_id = u.id
		WHERE c.parent_comment_id = $2
		ORDER BY c.created_at ASC
		LIMIT $3 OFFSET $4
	`

	rows, err := r.db.QueryxContext(ctx, query, userID, parentCommentID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var replies []comment.CommentWithDetails
	for rows.Next() {
		var c comment.CommentWithDetails

		err := rows.Scan(
			&c.ID,
			&c.PostID,
			&c.AuthorID,
			&c.ParentCommentID,
			&c.Content,
			&c.LikesCount,
			&c.CreatedAt,
			&c.UpdatedAt,
			&c.AuthorName,
			&c.AuthorAvatarURL,
			&c.AuthorIsVerified,
			&c.IsLikedByUser,
		)
		if err != nil {
			return nil, err
		}

		replies = append(replies, c)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	if replies == nil {
		replies = []comment.CommentWithDetails{}
	}

	return replies, nil
}

// GetCount gets the count of comments for a post
func (r *commentRepository) GetCount(ctx context.Context, postID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM comments WHERE post_id = $1`

	var count int
	err := r.db.GetContext(ctx, &count, query, postID)
	if err != nil {
		return 0, err
	}

	return count, nil
}

// IncrementLikes increments the likes count
// Note: This is also handled by database trigger, but provided for manual use if needed
func (r *commentRepository) IncrementLikes(ctx context.Context, commentID uuid.UUID) error {
	query := `UPDATE comments SET likes_count = likes_count + 1 WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, commentID)
	return err
}

// DecrementLikes decrements the likes count
// Note: This is also handled by database trigger, but provided for manual use if needed
func (r *commentRepository) DecrementLikes(ctx context.Context, commentID uuid.UUID) error {
	query := `UPDATE comments SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, commentID)
	return err
}
