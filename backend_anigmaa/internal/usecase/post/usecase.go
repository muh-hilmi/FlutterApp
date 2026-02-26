package post

import (
	"context"
	"errors"
	"log"
	"time"

	"github.com/anigmaa/backend/internal/domain/comment"
	"github.com/anigmaa/backend/internal/domain/event"
	"github.com/anigmaa/backend/internal/domain/interaction"
	"github.com/anigmaa/backend/internal/domain/post"
	"github.com/anigmaa/backend/internal/domain/user"
	"github.com/google/uuid"
)

var (
	ErrPostNotFound      = errors.New("post not found")
	ErrCommentNotFound   = errors.New("comment not found")
	ErrUnauthorized      = errors.New("unauthorized - not post/comment author")
	ErrAlreadyLiked      = errors.New("already liked")
	ErrNotLiked          = errors.New("not liked")
	ErrAlreadyReposted   = errors.New("already reposted")
	ErrNotReposted       = errors.New("not reposted")
	ErrAlreadyBookmarked = errors.New("already bookmarked")
	ErrNotBookmarked     = errors.New("not bookmarked")
	ErrCannotRepostOwn   = errors.New("cannot repost your own post")
	ErrEventNotFound     = errors.New("attached event not found")
)

// Usecase handles post business logic
type Usecase struct {
	postRepo        post.Repository
	commentRepo     comment.Repository
	interactionRepo interaction.Repository
	eventRepo       event.Repository
	userRepo        user.Repository
}

// NewUsecase creates a new post usecase
func NewUsecase(
	postRepo post.Repository,
	commentRepo comment.Repository,
	interactionRepo interaction.Repository,
	eventRepo event.Repository,
	userRepo user.Repository,
) *Usecase {
	return &Usecase{
		postRepo:        postRepo,
		commentRepo:     commentRepo,
		interactionRepo: interactionRepo,
		eventRepo:       eventRepo,
		userRepo:        userRepo,
	}
}

// CreatePost creates a new post
func (uc *Usecase) CreatePost(ctx context.Context, authorID uuid.UUID, req *post.CreatePostRequest) (*post.Post, error) {
	// Verify author exists
	_, err := uc.userRepo.GetByID(ctx, authorID)
	if err != nil {
		return nil, errors.New("author user not found")
	}

	// Verify attached event exists (only if provided)
	var attachedEventID uuid.UUID
	if req.AttachedEventID != nil && *req.AttachedEventID != uuid.Nil {
		_, err = uc.eventRepo.GetByID(ctx, *req.AttachedEventID)
		if err != nil {
			return nil, ErrEventNotFound
		}
		attachedEventID = *req.AttachedEventID
	}

	// Create post
	now := time.Now()
	newPost := &post.Post{
		ID:              uuid.New(),
		AuthorID:        authorID,
		Content:         req.Content,
		Type:            req.Type,
		AttachedEventID: attachedEventID,
		Visibility:      req.Visibility,
		CreatedAt:       now,
		UpdatedAt:       now,
		LikesCount:      0,
		CommentsCount:   0,
		RepostsCount:    0,
		SharesCount:     0,
	}

	if err := uc.postRepo.Create(ctx, newPost); err != nil {
		return nil, err
	}

	// Add images if provided
	if len(req.ImageURLs) > 0 {
		images := make([]post.PostImage, len(req.ImageURLs))
		for i, url := range req.ImageURLs {
			images[i] = post.PostImage{
				ID:       uuid.New(),
				PostID:   newPost.ID,
				ImageURL: url,
				Order:    i,
			}
		}
		if err := uc.postRepo.AddImages(ctx, images); err != nil {
			// Log error but don't fail post creation
		}
	}

	return newPost, nil
}

// GetPostByID gets a post by ID
func (uc *Usecase) GetPostByID(ctx context.Context, postID uuid.UUID) (*post.Post, error) {
	p, err := uc.postRepo.GetByID(ctx, postID)
	if err != nil {
		return nil, ErrPostNotFound
	}
	return p, nil
}

// GetPostWithDetails gets a post with all details for a specific user
func (uc *Usecase) GetPostWithDetails(ctx context.Context, postID, userID uuid.UUID) (*post.PostWithDetails, error) {
	p, err := uc.postRepo.GetWithDetails(ctx, postID, userID)
	if err != nil {
		return nil, ErrPostNotFound
	}
	return p, nil
}

// UpdatePost updates a post
func (uc *Usecase) UpdatePost(ctx context.Context, postID, userID uuid.UUID, req *post.UpdatePostRequest) (*post.Post, error) {
	// Get existing post
	existingPost, err := uc.postRepo.GetByID(ctx, postID)
	if err != nil {
		return nil, ErrPostNotFound
	}

	// Check if user is the author
	if existingPost.AuthorID != userID {
		return nil, ErrUnauthorized
	}

	// Update fields if provided
	if req.Content != nil {
		existingPost.Content = *req.Content
	}
	if req.Visibility != nil {
		existingPost.Visibility = *req.Visibility
	}

	existingPost.UpdatedAt = time.Now()

	// Save changes
	if err := uc.postRepo.Update(ctx, existingPost); err != nil {
		return nil, err
	}

	return existingPost, nil
}

// DeletePost deletes a post
func (uc *Usecase) DeletePost(ctx context.Context, postID, userID uuid.UUID) error {
	// Get existing post
	existingPost, err := uc.postRepo.GetByID(ctx, postID)
	if err != nil {
		return ErrPostNotFound
	}

	// Check if user is the author
	if existingPost.AuthorID != userID {
		return ErrUnauthorized
	}

	return uc.postRepo.Delete(ctx, postID)
}

// ArchivePost archives a post
func (uc *Usecase) ArchivePost(ctx context.Context, postID, userID uuid.UUID) (*post.Post, error) {
	// Get existing post
	existingPost, err := uc.postRepo.GetByID(ctx, postID)
	if err != nil {
		return nil, ErrPostNotFound
	}

	// Check if user is the author
	if existingPost.AuthorID != userID {
		return nil, ErrUnauthorized
	}

	// Archive the post
	existingPost.IsArchived = true
	existingPost.UpdatedAt = time.Now()

	if err := uc.postRepo.Update(ctx, existingPost); err != nil {
		return nil, err
	}

	return existingPost, nil
}

// UnarchivePost unarchives a post
func (uc *Usecase) UnarchivePost(ctx context.Context, postID, userID uuid.UUID) (*post.Post, error) {
	// Get existing post
	existingPost, err := uc.postRepo.GetByID(ctx, postID)
	if err != nil {
		return nil, ErrPostNotFound
	}

	// Check if user is the author
	if existingPost.AuthorID != userID {
		return nil, ErrUnauthorized
	}

	// Unarchive the post
	existingPost.IsArchived = false
	existingPost.UpdatedAt = time.Now()

	if err := uc.postRepo.Update(ctx, existingPost); err != nil {
		return nil, err
	}

	return existingPost, nil
}

// GetFeed gets a user's personalized feed
func (uc *Usecase) GetFeed(ctx context.Context, userID uuid.UUID, limit, offset int) ([]post.PostWithDetails, error) {
	// DEBUG: Log input parameters
	log.Printf("DEBUG: GetFeed called with userID=%v, limit=%d, offset=%d", userID, limit, offset)

	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	// Repository layer already sets IsLikedByUser via SQL EXISTS subquery
	// No need for batch query - it was causing the value to be overwritten incorrectly
	posts, err := uc.postRepo.GetFeed(ctx, userID, limit, offset)
	if err != nil {
		log.Printf("DEBUG: GetFeed error: %v", err)
		return nil, err
	}

	// DEBUG: Log results from repository
	log.Printf("DEBUG: GetFeed repository returned %d posts", len(posts))
	for i, p := range posts {
		log.Printf("DEBUG: Repository Post[%d] ID=%v, IsLikedByUser=%v", i, p.ID, p.IsLikedByUser)
	}

	return posts, nil
}

// CountFeed counts total posts in user's feed
func (uc *Usecase) CountFeed(ctx context.Context, userID uuid.UUID) (int, error) {
	return uc.postRepo.CountFeed(ctx, userID)
}

// GetUserPosts gets posts by a specific user
func (uc *Usecase) GetUserPosts(ctx context.Context, authorID, viewerID uuid.UUID, limit, offset int) ([]post.PostWithDetails, error) {
	// Verify author exists
	_, err := uc.userRepo.GetByID(ctx, authorID)
	if err != nil {
		return nil, errors.New("author user not found")
	}

	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	return uc.postRepo.GetUserPosts(ctx, authorID, viewerID, limit, offset)
}

// CountUserPosts counts total posts by a user
func (uc *Usecase) CountUserPosts(ctx context.Context, authorID uuid.UUID) (int, error) {
	return uc.postRepo.CountUserPosts(ctx, authorID)
}

// ListPosts lists posts with filters
func (uc *Usecase) ListPosts(ctx context.Context, filter *post.PostFilter, userID uuid.UUID) ([]post.PostWithDetails, error) {
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}

	return uc.postRepo.List(ctx, filter, userID)
}

// LikePost likes a post
func (uc *Usecase) LikePost(ctx context.Context, postID, userID uuid.UUID) error {
	// Check if post exists
	_, err := uc.postRepo.GetByID(ctx, postID)
	if err != nil {
		return ErrPostNotFound
	}

	// Check if already liked
	isLiked, err := uc.interactionRepo.IsLiked(ctx, userID, interaction.LikeablePost, postID)
	if err != nil {
		return err
	}
	if isLiked {
		return ErrAlreadyLiked
	}

	// Create like
	like := &interaction.Like{
		ID:           uuid.New(),
		UserID:       userID,
		LikeableType: interaction.LikeablePost,
		LikeableID:   postID,
		CreatedAt:    time.Now(),
	}

	if err := uc.interactionRepo.Like(ctx, like); err != nil {
		return err
	}

	// Note: likes_count is updated by DB trigger on the likes table — do not call IncrementLikes here
	return nil
}

// UnlikePost unlikes a post
func (uc *Usecase) UnlikePost(ctx context.Context, postID, userID uuid.UUID) error {
	// Check if post exists
	_, err := uc.postRepo.GetByID(ctx, postID)
	if err != nil {
		return ErrPostNotFound
	}

	// Check if liked
	isLiked, err := uc.interactionRepo.IsLiked(ctx, userID, interaction.LikeablePost, postID)
	if err != nil {
		return err
	}
	if !isLiked {
		return ErrNotLiked
	}

	// Remove like
	if err := uc.interactionRepo.Unlike(ctx, userID, interaction.LikeablePost, postID); err != nil {
		return err
	}

	// Note: likes_count is updated by DB trigger on the likes table — do not call DecrementLikes here
	return nil
}

// RepostPost reposts a post
func (uc *Usecase) RepostPost(ctx context.Context, userID uuid.UUID, req *post.RepostRequest) error {
	// Check if post exists
	originalPost, err := uc.postRepo.GetByID(ctx, req.PostID)
	if err != nil {
		return ErrPostNotFound
	}

	// Check if trying to repost own post
	if originalPost.AuthorID == userID {
		return ErrCannotRepostOwn
	}

	// Check if already reposted
	isReposted, err := uc.interactionRepo.IsReposted(ctx, userID, req.PostID)
	if err != nil {
		return err
	}
	if isReposted {
		return ErrAlreadyReposted
	}

	// Create repost
	repost := &interaction.Repost{
		ID:           uuid.New(),
		UserID:       userID,
		PostID:       req.PostID,
		QuoteContent: req.QuoteContent,
		CreatedAt:    time.Now(),
	}

	if err := uc.interactionRepo.Repost(ctx, repost); err != nil {
		return err
	}

	// Increment reposts count
	return uc.postRepo.IncrementReposts(ctx, req.PostID)
}

// UndoRepost undoes a repost
func (uc *Usecase) UndoRepost(ctx context.Context, postID, userID uuid.UUID) error {
	// Check if post exists
	_, err := uc.postRepo.GetByID(ctx, postID)
	if err != nil {
		return ErrPostNotFound
	}

	// Check if reposted
	isReposted, err := uc.interactionRepo.IsReposted(ctx, userID, postID)
	if err != nil {
		return err
	}
	if !isReposted {
		return ErrNotReposted
	}

	// Remove repost
	if err := uc.interactionRepo.UndoRepost(ctx, userID, postID); err != nil {
		return err
	}

	// Decrement reposts count
	return uc.postRepo.DecrementReposts(ctx, postID)
}

// BookmarkPost bookmarks a post
func (uc *Usecase) BookmarkPost(ctx context.Context, postID, userID uuid.UUID) error {
	// Check if post exists
	_, err := uc.postRepo.GetByID(ctx, postID)
	if err != nil {
		return ErrPostNotFound
	}

	// Check if already bookmarked
	isBookmarked, err := uc.interactionRepo.IsBookmarked(ctx, userID, postID)
	if err != nil {
		return err
	}
	if isBookmarked {
		return ErrAlreadyBookmarked
	}

	// Create bookmark
	bookmark := &interaction.Bookmark{
		ID:        uuid.New(),
		UserID:    userID,
		PostID:    postID,
		CreatedAt: time.Now(),
	}

	return uc.interactionRepo.Bookmark(ctx, bookmark)
}

// RemoveBookmark removes a bookmark
func (uc *Usecase) RemoveBookmark(ctx context.Context, postID, userID uuid.UUID) error {
	// Check if bookmarked
	isBookmarked, err := uc.interactionRepo.IsBookmarked(ctx, userID, postID)
	if err != nil {
		return err
	}
	if !isBookmarked {
		return ErrNotBookmarked
	}

	return uc.interactionRepo.RemoveBookmark(ctx, userID, postID)
}

// GetBookmarks gets a user's bookmarked posts with full post details
func (uc *Usecase) GetBookmarks(ctx context.Context, userID uuid.UUID, limit, offset int) ([]post.PostWithDetails, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	// CTO REVIEW: PERFORMANCE - N+1 Query Problem
	// Issue: Fetching bookmarks then looping to get each post individually
	// If user has 20 bookmarks, this makes 21 database queries (1 + 20)
	// Impact: Slow response time, high database load, poor scalability
	// Fix: Create single repository method GetBookmarkedPostsWithDetails that uses JOIN
	//   SELECT p.*, b.created_at as bookmarked_at FROM posts p
	//   INNER JOIN bookmarks b ON p.id = b.post_id
	//   WHERE b.user_id = $1 ORDER BY b.created_at DESC LIMIT $2 OFFSET $3
	// Priority: MEDIUM - Should fix before scaling

	// Get bookmark records
	bookmarks, err := uc.interactionRepo.GetBookmarks(ctx, userID, limit, offset)
	if err != nil {
		return nil, err
	}

	// If no bookmarks, return empty array
	if len(bookmarks) == 0 {
		return []post.PostWithDetails{}, nil
	}

	// Get full post details for each bookmarked post
	posts := make([]post.PostWithDetails, 0, len(bookmarks))
	for _, bookmark := range bookmarks {
		postDetails, err := uc.GetPostWithDetails(ctx, bookmark.PostID, userID)
		if err != nil {
			// Skip posts that were deleted or have errors
			continue
		}
		posts = append(posts, *postDetails)
	}

	return posts, nil
}

// CountBookmarks counts total bookmarks for a user
func (uc *Usecase) CountBookmarks(ctx context.Context, userID uuid.UUID) (int, error) {
	return uc.interactionRepo.CountBookmarks(ctx, userID)
}

// SharePost tracks a post share
func (uc *Usecase) SharePost(ctx context.Context, postID, userID uuid.UUID, platform *string) error {
	// Check if post exists
	_, err := uc.postRepo.GetByID(ctx, postID)
	if err != nil {
		return ErrPostNotFound
	}

	// Create share record
	share := &interaction.Share{
		ID:        uuid.New(),
		UserID:    userID,
		PostID:    postID,
		Platform:  platform,
		CreatedAt: time.Now(),
	}

	if err := uc.interactionRepo.Share(ctx, share); err != nil {
		return err
	}

	// Increment shares count
	return uc.postRepo.IncrementShares(ctx, postID)
}

// CreateComment creates a comment on a post
func (uc *Usecase) CreateComment(ctx context.Context, authorID uuid.UUID, req *comment.CreateCommentRequest) (*comment.CommentWithDetails, error) {
	// Check if post exists
	_, err := uc.postRepo.GetByID(ctx, req.PostID)
	if err != nil {
		return nil, ErrPostNotFound
	}

	// If parent comment is specified, verify it exists
	if req.ParentCommentID != nil {
		_, err := uc.commentRepo.GetByID(ctx, *req.ParentCommentID)
		if err != nil {
			return nil, ErrCommentNotFound
		}
	}

	// Create comment
	now := time.Now()
	newComment := &comment.Comment{
		ID:              uuid.New(),
		PostID:          req.PostID,
		AuthorID:        authorID,
		ParentCommentID: req.ParentCommentID,
		Content:         req.Content,
		CreatedAt:       now,
		UpdatedAt:       now,
		LikesCount:      0,
	}

	if err := uc.commentRepo.Create(ctx, newComment); err != nil {
		return nil, err
	}

	// Note: comments_count is automatically updated via database trigger (update_comments_count_trigger)
	// No manual increment needed here

	// Fetch comment with details to include author info
	commentWithDetails, err := uc.commentRepo.GetWithDetails(ctx, newComment.ID, authorID)
	if err != nil {
		// If we can't get details, return basic comment data with empty details
		// This shouldn't happen but provides a fallback
		return &comment.CommentWithDetails{
			Comment:          *newComment,
			AuthorName:       "",
			AuthorAvatarURL:  nil,
			AuthorIsVerified: false,
			IsLikedByUser:    false,
			RepliesCount:     0,
		}, nil
	}

	return commentWithDetails, nil
}

// UpdateComment updates a comment
func (uc *Usecase) UpdateComment(ctx context.Context, commentID, userID uuid.UUID, req *comment.UpdateCommentRequest) (*comment.Comment, error) {
	// Get existing comment
	existingComment, err := uc.commentRepo.GetByID(ctx, commentID)
	if err != nil {
		return nil, ErrCommentNotFound
	}

	// Check if user is the author
	if existingComment.AuthorID != userID {
		return nil, ErrUnauthorized
	}

	// Update content
	existingComment.Content = req.Content
	existingComment.UpdatedAt = time.Now()

	// Save changes
	if err := uc.commentRepo.Update(ctx, existingComment); err != nil {
		return nil, err
	}

	return existingComment, nil
}

// DeleteComment deletes a comment
func (uc *Usecase) DeleteComment(ctx context.Context, commentID, userID uuid.UUID) error {
	// Get existing comment
	existingComment, err := uc.commentRepo.GetByID(ctx, commentID)
	if err != nil {
		return ErrCommentNotFound
	}

	// Check if user is the author
	if existingComment.AuthorID != userID {
		return ErrUnauthorized
	}

	// Delete comment
	if err := uc.commentRepo.Delete(ctx, commentID); err != nil {
		return err
	}

	// Note: comments_count is automatically updated via database trigger (update_comments_count_trigger)
	// No manual decrement needed here

	return nil
}

// GetCommentsByPost gets comments for a post
func (uc *Usecase) GetCommentsByPost(ctx context.Context, postID, userID uuid.UUID, limit, offset int) ([]comment.CommentWithDetails, error) {
	// Check if post exists
	_, err := uc.postRepo.GetByID(ctx, postID)
	if err != nil {
		return nil, ErrPostNotFound
	}

	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	return uc.commentRepo.GetByPost(ctx, postID, userID, limit, offset)
}

// GetCommentReplies gets replies to a comment
func (uc *Usecase) GetCommentReplies(ctx context.Context, parentCommentID, userID uuid.UUID, limit, offset int) ([]comment.CommentWithDetails, error) {
	// Check if parent comment exists
	_, err := uc.commentRepo.GetByID(ctx, parentCommentID)
	if err != nil {
		return nil, ErrCommentNotFound
	}

	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	return uc.commentRepo.GetReplies(ctx, parentCommentID, userID, limit, offset)
}

// LikeComment likes a comment
func (uc *Usecase) LikeComment(ctx context.Context, commentID, userID uuid.UUID) error {
	// Check if comment exists
	_, err := uc.commentRepo.GetByID(ctx, commentID)
	if err != nil {
		return ErrCommentNotFound
	}

	// Check if already liked
	isLiked, err := uc.interactionRepo.IsLiked(ctx, userID, interaction.LikeableComment, commentID)
	if err != nil {
		return err
	}
	if isLiked {
		return ErrAlreadyLiked
	}

	// Create like
	like := &interaction.Like{
		ID:           uuid.New(),
		UserID:       userID,
		LikeableType: interaction.LikeableComment,
		LikeableID:   commentID,
		CreatedAt:    time.Now(),
	}

	if err := uc.interactionRepo.Like(ctx, like); err != nil {
		return err
	}

	// Note: likes_count is updated by DB trigger on the likes table — do not call IncrementLikes here
	return nil
}

// UnlikeComment unlikes a comment
func (uc *Usecase) UnlikeComment(ctx context.Context, commentID, userID uuid.UUID) error {
	// Check if comment exists
	_, err := uc.commentRepo.GetByID(ctx, commentID)
	if err != nil {
		return ErrCommentNotFound
	}

	// Check if liked
	isLiked, err := uc.interactionRepo.IsLiked(ctx, userID, interaction.LikeableComment, commentID)
	if err != nil {
		return err
	}
	if !isLiked {
		return ErrNotLiked
	}

	// Remove like
	if err := uc.interactionRepo.Unlike(ctx, userID, interaction.LikeableComment, commentID); err != nil {
		return err
	}

	// Note: likes_count is updated by DB trigger on the likes table — do not call DecrementLikes here
	return nil
}

// GetPublicPosts gets all public posts (for unauthenticated users)
func (uc *Usecase) GetPublicPosts(ctx context.Context, limit, offset int) ([]post.PostWithDetails, error) {
	// DEBUG: Log public feed request
	log.Printf("DEBUG: GetPublicPosts called with limit=%d, offset=%d", limit, offset)

	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	// Use a nil userID to indicate no user context - returns public posts only
	posts, err := uc.postRepo.GetFeed(ctx, uuid.Nil, limit, offset)
	if err != nil {
		log.Printf("DEBUG: GetPublicPosts error: %v", err)
		return nil, err
	}

	// DEBUG: Log public posts results
	log.Printf("DEBUG: GetPublicPosts returned %d posts", len(posts))
	for i, p := range posts {
		log.Printf("DEBUG: Public Post[%d] ID=%v, IsLikedByUser=%v", i, p.ID, p.IsLikedByUser)
	}

	// For public posts, there's no user context, so IsLikedByUser should always be false
	// This is already set correctly by the repository layer when userID is uuid.Nil
	return posts, nil
}

// CountPublicPosts counts total public posts
func (uc *Usecase) CountPublicPosts(ctx context.Context) (int, error) {
	// Use nil userID to count all public posts
	return uc.postRepo.CountFeed(ctx, uuid.Nil)
}
