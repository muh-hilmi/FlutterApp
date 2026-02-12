package postgres

import (
	"context"
	"database/sql"
	"time"

	"github.com/anigmaa/backend/internal/domain/auth"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type authTokenRepository struct {
	db *sqlx.DB
}

// NewAuthTokenRepository creates a new auth token repository
func NewAuthTokenRepository(db *sqlx.DB) auth.Repository {
	return &authTokenRepository{db: db}
}

// CreateToken creates a new auth token
func (r *authTokenRepository) CreateToken(ctx context.Context, token *auth.AuthToken) error {
	// Generate UUID if not provided
	if token.ID == uuid.Nil {
		token.ID = uuid.New()
	}

	// Set created_at if not provided
	if token.CreatedAt.IsZero() {
		token.CreatedAt = time.Now()
	}

	query := `
		INSERT INTO auth_tokens (id, user_id, token, token_type, expires_at, created_at)
		VALUES ($1, $2, $3, $4, $5, $6)
	`

	_, err := r.db.ExecContext(ctx, query,
		token.ID, token.UserID, token.Token, token.TokenType, token.ExpiresAt, token.CreatedAt,
	)

	return err
}

// GetTokenByValue gets a token by its value
func (r *authTokenRepository) GetTokenByValue(ctx context.Context, tokenValue string) (*auth.AuthToken, error) {
	query := `
		SELECT id, user_id, token, token_type, expires_at, used_at, created_at
		FROM auth_tokens
		WHERE token = $1
	`

	var token auth.AuthToken
	err := r.db.GetContext(ctx, &token, query, tokenValue)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, sql.ErrNoRows
		}
		return nil, err
	}

	return &token, nil
}

// MarkTokenAsUsed marks a token as used
func (r *authTokenRepository) MarkTokenAsUsed(ctx context.Context, tokenValue string) error {
	now := time.Now()
	query := `
		UPDATE auth_tokens
		SET used_at = $1
		WHERE token = $2 AND used_at IS NULL
	`

	result, err := r.db.ExecContext(ctx, query, now, tokenValue)
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

// DeleteExpiredTokens deletes all expired tokens
func (r *authTokenRepository) DeleteExpiredTokens(ctx context.Context) error {
	query := `DELETE FROM auth_tokens WHERE expires_at < $1`

	_, err := r.db.ExecContext(ctx, query, time.Now())
	return err
}

// DeleteTokensByUser deletes all tokens for a specific user
func (r *authTokenRepository) DeleteTokensByUser(ctx context.Context, userID uuid.UUID, tokenType auth.TokenType) error {
	query := `DELETE FROM auth_tokens WHERE user_id = $1 AND token_type = $2`

	_, err := r.db.ExecContext(ctx, query, userID, tokenType)
	return err
}
