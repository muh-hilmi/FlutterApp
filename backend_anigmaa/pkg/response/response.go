package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Response represents a standard API response
type Response struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Error   *ErrorInfo  `json:"error,omitempty"`
}

// ErrorInfo contains error details
type ErrorInfo struct {
	Code    string `json:"code"`
	Details string `json:"details,omitempty"`
}

// PaginationMeta contains pagination metadata
type PaginationMeta struct {
	Total   int  `json:"total"`
	Limit   int  `json:"limit"`
	Offset  int  `json:"offset"`
	HasNext bool `json:"hasNext"`
}

// PaginatedResponse represents a paginated API response
type PaginatedResponse struct {
	Success bool            `json:"success"`
	Message string          `json:"message,omitempty"`
	Data    interface{}     `json:"data"`
	Meta    *PaginationMeta `json:"meta"`
}

// Success sends a successful response
func Success(c *gin.Context, statusCode int, message string, data interface{}) {
	c.JSON(statusCode, Response{
		Success: true,
		Message: message,
		Data:    data,
	})
}

// Error sends an error response
func Error(c *gin.Context, statusCode int, message string, errorCode string, details string) {
	c.JSON(statusCode, Response{
		Success: false,
		Message: message,
		Error: &ErrorInfo{
			Code:    errorCode,
			Details: details,
		},
	})
}

// Paginated sends a paginated response
func Paginated(c *gin.Context, statusCode int, message string, data interface{}, meta *PaginationMeta) {
	c.JSON(statusCode, PaginatedResponse{
		Success: true,
		Message: message,
		Data:    data,
		Meta:    meta,
	})
}

// NewPaginationMeta creates pagination metadata
func NewPaginationMeta(total, limit, offset, currentCount int) *PaginationMeta {
	hasNext := offset+currentCount < total
	return &PaginationMeta{
		Total:   total,
		Limit:   limit,
		Offset:  offset,
		HasNext: hasNext,
	}
}

// BadRequest sends a 400 Bad Request response
func BadRequest(c *gin.Context, message string, details string) {
	Error(c, http.StatusBadRequest, message, "BAD_REQUEST", details)
}

// Unauthorized sends a 401 Unauthorized response
func Unauthorized(c *gin.Context, message string) {
	Error(c, http.StatusUnauthorized, message, "UNAUTHORIZED", "")
}

// Forbidden sends a 403 Forbidden response
func Forbidden(c *gin.Context, message string) {
	Error(c, http.StatusForbidden, message, "FORBIDDEN", "")
}

// NotFound sends a 404 Not Found response
func NotFound(c *gin.Context, message string) {
	Error(c, http.StatusNotFound, message, "NOT_FOUND", "")
}

// Conflict sends a 409 Conflict response
func Conflict(c *gin.Context, message string, details string) {
	Error(c, http.StatusConflict, message, "CONFLICT", details)
}

// InternalError sends a 500 Internal Server Error response
func InternalError(c *gin.Context, message string, details string) {
	Error(c, http.StatusInternalServerError, message, "INTERNAL_ERROR", details)
}
