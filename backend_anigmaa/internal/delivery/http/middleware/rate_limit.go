package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// windowCounter is a simple fixed-window request counter per key (IP address).
type windowCounter struct {
	mu      sync.Mutex
	count   int
	resetAt time.Time
}

// allow returns true if the request is within the limit for the current window.
func (w *windowCounter) allow(limit int, window time.Duration) bool {
	w.mu.Lock()
	defer w.mu.Unlock()

	now := time.Now()
	if now.After(w.resetAt) {
		w.count = 0
		w.resetAt = now.Add(window)
	}

	if w.count >= limit {
		return false
	}
	w.count++
	return true
}

// RateLimit returns a per-IP fixed-window rate limiting middleware.
//
//	limit:  maximum number of requests allowed per window
//	window: duration of each window (e.g. time.Minute)
//
// Counters are stored in memory so limits are per-instance.
// For multi-instance deployments, replace with a Redis-backed limiter (P2).
func RateLimit(limit int, window time.Duration) gin.HandlerFunc {
	var counters sync.Map

	// Background cleanup: remove expired counters to prevent unbounded memory growth.
	go func() {
		ticker := time.NewTicker(10 * time.Minute)
		defer ticker.Stop()
		for range ticker.C {
			now := time.Now()
			counters.Range(func(key, val any) bool {
				w := val.(*windowCounter)
				w.mu.Lock()
				expired := now.After(w.resetAt)
				w.mu.Unlock()
				if expired {
					counters.Delete(key)
				}
				return true
			})
		}
	}()

	return func(c *gin.Context) {
		ip := c.ClientIP()

		val, _ := counters.LoadOrStore(ip, &windowCounter{
			resetAt: time.Now().Add(window),
		})
		counter := val.(*windowCounter)

		if !counter.allow(limit, window) {
			c.Header("Retry-After", window.String())
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"success": false,
				"message": "Too many requests — please slow down.",
			})
			return
		}

		c.Next()
	}
}
