package user

import (
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
)

// ValidInterests contains the standardized list of valid interests (aligned with event/community categories)
var ValidInterests = []string{
	"Meetup",
	"Sports",
	"Workshop",
	"Networking",
	"Food",
	"Creative",
	"Outdoor",
	"Fitness",
	"Learning",
	"Social",
}

// ValidateInterests checks if all interests are valid (case-insensitive)
func ValidateInterests(interests []string) bool {
	if len(interests) == 0 {
		return true // Empty is valid
	}

	validMap := make(map[string]bool)
	for _, interest := range ValidInterests {
		validMap[strings.ToLower(interest)] = true
	}

	for _, interest := range interests {
		if !validMap[strings.ToLower(interest)] {
			return false
		}
	}
	return true
}

// User represents a user in the system (Google Auth only)
type User struct {
	ID              uuid.UUID  `json:"id" db:"id"`
	Email           string     `json:"email" db:"email"`
	Username        string     `json:"username" db:"username"` // Added for V1
	Role            string     `json:"role" db:"role"`         // Added for V1 (user, host, admin)
	Name            string     `json:"name" db:"name"`
	Bio             *string    `json:"bio,omitempty" db:"bio"`
	AvatarURL       *string    `json:"avatar_url,omitempty" db:"avatar_url"`
	Phone           *string    `json:"phone,omitempty" db:"phone"`
	DateOfBirth     *time.Time `json:"date_of_birth,omitempty" db:"date_of_birth"`
	Gender          *string    `json:"gender,omitempty" db:"gender"`
	Location        *string    `json:"location,omitempty" db:"location"` // City name
	Interests       []string   `json:"interests" db:"interests"`         // PostgreSQL text array
	CreatedAt       time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at" db:"updated_at"`
	LastLoginAt     *time.Time `json:"last_login_at,omitempty" db:"last_login_at"`
	IsVerified      bool       `json:"is_verified" db:"is_verified"`
	IsEmailVerified bool       `json:"is_email_verified" db:"is_email_verified"`
}

// UserSettings contains user preferences
type UserSettings struct {
	UserID             uuid.UUID `json:"user_id" db:"user_id"`
	PushNotifications  bool      `json:"push_notifications" db:"push_notifications"`
	EmailNotifications bool      `json:"email_notifications" db:"email_notifications"`
	DarkMode           bool      `json:"dark_mode" db:"dark_mode"`
	Language           string    `json:"language" db:"language"`
	LocationEnabled    bool      `json:"location_enabled" db:"location_enabled"`
	ShowOnlineStatus   bool      `json:"show_online_status" db:"show_online_status"`
}

// UserStats contains user statistics
type UserStats struct {
	UserID                 uuid.UUID `json:"user_id" db:"user_id"`
	EventsAttended         int       `json:"events_attended" db:"events_attended"`
	EventsCreated          int       `json:"events_created" db:"events_created"`
	FollowersCount         int       `json:"followers_count" db:"followers_count"`
	FollowingCount         int       `json:"following_count" db:"following_count"`
	ReviewsGiven           int       `json:"reviews_given" db:"reviews_given"`
	AverageRating          float64   `json:"average_rating" db:"average_rating"`
	PostsCount             int       `json:"posts_count" db:"posts_count"`
	InvitesSuccessfulCount int       `json:"invites_successful_count" db:"invites_successful_count"`
}

// UserPrivacy contains privacy settings
type UserPrivacy struct {
	UserID         uuid.UUID `json:"user_id" db:"user_id"`
	ProfileVisible bool      `json:"profile_visible" db:"profile_visible"`
	EventsVisible  bool      `json:"events_visible" db:"events_visible"`
	AllowFollowers bool      `json:"allow_followers" db:"allow_followers"`
	ShowEmail      bool      `json:"show_email" db:"show_email"`
	ShowLocation   bool      `json:"show_location" db:"show_location"`
}

// Follow represents a follow relationship
type Follow struct {
	ID          uuid.UUID `json:"id" db:"id"`
	FollowerID  uuid.UUID `json:"follower_id" db:"follower_id"`
	FollowingID uuid.UUID `json:"following_id" db:"following_id"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

// UserProfile is a complete user profile with stats and settings
type UserProfile struct {
	User        User         `json:"user"`
	Settings    UserSettings `json:"settings"`
	Stats       UserStats    `json:"stats"`
	Privacy     UserPrivacy  `json:"privacy"`
	IsFollowing *bool        `json:"is_following,omitempty"` // nil if not applicable (e.g., own profile), true/false otherwise
}

// FlexibleTime can unmarshal from multiple date/datetime formats
type FlexibleTime struct {
	time.Time
}

// UnmarshalJSON implements custom unmarshaling for FlexibleTime
func (ft *FlexibleTime) UnmarshalJSON(data []byte) error {
	// Remove quotes
	str := string(data)
	if len(str) >= 2 && str[0] == '"' && str[len(str)-1] == '"' {
		str = str[1 : len(str)-1]
	}

	// Try multiple formats
	formats := []string{
		time.RFC3339,                  // 2006-01-02T15:04:05Z07:00
		"2006-01-02T15:04:05.999",     // Flutter format without timezone
		"2006-01-02T15:04:05",         // ISO 8601 without timezone
		"2006-01-02",                  // Date only
		"2006-01-02 15:04:05",         // Common datetime format
	}

	for _, format := range formats {
		if t, err := time.Parse(format, str); err == nil {
			ft.Time = t
			return nil
		}
	}

	return fmt.Errorf("unable to parse time: %s", str)
}

// UpdateProfileRequest represents profile update data
type UpdateProfileRequest struct {
	Bio         *string       `json:"bio,omitempty" binding:"omitempty,max=150"`
	AvatarURL   *string       `json:"avatar_url,omitempty"`
	Phone       *string       `json:"phone,omitempty" binding:"omitempty,numeric,min=10,max=15"`
	DateOfBirth *FlexibleTime `json:"date_of_birth,omitempty"`
	Gender      *string       `json:"gender,omitempty" binding:"omitempty,oneof='Laki-laki' 'Perempuan' 'Lainnya' 'Prefer not to say'"`
	Location    *string       `json:"location,omitempty"`
	Interests   []string      `json:"interests,omitempty" binding:"omitempty,max=20,dive,min=1"`
}

// UpdateSettingsRequest represents settings update data
type UpdateSettingsRequest struct {
	PushNotifications  *bool   `json:"push_notifications,omitempty"`
	EmailNotifications *bool   `json:"email_notifications,omitempty"`
	DarkMode           *bool   `json:"dark_mode,omitempty"`
	Language           *string `json:"language,omitempty"`
	LocationEnabled    *bool   `json:"location_enabled,omitempty"`
	ShowOnlineStatus   *bool   `json:"show_online_status,omitempty"`
}

// GoogleAuthRequest represents Google authentication data
type GoogleAuthRequest struct {
	IDToken string `json:"idToken" binding:"required"`
}

// ProfileResponse represents public profile data for API response
type ProfileResponse struct {
	ID                     uuid.UUID  `json:"id"`
	Name                   string     `json:"name"`
	Bio                    *string    `json:"bio,omitempty"`
	AvatarURL              *string    `json:"avatar_url,omitempty"`
	Phone                  *string    `json:"phone,omitempty"`
	DateOfBirth            *time.Time `json:"date_of_birth,omitempty"`
	Gender                 *string    `json:"gender,omitempty"`
	Location               *string    `json:"location,omitempty"`
	Interests              []string   `json:"interests"`
	IsVerified             bool       `json:"is_verified"`
	IsEmailVerified        bool       `json:"is_email_verified"`
	CreatedAt              time.Time  `json:"created_at"`
	FollowersCount         int        `json:"followers_count"`
	FollowingCount         int        `json:"following_count"`
	EventsCreated          int        `json:"events_created"`
	PostsCount             int        `json:"posts_count"`
	InvitesSuccessfulCount int        `json:"invites_successful_count"`
	ShareLink              string     `json:"share_link"`
}

// ToProfileResponse converts UserProfile to ProfileResponse
func (up *UserProfile) ToProfileResponse(baseURL string) ProfileResponse {
	// Generate share link using user ID (no username in Google-only auth)
	shareLink := baseURL + "/user/" + up.User.ID.String()

	// Initialize empty interests array if nil
	interests := up.User.Interests
	if interests == nil {
		interests = []string{}
	}

	return ProfileResponse{
		ID:                     up.User.ID,
		Name:                   up.User.Name,
		Bio:                    up.User.Bio,
		AvatarURL:              up.User.AvatarURL,
		Phone:                  up.User.Phone,
		DateOfBirth:            up.User.DateOfBirth,
		Gender:                 up.User.Gender,
		Location:               up.User.Location,
		Interests:              interests,
		IsVerified:             up.User.IsVerified,
		IsEmailVerified:        up.User.IsEmailVerified,
		CreatedAt:              up.User.CreatedAt,
		FollowersCount:         up.Stats.FollowersCount,
		FollowingCount:         up.Stats.FollowingCount,
		EventsCreated:          up.Stats.EventsCreated,
		PostsCount:             up.Stats.PostsCount,
		InvitesSuccessfulCount: up.Stats.InvitesSuccessfulCount,
		ShareLink:              shareLink,
	}
}
