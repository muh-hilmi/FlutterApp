package handler

import (
	"net/http"
	"strconv"

	"github.com/anigmaa/backend/internal/delivery/http/middleware"
	"github.com/anigmaa/backend/internal/domain/post"
	eventUsecase "github.com/anigmaa/backend/internal/usecase/event"
	postUsecase "github.com/anigmaa/backend/internal/usecase/post"
	userUsecase "github.com/anigmaa/backend/internal/usecase/user"
	"github.com/anigmaa/backend/pkg/response"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ProfileHandler handles profile-related HTTP requests
type ProfileHandler struct {
	userUsecase  *userUsecase.Usecase
	postUsecase  *postUsecase.Usecase
	eventUsecase *eventUsecase.Usecase
}

// NewProfileHandler creates a new profile handler
func NewProfileHandler(
	userUsecase *userUsecase.Usecase,
	postUsecase *postUsecase.Usecase,
	eventUsecase *eventUsecase.Usecase,
) *ProfileHandler {
	return &ProfileHandler{
		userUsecase:  userUsecase,
		postUsecase:  postUsecase,
		eventUsecase: eventUsecase,
	}
}

// GetProfileByUsername godoc
// @Summary Get user profile by username
// @Description Get complete profile data for a user by their username
// @Tags profile
// @Accept json
// @Produce json
// @Param username path string true "Username"
// @Success 200 {object} response.Response{data=user.ProfileResponse}
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /profile/{username} [get]
func (h *ProfileHandler) GetProfileByUsername(c *gin.Context) {
	username := c.Param("username")

	// Get profile by username
	profile, err := h.userUsecase.GetProfileByUsername(c.Request.Context(), username)
	if err != nil {
		if err == userUsecase.ErrUserNotFound {
			response.NotFound(c, "User not found")
			return
		}
		response.InternalError(c, "Failed to get user profile", err.Error())
		return
	}

	// Convert to ProfileResponse with share link
	baseURL := "https://app.anigmaa.com"
	if c.GetHeader("X-Base-URL") != "" {
		baseURL = c.GetHeader("X-Base-URL")
	}
	profileResponse := profile.ToProfileResponse(baseURL)

	response.Success(c, http.StatusOK, "Profile retrieved successfully", profileResponse)
}

// GetProfilePosts godoc
// @Summary Get user posts by username
// @Description Get all posts created by a user
// @Tags profile
// @Accept json
// @Produce json
// @Param username path string true "Username"
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]post.PostResponse}
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /profile/{username}/posts [get]
func (h *ProfileHandler) GetProfilePosts(c *gin.Context) {
	username := c.Param("username")

	// Parse query parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Get user by username
	user, err := h.userUsecase.GetByUsername(c.Request.Context(), username)
	if err != nil {
		if err == userUsecase.ErrUserNotFound {
			response.NotFound(c, "User not found")
			return
		}
		response.InternalError(c, "Failed to get user", err.Error())
		return
	}

	// Get viewer ID (current user) for interaction flags
	viewerID := uuid.Nil
	if viewerIDStr, exists := middleware.GetUserID(c); exists {
		viewerID, _ = uuid.Parse(viewerIDStr)
	}

	// Get total count for pagination
	total, err := h.postUsecase.CountUserPosts(c.Request.Context(), user.ID)
	if err != nil {
		// If count fails, default to 0 but continue
		total = 0
	}

	// Get user posts
	posts, err := h.postUsecase.GetUserPosts(c.Request.Context(), user.ID, viewerID, limit, offset)
	if err != nil {
		response.InternalError(c, "Failed to get user posts", err.Error())
		return
	}

	// Ensure posts is not nil (return empty array instead)
	if posts == nil {
		posts = []post.PostWithDetails{}
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, limit, offset, len(posts))
	response.Paginated(c, http.StatusOK, "Posts retrieved successfully", posts, meta)
}

// GetProfileEvents godoc
// @Summary Get user events by username
// @Description Get all events created by a user
// @Tags profile
// @Accept json
// @Produce json
// @Param username path string true "Username"
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]event.EventWithDetails}
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /profile/{username}/events [get]
func (h *ProfileHandler) GetProfileEvents(c *gin.Context) {
	username := c.Param("username")

	// Parse query parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Get user by username
	user, err := h.userUsecase.GetByUsername(c.Request.Context(), username)
	if err != nil {
		if err == userUsecase.ErrUserNotFound {
			response.NotFound(c, "User not found")
			return
		}
		response.InternalError(c, "Failed to get user", err.Error())
		return
	}

	// Get total count for pagination
	total, err := h.eventUsecase.CountHostedEvents(c.Request.Context(), user.ID)
	if err != nil {
		// If count fails, default to 0 but continue
		total = 0
	}

	// Get events
	events, err := h.eventUsecase.GetByHost(c.Request.Context(), user.ID, limit, offset)
	if err != nil {
		response.InternalError(c, "Failed to get user events", err.Error())
		return
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, limit, offset, len(events))
	response.Paginated(c, http.StatusOK, "Events retrieved successfully", events, meta)
}
