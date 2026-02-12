package handler

import (
	"net/http"
	"strconv"

	"github.com/anigmaa/backend/internal/delivery/http/middleware"
	"github.com/anigmaa/backend/internal/domain/community"
	communityUsecase "github.com/anigmaa/backend/internal/usecase/community"
	"github.com/anigmaa/backend/pkg/response"
	"github.com/anigmaa/backend/pkg/validator"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// CommunityHandler handles community-related HTTP requests
type CommunityHandler struct {
	communityUsecase *communityUsecase.Usecase
	validator        *validator.Validator
}

// NewCommunityHandler creates a new community handler
func NewCommunityHandler(communityUsecase *communityUsecase.Usecase, validator *validator.Validator) *CommunityHandler {
	return &CommunityHandler{
		communityUsecase: communityUsecase,
		validator:        validator,
	}
}

// GetCommunities godoc
// @Summary Get all communities
// @Description Get list of communities with optional filtering
// @Tags communities
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param search query string false "Search query"
// @Param privacy query string false "Privacy filter" Enums(public, private, secret)
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]community.CommunityWithDetails}
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /communities [get]
func (h *CommunityHandler) GetCommunities(c *gin.Context) {
	// Parse query parameters
	search := c.Query("search")
	privacy := c.Query("privacy")
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	filter := &community.CommunityFilter{
		Limit:  limit,
		Offset: offset,
	}

	if search != "" {
		filter.Search = &search
	}
	if privacy != "" {
		p := community.Privacy(privacy)
		filter.Privacy = &p
	}

	// Get total count for pagination
	total, err := h.communityUsecase.CountCommunities(c.Request.Context(), filter)
	if err != nil {
		// If count fails, default to 0 but continue
		total = 0
	}

	// Call usecase
	communities, err := h.communityUsecase.GetAllCommunities(c.Request.Context(), filter)
	if err != nil {
		response.InternalError(c, "Failed to get communities", err.Error())
		return
	}

	// Ensure we return empty array instead of null
	if communities == nil {
		communities = []community.CommunityWithDetails{}
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, limit, offset, len(communities))
	response.Paginated(c, http.StatusOK, "Communities retrieved successfully", communities, meta)
}

// GetCommunityByID godoc
// @Summary Get community by ID
// @Description Get detailed information about a specific community
// @Tags communities
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Community ID" format(uuid)
// @Success 200 {object} response.Response{data=community.CommunityWithDetails}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /communities/{id} [get]
func (h *CommunityHandler) GetCommunityByID(c *gin.Context) {
	// Parse community ID from path
	communityIDStr := c.Param("id")
	communityID, err := uuid.Parse(communityIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid community ID", err.Error())
		return
	}

	// Get user ID from context
	userIDStr, _ := middleware.GetUserID(c)
	userID, _ := uuid.Parse(userIDStr)

	// Call usecase
	comm, err := h.communityUsecase.GetCommunityByID(c.Request.Context(), communityID, userID)
	if err != nil {
		if err == communityUsecase.ErrCommunityNotFound {
			response.NotFound(c, "Community not found")
			return
		}
		response.InternalError(c, "Failed to get community", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Community retrieved successfully", comm)
}

// CreateCommunity godoc
// @Summary Create a new community
// @Description Create a new community/group
// @Tags communities
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body community.CreateCommunityRequest true "Community creation data"
// @Success 201 {object} response.Response{data=community.Community}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /communities [post]
func (h *CommunityHandler) CreateCommunity(c *gin.Context) {
	// Get user ID from context
	creatorIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	creatorID, err := uuid.Parse(creatorIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	var req community.CreateCommunityRequest

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
	newCommunity, err := h.communityUsecase.CreateCommunity(c.Request.Context(), creatorID, &req)
	if err != nil {
		response.InternalError(c, "Failed to create community", err.Error())
		return
	}

	response.Success(c, http.StatusCreated, "Community created successfully", newCommunity)
}

// UpdateCommunity godoc
// @Summary Update community
// @Description Update an existing community (owner only)
// @Tags communities
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Community ID" format(uuid)
// @Param request body community.UpdateCommunityRequest true "Community update data"
// @Success 200 {object} response.Response{data=community.Community}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /communities/{id} [put]
func (h *CommunityHandler) UpdateCommunity(c *gin.Context) {
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

	// Parse community ID from path
	communityIDStr := c.Param("id")
	communityID, err := uuid.Parse(communityIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid community ID", err.Error())
		return
	}

	var req community.UpdateCommunityRequest

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
	updatedCommunity, err := h.communityUsecase.UpdateCommunity(c.Request.Context(), communityID, userID, &req)
	if err != nil {
		if err == communityUsecase.ErrCommunityNotFound {
			response.NotFound(c, "Community not found")
			return
		}
		if err == communityUsecase.ErrUnauthorized {
			response.Forbidden(c, "Only the community owner can update this community")
			return
		}
		response.InternalError(c, "Failed to update community", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Community updated successfully", updatedCommunity)
}

// DeleteCommunity godoc
// @Summary Delete community
// @Description Delete a community (owner only)
// @Tags communities
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Community ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /communities/{id} [delete]
func (h *CommunityHandler) DeleteCommunity(c *gin.Context) {
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

	// Parse community ID from path
	communityIDStr := c.Param("id")
	communityID, err := uuid.Parse(communityIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid community ID", err.Error())
		return
	}

	// Call usecase
	if err := h.communityUsecase.DeleteCommunity(c.Request.Context(), communityID, userID); err != nil {
		if err == communityUsecase.ErrCommunityNotFound {
			response.NotFound(c, "Community not found")
			return
		}
		if err == communityUsecase.ErrUnauthorized {
			response.Forbidden(c, "Only the community owner can delete this community")
			return
		}
		response.InternalError(c, "Failed to delete community", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Community deleted successfully", nil)
}

// JoinCommunity godoc
// @Summary Join a community
// @Description Join a community
// @Tags communities
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Community ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 409 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /communities/{id}/join [post]
func (h *CommunityHandler) JoinCommunity(c *gin.Context) {
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

	// Parse community ID from path
	communityIDStr := c.Param("id")
	communityID, err := uuid.Parse(communityIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid community ID", err.Error())
		return
	}

	// Call usecase
	if err := h.communityUsecase.JoinCommunity(c.Request.Context(), communityID, userID); err != nil {
		if err == communityUsecase.ErrCommunityNotFound {
			response.NotFound(c, "Community not found")
			return
		}
		if err == communityUsecase.ErrAlreadyMember {
			response.Conflict(c, "Already a member of this community", err.Error())
			return
		}
		response.InternalError(c, "Failed to join community", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Joined community successfully", nil)
}

// LeaveCommunity godoc
// @Summary Leave a community
// @Description Leave a community
// @Tags communities
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Community ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /communities/{id}/leave [delete]
func (h *CommunityHandler) LeaveCommunity(c *gin.Context) {
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

	// Parse community ID from path
	communityIDStr := c.Param("id")
	communityID, err := uuid.Parse(communityIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid community ID", err.Error())
		return
	}

	// Call usecase
	if err := h.communityUsecase.LeaveCommunity(c.Request.Context(), communityID, userID); err != nil {
		if err == communityUsecase.ErrCommunityNotFound {
			response.NotFound(c, "Community not found")
			return
		}
		if err == communityUsecase.ErrNotMember {
			response.BadRequest(c, "Not a member of this community", err.Error())
			return
		}
		response.InternalError(c, "Failed to leave community", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Left community successfully", nil)
}

// GetCommunityMembers godoc
// @Summary Get community members
// @Description Get list of members in a community
// @Tags communities
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Community ID" format(uuid)
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]community.CommunityMember}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /communities/{id}/members [get]
func (h *CommunityHandler) GetCommunityMembers(c *gin.Context) {
	// Parse community ID from path
	communityIDStr := c.Param("id")
	communityID, err := uuid.Parse(communityIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid community ID", err.Error())
		return
	}

	// Parse query parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Get total count for pagination
	total, err := h.communityUsecase.CountCommunityMembers(c.Request.Context(), communityID)
	if err != nil {
		// If count fails, default to 0 but continue
		total = 0
	}

	// Get members
	members, err := h.communityUsecase.GetCommunityMembers(c.Request.Context(), communityID, limit, offset)
	if err != nil {
		response.InternalError(c, "Failed to get community members", err.Error())
		return
	}

	// Ensure we return empty array instead of null
	if members == nil {
		members = []community.CommunityMember{}
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, limit, offset, len(members))
	response.Paginated(c, http.StatusOK, "Community members retrieved successfully", members, meta)
}

// GetUserCommunities godoc
// @Summary Get user's communities
// @Description Get list of communities the user has joined
// @Tags communities
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]community.CommunityWithDetails}
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /communities/my-communities [get]
func (h *CommunityHandler) GetUserCommunities(c *gin.Context) {
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

	// Parse query parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Get total count for pagination
	total, err := h.communityUsecase.CountUserCommunities(c.Request.Context(), userID)
	if err != nil {
		// If count fails, default to 0 but continue
		total = 0
	}

	// Get communities
	communities, err := h.communityUsecase.GetUserCommunities(c.Request.Context(), userID, limit, offset)
	if err != nil {
		response.InternalError(c, "Failed to get user communities", err.Error())
		return
	}

	// Ensure we return empty array instead of null
	if communities == nil {
		communities = []community.CommunityWithDetails{}
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, limit, offset, len(communities))
	response.Paginated(c, http.StatusOK, "User communities retrieved successfully", communities, meta)
}
