package qna

import (
	"context"
	"errors"
	"time"

	"github.com/anigmaa/backend/internal/domain/event"
	"github.com/anigmaa/backend/internal/domain/qna"
	"github.com/google/uuid"
)

var (
	ErrQnANotFound     = errors.New("Q&A not found")
	ErrEventNotFound   = errors.New("event not found")
	ErrUnauthorized    = errors.New("unauthorized")
	ErrAlreadyUpvoted  = errors.New("already upvoted")
	ErrNotUpvoted      = errors.New("not upvoted")
	ErrAlreadyAnswered = errors.New("question already answered")
)

// Usecase handles Q&A business logic
type Usecase struct {
	qnaRepo   qna.Repository
	eventRepo event.Repository
}

// NewUsecase creates a new Q&A use case
func NewUsecase(qnaRepo qna.Repository, eventRepo event.Repository) *Usecase {
	return &Usecase{
		qnaRepo:   qnaRepo,
		eventRepo: eventRepo,
	}
}

// AskQuestion creates a new question for an event
func (uc *Usecase) AskQuestion(ctx context.Context, userID uuid.UUID, req *qna.CreateQnARequest) (*qna.QnAWithDetails, error) {
	// Verify event exists
	_, err := uc.eventRepo.GetByID(ctx, req.EventID)
	if err != nil {
		return nil, ErrEventNotFound
	}

	// Create Q&A
	newQnA := &qna.QnA{
		ID:        uuid.New(),
		EventID:   req.EventID,
		Question:  req.Question,
		AskedByID: userID,
		AskedAt:   time.Now(),
		Upvotes:   0,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if err := uc.qnaRepo.Create(ctx, newQnA); err != nil {
		return nil, err
	}

	// Fetch the created Q&A with user details
	qnaWithDetails, err := uc.qnaRepo.GetByIDWithDetails(ctx, newQnA.ID, userID)
	if err != nil {
		return nil, err
	}

	return qnaWithDetails, nil
}

// GetEventQnA retrieves all Q&A for an event
func (uc *Usecase) GetEventQnA(ctx context.Context, eventID, userID uuid.UUID, limit, offset int) ([]qna.QnAWithDetails, error) {
	// Verify event exists
	_, err := uc.eventRepo.GetByID(ctx, eventID)
	if err != nil {
		return nil, ErrEventNotFound
	}

	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	return uc.qnaRepo.GetByEvent(ctx, eventID, userID, limit, offset)
}

// AnswerQuestion answers a question (event organizer only)
func (uc *Usecase) AnswerQuestion(ctx context.Context, qnaID, userID uuid.UUID, req *qna.AnswerQnARequest) (*qna.QnA, error) {
	// Get Q&A
	q, err := uc.qnaRepo.GetByID(ctx, qnaID)
	if err != nil {
		return nil, ErrQnANotFound
	}

	// Check if already answered
	if q.Answer != nil {
		return nil, ErrAlreadyAnswered
	}

	// TODO: Verify user is event organizer
	// For now, allow anyone to answer

	// Update Q&A with answer
	now := time.Now()
	q.Answer = &req.Answer
	q.AnsweredByID = &userID
	q.AnsweredAt = &now
	q.UpdatedAt = now

	if err := uc.qnaRepo.Update(ctx, q); err != nil {
		return nil, err
	}

	return q, nil
}

// UpvoteQuestion adds an upvote to a question
func (uc *Usecase) UpvoteQuestion(ctx context.Context, qnaID, userID uuid.UUID) error {
	// Check if Q&A exists
	_, err := uc.qnaRepo.GetByID(ctx, qnaID)
	if err != nil {
		return ErrQnANotFound
	}

	// Add upvote
	if err := uc.qnaRepo.Upvote(ctx, qnaID, userID); err != nil {
		if err.Error() == "already upvoted" {
			return ErrAlreadyUpvoted
		}
		return err
	}

	return nil
}

// RemoveUpvote removes an upvote from a question
func (uc *Usecase) RemoveUpvote(ctx context.Context, qnaID, userID uuid.UUID) error {
	// Check if Q&A exists
	_, err := uc.qnaRepo.GetByID(ctx, qnaID)
	if err != nil {
		return ErrQnANotFound
	}

	// Remove upvote
	if err := uc.qnaRepo.RemoveUpvote(ctx, qnaID, userID); err != nil {
		if err.Error() == "not upvoted" {
			return ErrNotUpvoted
		}
		return err
	}

	return nil
}

// DeleteQuestion deletes a question (author only)
func (uc *Usecase) DeleteQuestion(ctx context.Context, qnaID, userID uuid.UUID) error {
	// Get Q&A
	q, err := uc.qnaRepo.GetByID(ctx, qnaID)
	if err != nil {
		return ErrQnANotFound
	}

	// Check if user is the author
	if q.AskedByID != userID {
		return ErrUnauthorized
	}

	return uc.qnaRepo.Delete(ctx, qnaID)
}

// CountEventQnA counts total questions for an event
func (uc *Usecase) CountEventQnA(ctx context.Context, eventID uuid.UUID) (int, error) {
	return uc.qnaRepo.CountEventQnA(ctx, eventID)
}
