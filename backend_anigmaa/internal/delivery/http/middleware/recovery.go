package middleware

import (
	"log"

	"github.com/anigmaa/backend/pkg/response"
	"github.com/gin-gonic/gin"
)

// Recovery middleware recovers from panics and returns 500
func Recovery() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				log.Printf("Panic recovered: %v", err)
				response.InternalError(c, "Internal server error", "")
			}
		}()
		c.Next()
	}
}
