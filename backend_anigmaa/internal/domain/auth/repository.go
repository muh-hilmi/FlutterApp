package auth

import (
	"context"

	"github.com/google/uuid"
)

// Repository defines the interface for auth token persistence
type Repository interface {
	// CreateToken creates a new auth token
	CreateToken(ctx context.Context, token *AuthToken) error

	// GetTokenByValue gets a token by its value
	GetTokenByValue(ctx context.Context, tokenValue string) (*AuthToken, error)

	// MarkTokenAsUsed marks a token as used
	MarkTokenAsUsed(ctx context.Context, tokenValue string) error

	// DeleteExpiredTokens deletes all expired tokens
	DeleteExpiredTokens(ctx context.Context) error

	// DeleteTokensByUser deletes all tokens for a specific user
	DeleteTokensByUser(ctx context.Context, userID uuid.UUID, tokenType TokenType) error
}
