package feed_ranking

import (
	"time"
)

// RankingRequest represents the JSON input for the ranking agent
type RankingRequest struct {
	UserProfile UserProfile    `json:"user_profile"`
	Contents    Contents       `json:"contents"`
	TodayWindow *TodayWindow   `json:"today_window,omitempty"`
}

// UserProfile contains user preferences and history for personalization
type UserProfile struct {
	ID                  string             `json:"id"`
	PreferredCategories map[string]float64 `json:"preferred_categories,omitempty"` // category -> weight
	LikedEventIDs       []string           `json:"liked_event_ids,omitempty"`      // event IDs user liked
	FollowedHostIDs     []string           `json:"followed_host_ids,omitempty"`    // host IDs user follows
	Location            *Location          `json:"location,omitempty"`
	Timezone            string             `json:"timezone,omitempty"`
}

// Location represents geographic coordinates
type Location struct {
	City      string   `json:"city,omitempty"`
	Latitude  *float64 `json:"latitude,omitempty"`
	Longitude *float64 `json:"longitude,omitempty"`
}

// Contents contains all candidate events and posts
type Contents struct {
	Events []Event `json:"events"`
	Posts  []Post  `json:"posts"`
}

// Event represents an event with database fields
type Event struct {
	ID             string     `json:"id"`
	Title          string     `json:"title"`
	Description    string     `json:"description"`
	Category       string     `json:"category"`        // event category from DB
	CreatedAt      time.Time  `json:"created_at"`
	StartTime      time.Time  `json:"start_time"`
	City           string     `json:"city,omitempty"`
	Price          float64    `json:"price"`           // actual price from DB
	IsFree         bool       `json:"is_free"`         // free flag from DB
	MaxAttendees   int        `json:"max_attendees"`   // capacity from DB
	AttendeesCount int        `json:"attendees_count"` // current attendees from DB
	Tags           []string   `json:"tags,omitempty"`
	Visibility     string     `json:"visibility"`      // public, private, followers
	Status         string     `json:"status"`          // upcoming, completed, cancelled
	AuthorID       string     `json:"author_id,omitempty"`
	Location       *Location  `json:"location,omitempty"`
}

// Post represents a post with database fields
type Post struct {
	ID         string    `json:"id"`
	Caption    string    `json:"caption"`
	CreatedAt  time.Time `json:"created_at"`
	Tags       []string  `json:"tags,omitempty"`
	Visibility string    `json:"visibility"` // public, private, followers
	Status     string    `json:"status"`     // published, draft
	AuthorID   string    `json:"author_id,omitempty"`
	LikesCount int       `json:"likes_count"` // engagement signal from DB
}

// TodayWindow defines the time range for "today" in user's timezone
type TodayWindow struct {
	StartUTC time.Time `json:"start_utc"`
	EndUTC   time.Time `json:"end_utc"`
}

// RankingResponse represents the JSON output with ranked content IDs
type RankingResponse struct {
	TrendingEvent   []string `json:"trending_event"`   // global trending event
	ForYouPosts     []string `json:"for_you_posts"`    // personalized posts
	ForYouEvents    []string `json:"for_you_events"`   // personalized events
	ChillEvents     []string `json:"chill_events"`     // intimate/relaxed events
	HariIniEvents   []string `json:"hari_ini_events"`  // events happening today
	GratisEvents    []string `json:"gratis_events"`    // free events
	BayarEvents     []string `json:"bayar_events"`     // paid events
}

// ScoredContent holds a content ID with its computed score
type ScoredContent struct {
	ID    string
	Score float64
}
