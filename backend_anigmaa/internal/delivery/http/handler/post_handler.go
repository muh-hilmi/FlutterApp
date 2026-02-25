package handler

import (
	"log"
	"net/http"
	"strconv"

	"github.com/anigmaa/backend/internal/delivery/http/middleware"
	"github.com/anigmaa/backend/internal/domain/comment"
	"github.com/anigmaa/backend/internal/domain/post"
	postUsecase "github.com/anigmaa/backend/internal/usecase/post"
	"github.com/anigmaa/backend/pkg/response"
	"github.com/anigmaa/backend/pkg/validator"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// PostHandler handles post-related HTTP requests
type PostHandler struct {
	postUsecase *postUsecase.Usecase
	validator   *validator.Validator
}

// NewPostHandler creates a new post handler
func NewPostHandler(postUsecase *postUsecase.Usecase, validator *validator.Validator) *PostHandler {
	return &PostHandler{
		postUsecase: postUsecase,
		validator:   validator,
	}
}

// GetFeed godoc
// @Summary Get user feed
// @Description Get personalized feed of posts for the current user
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]post.PostWithDetails}
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/feed [get]
func (h *PostHandler) GetFeed(c *gin.Context) {
	// Parse query parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Get user ID from context (optional - supports public feed)
	userIDStr, exists := middleware.GetUserID(c)
	var userID uuid.UUID
	var err error

	if exists {
		userID, err = uuid.Parse(userIDStr)
		if err != nil {
			response.BadRequest(c, "Invalid user ID", err.Error())
			return
		}
		// DEBUG: Log userID
		log.Printf("DEBUG: userID = %v", userID)
	} else {
		// DEBUG: Log for public feed
		log.Printf("DEBUG: public feed request (no user authentication)")
	}

	// Get total count for pagination
	total := 0
	if exists {
		total, err = h.postUsecase.CountFeed(c.Request.Context(), userID)
		if err != nil {
			// If count fails, default to 0 but continue
			total = 0
		}
	} else {
		// For public feed, get count of public posts
		total, err = h.postUsecase.CountPublicPosts(c.Request.Context())
		if err != nil {
			total = 0
		}
	}

	// Call usecase to get posts
	var posts []post.PostWithDetails
	if exists {
		// Authenticated: get personalized feed
		posts, err = h.postUsecase.GetFeed(c.Request.Context(), userID, limit, offset)
	} else {
		// Public: get public posts
		posts, err = h.postUsecase.GetPublicPosts(c.Request.Context(), limit, offset)
	}

	if err != nil {
		response.InternalError(c, "Failed to get feed", err.Error())
		return
	}

	// DEBUG: Log posts results
	log.Printf("DEBUG: Retrieved %d posts from feed", len(posts))
	for i, p := range posts {
		log.Printf("DEBUG: Post[%d] ID=%v, IsLikedByUser=%v, AuthorID=%v",
			i, p.ID, p.IsLikedByUser, p.AuthorID)
	}

	// Transform to Flutter-compatible response format
	postResponses := make([]post.PostResponse, len(posts))
	for i, p := range posts {
		postResponses[i] = p.ToResponse()
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, limit, offset, len(posts))
	response.Paginated(c, http.StatusOK, "Feed retrieved successfully", postResponses, meta)
}

// CreatePost godoc
// @Summary Create a new post
// @Description Create a new social media post
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body post.CreatePostRequest true "Post creation data"
// @Success 201 {object} response.Response{data=post.Post}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts [post]
func (h *PostHandler) CreatePost(c *gin.Context) {
	// Get user ID from context
	authorIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	authorID, err := uuid.Parse(authorIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	var req post.CreatePostRequest

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

	// Custom validation: attached_event_id is required for text_with_event posts
	if req.Type == post.TypeTextWithEvent && (req.AttachedEventID == nil || *req.AttachedEventID == uuid.Nil) {
		response.BadRequest(c, "Validation failed", "attached_event_id is required for text_with_event posts")
		return
	}

	// Call usecase
	newPost, err := h.postUsecase.CreatePost(c.Request.Context(), authorID, &req)
	if err != nil {
		if err == postUsecase.ErrEventNotFound {
			response.NotFound(c, "Attached event not found")
			return
		}
		response.InternalError(c, "Failed to create post", err.Error())
		return
	}

	response.Success(c, http.StatusCreated, "Post created successfully", newPost)
}

// GetPostByID godoc
// @Summary Get post by ID
// @Description Get detailed information about a specific post
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Post ID" format(uuid)
// @Success 200 {object} response.Response{data=post.PostWithDetails}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/{id} [get]
func (h *PostHandler) GetPostByID(c *gin.Context) {
	// Parse post ID from path
	postIDStr := c.Param("id")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid post ID", err.Error())
		return
	}

	// Get user ID from context (optional)
	userIDStr, _ := middleware.GetUserID(c)
	userID, _ := uuid.Parse(userIDStr)

	// Call usecase
	postDetails, err := h.postUsecase.GetPostWithDetails(c.Request.Context(), postID, userID)
	if err != nil {
		if err == postUsecase.ErrPostNotFound {
			response.NotFound(c, "Post not found")
			return
		}
		response.InternalError(c, "Failed to get post", err.Error())
		return
	}

	// Transform to Flutter-compatible response format
	postResponse := postDetails.ToResponse()

	response.Success(c, http.StatusOK, "Post retrieved successfully", postResponse)
}

// UpdatePost godoc
// @Summary Update post
// @Description Update an existing post (author only)
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Post ID" format(uuid)
// @Param request body post.UpdatePostRequest true "Post update data"
// @Success 200 {object} response.Response{data=post.Post}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/{id} [put]
func (h *PostHandler) UpdatePost(c *gin.Context) {
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

	// Parse post ID from path
	postIDStr := c.Param("id")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid post ID", err.Error())
		return
	}

	var req post.UpdatePostRequest

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
	updatedPost, err := h.postUsecase.UpdatePost(c.Request.Context(), postID, userID, &req)
	if err != nil {
		if err == postUsecase.ErrPostNotFound {
			response.NotFound(c, "Post not found")
			return
		}
		if err == postUsecase.ErrUnauthorized {
			response.Forbidden(c, "Only the post author can update this post")
			return
		}
		response.InternalError(c, "Failed to update post", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Post updated successfully", updatedPost)
}

// DeletePost godoc
// @Summary Delete post
// @Description Delete a post (author only)
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Post ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/{id} [delete]
func (h *PostHandler) DeletePost(c *gin.Context) {
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

	// Parse post ID from path
	postIDStr := c.Param("id")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid post ID", err.Error())
		return
	}

	// Call usecase
	if err := h.postUsecase.DeletePost(c.Request.Context(), postID, userID); err != nil {
		if err == postUsecase.ErrPostNotFound {
			response.NotFound(c, "Post not found")
			return
		}
		if err == postUsecase.ErrUnauthorized {
			response.Forbidden(c, "Only the post author can delete this post")
			return
		}
		response.InternalError(c, "Failed to delete post", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Post deleted successfully", nil)
}

// LikePost godoc
// @Summary Like a post
// @Description Like a post
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Post ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 409 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/{id}/like [post]
func (h *PostHandler) LikePost(c *gin.Context) {
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

	// Parse post ID from path
	postIDStr := c.Param("id")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid post ID", err.Error())
		return
	}

	// Call usecase
	if err := h.postUsecase.LikePost(c.Request.Context(), postID, userID); err != nil {
		if err == postUsecase.ErrPostNotFound {
			response.NotFound(c, "Post not found")
			return
		}
		if err == postUsecase.ErrAlreadyLiked {
			response.Conflict(c, "Post already liked", err.Error())
			return
		}
		response.InternalError(c, "Failed to like post", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Post liked successfully", nil)
}

// UnlikePost godoc
// @Summary Unlike a post
// @Description Remove like from a post
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Post ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/{id}/unlike [post]
func (h *PostHandler) UnlikePost(c *gin.Context) {
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

	// Parse post ID from path
	postIDStr := c.Param("id")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid post ID", err.Error())
		return
	}

	// Call usecase
	if err := h.postUsecase.UnlikePost(c.Request.Context(), postID, userID); err != nil {
		if err == postUsecase.ErrPostNotFound {
			response.NotFound(c, "Post not found")
			return
		}
		if err == postUsecase.ErrNotLiked {
			response.BadRequest(c, "Post not liked", err.Error())
			return
		}
		response.InternalError(c, "Failed to unlike post", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Post unliked successfully", nil)
}

// RepostPost godoc
// @Summary Repost a post
// @Description Repost or quote a post
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body post.RepostRequest true "Repost data"
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 409 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/repost [post]
func (h *PostHandler) RepostPost(c *gin.Context) {
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

	var req post.RepostRequest

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
	if err := h.postUsecase.RepostPost(c.Request.Context(), userID, &req); err != nil {
		if err == postUsecase.ErrPostNotFound {
			response.NotFound(c, "Post not found")
			return
		}
		if err == postUsecase.ErrCannotRepostOwn {
			response.BadRequest(c, "Cannot repost your own post", err.Error())
			return
		}
		if err == postUsecase.ErrAlreadyReposted {
			response.Conflict(c, "Post already reposted", err.Error())
			return
		}
		response.InternalError(c, "Failed to repost post", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Post reposted successfully", nil)
}

// UndoRepost godoc
// @Summary Undo repost
// @Description Remove a repost
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Post ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/{id}/undo-repost [post]
func (h *PostHandler) UndoRepost(c *gin.Context) {
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

	// Parse post ID from path
	postIDStr := c.Param("id")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid post ID", err.Error())
		return
	}

	// Call usecase
	if err := h.postUsecase.UndoRepost(c.Request.Context(), postID, userID); err != nil {
		if err == postUsecase.ErrPostNotFound {
			response.NotFound(c, "Post not found")
			return
		}
		if err == postUsecase.ErrNotReposted {
			response.BadRequest(c, "Post not reposted", err.Error())
			return
		}
		response.InternalError(c, "Failed to undo repost", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Repost undone successfully", nil)
}

// AddComment godoc
// @Summary Add comment to post
// @Description Add a comment or reply to a post
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body comment.CreateCommentRequest true "Comment data"
// @Success 201 {object} response.Response{data=comment.Comment}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/comments [post]
func (h *PostHandler) AddComment(c *gin.Context) {
	// Get user ID from context
	authorIDStr, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "User not authenticated")
		return
	}

	authorID, err := uuid.Parse(authorIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid user ID", err.Error())
		return
	}

	var req comment.CreateCommentRequest

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
	newCommentWithDetails, err := h.postUsecase.CreateComment(c.Request.Context(), authorID, &req)
	if err != nil {
		if err == postUsecase.ErrPostNotFound {
			response.NotFound(c, "Post not found")
			return
		}
		if err == postUsecase.ErrCommentNotFound {
			response.NotFound(c, "Parent comment not found")
			return
		}
		response.InternalError(c, "Failed to add comment", err.Error())
		return
	}

	response.Success(c, http.StatusCreated, "Comment added successfully", newCommentWithDetails)
}

// GetComments godoc
// @Summary Get post comments
// @Description Get comments for a specific post
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Post ID" format(uuid)
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]comment.CommentWithDetails}
// @Failure 400 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/{id}/comments [get]
func (h *PostHandler) GetComments(c *gin.Context) {
	// Parse post ID from path
	postIDStr := c.Param("id")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid post ID", err.Error())
		return
	}

	// Get user ID from context (optional)
	userIDStr, _ := middleware.GetUserID(c)
	userID, _ := uuid.Parse(userIDStr)

	// Parse query parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Call usecase
	comments, err := h.postUsecase.GetCommentsByPost(c.Request.Context(), postID, userID, limit, offset)
	if err != nil {
		if err == postUsecase.ErrPostNotFound {
			response.NotFound(c, "Post not found")
			return
		}
		response.InternalError(c, "Failed to get comments", err.Error())
		return
	}

	// Ensure we return empty array instead of null
	if comments == nil {
		comments = []comment.CommentWithDetails{}
	}

	response.Success(c, http.StatusOK, "Comments retrieved successfully", comments)
}

// UpdateComment godoc
// @Summary Update comment
// @Description Update a comment (author only)
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Comment ID" format(uuid)
// @Param request body comment.UpdateCommentRequest true "Comment update data"
// @Success 200 {object} response.Response{data=comment.Comment}
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/comments/{id} [put]
func (h *PostHandler) UpdateComment(c *gin.Context) {
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

	// Parse comment ID from path
	commentIDStr := c.Param("id")
	commentID, err := uuid.Parse(commentIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid comment ID", err.Error())
		return
	}

	var req comment.UpdateCommentRequest

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
	updatedComment, err := h.postUsecase.UpdateComment(c.Request.Context(), commentID, userID, &req)
	if err != nil {
		if err == postUsecase.ErrCommentNotFound {
			response.NotFound(c, "Comment not found")
			return
		}
		if err == postUsecase.ErrUnauthorized {
			response.Forbidden(c, "Only the comment author can update this comment")
			return
		}
		response.InternalError(c, "Failed to update comment", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Comment updated successfully", updatedComment)
}

// DeleteComment godoc
// @Summary Delete comment
// @Description Delete a comment (author only)
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Comment ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 403 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/comments/{id} [delete]
func (h *PostHandler) DeleteComment(c *gin.Context) {
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

	// Parse comment ID from path
	commentIDStr := c.Param("id")
	commentID, err := uuid.Parse(commentIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid comment ID", err.Error())
		return
	}

	// Call usecase
	if err := h.postUsecase.DeleteComment(c.Request.Context(), commentID, userID); err != nil {
		if err == postUsecase.ErrCommentNotFound {
			response.NotFound(c, "Comment not found")
			return
		}
		if err == postUsecase.ErrUnauthorized {
			response.Forbidden(c, "Only the comment author can delete this comment")
			return
		}
		response.InternalError(c, "Failed to delete comment", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Comment deleted successfully", nil)
}

// LikeComment godoc
// @Summary Like a comment
// @Description Like a comment on a post
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param postId path string true "Post ID" format(uuid)
// @Param commentId path string true "Comment ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 409 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/{postId}/comments/{commentId}/like [post]
func (h *PostHandler) LikeComment(c *gin.Context) {
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

	// Parse comment ID from path
	commentIDStr := c.Param("commentId")
	commentID, err := uuid.Parse(commentIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid comment ID", err.Error())
		return
	}

	// Call usecase
	if err := h.postUsecase.LikeComment(c.Request.Context(), commentID, userID); err != nil {
		if err == postUsecase.ErrCommentNotFound {
			response.NotFound(c, "Comment not found")
			return
		}
		if err == postUsecase.ErrAlreadyLiked {
			response.Conflict(c, "Comment already liked", err.Error())
			return
		}
		response.InternalError(c, "Failed to like comment", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Comment liked successfully", nil)
}

// UnlikeComment godoc
// @Summary Unlike a comment
// @Description Remove like from a comment
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param postId path string true "Post ID" format(uuid)
// @Param commentId path string true "Comment ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/{postId}/comments/{commentId}/unlike [post]
func (h *PostHandler) UnlikeComment(c *gin.Context) {
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

	// Parse comment ID from path
	commentIDStr := c.Param("commentId")
	commentID, err := uuid.Parse(commentIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid comment ID", err.Error())
		return
	}

	// Call usecase
	if err := h.postUsecase.UnlikeComment(c.Request.Context(), commentID, userID); err != nil {
		if err == postUsecase.ErrCommentNotFound {
			response.NotFound(c, "Comment not found")
			return
		}
		if err == postUsecase.ErrNotLiked {
			response.BadRequest(c, "Comment not liked", err.Error())
			return
		}
		response.InternalError(c, "Failed to unlike comment", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Comment unliked successfully", nil)
}

// BookmarkPost godoc
// @Summary Bookmark a post
// @Description Bookmark a post for later viewing
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Post ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 409 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/{id}/bookmark [post]
func (h *PostHandler) BookmarkPost(c *gin.Context) {
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

	// Parse post ID from path
	postIDStr := c.Param("id")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid post ID", err.Error())
		return
	}

	// Call usecase
	if err := h.postUsecase.BookmarkPost(c.Request.Context(), postID, userID); err != nil {
		if err == postUsecase.ErrPostNotFound {
			response.NotFound(c, "Post not found")
			return
		}
		if err == postUsecase.ErrAlreadyBookmarked {
			response.Conflict(c, "Post already bookmarked", err.Error())
			return
		}
		response.InternalError(c, "Failed to bookmark post", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Post bookmarked successfully", nil)
}

// RemoveBookmark godoc
// @Summary Remove bookmark from a post
// @Description Remove a bookmark from a post
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Post ID" format(uuid)
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Failure 401 {object} response.Response
// @Failure 404 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/{id}/bookmark [delete]
func (h *PostHandler) RemoveBookmark(c *gin.Context) {
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

	// Parse post ID from path
	postIDStr := c.Param("id")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		response.BadRequest(c, "Invalid post ID", err.Error())
		return
	}

	// Call usecase
	if err := h.postUsecase.RemoveBookmark(c.Request.Context(), postID, userID); err != nil {
		if err == postUsecase.ErrPostNotFound {
			response.NotFound(c, "Post not found")
			return
		}
		if err == postUsecase.ErrNotBookmarked {
			response.BadRequest(c, "Post not bookmarked", err.Error())
			return
		}
		response.InternalError(c, "Failed to remove bookmark", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Bookmark removed successfully", nil)
}

// GetBookmarks godoc
// @Summary Get bookmarked posts
// @Description Get all posts bookmarked by the current user
// @Tags posts
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} response.Response{data=[]post.PostWithDetails}
// @Failure 401 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /posts/bookmarks [get]
func (h *PostHandler) GetBookmarks(c *gin.Context) {
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

	// Parse query parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Get total count for pagination
	total, err := h.postUsecase.CountBookmarks(c.Request.Context(), userID)
	if err != nil {
		// If count fails, default to 0 but continue
		total = 0
	}

	// Get bookmarked posts
	posts, err := h.postUsecase.GetBookmarks(c.Request.Context(), userID, limit, offset)
	if err != nil {
		response.InternalError(c, "Failed to get bookmarks", err.Error())
		return
	}

	// Transform to Flutter-compatible response format
	postResponses := make([]post.PostResponse, len(posts))
	for i, p := range posts {
		postResponses[i] = p.ToResponse()
	}

	// Ensure we return empty array instead of null
	if postResponses == nil {
		postResponses = []post.PostResponse{}
	}

	// Create pagination metadata with correct total
	meta := response.NewPaginationMeta(total, limit, offset, len(posts))
	response.Paginated(c, http.StatusOK, "Bookmarks retrieved successfully", postResponses, meta)
}
