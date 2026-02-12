package qna

import (
	"context"

	"github.com/google/uuid"
)

// Repository defines the interface for Q&A data operations
type Repository interface {
	// Create creates a new question
	Create(ctx context.Context, qna *QnA) error

	// GetByID retrieves a Q&A by ID
	GetByID(ctx context.Context, id uuid.UUID) (*QnA, error)

	// GetByIDWithDetails retrieves a Q&A by ID with user details
	GetByIDWithDetails(ctx context.Context, id, userID uuid.UUID) (*QnAWithDetails, error)

	// GetByEvent retrieves all Q&A for an event
	GetByEvent(ctx context.Context, eventID, userID uuid.UUID, limit, offset int) ([]QnAWithDetails, error)

	// Update updates a Q&A (for answering)
	Update(ctx context.Context, qna *QnA) error

	// Delete deletes a Q&A
	Delete(ctx context.Context, id uuid.UUID) error

	// Upvote adds an upvote to a question
	Upvote(ctx context.Context, qnaID, userID uuid.UUID) error

	// RemoveUpvote removes an upvote from a question
	RemoveUpvote(ctx context.Context, qnaID, userID uuid.UUID) error

	// IsUpvotedByUser checks if a user has upvoted a question
	IsUpvotedByUser(ctx context.Context, qnaID, userID uuid.UUID) (bool, error)

	// GetUpvoteCount gets the number of upvotes for a question
	GetUpvoteCount(ctx context.Context, qnaID uuid.UUID) (int, error)

	// CountEventQnA counts total questions for an event
	CountEventQnA(ctx context.Context, eventID uuid.UUID) (int, error)
}
