package postgres

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/anigmaa/backend/internal/domain/user"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/lib/pq"
)

type userRepository struct {
	db *sqlx.DB
}

// NewUserRepository creates a new user repository
func NewUserRepository(db *sqlx.DB) user.Repository {
	return &userRepository{db: db}
}

// Create creates a new user (Google Auth only)
func (r *userRepository) Create(ctx context.Context, u *user.User) error {
	query := `
		INSERT INTO users (
			id, email, username, name, role, bio, avatar_url,
			phone, date_of_birth, gender, location, interests,
			created_at, updated_at, is_verified, is_email_verified
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
		RETURNING id, created_at, updated_at
	`

	u.ID = uuid.New()
	u.CreatedAt = time.Now()
	u.UpdatedAt = time.Now()
	u.IsVerified = false // Default
    if u.Role == "" {
        u.Role = "user"
    }

	return r.db.QueryRowContext(ctx, query,
		u.ID, u.Email, u.Username, u.Name, u.Role, u.Bio, u.AvatarURL,
		u.Phone, u.DateOfBirth, u.Gender, u.Location, pq.Array(u.Interests),
		u.CreatedAt, u.UpdatedAt, u.IsVerified, u.IsEmailVerified,
	).Scan(&u.ID, &u.CreatedAt, &u.UpdatedAt)
}

// GetByID gets a user by ID
func (r *userRepository) GetByID(ctx context.Context, id uuid.UUID) (*user.User, error) {
	var u user.User
	query := `
		SELECT id, email, username, role, name as name, bio, avatar_url,
		       phone, date_of_birth, gender, location, interests,
		       created_at, updated_at, last_login_at, is_verified, is_email_verified
		FROM users WHERE id = $1
	`

	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&u.ID, &u.Email, &u.Username, &u.Role, &u.Name, &u.Bio, &u.AvatarURL,
		&u.Phone, &u.DateOfBirth, &u.Gender, &u.Location, pq.Array(&u.Interests),
		&u.CreatedAt, &u.UpdatedAt, &u.LastLoginAt, &u.IsVerified, &u.IsEmailVerified,
	)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}
	if err != nil {
		return nil, err
	}

	return &u, nil
}

// GetByEmail gets a user by email
func (r *userRepository) GetByEmail(ctx context.Context, email string) (*user.User, error) {
	var u user.User
	query := `
		SELECT id, email, username, role, name as name, bio, avatar_url,
		       phone, date_of_birth, gender, location, interests,
		       created_at, updated_at, last_login_at, is_verified, is_email_verified
		FROM users WHERE email = $1
	`

	err := r.db.QueryRowContext(ctx, query, email).Scan(
		&u.ID, &u.Email, &u.Username, &u.Role, &u.Name, &u.Bio, &u.AvatarURL,
		&u.Phone, &u.DateOfBirth, &u.Gender, &u.Location, pq.Array(&u.Interests),
		&u.CreatedAt, &u.UpdatedAt, &u.LastLoginAt, &u.IsVerified, &u.IsEmailVerified,
	)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}
	if err != nil {
		return nil, err
	}

	return &u, nil
}

// GetByUsername gets a user by username
func (r *userRepository) GetByUsername(ctx context.Context, username string) (*user.User, error) {
	var u user.User
	query := `
		SELECT id, email, username, role, name as name, bio, avatar_url,
		       phone, date_of_birth, gender, location, interests,
		       created_at, updated_at, last_login_at, is_verified, is_email_verified
		FROM users WHERE username = $1
	`

	err := r.db.QueryRowContext(ctx, query, username).Scan(
		&u.ID, &u.Email, &u.Username, &u.Role, &u.Name, &u.Bio, &u.AvatarURL,
		&u.Phone, &u.DateOfBirth, &u.Gender, &u.Location, pq.Array(&u.Interests),
		&u.CreatedAt, &u.UpdatedAt, &u.LastLoginAt, &u.IsVerified, &u.IsEmailVerified,
	)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}
	if err != nil {
		return nil, err
	}

	return &u, nil
}

// Update updates a user
func (r *userRepository) Update(ctx context.Context, u *user.User) error {
	query := `
		UPDATE users
		SET name = $1, bio = $2, avatar_url = $3,
			phone = $4, date_of_birth = $5, gender = $6, location = $7, interests = $8,
			updated_at = $9, last_login_at = $10, is_verified = $11, is_email_verified = $12
		WHERE id = $13
	`

	u.UpdatedAt = time.Now()

	_, err := r.db.ExecContext(ctx, query,
		u.Name, u.Bio, u.AvatarURL,
		u.Phone, u.DateOfBirth, u.Gender, u.Location, pq.Array(u.Interests),
		u.UpdatedAt, u.LastLoginAt, u.IsVerified, u.IsEmailVerified, u.ID,
	)

	return err
}

// Delete deletes a user
func (r *userRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM users WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	return err
}

// GetProfile gets a complete user profile
func (r *userRepository) GetProfile(ctx context.Context, userID uuid.UUID) (*user.UserProfile, error) {
	var profile user.UserProfile

	// Get user
	u, err := r.GetByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	profile.User = *u

	// Get settings
	var settings user.UserSettings
	settingsQuery := `SELECT * FROM user_settings WHERE user_id = $1`
	err = r.db.GetContext(ctx, &settings, settingsQuery, userID)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	profile.Settings = settings

	// Get stats
	stats, err := r.GetStats(ctx, userID)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	if stats != nil {
		profile.Stats = *stats
	}

	// Get privacy
	var privacy user.UserPrivacy
	privacyQuery := `SELECT * FROM user_privacy WHERE user_id = $1`
	err = r.db.GetContext(ctx, &privacy, privacyQuery, userID)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	profile.Privacy = privacy

	return &profile, nil
}

// GetProfileByUsername is deprecated - Google Auth only, no usernames
// Kept for backwards compatibility but will always return not found
func (r *userRepository) GetProfileByUsername(ctx context.Context, username string) (*user.UserProfile, error) {
	return nil, fmt.Errorf("user not found")
}

// UpdateSettings updates user settings
func (r *userRepository) UpdateSettings(ctx context.Context, settings *user.UserSettings) error {
	query := `
		INSERT INTO user_settings (user_id, push_notifications, email_notifications, dark_mode, language, location_enabled, show_online_status)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		ON CONFLICT (user_id) DO UPDATE SET
			push_notifications = EXCLUDED.push_notifications,
			email_notifications = EXCLUDED.email_notifications,
			dark_mode = EXCLUDED.dark_mode,
			language = EXCLUDED.language,
			location_enabled = EXCLUDED.location_enabled,
			show_online_status = EXCLUDED.show_online_status
	`

	_, err := r.db.ExecContext(ctx, query,
		settings.UserID, settings.PushNotifications, settings.EmailNotifications,
		settings.DarkMode, settings.Language, settings.LocationEnabled, settings.ShowOnlineStatus,
	)

	return err
}

// UpdatePrivacy updates user privacy settings
func (r *userRepository) UpdatePrivacy(ctx context.Context, privacy *user.UserPrivacy) error {
	query := `
		INSERT INTO user_privacy (user_id, profile_visible, events_visible, allow_followers, show_email, show_location)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (user_id) DO UPDATE SET
			profile_visible = EXCLUDED.profile_visible,
			events_visible = EXCLUDED.events_visible,
			allow_followers = EXCLUDED.allow_followers,
			show_email = EXCLUDED.show_email,
			show_location = EXCLUDED.show_location
	`

	_, err := r.db.ExecContext(ctx, query,
		privacy.UserID, privacy.ProfileVisible, privacy.EventsVisible,
		privacy.AllowFollowers, privacy.ShowEmail, privacy.ShowLocation,
	)

	return err
}

// Follow follows a user
func (r *userRepository) Follow(ctx context.Context, followerID, followingID uuid.UUID) error {
	query := `
		INSERT INTO follows (id, follower_id, following_id, created_at)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (follower_id, following_id) DO NOTHING
	`

	_, err := r.db.ExecContext(ctx, query, uuid.New(), followerID, followingID, time.Now())
	if err != nil {
		return err
	}

	// Update follower/following counts
	_ = r.updateFollowCounts(ctx, followerID, followingID)

	return nil
}

// Unfollow unfollows a user
func (r *userRepository) Unfollow(ctx context.Context, followerID, followingID uuid.UUID) error {
	query := `DELETE FROM follows WHERE follower_id = $1 AND following_id = $2`

	_, err := r.db.ExecContext(ctx, query, followerID, followingID)
	if err != nil {
		return err
	}

	// Update follower/following counts
	_ = r.updateFollowCounts(ctx, followerID, followingID)

	return nil
}

// GetFollowers gets users following a specific user
func (r *userRepository) GetFollowers(ctx context.Context, userID uuid.UUID, limit, offset int) ([]user.User, error) {
	query := `
		SELECT u.id, u.email, u.username, u.role, u.name as name, u.bio, u.avatar_url,
		       u.phone, u.date_of_birth, u.gender, u.location, u.interests,
		       u.created_at, u.updated_at, u.last_login_at, u.is_verified, u.is_email_verified
		FROM users u
		INNER JOIN follows f ON u.id = f.follower_id
		WHERE f.following_id = $1
		ORDER BY f.created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.db.QueryContext(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []user.User
	for rows.Next() {
		var u user.User
		err := rows.Scan(
			&u.ID, &u.Email, &u.Username, &u.Role, &u.Name, &u.Bio, &u.AvatarURL,
			&u.Phone, &u.DateOfBirth, &u.Gender, &u.Location, pq.Array(&u.Interests),
			&u.CreatedAt, &u.UpdatedAt, &u.LastLoginAt, &u.IsVerified, &u.IsEmailVerified,
		)
		if err != nil {
			return nil, err
		}
		users = append(users, u)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return users, nil
}

// GetFollowing gets users that a specific user is following
func (r *userRepository) GetFollowing(ctx context.Context, userID uuid.UUID, limit, offset int) ([]user.User, error) {
	query := `
		SELECT u.id, u.email, u.username, u.role, u.name as name, u.bio, u.avatar_url,
		       u.phone, u.date_of_birth, u.gender, u.location, u.interests,
		       u.created_at, u.updated_at, u.last_login_at, u.is_verified, u.is_email_verified
		FROM users u
		INNER JOIN follows f ON u.id = f.following_id
		WHERE f.follower_id = $1
		ORDER BY f.created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.db.QueryContext(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []user.User
	for rows.Next() {
		var u user.User
		err := rows.Scan(
			&u.ID, &u.Email, &u.Username, &u.Role, &u.Name, &u.Bio, &u.AvatarURL,
			&u.Phone, &u.DateOfBirth, &u.Gender, &u.Location, pq.Array(&u.Interests),
			&u.CreatedAt, &u.UpdatedAt, &u.LastLoginAt, &u.IsVerified, &u.IsEmailVerified,
		)
		if err != nil {
			return nil, err
		}
		users = append(users, u)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return users, nil
}

// IsFollowing checks if a user is following another user
func (r *userRepository) IsFollowing(ctx context.Context, followerID, followingID uuid.UUID) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM follows WHERE follower_id = $1 AND following_id = $2)`

	var exists bool
	err := r.db.GetContext(ctx, &exists, query, followerID, followingID)
	return exists, err
}

// GetStats gets user statistics
func (r *userRepository) GetStats(ctx context.Context, userID uuid.UUID) (*user.UserStats, error) {
	var stats user.UserStats
	query := `SELECT * FROM user_stats WHERE user_id = $1`

	err := r.db.GetContext(ctx, &stats, query, userID)
	if err == sql.ErrNoRows {
		// Return default stats if not found
		return &user.UserStats{
			UserID:         userID,
			EventsAttended: 0,
			EventsCreated:  0,
			FollowersCount: 0,
			FollowingCount: 0,
			ReviewsGiven:   0,
			AverageRating:  0,
		}, nil
	}
	if err != nil {
		return nil, err
	}

	return &stats, nil
}

// IncrementEventsAttended increments events attended count
func (r *userRepository) IncrementEventsAttended(ctx context.Context, userID uuid.UUID) error {
	query := `
		INSERT INTO user_stats (user_id, events_attended, events_created, followers_count, following_count, reviews_given, average_rating)
		VALUES ($1, 1, 0, 0, 0, 0, 0)
		ON CONFLICT (user_id) DO UPDATE SET
			events_attended = user_stats.events_attended + 1
	`

	_, err := r.db.ExecContext(ctx, query, userID)
	return err
}

// IncrementEventsCreated increments events created count
func (r *userRepository) IncrementEventsCreated(ctx context.Context, userID uuid.UUID) error {
	query := `
		INSERT INTO user_stats (user_id, events_attended, events_created, followers_count, following_count, reviews_given, average_rating)
		VALUES ($1, 0, 1, 0, 0, 0, 0)
		ON CONFLICT (user_id) DO UPDATE SET
			events_created = user_stats.events_created + 1
	`

	_, err := r.db.ExecContext(ctx, query, userID)
	return err
}

// UpdateAverageRating updates average rating
func (r *userRepository) UpdateAverageRating(ctx context.Context, userID uuid.UUID, rating float64) error {
	query := `
		UPDATE user_stats
		SET average_rating = $1, reviews_given = reviews_given + 1
		WHERE user_id = $2
	`

	_, err := r.db.ExecContext(ctx, query, rating, userID)
	return err
}

// SearchUsers searches users by name or email
func (r *userRepository) SearchUsers(ctx context.Context, query string, limit, offset int) ([]user.User, error) {
	searchQuery := `
		SELECT id, email, username, role, name as name, bio, avatar_url,
		       phone, date_of_birth, gender, location, interests,
		       created_at, updated_at, last_login_at, is_verified, is_email_verified
		FROM users
		WHERE name ILIKE $1 OR email ILIKE $1 OR username ILIKE $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.db.QueryContext(ctx, searchQuery, "%"+query+"%", limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []user.User
	for rows.Next() {
		var u user.User
		err := rows.Scan(
			&u.ID, &u.Email, &u.Username, &u.Role, &u.Name, &u.Bio, &u.AvatarURL,
			&u.Phone, &u.DateOfBirth, &u.Gender, &u.Location, pq.Array(&u.Interests),
			&u.CreatedAt, &u.UpdatedAt, &u.LastLoginAt, &u.IsVerified, &u.IsEmailVerified,
		)
		if err != nil {
			return nil, err
		}
		users = append(users, u)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return users, nil
}

// updateFollowCounts updates follower/following counts for both users
func (r *userRepository) updateFollowCounts(ctx context.Context, followerID, followingID uuid.UUID) error {
	// Update follower's following count
	followingCountQuery := `
		INSERT INTO user_stats (user_id, events_attended, events_created, followers_count, following_count, reviews_given, average_rating)
		VALUES ($1, 0, 0, 0, (SELECT COUNT(*) FROM follows WHERE follower_id = $1), 0, 0)
		ON CONFLICT (user_id) DO UPDATE SET
			following_count = (SELECT COUNT(*) FROM follows WHERE follower_id = $1)
	`
	_, _ = r.db.ExecContext(ctx, followingCountQuery, followerID)

	// Update following user's followers count
	followersCountQuery := `
		INSERT INTO user_stats (user_id, events_attended, events_created, followers_count, following_count, reviews_given, average_rating)
		VALUES ($1, 0, 0, (SELECT COUNT(*) FROM follows WHERE following_id = $1), 0, 0, 0)
		ON CONFLICT (user_id) DO UPDATE SET
			followers_count = (SELECT COUNT(*) FROM follows WHERE following_id = $1)
	`
	_, _ = r.db.ExecContext(ctx, followersCountQuery, followingID)

	return nil
}

// CountFollowers counts total followers for a user
func (r *userRepository) CountFollowers(ctx context.Context, userID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM follows WHERE following_id = $1`
	var count int
	err := r.db.QueryRowContext(ctx, query, userID).Scan(&count)
	return count, err
}

// CountFollowing counts total users a user is following
func (r *userRepository) CountFollowing(ctx context.Context, userID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM follows WHERE follower_id = $1`
	var count int
	err := r.db.QueryRowContext(ctx, query, userID).Scan(&count)
	return count, err
}

// CountSearchResults counts total users matching search query
func (r *userRepository) CountSearchResults(ctx context.Context, query string) (int, error) {
	sql := `
		SELECT COUNT(*)
		FROM users
		WHERE (name ILIKE $1 OR email ILIKE $1)
	`
	searchTerm := "%" + query + "%"
	var count int
	err := r.db.QueryRowContext(ctx, sql, searchTerm).Scan(&count)
	return count, err
}
