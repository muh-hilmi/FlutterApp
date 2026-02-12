package middleware

import (
	"strings"

	"github.com/anigmaa/backend/internal/domain/user"
	"github.com/anigmaa/backend/pkg/jwt"
	"github.com/anigmaa/backend/pkg/response"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// JWTAuth middleware validates JWT token
func JWTAuth(jwtManager *jwt.JWTManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			response.Unauthorized(c, "Authorization header required")
			c.Abort()
			return
		}

		// Check if it starts with "Bearer "
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			response.Unauthorized(c, "Invalid authorization header format")
			c.Abort()
			return
		}

		// Validate token
		tokenString := parts[1]
		claims, err := jwtManager.Verify(tokenString)
		if err != nil {
			response.Unauthorized(c, "Invalid or expired token")
			c.Abort()
			return
		}

		// Set user ID in context (convert UUID to string)
		c.Set("user_id", claims.UserID.String())
		c.Set("email", claims.Email)

		c.Next()
	}
}

// GetUserID gets the user ID from context
func GetUserID(c *gin.Context) (string, bool) {
	userID, exists := c.Get("user_id")
	if !exists {
		return "", false
	}
	return userID.(string), true
}

// GetEmail gets the email from context
func GetEmail(c *gin.Context) (string, bool) {
	email, exists := c.Get("email")
	if !exists {
		return "", false
	}
	return email.(string), true
}

// RequireEmailVerification middleware checks if user's email is verified
// This should be used AFTER JWTAuth middleware
func RequireEmailVerification(userRepo user.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from context (set by JWTAuth middleware)
		userIDStr, exists := GetUserID(c)
		if !exists {
			response.Unauthorized(c, "User not authenticated")
			c.Abort()
			return
		}

		// Parse user ID
		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			response.BadRequest(c, "Invalid user ID", err.Error())
			c.Abort()
			return
		}

		// Get user from database
		currentUser, err := userRepo.GetByID(c.Request.Context(), userID)
		if err != nil {
			response.Unauthorized(c, "User not found")
			c.Abort()
			return
		}

		// Check if email is verified
		if !currentUser.IsEmailVerified {
			response.Error(c, 403, "Email verification required. Please verify your email to access this feature.", "EMAIL_VERIFICATION_REQUIRED", "")
			c.Abort()
			return
		}

		c.Next()
	}
}
