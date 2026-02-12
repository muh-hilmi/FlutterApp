package feed_ranking

import (
	"testing"
	"time"
)

func TestRankTrendingEvent(t *testing.T) {
	ranker := NewRanker()

	now := time.Now()
	events := []Event{
		{
			ID:         "e1",
			Title:      "Viral Event",
			CreatedAt:  now.Add(-1 * time.Hour), // recent
			Visibility: "public",
			Status:     "published",
			Metrics: Metrics{
				Views24h:  10000,
				Likes24h:  500,
				Shares24h: 100,
				Saves:     50,
			},
		},
		{
			ID:         "e2",
			Title:      "Old Event",
			CreatedAt:  now.Add(-72 * time.Hour), // old
			Visibility: "public",
			Status:     "published",
			Metrics: Metrics{
				Views24h:  5000,
				Likes24h:  200,
				Shares24h: 50,
				Saves:     20,
			},
		},
		{
			ID:         "e3",
			Title:      "Medium Event",
			CreatedAt:  now.Add(-12 * time.Hour),
			Visibility: "public",
			Status:     "published",
			Metrics: Metrics{
				Views24h:  3000,
				Likes24h:  150,
				Shares24h: 30,
				Saves:     15,
			},
		},
	}

	result := ranker.rankTrendingEvent(events)

	// e1 should be first (most engagement + recent)
	if len(result) != 3 {
		t.Errorf("Expected 3 results, got %d", len(result))
	}

	if result[0] != "e1" {
		t.Errorf("Expected e1 to be first, got %s", result[0])
	}
}

func TestRankChillEvents(t *testing.T) {
	ranker := NewRanker()

	events := []Event{
		{
			ID:         "e1",
			Title:      "Chill Coffee Hangout",
			Mood:       "chill",
			Capacity:   10,
			Visibility: "public",
			Status:     "published",
			Tags:       []string{"coffee", "relax"},
			Metrics: Metrics{
				Views24h: 100,
				Saves:    20,
			},
		},
		{
			ID:         "e2",
			Title:      "Huge Party",
			Mood:       "hype",
			Capacity:   500,
			Visibility: "public",
			Status:     "published",
			Tags:       []string{"party", "dance"},
			Metrics: Metrics{
				Views24h:  5000,
				Shares24h: 200,
			},
		},
		{
			ID:         "e3",
			Title:      "Peaceful Meditation",
			Mood:       "calm",
			Capacity:   8,
			Visibility: "public",
			Status:     "published",
			Tags:       []string{"meditation", "chill"},
			Metrics: Metrics{
				Views24h: 150,
				Saves:    30,
				AvgViewMs: 180000, // long view time
			},
		},
	}

	result := ranker.rankChillEvents(events)

	// e3 and e1 should be returned (chill vibes), e2 should be excluded
	if len(result) != 2 {
		t.Errorf("Expected 2 chill events, got %d", len(result))
	}

	// Check that huge party is not included
	for _, id := range result {
		if id == "e2" {
			t.Errorf("Huge party (e2) should not be in chill events")
		}
	}
}

func TestRankGratisEvents(t *testing.T) {
	ranker := NewRanker()

	events := []Event{
		{
			ID:         "e1",
			PriceCents: 0,
			Visibility: "public",
			Status:     "published",
			Metrics: Metrics{
				Likes24h: 100,
			},
		},
		{
			ID:         "e2",
			PriceCents: 50000, // paid
			Visibility: "public",
			Status:     "published",
			Metrics: Metrics{
				Likes24h: 200,
			},
		},
		{
			ID:         "e3",
			PriceCents: 0,
			Visibility: "public",
			Status:     "published",
			Metrics: Metrics{
				Likes24h: 50,
			},
		},
	}

	result := ranker.rankGratisEvents(events)

	// Only e1 and e3 should be returned (free events)
	if len(result) != 2 {
		t.Errorf("Expected 2 free events, got %d", len(result))
	}

	// Check paid event is excluded
	for _, id := range result {
		if id == "e2" {
			t.Errorf("Paid event (e2) should not be in free events")
		}
	}

	// e1 should rank higher (more likes)
	if result[0] != "e1" {
		t.Errorf("Expected e1 to rank first, got %s", result[0])
	}
}

func TestRankBayarEvents(t *testing.T) {
	ranker := NewRanker()

	events := []Event{
		{
			ID:         "e1",
			PriceCents: 100000,
			Visibility: "public",
			Status:     "published",
			Metrics: Metrics{
				Likes24h: 100,
				Saves:    20,
			},
		},
		{
			ID:         "e2",
			PriceCents: 0, // free
			Visibility: "public",
			Status:     "published",
			Metrics: Metrics{
				Likes24h: 200,
			},
		},
		{
			ID:         "e3",
			PriceCents: 50000,
			Visibility: "public",
			Status:     "published",
			Metrics: Metrics{
				Likes24h: 50,
				Saves:    30,
			},
		},
	}

	result := ranker.rankBayarEvents(events)

	// Only e1 and e3 should be returned (paid events)
	if len(result) != 2 {
		t.Errorf("Expected 2 paid events, got %d", len(result))
	}

	// Check free event is excluded
	for _, id := range result {
		if id == "e2" {
			t.Errorf("Free event (e2) should not be in paid events")
		}
	}
}

func TestRankHariIniEvents(t *testing.T) {
	ranker := NewRanker()

	now := time.Now().UTC()
	todayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	todayEnd := todayStart.Add(24 * time.Hour)

	todayWindow := &TodayWindow{
		StartUTC: todayStart,
		EndUTC:   todayEnd,
	}

	events := []Event{
		{
			ID:         "e1",
			StartTime:  todayStart.Add(5 * time.Hour), // today morning
			Visibility: "public",
			Status:     "published",
			Metrics: Metrics{
				Likes24h: 50,
			},
		},
		{
			ID:         "e2",
			StartTime:  todayStart.Add(-12 * time.Hour), // yesterday
			Visibility: "public",
			Status:     "published",
			Metrics: Metrics{
				Likes24h: 100,
			},
		},
		{
			ID:         "e3",
			StartTime:  todayStart.Add(20 * time.Hour), // today evening
			Visibility: "public",
			Status:     "published",
			Metrics: Metrics{
				Likes24h: 30,
			},
		},
	}

	result := ranker.rankHariIniEvents(events, todayWindow)

	// Only e1 and e3 should be returned (today's events)
	if len(result) != 2 {
		t.Errorf("Expected 2 today's events, got %d", len(result))
	}

	// Check yesterday's event is excluded
	for _, id := range result {
		if id == "e2" {
			t.Errorf("Yesterday's event (e2) should not be in today's events")
		}
	}
}

func TestRankForYouPosts(t *testing.T) {
	ranker := NewRanker()

	user := UserProfile{
		ID: "u1",
		PreferredTags: map[string]float64{
			"tech":   1.5,
			"coding": 1.2,
		},
		FollowedAuthors: []string{"author1"},
		AvgViewTimeMs:   30000,
	}

	posts := []Post{
		{
			ID:         "p1",
			AuthorID:   "author1", // followed author
			Tags:       []string{"tech", "programming"},
			Visibility: "public",
			Status:     "published",
			Metrics: Metrics{
				Likes24h: 50,
				Saves:    10,
			},
		},
		{
			ID:         "p2",
			AuthorID:   "author2",
			Tags:       []string{"food", "recipe"},
			Visibility: "public",
			Status:     "published",
			Metrics: Metrics{
				Likes24h: 100,
				Saves:    5,
			},
		},
		{
			ID:         "p3",
			AuthorID:   "author3",
			Tags:       []string{"tech", "AI"},
			Visibility: "public",
			Status:     "published",
			Metrics: Metrics{
				Likes24h:  30,
				Saves:     8,
				AvgViewMs: 60000, // longer than user avg
			},
		},
	}

	result := ranker.rankForYouPosts(posts, user)

	if len(result) != 3 {
		t.Errorf("Expected 3 results, got %d", len(result))
	}

	// p1 should rank highest (followed author + matching tags)
	if result[0] != "p1" {
		t.Errorf("Expected p1 to rank first (followed author), got %s", result[0])
	}
}

func TestFilterValidContent(t *testing.T) {
	ranker := NewRanker()

	events := []Event{
		{
			ID:         "e1",
			Visibility: "public",
			Status:     "published",
		},
		{
			ID:         "e2",
			Visibility: "private",
			Status:     "published",
		},
		{
			ID:         "e3",
			Visibility: "public",
			Status:     "draft",
		},
		{
			ID:         "e4",
			Visibility: "PUBLIC", // test case insensitive
			Status:     "PUBLISHED",
		},
	}

	result := ranker.filterValidEvents(events)

	// Only e1 and e4 should pass (public + published)
	if len(result) != 2 {
		t.Errorf("Expected 2 valid events, got %d", len(result))
	}

	validIDs := make(map[string]bool)
	for _, e := range result {
		validIDs[e.ID] = true
	}

	if !validIDs["e1"] || !validIDs["e4"] {
		t.Errorf("Expected e1 and e4 to be valid")
	}
}

func TestFullRankingFlow(t *testing.T) {
	ranker := NewRanker()

	now := time.Now().UTC()
	todayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	todayEnd := todayStart.Add(24 * time.Hour)

	req := RankingRequest{
		UserProfile: UserProfile{
			ID: "u1",
			PreferredTags: map[string]float64{
				"tech": 1.5,
			},
			FollowedAuthors: []string{"author1"},
			AvgViewTimeMs:   30000,
		},
		Contents: Contents{
			Events: []Event{
				{
					ID:         "e1",
					Mood:       "chill",
					Capacity:   10,
					PriceCents: 0,
					StartTime:  todayStart.Add(5 * time.Hour),
					Visibility: "public",
					Status:     "published",
					Tags:       []string{"coffee"},
					Metrics: Metrics{
						Views24h: 100,
						Saves:    10,
					},
				},
				{
					ID:         "e2",
					Capacity:   50,
					PriceCents: 50000,
					StartTime:  todayStart.Add(10 * time.Hour),
					Visibility: "public",
					Status:     "published",
					Metrics: Metrics{
						Views24h:  5000,
						Likes24h:  200,
						Shares24h: 50,
					},
				},
			},
			Posts: []Post{
				{
					ID:         "p1",
					AuthorID:   "author1",
					Tags:       []string{"tech"},
					Visibility: "public",
					Status:     "published",
					Metrics: Metrics{
						Likes24h: 50,
					},
				},
			},
		},
		TodayWindow: &TodayWindow{
			StartUTC: todayStart,
			EndUTC:   todayEnd,
		},
	}

	response := ranker.Rank(req)

	// Validate all feeds are populated
	if len(response.TrendingEvent) == 0 {
		t.Error("TrendingEvent should not be empty")
	}

	if len(response.ForYouPosts) == 0 {
		t.Error("ForYouPosts should not be empty")
	}

	if len(response.ForYouEvents) == 0 {
		t.Error("ForYouEvents should not be empty")
	}

	if len(response.ChillEvents) == 0 {
		t.Error("ChillEvents should not be empty (e1 is chill)")
	}

	if len(response.HariIniEvents) != 2 {
		t.Errorf("HariIniEvents should have 2 events (both are today), got %d", len(response.HariIniEvents))
	}

	if len(response.GratisEvents) == 0 {
		t.Error("GratisEvents should not be empty (e1 is free)")
	}

	if len(response.BayarEvents) == 0 {
		t.Error("BayarEvents should not be empty (e2 is paid)")
	}

	// e1 should be in ChillEvents
	found := false
	for _, id := range response.ChillEvents {
		if id == "e1" {
			found = true
			break
		}
	}
	if !found {
		t.Error("e1 should be in ChillEvents")
	}
}
