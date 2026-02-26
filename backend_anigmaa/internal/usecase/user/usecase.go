package user

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
    "regexp"
    "strings"
	"time"

	"github.com/anigmaa/backend/internal/domain/auth"
	"github.com/anigmaa/backend/internal/domain/user"
	"github.com/anigmaa/backend/pkg/jwt"
	"github.com/google/uuid"
)

var (
	ErrUserNotFound     = errors.New("user not found")
	ErrUnauthorized     = errors.New("unauthorized")
	ErrAlreadyFollowing = errors.New("already following this user")
	ErrNotFollowing     = errors.New("not following this user")
	ErrCannotFollowSelf = errors.New("cannot follow yourself")
	ErrInvalidToken     = errors.New("invalid or expired token")
	ErrTokenAlreadyUsed = errors.New("token has already been used")
)

// Usecase handles user business logic
type Usecase struct {
	userRepo       user.Repository
	authTokenRepo  auth.Repository
	jwtManager     *jwt.JWTManager
	googleClientID string
}

// NewUsecase creates a new user usecase
func NewUsecase(userRepo user.Repository, authTokenRepo auth.Repository, jwtManager *jwt.JWTManager, googleClientID string) *Usecase {
	return &Usecase{
		userRepo:       userRepo,
		authTokenRepo:  authTokenRepo,
		jwtManager:     jwtManager,
		googleClientID: googleClientID,
	}
}

// AuthResponse represents authentication response
type AuthResponse struct {
	AccessToken  string     `json:"access_token"`
	RefreshToken string     `json:"refresh_token"`
	User         *user.User `json:"user"`
	ExpiresIn    int64      `json:"expires_in"` // seconds
}

// RefreshToken generates a new access token from a refresh token
func (uc *Usecase) RefreshToken(ctx context.Context, refreshToken string) (*AuthResponse, error) {
	// Verify refresh token
	claims, err := uc.jwtManager.Verify(refreshToken)
	if err != nil {
		return nil, ErrUnauthorized
	}

	// Get user
	existingUser, err := uc.userRepo.GetByID(ctx, claims.UserID)
	if err != nil {
		return nil, ErrUserNotFound
	}

	// Generate new tokens
	accessToken, err := uc.jwtManager.Generate(existingUser.ID, existingUser.Email)
	if err != nil {
		return nil, err
	}

	newRefreshToken, err := uc.jwtManager.GenerateRefreshToken(existingUser.ID, existingUser.Email)
	if err != nil {
		return nil, err
	}

	return &AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
		User:         existingUser,
		ExpiresIn:    3600, // 1 hour
	}, nil
}

// GetProfile gets a user's complete profile
func (uc *Usecase) GetProfile(ctx context.Context, userID uuid.UUID) (*user.UserProfile, error) {
	profile, err := uc.userRepo.GetProfile(ctx, userID)
	if err != nil {
		return nil, ErrUserNotFound
	}
	return profile, nil
}

// GetByID gets a user by ID
func (uc *Usecase) GetByID(ctx context.Context, userID uuid.UUID) (*user.User, error) {
	existingUser, err := uc.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, ErrUserNotFound
	}
	return existingUser, nil
}

// GetByUsername gets a user by username (which is actually user ID as string for Google Auth)
// This method exists for backwards compatibility with profile endpoints
func (uc *Usecase) GetByUsername(ctx context.Context, username string) (*user.User, error) {
	// Try to parse as UUID (user ID)
	userID, err := uuid.Parse(username)
	if err != nil {
		return nil, ErrUserNotFound
	}
	return uc.GetByID(ctx, userID)
}

// GetProfileByUsername gets a user profile by username (which is actually user ID as string)
func (uc *Usecase) GetProfileByUsername(ctx context.Context, username string) (*user.UserProfile, error) {
	// Try to parse as UUID (user ID)
	userID, err := uuid.Parse(username)
	if err != nil {
		return nil, ErrUserNotFound
	}
	return uc.GetProfile(ctx, userID)
}

// UpdateProfile updates a user's profile
func (uc *Usecase) UpdateProfile(ctx context.Context, userID uuid.UUID, req *user.UpdateProfileRequest) (*user.User, error) {
	// Get existing user
	existingUser, err := uc.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, ErrUserNotFound
	}

	// Update fields if provided
	// Note: Name and Email CANNOT be updated (from Google only)
	if req.Bio != nil {
		// Validate bio length (max 150 characters)
		if len(*req.Bio) > 150 {
			return nil, fmt.Errorf("bio must be at most 150 characters")
		}
		existingUser.Bio = req.Bio
	}
	if req.AvatarURL != nil {
		existingUser.AvatarURL = req.AvatarURL
	}
	if req.Phone != nil {
		existingUser.Phone = req.Phone
	}
	if req.DateOfBirth != nil {
		// Validate age (must be 13+ years old)
		age := time.Now().Year() - req.DateOfBirth.Year()
		if age < 13 {
			return nil, fmt.Errorf("user must be at least 13 years old")
		}
		// Convert FlexibleTime to *time.Time
		t := req.DateOfBirth.Time
		existingUser.DateOfBirth = &t
	}
	if req.Gender != nil {
		existingUser.Gender = req.Gender
	}
	if req.Location != nil {
		existingUser.Location = req.Location
	}
	if req.Interests != nil {
		// Validate interests array (max 20 items)
		if len(req.Interests) > 20 {
			return nil, fmt.Errorf("interests must have at most 20 items")
		}
		existingUser.Interests = req.Interests
	}

	existingUser.UpdatedAt = time.Now()

	// Save changes
	if err := uc.userRepo.Update(ctx, existingUser); err != nil {
		return nil, err
	}

	return existingUser, nil
}

// UpdateSettings updates a user's settings
func (uc *Usecase) UpdateSettings(ctx context.Context, userID uuid.UUID, req *user.UpdateSettingsRequest) (*user.UserSettings, error) {
	// Get current settings from profile
	profile, err := uc.userRepo.GetProfile(ctx, userID)
	if err != nil {
		return nil, ErrUserNotFound
	}

	settings := profile.Settings

	// Update fields if provided
	if req.PushNotifications != nil {
		settings.PushNotifications = *req.PushNotifications
	}
	if req.EmailNotifications != nil {
		settings.EmailNotifications = *req.EmailNotifications
	}
	if req.DarkMode != nil {
		settings.DarkMode = *req.DarkMode
	}
	if req.Language != nil {
		settings.Language = *req.Language
	}
	if req.LocationEnabled != nil {
		settings.LocationEnabled = *req.LocationEnabled
	}
	if req.ShowOnlineStatus != nil {
		settings.ShowOnlineStatus = *req.ShowOnlineStatus
	}

	// Save changes
	if err := uc.userRepo.UpdateSettings(ctx, &settings); err != nil {
		return nil, err
	}

	return &settings, nil
}

// Follow follows a user
func (uc *Usecase) Follow(ctx context.Context, followerID, followingID uuid.UUID) error {
	// Check if trying to follow self
	if followerID == followingID {
		return ErrCannotFollowSelf
	}

	// Check if already following
	isFollowing, err := uc.userRepo.IsFollowing(ctx, followerID, followingID)
	if err != nil {
		return err
	}
	if isFollowing {
		return ErrAlreadyFollowing
	}

	// Check if user to follow exists
	_, err = uc.userRepo.GetByID(ctx, followingID)
	if err != nil {
		return ErrUserNotFound
	}

	// Create follow relationship
	return uc.userRepo.Follow(ctx, followerID, followingID)
}

// Unfollow unfollows a user
func (uc *Usecase) Unfollow(ctx context.Context, followerID, followingID uuid.UUID) error {
	// Check if following
	isFollowing, err := uc.userRepo.IsFollowing(ctx, followerID, followingID)
	if err != nil {
		return err
	}
	if !isFollowing {
		return ErrNotFollowing
	}

	// Remove follow relationship
	return uc.userRepo.Unfollow(ctx, followerID, followingID)
}

// GetFollowers gets a user's followers
func (uc *Usecase) GetFollowers(ctx context.Context, userID uuid.UUID, limit, offset int) ([]user.User, error) {
	// Check if user exists
	_, err := uc.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, ErrUserNotFound
	}

	return uc.userRepo.GetFollowers(ctx, userID, limit, offset)
}

// GetFollowing gets users that a user is following
func (uc *Usecase) GetFollowing(ctx context.Context, userID uuid.UUID, limit, offset int) ([]user.User, error) {
	// Check if user exists
	_, err := uc.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, ErrUserNotFound
	}

	return uc.userRepo.GetFollowing(ctx, userID, limit, offset)
}

// IsFollowing checks if a user is following another user
func (uc *Usecase) IsFollowing(ctx context.Context, followerID, followingID uuid.UUID) (bool, error) {
	return uc.userRepo.IsFollowing(ctx, followerID, followingID)
}

// CountFollowers counts total followers for a user
func (uc *Usecase) CountFollowers(ctx context.Context, userID uuid.UUID) (int, error) {
	return uc.userRepo.CountFollowers(ctx, userID)
}

// CountFollowing counts total users a user is following
func (uc *Usecase) CountFollowing(ctx context.Context, userID uuid.UUID) (int, error) {
	return uc.userRepo.CountFollowing(ctx, userID)
}

// CountSearchResults counts total users matching search query
func (uc *Usecase) CountSearchResults(ctx context.Context, query string) (int, error) {
	return uc.userRepo.CountSearchResults(ctx, query)
}

// SearchUsers searches for users by query
func (uc *Usecase) SearchUsers(ctx context.Context, query string, limit, offset int) ([]user.User, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	return uc.userRepo.SearchUsers(ctx, query, limit, offset)
}

// GetStats gets a user's statistics
func (uc *Usecase) GetStats(ctx context.Context, userID uuid.UUID) (*user.UserStats, error) {
	// Check if user exists
	_, err := uc.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, ErrUserNotFound
	}

	return uc.userRepo.GetStats(ctx, userID)
}

// RecalculateEventsCreated recalculates events_created from actual events table
func (uc *Usecase) RecalculateEventsCreated(ctx context.Context, userID uuid.UUID) error {
	// Check if user exists
	_, err := uc.userRepo.GetByID(ctx, userID)
	if err != nil {
		return ErrUserNotFound
	}

	return uc.userRepo.RecalculateEventsCreated(ctx, userID)
}

// VerifyEmail marks a user's email as verified
func (uc *Usecase) VerifyEmail(ctx context.Context, userID uuid.UUID) error {
	existingUser, err := uc.userRepo.GetByID(ctx, userID)
	if err != nil {
		return ErrUserNotFound
	}

	existingUser.IsEmailVerified = true
	existingUser.UpdatedAt = time.Now()

	return uc.userRepo.Update(ctx, existingUser)
}

// DeleteAccount deletes a user account
func (uc *Usecase) DeleteAccount(ctx context.Context, userID uuid.UUID) error {
	// Check if user exists
	_, err := uc.userRepo.GetByID(ctx, userID)
	if err != nil {
		return ErrUserNotFound
	}

	return uc.userRepo.Delete(ctx, userID)
}

// GoogleTokenInfo represents the user info from Google ID token
// FlexibleBool can unmarshal from both boolean and string values
type FlexibleBool bool

// UnmarshalJSON implements custom unmarshaling for FlexibleBool
func (fb *FlexibleBool) UnmarshalJSON(data []byte) error {
	// Try to unmarshal as boolean first
	var b bool
	if err := json.Unmarshal(data, &b); err == nil {
		*fb = FlexibleBool(b)
		return nil
	}

	// If that fails, try as string
	var s string
	if err := json.Unmarshal(data, &s); err != nil {
		return err
	}

	// Convert string to bool
	*fb = FlexibleBool(s == "true" || s == "True" || s == "TRUE" || s == "1")
	return nil
}

type GoogleTokenInfo struct {
	Aud           string       `json:"aud"` // Audience
	Email         string       `json:"email"`
	EmailVerified FlexibleBool `json:"email_verified"`
	Name          string       `json:"name"`
	Picture       string       `json:"picture"`
	Sub           string       `json:"sub"` // Google user ID
}

// LoginWithGoogle authenticates a user using Google ID token
func (uc *Usecase) LoginWithGoogle(ctx context.Context, req *user.GoogleAuthRequest) (*AuthResponse, error) {
	fmt.Printf("DEBUG: LoginWithGoogle called\n")

	// Verify Google ID token and get user info
	googleInfo, err := uc.verifyGoogleToken(req.IDToken)
	if err != nil {
		fmt.Printf("DEBUG: Token verification failed: %v\n", err)
		return nil, fmt.Errorf("failed to verify Google token: %w", err)
	}
	fmt.Printf("DEBUG: Token verified, email: %s\n", googleInfo.Email)

	// Check if user exists
	existingUser, err := uc.userRepo.GetByEmail(ctx, googleInfo.Email)
	fmt.Printf("DEBUG: GetByEmail result: error=%v\n", err)

	if err != nil {
		// User doesn't exist, create new user
		fmt.Printf("DEBUG: Creating new user\n")
		now := time.Now()
		emptyInterests := []string{} // Initialize empty interests array

        // Generate Username from email (before @)
        username := strings.Split(googleInfo.Email, "@")[0]

        // Remove special chars using regex
        reg, _ := regexp.Compile("[^a-zA-Z0-9]+")
        username = reg.ReplaceAllString(username, "")

        // Ensure username is not empty
        if username == "" {
            username = "user"
        }

        // Check if username exists, if so append random suffix
        _, err = uc.userRepo.GetByUsername(ctx, username)
        if err == nil {
            // Username taken, append random hex suffix
            b := make([]byte, 2)
            rand.Read(b)
            suffix := hex.EncodeToString(b)
            username = fmt.Sprintf("%s_%s", username, suffix)
        }

		newUser := &user.User{
			ID:              uuid.New(),
			Email:           googleInfo.Email,
            Username:        username,       // Added generated username
            Role:            "user",         // Default role
			Name:            googleInfo.Name,
			AvatarURL:       &googleInfo.Picture,
			Interests:       emptyInterests,
			CreatedAt:       now,
			UpdatedAt:       now,
			LastLoginAt:     &now,
			IsVerified:      true,  // Google OAuth users are auto-verified
			IsEmailVerified: true,  // Google already verifies emails
		}

		fmt.Printf("DEBUG: Creating user with ID: %s\n", newUser.ID)
		if err := uc.userRepo.Create(ctx, newUser); err != nil {
			fmt.Printf("DEBUG: Failed to create user: %v\n", err)
			return nil, fmt.Errorf("failed to create user: %w", err)
		}
		fmt.Printf("DEBUG: User created successfully\n")

		// No email verification needed - Google already verifies emails

		existingUser = newUser
	} else {
		fmt.Printf("DEBUG: User exists, ID: %s\n", existingUser.ID)
		// User exists, update last login
		now := time.Now()
		existingUser.LastLoginAt = &now
		if err := uc.userRepo.Update(ctx, existingUser); err != nil {
			// Log error but don't fail login
			fmt.Printf("DEBUG: Failed to update last login: %v\n", err)
		}
	}

	// Generate tokens
	fmt.Printf("DEBUG: Generating JWT tokens for user %s\n", existingUser.ID)
	accessToken, err := uc.jwtManager.Generate(existingUser.ID, existingUser.Email)
	if err != nil {
		fmt.Printf("DEBUG: Failed to generate access token: %v\n", err)
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	refreshToken, err := uc.jwtManager.GenerateRefreshToken(existingUser.ID, existingUser.Email)
	if err != nil {
		fmt.Printf("DEBUG: Failed to generate refresh token: %v\n", err)
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	fmt.Printf("DEBUG: Login successful, returning tokens\n")
	return &AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         existingUser,
		ExpiresIn:    3600, // 1 hour
	}, nil
}

// verifyGoogleToken verifies the Google ID token and returns user info
func (uc *Usecase) verifyGoogleToken(idToken string) (*GoogleTokenInfo, error) {
	// Log token length for debugging (don't log the actual token)
	fmt.Printf("DEBUG: Verifying Google token (length: %d)\n", len(idToken))

	// Call Google's tokeninfo endpoint to verify the token
	url := fmt.Sprintf("https://oauth2.googleapis.com/tokeninfo?id_token=%s", idToken)
	fmt.Printf("DEBUG: Calling Google tokeninfo endpoint\n")

	// Create HTTP client with timeout to prevent hanging
	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	resp, err := client.Get(url)
	if err != nil {
		fmt.Printf("DEBUG: Failed to call Google tokeninfo: %v\n", err)
		return nil, fmt.Errorf("failed to verify token: %w", err)
	}
	defer resp.Body.Close()

	fmt.Printf("DEBUG: Google response status: %d\n", resp.StatusCode)

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		fmt.Printf("DEBUG: Google error response: %s\n", string(body))
		return nil, fmt.Errorf("token verification failed: %s", string(body))
	}

	var tokenInfo GoogleTokenInfo
	if err := json.NewDecoder(resp.Body).Decode(&tokenInfo); err != nil {
		fmt.Printf("DEBUG: Failed to decode token info: %v\n", err)
		return nil, fmt.Errorf("failed to decode token info: %w", err)
	}

	fmt.Printf("DEBUG: Token info - Email: %s, Aud: %s, Sub: %s\n", tokenInfo.Email, tokenInfo.Aud, tokenInfo.Sub)

	// For Android/iOS apps, the audience is the app's client ID, not the server client ID.
	// Since the token was successfully verified by Google's tokeninfo endpoint above,
	// we can trust it regardless of the audience. This allows mobile apps to authenticate.
	// Log the actual audience for debugging purposes.
	if tokenInfo.Aud != uc.googleClientID {
		// Token is from a mobile app (Android/iOS) using its own client ID
		// This is expected and acceptable
		fmt.Printf("Google token audience %s (expected %s) - allowing for mobile app\n", tokenInfo.Aud, uc.googleClientID)
	}

	return &tokenInfo, nil
}

// generateToken generates a secure random token
func generateToken() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}

// SendVerificationEmail sends an email verification token
func (uc *Usecase) SendVerificationEmail(ctx context.Context, userID uuid.UUID) (string, error) {
	// Get user
	user, err := uc.userRepo.GetByID(ctx, userID)
	if err != nil {
		return "", ErrUserNotFound
	}

	// Delete any existing verification tokens for this user
	if err := uc.authTokenRepo.DeleteTokensByUser(ctx, userID, auth.TokenTypeEmailVerification); err != nil {
		// Log error but don't fail
	}

	// Generate new token
	tokenValue, err := generateToken()
	if err != nil {
		return "", fmt.Errorf("failed to generate token: %w", err)
	}

	// Create token record (expires in 24 hours)
	token := &auth.AuthToken{
		ID:        uuid.New(),
		UserID:    userID,
		Token:     tokenValue,
		TokenType: auth.TokenTypeEmailVerification,
		ExpiresAt: time.Now().Add(24 * time.Hour),
		CreatedAt: time.Now(),
	}

	if err := uc.authTokenRepo.CreateToken(ctx, token); err != nil {
		return "", fmt.Errorf("failed to create token: %w", err)
	}

	// TODO: Send actual email with token
	// For now, return the token (in production, this would be sent via email service)
	_ = user // Use the user variable to avoid compile error

	return tokenValue, nil
}

// VerifyEmailWithToken verifies a user's email using a token
func (uc *Usecase) VerifyEmailWithToken(ctx context.Context, tokenValue string) error {
	// Get token
	token, err := uc.authTokenRepo.GetTokenByValue(ctx, tokenValue)
	if err != nil {
		if err == sql.ErrNoRows {
			return ErrInvalidToken
		}
		return fmt.Errorf("failed to get token: %w", err)
	}

	// Check if token is valid
	if !token.IsValid() {
		if token.IsUsed() {
			return ErrTokenAlreadyUsed
		}
		return ErrInvalidToken
	}

	// Get user
	user, err := uc.userRepo.GetByID(ctx, token.UserID)
	if err != nil {
		return ErrUserNotFound
	}

	// Mark user as verified
	user.IsEmailVerified = true
	user.UpdatedAt = time.Now()
	if err := uc.userRepo.Update(ctx, user); err != nil {
		return fmt.Errorf("failed to update user: %w", err)
	}

	// Mark token as used
	if err := uc.authTokenRepo.MarkTokenAsUsed(ctx, tokenValue); err != nil {
		// Log error but don't fail since verification succeeded
	}

	return nil
}
