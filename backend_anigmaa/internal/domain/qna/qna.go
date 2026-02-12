package qna

import (
	"time"

	"github.com/google/uuid"
)

// QnA represents a question and answer for an event
type QnA struct {
	ID              uuid.UUID  `json:"id" db:"id"`
	EventID         uuid.UUID  `json:"eventId" db:"event_id"`
	Question        string     `json:"question" db:"question"`
	Answer          *string    `json:"answer,omitempty" db:"answer"`
	AskedByID       uuid.UUID  `json:"-" db:"user_id"`
	AnsweredByID    *uuid.UUID `json:"-" db:"answered_by"`
	AskedAt         time.Time  `json:"askedAt" db:"asked_at"`
	AnsweredAt      *time.Time `json:"answeredAt,omitempty" db:"answered_at"`
	Upvotes         int        `json:"upvotes" db:"upvotes"`
	IsUpvotedByUser bool       `json:"isUpvotedByCurrentUser" db:"-"`
	CreatedAt       time.Time  `json:"-" db:"created_at"`
	UpdatedAt       time.Time  `json:"-" db:"updated_at"`
}

// QnAWithDetails includes user details for askedBy and answeredBy
type QnAWithDetails struct {
	ID              uuid.UUID      `json:"id"`
	EventID         uuid.UUID      `json:"eventId"`
	Question        string         `json:"question"`
	Answer          *string        `json:"answer,omitempty"`
	AskedBy         UserBasicInfo  `json:"askedBy"`
	AnsweredBy      *UserBasicInfo `json:"answeredBy,omitempty"`
	AskedAt         time.Time      `json:"askedAt"`
	AnsweredAt      *time.Time     `json:"answeredAt,omitempty"`
	Upvotes         int            `json:"upvotes"`
	IsUpvotedByUser bool           `json:"isUpvotedByCurrentUser"`
}

// UserBasicInfo represents basic user information
type UserBasicInfo struct {
	ID        uuid.UUID `json:"id"`
	Name      string    `json:"name"`
	Email     string    `json:"email"`
	Avatar    *string   `json:"avatar,omitempty"`
	CreatedAt time.Time `json:"createdAt"`
}

// CreateQnARequest represents the request to create a Q&A
type CreateQnARequest struct {
	EventID  uuid.UUID `json:"event_id" validate:"required"`
	Question string    `json:"question" validate:"required,min=3,max=500"`
}

// AnswerQnARequest represents the request to answer a question
type AnswerQnARequest struct {
	Answer string `json:"answer" validate:"required,min=1,max=1000"`
}
