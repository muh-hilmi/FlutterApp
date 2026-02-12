package postgres

import (
	"context"
	"fmt"

	"github.com/anigmaa/backend/internal/domain/qna"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

// QnARepository implements the qna.Repository interface
type QnARepository struct {
	db *sqlx.DB
}

// NewQnARepository creates a new Q&A repository
func NewQnARepository(db *sqlx.DB) *QnARepository {
	return &QnARepository{db: db}
}

// Create creates a new question
func (r *QnARepository) Create(ctx context.Context, q *qna.QnA) error {
	query := `
		INSERT INTO event_qna (id, event_id, question, asked_by_id, asked_at, upvotes, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
	`

	_, err := r.db.ExecContext(ctx, query,
		q.ID,
		q.EventID,
		q.Question,
		q.AskedByID,
		q.AskedAt,
		q.Upvotes,
	)

	return err
}

// GetByID retrieves a Q&A by ID
func (r *QnARepository) GetByID(ctx context.Context, id uuid.UUID) (*qna.QnA, error) {
	query := `
		SELECT id, event_id, question, answer, asked_by_id, answered_by_id,
		       asked_at, answered_at, upvotes, created_at, updated_at
		FROM event_qna
		WHERE id = $1
	`

	q := &qna.QnA{}
	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&q.ID,
		&q.EventID,
		&q.Question,
		&q.Answer,
		&q.AskedByID,
		&q.AnsweredByID,
		&q.AskedAt,
		&q.AnsweredAt,
		&q.Upvotes,
		&q.CreatedAt,
		&q.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("Q&A not found")
	}

	return q, err
}

// GetByIDWithDetails retrieves a Q&A by ID with user details
func (r *QnARepository) GetByIDWithDetails(ctx context.Context, id, userID uuid.UUID) (*qna.QnAWithDetails, error) {
	query := `
		SELECT
			q.id, q.event_id, q.question, q.answer,
			q.asked_at, q.answered_at, q.upvotes,
			-- Asked by user
			u1.id as asked_by_id,
			u1.name as asked_by_name,
			u1.email as asked_by_email,
			u1.avatar_url as asked_by_avatar,
			u1.created_at as asked_by_created_at,
			-- Answered by user (nullable)
			u2.id as answered_by_id,
			u2.name as answered_by_name,
			u2.email as answered_by_email,
			u2.avatar_url as answered_by_avatar,
			u2.created_at as answered_by_created_at,
			-- Check if current user upvoted
			EXISTS(
				SELECT 1 FROM qna_upvotes
				WHERE qna_id = q.id AND user_id = $2
			) as is_upvoted
		FROM event_qna q
		INNER JOIN users u1 ON q.asked_by_id = u1.id
		LEFT JOIN users u2 ON q.answered_by_id = u2.id
		WHERE q.id = $1
	`

	var q qna.QnAWithDetails
	var askedByID, askedByName, askedByEmail string
	var askedByAvatar *string
	var askedByCreatedAt string
	var answeredByID, answeredByName, answeredByEmail *string
	var answeredByAvatar *string
	var answeredByCreatedAt *string

	err := r.db.QueryRowContext(ctx, query, id, userID).Scan(
		&q.ID,
		&q.EventID,
		&q.Question,
		&q.Answer,
		&q.AskedAt,
		&q.AnsweredAt,
		&q.Upvotes,
		&askedByID,
		&askedByName,
		&askedByEmail,
		&askedByAvatar,
		&askedByCreatedAt,
		&answeredByID,
		&answeredByName,
		&answeredByEmail,
		&answeredByAvatar,
		&answeredByCreatedAt,
		&q.IsUpvotedByUser,
	)

	if err != nil {
		return nil, fmt.Errorf("Q&A not found")
	}

	// Parse asked by user
	askedByUUID, _ := uuid.Parse(askedByID)
	q.AskedBy = qna.UserBasicInfo{
		ID:     askedByUUID,
		Name:   askedByName,
		Email:  askedByEmail,
		Avatar: askedByAvatar,
	}

	// Parse answered by user if exists
	if answeredByID != nil {
		answeredByUUID, _ := uuid.Parse(*answeredByID)
		q.AnsweredBy = &qna.UserBasicInfo{
			ID:     answeredByUUID,
			Name:   *answeredByName,
			Email:  *answeredByEmail,
			Avatar: answeredByAvatar,
		}
	}

	return &q, nil
}

// GetByEvent retrieves all Q&A for an event
func (r *QnARepository) GetByEvent(ctx context.Context, eventID, userID uuid.UUID, limit, offset int) ([]qna.QnAWithDetails, error) {
	query := `
		SELECT
			q.id, q.event_id, q.question, q.answer,
			q.asked_at, q.answered_at, q.upvotes,
			-- Asked by user
			u1.id as asked_by_id,
			u1.name as asked_by_name,
			u1.email as asked_by_email,
			u1.avatar_url as asked_by_avatar,
			u1.created_at as asked_by_created_at,
			-- Answered by user (nullable)
			u2.id as answered_by_id,
			u2.name as answered_by_name,
			u2.email as answered_by_email,
			u2.avatar_url as answered_by_avatar,
			u2.created_at as answered_by_created_at,
			-- Check if current user upvoted
			EXISTS(
				SELECT 1 FROM qna_upvotes
				WHERE qna_id = q.id AND user_id = $2
			) as is_upvoted
		FROM event_qna q
		INNER JOIN users u1 ON q.asked_by_id = u1.id
		LEFT JOIN users u2 ON q.answered_by_id = u2.id
		WHERE q.event_id = $1
		ORDER BY q.upvotes DESC, q.asked_at DESC
		LIMIT $3 OFFSET $4
	`

	rows, err := r.db.QueryContext(ctx, query, eventID, userID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var qnaList []qna.QnAWithDetails

	for rows.Next() {
		var q qna.QnAWithDetails
		var askedByID, askedByName, askedByEmail string
		var askedByAvatar *string
		var askedByCreatedAt string
		var answeredByID, answeredByName, answeredByEmail *string
		var answeredByAvatar *string
		var answeredByCreatedAt *string

		err := rows.Scan(
			&q.ID,
			&q.EventID,
			&q.Question,
			&q.Answer,
			&q.AskedAt,
			&q.AnsweredAt,
			&q.Upvotes,
			&askedByID,
			&askedByName,
			&askedByEmail,
			&askedByAvatar,
			&askedByCreatedAt,
			&answeredByID,
			&answeredByName,
			&answeredByEmail,
			&answeredByAvatar,
			&answeredByCreatedAt,
			&q.IsUpvotedByUser,
		)

		if err != nil {
			return nil, err
		}

		// Parse asked by user
		askedByUUID, _ := uuid.Parse(askedByID)
		q.AskedBy = qna.UserBasicInfo{
			ID:     askedByUUID,
			Name:   askedByName,
			Email:  askedByEmail,
			Avatar: askedByAvatar,
		}

		// Parse answered by user if exists
		if answeredByID != nil {
			answeredByUUID, _ := uuid.Parse(*answeredByID)
			q.AnsweredBy = &qna.UserBasicInfo{
				ID:     answeredByUUID,
				Name:   *answeredByName,
				Email:  *answeredByEmail,
				Avatar: answeredByAvatar,
			}
		}

		qnaList = append(qnaList, q)
	}

	if qnaList == nil {
		qnaList = []qna.QnAWithDetails{}
	}

	return qnaList, rows.Err()
}

// Update updates a Q&A (for answering)
func (r *QnARepository) Update(ctx context.Context, q *qna.QnA) error {
	query := `
		UPDATE event_qna
		SET answer = $1, answered_by_id = $2, answered_at = $3, updated_at = NOW()
		WHERE id = $4
	`

	_, err := r.db.ExecContext(ctx, query,
		q.Answer,
		q.AnsweredByID,
		q.AnsweredAt,
		q.ID,
	)

	return err
}

// Delete deletes a Q&A
func (r *QnARepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM event_qna WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	return err
}

// Upvote adds an upvote to a question
func (r *QnARepository) Upvote(ctx context.Context, qnaID, userID uuid.UUID) error {
	// Start transaction
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// Check if already upvoted
	var exists bool
	err = tx.QueryRowContext(ctx, `
		SELECT EXISTS(SELECT 1 FROM qna_upvotes WHERE qna_id = $1 AND user_id = $2)
	`, qnaID, userID).Scan(&exists)
	if err != nil {
		return err
	}

	if exists {
		return fmt.Errorf("already upvoted")
	}

	// Insert upvote
	_, err = tx.ExecContext(ctx, `
		INSERT INTO qna_upvotes (qna_id, user_id, created_at)
		VALUES ($1, $2, NOW())
	`, qnaID, userID)
	if err != nil {
		return err
	}

	// Increment upvote count
	_, err = tx.ExecContext(ctx, `
		UPDATE event_qna SET upvotes = upvotes + 1 WHERE id = $1
	`, qnaID)
	if err != nil {
		return err
	}

	return tx.Commit()
}

// RemoveUpvote removes an upvote from a question
func (r *QnARepository) RemoveUpvote(ctx context.Context, qnaID, userID uuid.UUID) error {
	// Start transaction
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// Delete upvote
	result, err := tx.ExecContext(ctx, `
		DELETE FROM qna_upvotes WHERE qna_id = $1 AND user_id = $2
	`, qnaID, userID)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("not upvoted")
	}

	// Decrement upvote count
	_, err = tx.ExecContext(ctx, `
		UPDATE event_qna SET upvotes = GREATEST(upvotes - 1, 0) WHERE id = $1
	`, qnaID)
	if err != nil {
		return err
	}

	return tx.Commit()
}

// IsUpvotedByUser checks if a user has upvoted a question
func (r *QnARepository) IsUpvotedByUser(ctx context.Context, qnaID, userID uuid.UUID) (bool, error) {
	var exists bool
	query := `SELECT EXISTS(SELECT 1 FROM qna_upvotes WHERE qna_id = $1 AND user_id = $2)`
	err := r.db.QueryRowContext(ctx, query, qnaID, userID).Scan(&exists)
	return exists, err
}

// GetUpvoteCount gets the number of upvotes for a question
func (r *QnARepository) GetUpvoteCount(ctx context.Context, qnaID uuid.UUID) (int, error) {
	var count int
	query := `SELECT upvotes FROM event_qna WHERE id = $1`
	err := r.db.QueryRowContext(ctx, query, qnaID).Scan(&count)
	return count, err
}

// CountEventQnA counts total questions for an event
func (r *QnARepository) CountEventQnA(ctx context.Context, eventID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM event_qna WHERE event_id = $1`
	var count int
	err := r.db.QueryRowContext(ctx, query, eventID).Scan(&count)
	return count, err
}
