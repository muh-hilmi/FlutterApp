package discovery

import (
	"context"
	"errors"
	"math"
	"time"

	"github.com/anigmaa/backend/internal/domain/event"
	"github.com/anigmaa/backend/internal/domain/user"
	"github.com/google/uuid"
)

var (
	ErrNoEventsFound = errors.New("no matching events found")
	ErrUserNotFound  = errors.New("user not found")
)

// MatchPreferences represents user preferences for event matching
type MatchPreferences struct {
	Categories   []event.EventCategory `json:"categories,omitempty"`
	MaxDistance  *float64              `json:"max_distance,omitempty"` // in kilometers
	MaxPrice     *float64              `json:"max_price,omitempty"`
	FreeOnly     bool                  `json:"free_only"`
	StartTimeMin *time.Time            `json:"start_time_min,omitempty"`
	StartTimeMax *time.Time            `json:"start_time_max,omitempty"`
}

// MatchResult represents a matched event with score
type MatchResult struct {
	Event    *event.EventWithDetails `json:"event"`
	Score    float64                 `json:"score"`              // 0-100
	Distance *float64                `json:"distance,omitempty"` // in kilometers
	Reason   string                  `json:"reason"`             // Why this event was matched
}

// Matcher handles event discovery and matching logic
type Matcher struct {
	eventRepo event.Repository
	userRepo  user.Repository
}

// NewMatcher creates a new discovery matcher
func NewMatcher(eventRepo event.Repository, userRepo user.Repository) *Matcher {
	return &Matcher{
		eventRepo: eventRepo,
		userRepo:  userRepo,
	}
}

// FindMatch finds matching events for a user using random + engagement bias
// Algorithm: Random selection from candidate events, weighted by attendees count
func (m *Matcher) FindMatch(ctx context.Context, userID uuid.UUID, userLat, userLng *float64, prefs *MatchPreferences) ([]MatchResult, error) {
	// Get user to personalize results
	_, err := m.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, ErrUserNotFound
	}

	// Build event filter
	filter := &event.EventFilter{
		Status: func() *event.EventStatus { s := event.StatusUpcoming; return &s }(),
		Limit:  100, // Get larger pool for random selection
		Offset: 0,
	}

	// Apply preferences
	if prefs != nil {
		if len(prefs.Categories) > 0 {
			filter.Category = &prefs.Categories[0]
		}

		if prefs.FreeOnly {
			isFree := true
			filter.IsFree = &isFree
		}

		if prefs.StartTimeMin != nil {
			filter.StartDate = prefs.StartTimeMin
		}

		if prefs.StartTimeMax != nil {
			filter.EndDate = prefs.StartTimeMax
		}

		if userLat != nil && userLng != nil && prefs.MaxDistance != nil {
			filter.Lat = userLat
			filter.Lng = userLng
			filter.Radius = prefs.MaxDistance
		}
	}

	// Get candidate events
	events, err := m.eventRepo.List(ctx, filter)
	if err != nil {
		return nil, err
	}

	if len(events) == 0 {
		return nil, ErrNoEventsFound
	}

	// Simple random with engagement bias
	results := make([]MatchResult, 0, len(events))
	for _, evt := range events {
		// Apply hard filters
		if prefs != nil {
			if prefs.MaxPrice != nil && evt.Price != nil && *evt.Price > *prefs.MaxPrice {
				continue
			}
			if prefs.MaxDistance != nil && evt.Distance != nil && *evt.Distance > *prefs.MaxDistance {
				continue
			}
		}

		// Simple engagement score: attendees count (+ 1 to avoid zero)
		score := float64(evt.AttendeesCount + 1)

		results = append(results, MatchResult{
			Event:    &evt,
			Score:    score,
			Distance: evt.Distance,
			Reason:   "Recommended for you",
		})
	}

	if len(results) == 0 {
		return nil, ErrNoEventsFound
	}

	// Random shuffle with engagement bias
	shuffleWithBias(results)

	// Return top matches (limit to 10)
	maxResults := 10
	if len(results) > maxResults {
		results = results[:maxResults]
	}

	return results, nil
}

// FindQuickMatch finds a single best match for instant "I'm bored" discovery
func (m *Matcher) FindQuickMatch(ctx context.Context, userID uuid.UUID, userLat, userLng *float64) (*MatchResult, error) {
	// Quick match with minimal preferences - find something happening soon and nearby
	now := time.Now()
	maxTime := now.Add(24 * time.Hour) // Events in the next 24 hours

	prefs := &MatchPreferences{
		StartTimeMin: &now,
		StartTimeMax: &maxTime,
	}

	// If location provided, prioritize nearby events
	if userLat != nil && userLng != nil {
		maxDist := 10.0 // 10km radius
		prefs.MaxDistance = &maxDist
	}

	matches, err := m.FindMatch(ctx, userID, userLat, userLng, prefs)
	if err != nil {
		return nil, err
	}

	if len(matches) == 0 {
		return nil, ErrNoEventsFound
	}

	// Return the best match
	return &matches[0], nil
}

// GetRecommendations gets personalized event recommendations
func (m *Matcher) GetRecommendations(ctx context.Context, userID uuid.UUID, userLat, userLng *float64, limit int) ([]MatchResult, error) {
	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}

	// Get user's interests and history to personalize
	// For now, use simple preferences
	prefs := &MatchPreferences{
		FreeOnly: false, // Include both free and paid
	}

	matches, err := m.FindMatch(ctx, userID, userLat, userLng, prefs)
	if err != nil {
		return nil, err
	}

	// Limit results
	if len(matches) > limit {
		matches = matches[:limit]
	}

	return matches, nil
}

// shuffleWithBias randomly shuffles results with bias towards higher scores
// Higher engagement = higher probability to appear near the top
func shuffleWithBias(results []MatchResult) {
	n := len(results)
	if n <= 1 {
		return
	}

	// Fisher-Yates shuffle with weighted probability
	for i := 0; i < n-1; i++ {
		// Calculate total weight for remaining items
		totalWeight := 0.0
		for j := i; j < n; j++ {
			totalWeight += results[j].Score
		}

		if totalWeight <= 0 {
			// If no weights, do regular shuffle
			j := i + int(math.Floor(float64(n-i)*0.5)) // simple random position
			results[i], results[j] = results[j], results[i]
			continue
		}

		// Select random weighted position
		// Use a simple pseudo-random based on current time and index
		// In production, use crypto/rand or math/rand with seed
		randomValue := float64((time.Now().UnixNano()+int64(i*7))%1000) / 1000.0
		target := randomValue * totalWeight

		// Find the item that corresponds to this weight
		cumulative := 0.0
		selectedIdx := i
		for j := i; j < n; j++ {
			cumulative += results[j].Score
			if cumulative >= target {
				selectedIdx = j
				break
			}
		}

		// Swap selected item to current position
		if selectedIdx != i {
			results[i], results[selectedIdx] = results[selectedIdx], results[i]
		}
	}
}

// CalculateDistance calculates distance between two coordinates using Haversine formula
// Returns distance in kilometers
func CalculateDistance(lat1, lng1, lat2, lng2 float64) float64 {
	const earthRadius = 6371.0 // Earth's radius in kilometers

	// Convert to radians
	lat1Rad := lat1 * math.Pi / 180
	lng1Rad := lng1 * math.Pi / 180
	lat2Rad := lat2 * math.Pi / 180
	lng2Rad := lng2 * math.Pi / 180

	// Haversine formula
	dlat := lat2Rad - lat1Rad
	dlng := lng2Rad - lng1Rad

	a := math.Sin(dlat/2)*math.Sin(dlat/2) +
		math.Cos(lat1Rad)*math.Cos(lat2Rad)*
			math.Sin(dlng/2)*math.Sin(dlng/2)

	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	distance := earthRadius * c
	return distance
}

// GetTrendingEvents gets trending events using random + engagement bias
func (m *Matcher) GetTrendingEvents(ctx context.Context, userID uuid.UUID, limit int) ([]event.EventWithDetails, error) {
	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}

	// Get upcoming events
	filter := &event.EventFilter{
		Status: func() *event.EventStatus { s := event.StatusUpcoming; return &s }(),
		Limit:  100, // Get larger pool
		Offset: 0,
	}

	events, err := m.eventRepo.List(ctx, filter)
	if err != nil {
		return nil, err
	}

	// Convert to match results for weighted shuffle
	results := make([]MatchResult, 0, len(events))
	for _, evt := range events {
		// Score by engagement (attendees count)
		score := float64(evt.AttendeesCount + 1)
		results = append(results, MatchResult{
			Event: &evt,
			Score: score,
		})
	}

	// Apply random with engagement bias
	shuffleWithBias(results)

	// Extract events from results
	trending := make([]event.EventWithDetails, 0, limit)
	for i := 0; i < len(results) && i < limit; i++ {
		trending = append(trending, *results[i].Event)
	}

	return trending, nil
}

// GetEventsNearby gets events near a location
func (m *Matcher) GetEventsNearby(ctx context.Context, userID uuid.UUID, lat, lng, radiusKm float64, limit int) ([]event.EventWithDetails, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	return m.eventRepo.GetNearby(ctx, lat, lng, radiusKm, limit)
}
