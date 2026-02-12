package handler

import (
	"net/http"

	"github.com/anigmaa/backend/internal/usecase/feed_ranking"
	"github.com/anigmaa/backend/pkg/response"
	"github.com/gin-gonic/gin"
)

// FeedRankingHandler handles feed ranking requests
type FeedRankingHandler struct {
	ranker *feed_ranking.Ranker
}

// NewFeedRankingHandler creates a new feed ranking handler
func NewFeedRankingHandler(ranker *feed_ranking.Ranker) *FeedRankingHandler {
	return &FeedRankingHandler{
		ranker: ranker,
	}
}

// RankFeeds handles POST /api/v1/feed/rank
// @Summary Rank content for personalized feeds
// @Description Accepts user profile and content list, returns ranked feeds for 7 different feed types
// @Tags Feed Ranking
// @Accept json
// @Produce json
// @Param request body feed_ranking.RankingRequest true "Ranking request with user profile and contents"
// @Success 200 {object} feed_ranking.RankingResponse
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/feed/rank [post]
func (h *FeedRankingHandler) RankFeeds(c *gin.Context) {
	var req feed_ranking.RankingRequest

	// Parse JSON request body
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if req.UserProfile.ID == "" {
		response.BadRequest(c, "Validation failed", "user_profile.id is required")
		return
	}

	// Execute ranking
	result := h.ranker.Rank(req)

	// Return JSON response
	c.JSON(http.StatusOK, result)
}
