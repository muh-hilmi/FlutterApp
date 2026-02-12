package handler

import (
	"net/http"
	"strconv"

	"github.com/anigmaa/backend/internal/delivery/http/middleware"
	"github.com/anigmaa/backend/internal/domain/user"
	userUsecase "github.com/anigmaa/backend/internal/usecase/user"
	"github.com/anigmaa/backend/pkg/response"
	"github.com/anigmaa/backend/pkg/validator"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// UserHandler handles user-related HTTP requests
type UserHandler struct {
	userUsecase *userUsecase.Usecase
	validator   *validator.Validator
}

// NewUserHandler creates a new user handler
func NewUserHandler(userUsecase *userUsecase.Usecase, validator *validator.Validator) *UserHandler {
	return &UserHandler{
		userUsecase: userUsecase,
		validator:   validator,
	}
}

// GetMe godoc
// @Summary Get current user profile
// @Description Get the complete profile of the currently authenticated user
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} response.Response{data=user.UserProfile}
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /users/me [get]
func (h *UserHandler) GetMe(c *gin.Context) {
	// Get user ID from context
	userIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Call usecase
	profile, err := h.userUsecase.GetProfile(c.Request.Context(), userID)
	if err != nil {
		if err == userUsecase.ErrUserNotFound {
			response.NotFound(c, "User not found")
			return
		}
		response.InternalError(c, "Failed to get user profile", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Profile retrieved successfully", profile)
}

// UpdateMe godoc
// @Summary Update current user profile
// @Description Update the profile of the currently authenticated user
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body user.UpdateProfileRequest true "Profile update data"
// @Success 200 {object} response.Response{data=user.User}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /users/me [put]
func (h *UserHandler) UpdateMe(c *gin.Context) {
	// Get user ID from context
	userIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	var req user.UpdateProfileRequest

	// Parse request body
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := h.validator.Validate(&req); err != nil {
		response.BadRequest(c, "Validation failed", err.Error())
		return
	}

	// Call usecase
	updatedUser, err := h.userUsecase.UpdateProfile(c.Request.Context(), userID, &req)
	if err != nil {
		if err == userUsecase.ErrUserNotFound {
			response.NotFound(c, "User not found")
			return
		}
		response.InternalError(c, "Failed to update profile", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Profile updated successfully", updatedUser)
}

// GetUserByID godoc
// @Summary Get user by ID
// @Description Get a user's profile by their ID
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "User ID" format(uuid)
// @Success 200 {object} response.Response{data=user.UserProfile}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /users/{id} [get]
func (h *UserHandler) GetUserByID(c *gin.Context) {
	// Parse user ID from path
	userIDStr := c.Param("id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Call usecase
	profile, err := h.userUsecase.GetProfile(c.Request.Context(), userID)
	if err != nil {
		if err == userUsecase.ErrUserNotFound {
			response.NotFound(c, "User not found")
			return
		}
		response.InternalError(c, "Failed to get user profile", err.Error())
		return
	}

	// Get current user ID from context (if authenticated)
	currentUserIDStr, exists := middleware.GetUserID(c)
	println("[DEBUG] GetUserByID - currentUserIDStr:", currentUserIDStr, "exists:", exists)
	if exists {
		currentUserID, err := uuid.Parse(currentUserIDStr)
		println("[DEBUG] GetUserByID - currentUserID:", currentUserID.String(), "targetUserID:", userID.String(), "parseErr:", err)
		if err == nil && currentUserID != userID {
			// Check if current user is following this user
			isFollowing, err := h.userUsecase.IsFollowing(c.Request.Context(), currentUserID, userID)
			println("[DEBUG] GetUserByID - isFollowing:", isFollowing, "err:", err)
			if err == nil {
				profile.IsFollowing = &isFollowing
				println("[DEBUG] GetUserByID - profile.IsFollowing set to:", *profile.IsFollowing)
			}
		} else if currentUserID == userID {
			println("[DEBUG] GetUserByID - viewing own profile, leaving IsFollowing as nil")
		}
		// If viewing own profile or error checking, leave IsFollowing as nil
	} else {
		println("[DEBUG] GetUserByID - no current user in context")
	}

	response.Success(c, http.StatusOK, "User profile retrieved successfully", profile)
}

// GetFollowers godoc
// @Summary Get user's followers
// @Description Get a list of users following the specified user
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "User ID" format(uuid)
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]user.User}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /users/{id}/followers [get]
func (h *UserHandler) GetFollowers(c *gin.Context) {
	// Parse user ID from path
	userIDStr := c.Param("id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Parse query parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Get total count for pagination
	total, err := h.userUsecase.CountFollowers(c.Request.Context(), userID)
	if err != nil {
		// If count fails, default to 0 but continue
		total = 0
	}

	// Get followers
	followers, err := h.userUsecase.GetFollowers(c.Request.Context(), userID, limit, offset)
	if err != nil {
		if err == userUsecase.ErrUserNotFound {
			response.NotFound(c, "User not found")
			return
		}
		response.InternalError(c, "Failed to get followers", err.Error())
		return
	}

	// Ensure we return empty array instead of null when no followers
	if followers == nil {
		followers = []user.User{}
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, limit, offset, len(followers))
	response.Paginated(c, http.StatusOK, "Followers retrieved successfully", followers, meta)
}

// GetFollowing godoc
// @Summary Get users being followed
// @Description Get a list of users that the specified user is following
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "User ID" format(uuid)
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]user.User}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /users/{id}/following [get]
func (h *UserHandler) GetFollowing(c *gin.Context) {
	// Parse user ID from path
	userIDStr := c.Param("id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Parse query parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Get total count for pagination
	total, err := h.userUsecase.CountFollowing(c.Request.Context(), userID)
	if err != nil {
		// If count fails, default to 0 but continue
		total = 0
	}

	// Get following
	following, err := h.userUsecase.GetFollowing(c.Request.Context(), userID, limit, offset)
	if err != nil {
		if err == userUsecase.ErrUserNotFound {
			response.NotFound(c, "User not found")
			return
		}
		response.InternalError(c, "Failed to get following", err.Error())
		return
	}

	// Ensure we return empty array instead of null when not following anyone
	if following == nil {
		following = []user.User{}
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, limit, offset, len(following))
	response.Paginated(c, http.StatusOK, "Following retrieved successfully", following, meta)
}

// FollowUser godoc
// @Summary Follow a user
// @Description Follow another user
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "User ID to follow" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 409 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /users/{id}/follow [post]
func (h *UserHandler) FollowUser(c *gin.Context) {
	// Get current user ID from context
	followerIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	followerID, err := uuid.Parse(followerIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Parse user ID to follow from path
	followingIDStr := c.Param("id")
	followingID, err := uuid.Parse(followingIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Call usecase
	if err := h.userUsecase.Follow(c.Request.Context(), followerID, followingID); err != nil {
		if err == userUsecase.ErrCannotFollowSelf {
			response.BadRequest(c, "Cannot follow yourself", err.Error())
			return
		}
		if err == userUsecase.ErrAlreadyFollowing {
			response.Conflict(c, "Already following this user", err.Error())
			return
		}
		if err == userUsecase.ErrUserNotFound {
			response.NotFound(c, "User not found")
			return
		}
		response.InternalError(c, "Failed to follow user", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "User followed successfully", nil)
}

// UnfollowUser godoc
// @Summary Unfollow a user
// @Description Unfollow a user you are currently following
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "User ID to unfollow" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /users/{id}/unfollow [post]
func (h *UserHandler) UnfollowUser(c *gin.Context) {
	// Get current user ID from context
	followerIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	followerID, err := uuid.Parse(followerIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Parse user ID to unfollow from path
	followingIDStr := c.Param("id")
	followingID, err := uuid.Parse(followingIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Call usecase
	if err := h.userUsecase.Unfollow(c.Request.Context(), followerID, followingID); err != nil {
		if err == userUsecase.ErrNotFollowing {
			response.BadRequest(c, "Not following this user", err.Error())
			return
		}
		response.InternalError(c, "Failed to unfollow user", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "User unfollowed successfully", nil)
}

// GetUserStats godoc
// @Summary Get user statistics
// @Description Get statistics for a user (events attended, followers, etc.)
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "User ID" format(uuid)
// @Success 200 {object} response.Response{data=user.UserStats}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /users/{id}/stats [get]
func (h *UserHandler) GetUserStats(c *gin.Context) {
	// Parse user ID from path
	userIDStr := c.Param("id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Call usecase
	stats, err := h.userUsecase.GetStats(c.Request.Context(), userID)
	if err != nil {
		if err == userUsecase.ErrUserNotFound {
			response.NotFound(c, "User not found")
			return
		}
		response.InternalError(c, "Failed to get user stats", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "User statistics retrieved successfully", stats)
}

// UpdateSettings godoc
// @Summary Update user settings
// @Description Update settings for the current user
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body user.UpdateSettingsRequest true "Settings update data"
// @Success 200 {object} response.Response{data=user.UserSettings}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /users/me/settings [put]
func (h *UserHandler) UpdateSettings(c *gin.Context) {
	// Get user ID from context
	userIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	var req user.UpdateSettingsRequest

	// Parse request body
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := h.validator.Validate(&req); err != nil {
		response.BadRequest(c, "Validation failed", err.Error())
		return
	}

	// Call usecase
	settings, err := h.userUsecase.UpdateSettings(c.Request.Context(), userID, &req)
	if err != nil {
		if err == userUsecase.ErrUserNotFound {
			response.NotFound(c, "User not found")
			return
		}
		response.InternalError(c, "Failed to update settings", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Settings updated successfully", settings)
}

// SearchUsers godoc
// @Summary Search users
// @Description Search for users by name or username
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param q query string true "Search query" minlength(2)
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]user.User}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /users/search [get]
func (h *UserHandler) SearchUsers(c *gin.Context) {
	// Get search query from query params
	query := c.Query("q")
	if query == "" || len(query) < 2 {
		response.BadRequest(c, "Search query must be at least 2 characters", "")
		return
	}

	// Parse query parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Get total count for pagination
	total, err := h.userUsecase.CountSearchResults(c.Request.Context(), query)
	if err != nil {
		// If count fails, default to 0 but continue
		total = 0
	}

	// Search users
	users, err := h.userUsecase.SearchUsers(c.Request.Context(), query, limit, offset)
	if err != nil {
		response.InternalError(c, "Failed to search users", err.Error())
		return
	}

	// Ensure we return empty array instead of null
	if users == nil {
		users = []user.User{}
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, limit, offset, len(users))
	response.Paginated(c, http.StatusOK, "Users found successfully", users, meta)
}

// DeleteAccount godoc
// @Summary Delete current user account
// @Description Permanently delete the currently authenticated user's account
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /users/me [delete]
func (h *UserHandler) DeleteAccount(c *gin.Context) {
	// Get user ID from context
	userIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	// Call usecase to delete account
	if err := h.userUsecase.DeleteAccount(c.Request.Context(), userID); err != nil {
		if err == userUsecase.ErrUserNotFound {
			response.NotFound(c, "User not found")
			return
		}
		response.InternalError(c, "Failed to delete account", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Account deleted successfully", nil)
}
