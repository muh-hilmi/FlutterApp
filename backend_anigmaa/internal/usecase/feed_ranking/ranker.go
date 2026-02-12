package feed_ranking

import (
	"math"
	"sort"
	"strings"
	"time"
)

// Ranker orchestrates the feed ranking for all feed types
type Ranker struct{}

// NewRanker creates a new feed ranker instance
func NewRanker() *Ranker {
	return &Ranker{}
}

// Rank processes the ranking request and returns ranked feeds
func (r *Ranker) Rank(req RankingRequest) RankingResponse {
	// Filter valid content (public + published only)
	validEvents := r.filterValidEvents(req.Contents.Events)
	validPosts := r.filterValidPosts(req.Contents.Posts)

	response := RankingResponse{
		TrendingEvent: r.rankTrendingEvent(validEvents),
		ForYouPosts:   r.rankForYouPosts(validPosts, req.UserProfile),
		ForYouEvents:  r.rankForYouEvents(validEvents, req.UserProfile),
		ChillEvents:   r.rankChillEvents(validEvents),
		HariIniEvents: r.rankHariIniEvents(validEvents, req.TodayWindow),
		GratisEvents:  r.rankGratisEvents(validEvents),
		BayarEvents:   r.rankBayarEvents(validEvents),
	}

	return response
}

// filterValidEvents returns only public and upcoming/live events
func (r *Ranker) filterValidEvents(events []Event) []Event {
	valid := make([]Event, 0, len(events))
	for _, e := range events {
		statusLower := strings.ToLower(e.Status)
		visibilityLower := strings.ToLower(e.Visibility)
		// Only show public events that are upcoming or live
		if visibilityLower == "public" && (statusLower == "upcoming" || statusLower == "live") {
			valid = append(valid, e)
		}
	}
	return valid
}

// filterValidPosts returns only public posts
func (r *Ranker) filterValidPosts(posts []Post) []Post {
	valid := make([]Post, 0, len(posts))
	for _, p := range posts {
		if strings.ToLower(p.Visibility) == "public" {
			valid = append(valid, p)
		}
	}
	return valid
}

// rankTrendingEvent ranks events by attendees count and recency
// Priority: high attendees_count with recency boost
func (r *Ranker) rankTrendingEvent(events []Event) []string {
	scored := make([]ScoredContent, 0, len(events))

	for _, event := range events {
		score := r.calculateTrendingScore(event)
		scored = append(scored, ScoredContent{ID: event.ID, Score: score})
	}

	// Sort descending by score
	sort.Slice(scored, func(i, j int) bool {
		return scored[i].Score > scored[j].Score
	})

	return extractIDs(scored)
}

// calculateTrendingScore computes trending score with attendees + recency
func (r *Ranker) calculateTrendingScore(event Event) float64 {
	// Popularity score: more attendees = higher score
	popularityScore := float64(event.AttendeesCount) * 10.0

	// Capacity utilization bonus (events that are filling up fast)
	if event.MaxAttendees > 0 {
		utilizationRate := float64(event.AttendeesCount) / float64(event.MaxAttendees)
		if utilizationRate > 0.5 { // More than half full
			popularityScore *= (1.0 + utilizationRate*0.5)
		}
	}

	// Recency boost (exponential decay: newer = higher score)
	hoursSinceCreation := time.Since(event.CreatedAt).Hours()
	recencyMultiplier := math.Exp(-hoursSinceCreation / 72.0) // decay over 3 days

	return popularityScore * recencyMultiplier
}

// rankForYouPosts ranks posts by likes count and recency
func (r *Ranker) rankForYouPosts(posts []Post, user UserProfile) []string {
	scored := make([]ScoredContent, 0, len(posts))

	for _, post := range posts {
		// Simple scoring: likes count + recency
		score := float64(post.LikesCount) * 5.0

		// Recency boost
		hoursSinceCreation := time.Since(post.CreatedAt).Hours()
		recencyMultiplier := math.Exp(-hoursSinceCreation / 48.0)
		score *= recencyMultiplier

		scored = append(scored, ScoredContent{ID: post.ID, Score: score})
	}

	sort.Slice(scored, func(i, j int) bool {
		return scored[i].Score > scored[j].Score
	})

	return extractIDs(scored)
}

// rankForYouEvents ranks events by category preference and engagement
func (r *Ranker) rankForYouEvents(events []Event, user UserProfile) []string {
	scored := make([]ScoredContent, 0, len(events))

	for _, event := range events {
		score := r.calculateEventPersonalizationScore(event, user)
		scored = append(scored, ScoredContent{ID: event.ID, Score: score})
	}

	sort.Slice(scored, func(i, j int) bool {
		return scored[i].Score > scored[j].Score
	})

	return extractIDs(scored)
}

// calculateEventPersonalizationScore computes user-event affinity
func (r *Ranker) calculateEventPersonalizationScore(event Event, user UserProfile) float64 {
	score := 0.0

	// Category preference matching
	if weight, exists := user.PreferredCategories[strings.ToLower(event.Category)]; exists {
		score += weight * 50.0 // Strong boost for preferred categories
	} else {
		score += 10.0 // Base score for all events
	}

	// Host following bonus
	for _, followedHost := range user.FollowedHostIDs {
		if followedHost == event.AuthorID {
			score += 100.0 // Strong boost for followed hosts
			break
		}
	}

	// Popularity signals
	score += float64(event.AttendeesCount) * 3.0

	// Recency boost
	hoursSinceCreation := time.Since(event.CreatedAt).Hours()
	recencyMultiplier := math.Exp(-hoursSinceCreation / 72.0)
	score *= recencyMultiplier

	return score
}

// rankChillEvents ranks intimate/small events
// Priority: categories like coffee, meetup, social with small capacity
func (r *Ranker) rankChillEvents(events []Event) []string {
	scored := make([]ScoredContent, 0, len(events))

	for _, event := range events {
		// Filter: only chill-related categories
		if !r.isChillCategory(event.Category) {
			continue // skip non-chill events
		}

		// Filter: small capacity events (intimate gatherings)
		if event.MaxAttendees > 25 {
			continue // skip large events
		}

		score := r.calculateChillScore(event)
		scored = append(scored, ScoredContent{ID: event.ID, Score: score})
	}

	sort.Slice(scored, func(i, j int) bool {
		return scored[i].Score > scored[j].Score
	})

	return extractIDs(scored)
}

// isChillCategory checks if category indicates chill/relaxed vibe
func (r *Ranker) isChillCategory(category string) bool {
	chillCategories := []string{"coffee", "meetup", "social", "food", "networking", "nightlife"}
	categoryLower := strings.ToLower(category)
	for _, chillCat := range chillCategories {
		if categoryLower == chillCat {
			return true
		}
	}
	return false
}

// calculateChillScore computes chill vibe score based on capacity
func (r *Ranker) calculateChillScore(event Event) float64 {
	score := 0.0

	// Ideal capacity: small intimate gatherings (6-15 people)
	if event.MaxAttendees >= 6 && event.MaxAttendees <= 12 {
		score += 50.0
	} else if event.MaxAttendees >= 4 && event.MaxAttendees <= 20 {
		score += 30.0 // still acceptable
	} else {
		score += 10.0 // larger events get lower score
	}

	// Popularity bonus (but not too popular - want intimate vibe)
	if event.AttendeesCount > 0 && event.AttendeesCount <= 10 {
		score += float64(event.AttendeesCount) * 5.0
	} else if event.AttendeesCount > 10 {
		// Penalty for too many attendees (not intimate anymore)
		score += 20.0
	}

	// Recency bonus
	hoursSinceCreation := time.Since(event.CreatedAt).Hours()
	if hoursSinceCreation < 48 { // Recent events
		score += 15.0
	}

	return score
}

// rankHariIniEvents ranks events happening today (within today_window)
// Priority: start_time within user's local today
func (r *Ranker) rankHariIniEvents(events []Event, todayWindow *TodayWindow) []string {
	if todayWindow == nil {
		// If no window provided, use UTC midnight-to-midnight
		now := time.Now().UTC()
		start := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
		end := start.Add(24 * time.Hour)
		todayWindow = &TodayWindow{StartUTC: start, EndUTC: end}
	}

	scored := make([]ScoredContent, 0, len(events))

	for _, event := range events {
		// Filter: only events starting within today's window
		if event.StartTime.Before(todayWindow.StartUTC) || event.StartTime.After(todayWindow.EndUTC) {
			continue
		}

		score := r.calculateHariIniScore(event, todayWindow)
		scored = append(scored, ScoredContent{ID: event.ID, Score: score})
	}

	sort.Slice(scored, func(i, j int) bool {
		return scored[i].Score > scored[j].Score
	})

	return extractIDs(scored)
}

// calculateHariIniScore prioritizes events starting soon
func (r *Ranker) calculateHariIniScore(event Event, todayWindow *TodayWindow) float64 {
	// Base score: popularity
	score := float64(event.AttendeesCount) * 5.0

	// Urgency boost: events starting sooner rank higher
	now := time.Now().UTC()
	hoursUntilStart := event.StartTime.Sub(now).Hours()

	if hoursUntilStart >= 0 && hoursUntilStart <= 24 {
		// Inverse score: sooner = higher
		urgencyBoost := (24.0 - hoursUntilStart) * 3.0
		score += urgencyBoost
	}

	return score
}

// rankGratisEvents ranks free events
// Priority: free events with high attendees count
func (r *Ranker) rankGratisEvents(events []Event) []string {
	scored := make([]ScoredContent, 0, len(events))

	for _, event := range events {
		if !event.IsFree {
			continue // skip paid events
		}

		// Score by popularity and recency
		score := float64(event.AttendeesCount) * 8.0

		// Recency boost
		hoursSinceCreation := time.Since(event.CreatedAt).Hours()
		recencyMultiplier := math.Exp(-hoursSinceCreation / 72.0)
		score *= recencyMultiplier

		scored = append(scored, ScoredContent{ID: event.ID, Score: score})
	}

	sort.Slice(scored, func(i, j int) bool {
		return scored[i].Score > scored[j].Score
	})

	return extractIDs(scored)
}

// rankBayarEvents ranks paid events
// Priority: paid events with high attendees count (value signals)
func (r *Ranker) rankBayarEvents(events []Event) []string {
	scored := make([]ScoredContent, 0, len(events))

	for _, event := range events {
		if event.IsFree {
			continue // skip free events
		}

		// Score by popularity
		score := float64(event.AttendeesCount) * 8.0

		// Quality signal: higher price may indicate premium event
		if event.Price > 0 {
			priceSignal := math.Log(event.Price + 1.0)
			score += priceSignal * 2.0
		}

		// Recency boost
		hoursSinceCreation := time.Since(event.CreatedAt).Hours()
		recencyMultiplier := math.Exp(-hoursSinceCreation / 72.0)
		score *= recencyMultiplier

		scored = append(scored, ScoredContent{ID: event.ID, Score: score})
	}

	sort.Slice(scored, func(i, j int) bool {
		return scored[i].Score > scored[j].Score
	})

	return extractIDs(scored)
}

// extractIDs converts scored content to ID list
func extractIDs(scored []ScoredContent) []string {
	ids := make([]string, len(scored))
	for i, sc := range scored {
		ids[i] = sc.ID
	}
	return ids
}
