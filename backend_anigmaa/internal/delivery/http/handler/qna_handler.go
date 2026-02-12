package handler

import (
	"net/http"
	"strconv"

	"github.com/anigmaa/backend/internal/delivery/http/middleware"
	"github.com/anigmaa/backend/internal/domain/qna"
	qnaUsecase "github.com/anigmaa/backend/internal/usecase/qna"
	"github.com/anigmaa/backend/pkg/response"
	"github.com/anigmaa/backend/pkg/validator"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// QnAHandler handles Q&A-related HTTP requests
type QnAHandler struct {
	qnaUsecase *qnaUsecase.Usecase
	validator  *validator.Validator
}

// NewQnAHandler creates a new Q&A handler
func NewQnAHandler(qnaUsecase *qnaUsecase.Usecase, validator *validator.Validator) *QnAHandler {
	return &QnAHandler{
		qnaUsecase: qnaUsecase,
		validator:  validator,
	}
}

// GetEventQnA godoc
// @Summary Get event Q&A
// @Description Get all questions and answers for an event
// @Tags qna
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Event ID" format(uuid)
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]qna.QnAWithDetails}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/{id}/qna [get]
func (h *QnAHandler) GetEventQnA(c *gin.Context) {
	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	// Get user ID from context (optional)
	userIDStr, _ := middleware.GetUserID(c)
	userID, _ := uuid.Parse(userIDStr)

	// Parse query parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Get total count for pagination
	total, err := h.qnaUsecase.CountEventQnA(c.Request.Context(), eventID)
	if err != nil {
		// If count fails, default to 0 but continue
		total = 0
	}

	// Get Q&A list
	qnaList, err := h.qnaUsecase.GetEventQnA(c.Request.Context(), eventID, userID, limit, offset)
	if err != nil {
		if err == qnaUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		response.InternalError(c, "Failed to get Q&A", err.Error())
		return
	}

	// Ensure we return empty array instead of null
	if qnaList == nil {
		qnaList = []qna.QnAWithDetails{}
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, limit, offset, len(qnaList))
	response.Paginated(c, http.StatusOK, "Q&A retrieved successfully", qnaList, meta)
}

// AskQuestion godoc
// @Summary Ask a question
// @Description Ask a question for an event
// @Tags qna
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Event ID" format(uuid)
// @Param request body qna.CreateQnARequest true "Question data"
// @Success 201 {object} response.Response{data=qna.QnAWithDetails}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /events/{id}/qna [post]
func (h *QnAHandler) AskQuestion(c *gin.Context) {
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

	// Parse event ID from path
	eventIDStr := c.Param("id")
	eventID, err := uuid.Parse(eventIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid event ID", err.Error())
		return
	}

	var req qna.CreateQnARequest

	// Parse request body
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request body", err.Error())
		return
	}

	// Set event ID from path
	req.EventID = eventID

	// Validate request
	if err := h.validator.Validate(&req); err != nil {
		response.BadRequest(c, "Validation failed", err.Error())
		return
	}

	// Call usecase
	newQnA, err := h.qnaUsecase.AskQuestion(c.Request.Context(), userID, &req)
	if err != nil {
		if err == qnaUsecase.ErrEventNotFound {
			response.NotFound(c, "Event not found")
			return
		}
		response.InternalError(c, "Failed to ask question", err.Error())
		return
	}

	response.Success(c, http.StatusCreated, "Question asked successfully", newQnA)
}

// UpvoteQuestion godoc
// @Summary Upvote a question
// @Description Upvote a question
// @Tags qna
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Question ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 409 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /qna/{id}/upvote [post]
func (h *QnAHandler) UpvoteQuestion(c *gin.Context) {
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

	// Parse question ID from path
	qnaIDStr := c.Param("id")
	qnaID, err := uuid.Parse(qnaIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid question ID", err.Error())
		return
	}

	// Call usecase
	if err := h.qnaUsecase.UpvoteQuestion(c.Request.Context(), qnaID, userID); err != nil {
		if err == qnaUsecase.ErrQnANotFound {
			response.NotFound(c, "Question not found")
			return
		}
		if err == qnaUsecase.ErrAlreadyUpvoted {
			response.Conflict(c, "Question already upvoted", err.Error())
			return
		}
		response.InternalError(c, "Failed to upvote question", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Question upvoted successfully", nil)
}

// RemoveUpvote godoc
// @Summary Remove upvote from a question
// @Description Remove upvote from a question
// @Tags qna
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Question ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /qna/{id}/upvote [delete]
func (h *QnAHandler) RemoveUpvote(c *gin.Context) {
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

	// Parse question ID from path
	qnaIDStr := c.Param("id")
	qnaID, err := uuid.Parse(qnaIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid question ID", err.Error())
		return
	}

	// Call usecase
	if err := h.qnaUsecase.RemoveUpvote(c.Request.Context(), qnaID, userID); err != nil {
		if err == qnaUsecase.ErrQnANotFound {
			response.NotFound(c, "Question not found")
			return
		}
		if err == qnaUsecase.ErrNotUpvoted {
			response.BadRequest(c, "Question not upvoted", err.Error())
			return
		}
		response.InternalError(c, "Failed to remove upvote", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Upvote removed successfully", nil)
}

// AnswerQuestion godoc
// @Summary Answer a question
// @Description Answer a question (event organizer only)
// @Tags qna
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Question ID" format(uuid)
// @Param request body qna.AnswerQnARequest true "Answer data"
// @Success 200 {object} response.Response{data=qna.QnA}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /qna/{id}/answer [post]
func (h *QnAHandler) AnswerQuestion(c *gin.Context) {
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

	// Parse question ID from path
	qnaIDStr := c.Param("id")
	qnaID, err := uuid.Parse(qnaIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid question ID", err.Error())
		return
	}

	var req qna.AnswerQnARequest

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
	answeredQnA, err := h.qnaUsecase.AnswerQuestion(c.Request.Context(), qnaID, userID, &req)
	if err != nil {
		if err == qnaUsecase.ErrQnANotFound {
			response.NotFound(c, "Question not found")
			return
		}
		if err == qnaUsecase.ErrAlreadyAnswered {
			response.Conflict(c, "Question already answered", err.Error())
			return
		}
		response.InternalError(c, "Failed to answer question", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Question answered successfully", answeredQnA)
}

// DeleteQuestion godoc
// @Summary Delete a question
// @Description Delete a question (author only)
// @Tags qna
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Question ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /qna/{id} [delete]
func (h *QnAHandler) DeleteQuestion(c *gin.Context) {
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

	// Parse question ID from path
	qnaIDStr := c.Param("id")
	qnaID, err := uuid.Parse(qnaIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid question ID", err.Error())
		return
	}

	// Call usecase
	if err := h.qnaUsecase.DeleteQuestion(c.Request.Context(), qnaID, userID); err != nil {
		if err == qnaUsecase.ErrQnANotFound {
			response.NotFound(c, "Question not found")
			return
		}
		if err == qnaUsecase.ErrUnauthorized {
			response.Forbidden(c, "Only the question author can delete this question")
			return
		}
		response.InternalError(c, "Failed to delete question", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Question deleted successfully", nil)
}
