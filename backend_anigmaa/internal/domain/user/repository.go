package user

import (
	"context"

	"github.com/google/uuid"
)

// Repository defines the interface for user data access
type Repository interface {
	// User CRUD
	Create(ctx context.Context, user *User) error
	GetByID(ctx context.Context, id uuid.UUID) (*User, error)
	GetByEmail(ctx context.Context, email string) (*User, error)
	GetByUsername(ctx context.Context, username string) (*User, error)
	Update(ctx context.Context, user *User) error
	Delete(ctx context.Context, id uuid.UUID) error

	// User Profile
	GetProfile(ctx context.Context, userID uuid.UUID) (*UserProfile, error)
	GetProfileByUsername(ctx context.Context, username string) (*UserProfile, error)
	UpdateSettings(ctx context.Context, settings *UserSettings) error
	UpdatePrivacy(ctx context.Context, privacy *UserPrivacy) error

	// Follow system
	Follow(ctx context.Context, followerID, followingID uuid.UUID) error
	Unfollow(ctx context.Context, followerID, followingID uuid.UUID) error
	GetFollowers(ctx context.Context, userID uuid.UUID, limit, offset int) ([]User, error)
	GetFollowing(ctx context.Context, userID uuid.UUID, limit, offset int) ([]User, error)
	IsFollowing(ctx context.Context, followerID, followingID uuid.UUID) (bool, error)

	// Counting for pagination
	CountFollowers(ctx context.Context, userID uuid.UUID) (int, error)
	CountFollowing(ctx context.Context, userID uuid.UUID) (int, error)
	CountSearchResults(ctx context.Context, query string) (int, error)

	// Stats
	GetStats(ctx context.Context, userID uuid.UUID) (*UserStats, error)
	IncrementEventsAttended(ctx context.Context, userID uuid.UUID) error
	IncrementEventsCreated(ctx context.Context, userID uuid.UUID) error
	UpdateAverageRating(ctx context.Context, userID uuid.UUID, rating float64) error

	// Search
	SearchUsers(ctx context.Context, query string, limit, offset int) ([]User, error)
}
