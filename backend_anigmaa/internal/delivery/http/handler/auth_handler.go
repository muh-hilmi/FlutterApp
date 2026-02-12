package handler

import (
	"net/http"

	"github.com/anigmaa/backend/internal/delivery/http/middleware"
	"github.com/anigmaa/backend/internal/domain/user"
	userUsecase "github.com/anigmaa/backend/internal/usecase/user"
	"github.com/anigmaa/backend/pkg/response"
	"github.com/anigmaa/backend/pkg/validator"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AuthHandler handles authentication-related HTTP requests
type AuthHandler struct {
	userUsecase *userUsecase.Usecase
	validator   *validator.Validator
}

// NewAuthHandler creates a new authentication handler
func NewAuthHandler(userUsecase *userUsecase.Usecase, validator *validator.Validator) *AuthHandler {
	return &AuthHandler{
		userUsecase: userUsecase,
		validator:   validator,
	}
}

// Logout godoc
// @Summary Logout user
// @Description Logout the current user (invalidate token)
// @Tags auth
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} response.Response
// @Failure 401 {object} response.Response
// @Router /auth/logout [post]
func (h *AuthHandler) Logout(c *gin.Context) {
	// In a stateless JWT system, logout is typically handled on the client side
	// The client should remove the token from storage
	// For server-side logout, you would need to implement token blacklisting
	// using Redis or similar storage

	response.Success(c, http.StatusOK, "Logout successful", nil)
}

// RefreshToken godoc
// @Summary Refresh access token
// @Description Get a new access token using a refresh token
// @Tags auth
// @Accept json
// @Produce json
// @Param request body map[string]string true "Refresh token"
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /auth/refresh [post]
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
	}

	// Parse request body
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request body", err.Error())
		return
	}

	// Call usecase
	authResp, err := h.userUsecase.RefreshToken(c.Request.Context(), req.RefreshToken)
	if err != nil {
		if err == userUsecase.ErrUnauthorized {
			response.Unauthorized(c, "Invalid or expired refresh token")
			return
		}
		response.InternalError(c, "Failed to refresh token", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Token refreshed successfully", authResp)
}

// VerifyEmail godoc
// @Summary Verify email
// @Description Verify user email using verification token
// @Tags auth
// @Accept json
// @Produce json
// @Param request body map[string]string true "Verification token"
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /auth/verify-email [post]
func (h *AuthHandler) VerifyEmail(c *gin.Context) {
	var req struct {
		Token string `json:"token" binding:"required"`
	}

	// Parse request body
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request body", err.Error())
		return
	}

	// Call usecase to verify email with token
	if err := h.userUsecase.VerifyEmailWithToken(c.Request.Context(), req.Token); err != nil {
		if err == userUsecase.ErrInvalidToken {
			response.Unauthorized(c, "Invalid or expired verification token")
			return
		}
		if err == userUsecase.ErrTokenAlreadyUsed {
			response.BadRequest(c, "Verification token has already been used", err.Error())
			return
		}
		if err == userUsecase.ErrUserNotFound {
			response.NotFound(c, "User not found")
			return
		}
		response.InternalError(c, "Failed to verify email", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Email verified successfully", nil)
}

// ResendVerificationEmail godoc
// @Summary Resend verification email
// @Description Resend email verification token to the current user
// @Tags auth
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /auth/resend-verification [post]
func (h *AuthHandler) ResendVerificationEmail(c *gin.Context) {
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

	// Call usecase to generate and send verification token
	token, err := h.userUsecase.SendVerificationEmail(c.Request.Context(), userID)
	if err != nil {
		if err == userUsecase.ErrUserNotFound {
			response.NotFound(c, "User not found")
			return
		}
		response.InternalError(c, "Failed to send verification email", err.Error())
		return
	}

	// In production, the token would be sent via email
	// For development/testing, return the token in the response
	response.Success(c, http.StatusOK, "Verification email sent", gin.H{
		"token": token, // Remove this in production
	})
}

// GetMe godoc
// @Summary Get current user
// @Description Get the profile of the currently authenticated user
// @Tags auth
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} response.Response{data=user.UserProfile}
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /auth/me [get]
func (h *AuthHandler) GetMe(c *gin.Context) {
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

// LoginWithGoogle godoc
// @Summary Login with Google
// @Description Authenticate user with Google ID token
// @Tags auth
// @Accept json
// @Produce json
// @Param request body user.GoogleAuthRequest true "Google ID token"
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /auth/google [post]
func (h *AuthHandler) LoginWithGoogle(c *gin.Context) {
	var req user.GoogleAuthRequest

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
	authResp, err := h.userUsecase.LoginWithGoogle(c.Request.Context(), &req)
	if err != nil {
		response.Error(c, http.StatusUnauthorized, err.Error(), "UNAUTHORIZED", "")
		return
	}

	response.Success(c, http.StatusOK, "Login successful", authResp)
}
