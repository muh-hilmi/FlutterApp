package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/anigmaa/backend/config"
	_ "github.com/anigmaa/backend/docs"
	"github.com/anigmaa/backend/internal/delivery/http/handler"
	"github.com/anigmaa/backend/internal/delivery/http/middleware"
	"github.com/anigmaa/backend/internal/infrastructure/cache"
	"github.com/anigmaa/backend/internal/infrastructure/database"
	"github.com/anigmaa/backend/internal/infrastructure/payment"
	"github.com/anigmaa/backend/internal/infrastructure/storage"
	"github.com/anigmaa/backend/internal/repository/postgres"
	"github.com/anigmaa/backend/internal/usecase/analytics"
	"github.com/anigmaa/backend/internal/usecase/community"
	"github.com/anigmaa/backend/internal/usecase/event"
	"github.com/anigmaa/backend/internal/usecase/feed_ranking"
	"github.com/anigmaa/backend/internal/usecase/post"
	"github.com/anigmaa/backend/internal/usecase/qna"
	"github.com/anigmaa/backend/internal/usecase/ticket"
	"github.com/anigmaa/backend/internal/usecase/user"
	"github.com/anigmaa/backend/pkg/jwt"
	"github.com/anigmaa/backend/pkg/validator"
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

// @title           Anigmaa Backend API
// @version         1.0
// @description     Backend API for Anigmaa event and social platform
// @termsOfService  http://swagger.io/terms/

// @contact.name   API Support
// @contact.email  support@anigmaa.com

// @license.name  Apache 2.0
// @license.url   http://www.apache.org/licenses/LICENSE-2.0.html

// @host      localhost:8081
// @BasePath  /api/v1

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and JWT token.

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Set Gin mode
	if cfg.Server.Env == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Initialize database connection
	db, err := database.NewPostgresDB(&cfg.Database)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()
	log.Println("✓ Connected to PostgreSQL database")

	// Run database migrations automatically
	if err := database.RunMigrations(db, "migrations/consolidated"); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}

	// Initialize Redis connection
	redisClient, err := cache.NewRedisClient(&cfg.Redis)
	if err != nil {
		log.Fatalf("Failed to connect to Redis: %v", err)
	}
	defer redisClient.Close()
	log.Println("✓ Connected to Redis cache")

	// Initialize validator
	validate := validator.New()

	// Initialize JWT manager
	jwtManager := jwt.NewJWTManager(cfg.JWT.Secret, cfg.JWT.Expiration, cfg.JWT.RefreshExpiration)

	// Initialize storage
	storageService, err := storage.NewStorage(&cfg.Storage)
	if err != nil {
		log.Fatalf("Failed to initialize storage: %v", err)
	}
	log.Printf("✓ Storage initialized (type: %s)", cfg.Storage.Type)

	// Initialize Midtrans payment client
	midtransClient := payment.NewMidtransClient(&cfg.Midtrans)
	log.Printf("✓ Midtrans client initialized (mode: %s)", map[bool]string{true: "production", false: "sandbox"}[cfg.Midtrans.IsProduction])

	// Initialize repositories
	userRepo := postgres.NewUserRepository(db)
	eventRepo := postgres.NewEventRepository(db)
	postRepo := postgres.NewPostRepository(db)
	commentRepo := postgres.NewCommentRepository(db)
	ticketRepo := postgres.NewTicketRepository(db)
	interactionRepo := postgres.NewInteractionRepository(db)
	qnaRepo := postgres.NewQnARepository(db)
	communityRepo := postgres.NewCommunityRepository(db)
	authTokenRepo := postgres.NewAuthTokenRepository(db)

	// Initialize use cases
	userUsecase := user.NewUsecase(userRepo, authTokenRepo, jwtManager, cfg.Google.ClientID)
	eventUsecase := event.NewUsecase(eventRepo, userRepo)
	postUsecase := post.NewUsecase(postRepo, commentRepo, interactionRepo, eventRepo, userRepo)
	ticketUsecase := ticket.NewUsecase(ticketRepo, eventRepo, userRepo, midtransClient)
	analyticsUsecase := analytics.NewUsecase(eventRepo, ticketRepo)
	qnaUsecase := qna.NewUsecase(qnaRepo, eventRepo)
	communityUsecase := community.NewUsecase(communityRepo)
	feedRanker := feed_ranking.NewRanker()

	// Initialize HTTP handlers
	authHandler := handler.NewAuthHandler(userUsecase, validate)
	userHandler := handler.NewUserHandler(userUsecase, validate)
	eventHandler := handler.NewEventHandler(eventUsecase, ticketUsecase, validate)
	postHandler := handler.NewPostHandler(postUsecase, validate)
	ticketHandler := handler.NewTicketHandler(ticketUsecase, validate)
	analyticsHandler := handler.NewAnalyticsHandler(analyticsUsecase)
	profileHandler := handler.NewProfileHandler(userUsecase, postUsecase, eventUsecase)
	qnaHandler := handler.NewQnAHandler(qnaUsecase, validate)
	uploadHandler := handler.NewUploadHandler(storageService)
	communityHandler := handler.NewCommunityHandler(communityUsecase, validate)
	paymentHandler := handler.NewPaymentHandler(midtransClient)
	feedRankingHandler := handler.NewFeedRankingHandler(feedRanker)

	// Setup router
	router := gin.Default()

	// Apply global middleware
	router.Use(middleware.CORS(cfg.CORS.AllowedOrigins))
	router.Use(middleware.Logger())
	router.Use(middleware.Recovery())

	// Swagger documentation
	router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// Static file serving for uploaded images
	// Serve files from the uploads directory at /uploads route
	router.Static("/uploads", cfg.Storage.UploadDir)

	// Health check endpoints
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"service": "anigmaa-backend",
			"version": "1.0.0",
		})
	})

	router.GET("/health/db", func(c *gin.Context) {
		if err := db.Ping(); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"status": "error",
				"error":  "database connection failed",
			})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"status": "ok",
			"db":     "connected",
		})
	})

	router.GET("/health/redis", func(c *gin.Context) {
		ctx := context.Background()
		if err := redisClient.Ping(ctx).Err(); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"status": "error",
				"error":  "redis connection failed",
			})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"status": "ok",
			"redis":  "connected",
		})
	})

	// CTO REVIEW: PRODUCTION BLOCKERS - Missing critical middleware
	// 1. NO RATE LIMITING - API is vulnerable to abuse/DDoS
	//    Fix: Add rate limiting middleware (e.g., gin-limiter, tollbooth)
	//    Recommended: 100 req/min per IP for public endpoints, 300 req/min for authenticated
	// 2. NO REQUEST TIMEOUT - Long-running queries can exhaust resources
	//    Fix: Add context timeout middleware (e.g., 30s max)
	// 3. NO ERROR MONITORING - No Sentry/Rollbar integration for production errors
	//    Fix: Add error tracking service integration
	// 4. NO GRACEFUL SHUTDOWN TESTING - Server may cut connections abruptly
	//    Fix: Verify graceful shutdown waits for in-flight requests (see line 340+)
	// 5. CORS might need adjustment for production domains
	//    Fix: Review CORS settings for production deployment
	// Priority: URGENT - These are production deployment blockers

	// API v1 routes
	v1 := router.Group("/api/v1")
	{
		// Public routes (no auth required)
		auth := v1.Group("/auth")
		{
			// Google OAuth only - traditional auth removed
			// Email verification removed - Google already verifies emails
			auth.POST("/google", authHandler.LoginWithGoogle)
		}

		// Protected routes (auth required)
		authMiddleware := middleware.JWTAuth(jwtManager)

		// Auth routes (with authentication)
		authProtected := v1.Group("/auth")
		authProtected.Use(authMiddleware)
		{
			authProtected.POST("/logout", authHandler.Logout)
			authProtected.POST("/refresh", authHandler.RefreshToken)
		}

		// User routes
		users := v1.Group("/users")
		users.Use(authMiddleware)
		{
			users.GET("/me", userHandler.GetMe)
			users.PUT("/me", userHandler.UpdateMe)
			users.PATCH("/me", userHandler.UpdateMe) // Support partial updates
			users.DELETE("/me", userHandler.DeleteAccount) // Delete account
			users.PUT("/me/settings", userHandler.UpdateSettings)
			users.GET("/search", userHandler.SearchUsers)
			users.GET("/:id", userHandler.GetUserByID)
			users.GET("/:id/followers", userHandler.GetFollowers)
			users.GET("/:id/following", userHandler.GetFollowing)
			users.POST("/:id/follow", userHandler.FollowUser)
			users.DELETE("/:id/follow", userHandler.UnfollowUser)
			users.GET("/:id/stats", userHandler.GetUserStats)
		}

		// Event routes
		events := v1.Group("/events")
		{
			events.GET("", eventHandler.GetEvents)
			events.GET("/nearby", eventHandler.GetNearbyEvents)
			events.GET("/:id", eventHandler.GetEventByID)
			events.GET("/:id/attendees", eventHandler.GetEventAttendees)
			events.GET("/:id/interest/count", eventHandler.GetEventInterestCount)
		}

		eventsProtected := v1.Group("/events")
		eventsProtected.Use(authMiddleware)
		{
			eventsProtected.POST("", eventHandler.CreateEvent)
			eventsProtected.PUT("/:id", eventHandler.UpdateEvent)
			eventsProtected.DELETE("/:id", eventHandler.DeleteEvent)
			eventsProtected.POST("/:id/join", eventHandler.JoinEvent)
			eventsProtected.DELETE("/:id/join", eventHandler.LeaveEvent)
			eventsProtected.GET("/my-events", eventHandler.GetMyEvents)
			eventsProtected.GET("/hosted", eventHandler.GetHostedEvents)
			eventsProtected.GET("/joined", eventHandler.GetJoinedEvents)

			// Event image management endpoints
			eventsProtected.POST("/:id/images", eventHandler.AddEventImages)
			eventsProtected.DELETE("/:id/images/:imageId", eventHandler.DeleteEventImage)

			// Interest/Like endpoints
			eventsProtected.POST("/:id/interest", eventHandler.ToggleEventInterest)
			eventsProtected.GET("/:id/interest/status", eventHandler.GetEventInterestStatus)

			// Event Q&A endpoints
			eventsProtected.GET("/:id/qna", qnaHandler.GetEventQnA)
			eventsProtected.POST("/:id/qna", qnaHandler.AskQuestion)
		}

		// Post routes - Public routes (view only)
		postsPublic := v1.Group("/posts")
		{
			// IMPORTANT: Static routes MUST come before parameterized routes

			// Get post by ID - public
			postsPublic.GET("/:id", postHandler.GetPostByID)
		}

		// Post routes - Protected routes (require auth)
		posts := v1.Group("/posts")
		posts.Use(authMiddleware)
		{
			// Feed endpoint - authenticated (personalized feed with like status)
			// IMPORTANT: Must come before /:id route to avoid route conflicts
			posts.GET("/feed", postHandler.GetFeed)

			// Bookmarks endpoint (must be before :id routes)
			posts.GET("/bookmarks", postHandler.GetBookmarks)

			// Get comments for a post (must be before /:id route)
			posts.GET("/:id/comments", postHandler.GetComments)

			// Create post
			posts.POST("", postHandler.CreatePost)

			// Repost endpoint
			posts.POST("/repost", postHandler.RepostPost)
			posts.POST("/:id/undo-repost", postHandler.UndoRepost)

			// Comment endpoints
			posts.POST("/comments", postHandler.AddComment)
			posts.PUT("/comments/:commentId", postHandler.UpdateComment)
			posts.DELETE("/comments/:commentId", postHandler.DeleteComment)

			// Post operations by ID
			posts.PUT("/:id", postHandler.UpdatePost)
			posts.DELETE("/:id", postHandler.DeletePost)

			// Post interactions
			posts.POST("/:id/like", postHandler.LikePost)
			posts.POST("/:id/unlike", postHandler.UnlikePost)
			posts.POST("/:id/bookmark", postHandler.BookmarkPost)
			posts.DELETE("/:id/bookmark", postHandler.RemoveBookmark)

			// Comment like/unlike
			posts.POST("/:id/comments/:commentId/like", postHandler.LikeComment)
			posts.POST("/:id/comments/:commentId/unlike", postHandler.UnlikeComment)
		}

		// Ticket routes
		tickets := v1.Group("/tickets")
		tickets.Use(authMiddleware)
		{
			tickets.POST("/purchase", ticketHandler.PurchaseTicket)
			tickets.GET("/my-tickets", ticketHandler.GetMyTickets)
			tickets.GET("/:id", ticketHandler.GetTicketByID)
			tickets.POST("/check-in", ticketHandler.CheckIn)
			tickets.POST("/:id/cancel", ticketHandler.CancelTicket)
			tickets.GET("/transactions/:id", ticketHandler.GetTransaction)
		}

		// Event tickets (host only)
		v1.GET("/events/:id/tickets", authMiddleware, eventHandler.GetEventTickets)

		// Analytics routes (host only)
		analytics := v1.Group("/analytics")
		analytics.Use(authMiddleware)
		{
			analytics.GET("/events/:id", analyticsHandler.GetEventAnalytics)
			analytics.GET("/events/:id/transactions", analyticsHandler.GetEventTransactions)
			analytics.GET("/host/revenue", analyticsHandler.GetHostRevenueSummary)
			analytics.GET("/host/events", analyticsHandler.GetHostEventsList)
		}

		// Profile routes (DEPRECATED - username lookup removed in Google OAuth migration)
		// These routes will always return 404 since usernames no longer exist
		// TODO: Replace with user ID-based routes (e.g., /users/:id/profile)
		profile := v1.Group("/profile")
		{
			profile.GET("/:username", profileHandler.GetProfileByUsername)
			profile.GET("/:username/posts", profileHandler.GetProfilePosts)
			profile.GET("/:username/events", profileHandler.GetProfileEvents)
		}

		// Q&A routes
		qnaRoutes := v1.Group("/qna")
		qnaRoutes.Use(authMiddleware)
		{
			qnaRoutes.POST("/:id/upvote", qnaHandler.UpvoteQuestion)
			qnaRoutes.DELETE("/:id/upvote", qnaHandler.RemoveUpvote)
			qnaRoutes.POST("/:id/answer", qnaHandler.AnswerQuestion)
			qnaRoutes.DELETE("/:id", qnaHandler.DeleteQuestion)
		}

		// Upload routes
		upload := v1.Group("/upload")
		upload.Use(authMiddleware)
		{
			upload.POST("/image", uploadHandler.UploadImage)
		}

		// Feed Ranking routes (public - no auth required for flexibility)
		feed := v1.Group("/feed")
		{
			feed.POST("/rank", feedRankingHandler.RankFeeds)
		}

		// Community routes
		communities := v1.Group("/communities")
		communities.Use(authMiddleware)
		{
			communities.GET("", communityHandler.GetCommunities)
			communities.GET("/my-communities", communityHandler.GetUserCommunities)
			communities.POST("", communityHandler.CreateCommunity)
			communities.GET("/:id", communityHandler.GetCommunityByID)
			communities.PUT("/:id", communityHandler.UpdateCommunity)
			communities.DELETE("/:id", communityHandler.DeleteCommunity)
			communities.POST("/:id/join", communityHandler.JoinCommunity)
			communities.DELETE("/:id/leave", communityHandler.LeaveCommunity)
			communities.GET("/:id/members", communityHandler.GetCommunityMembers)
		}

		// Webhook routes (public - no auth required)
		webhooks := v1.Group("/webhooks")
		{
			webhooks.POST("/midtrans", paymentHandler.MidtransWebhook)
		}

		// Payment routes (protected)
		payments := v1.Group("/payments")
		payments.Use(authMiddleware)
		{
			payments.POST("/initiate", paymentHandler.InitiatePayment)
			payments.POST("/status", paymentHandler.CheckPaymentStatus)
			payments.GET("/client-key", paymentHandler.GetClientKey)
		}
	}

	// Start server
	addr := fmt.Sprintf(":%s", cfg.Server.Port)
	server := &http.Server{
		Addr:           addr,
		Handler:        router,
		ReadTimeout:    10 * time.Second,
		WriteTimeout:   10 * time.Second,
		MaxHeaderBytes: 1 << 20, // 1 MB
	}

	// Graceful shutdown
	go func() {
		log.Printf("🚀 Server starting on http://localhost%s", addr)
		log.Printf("📝 Environment: %s", cfg.Server.Env)
		log.Printf("📚 API Documentation: http://localhost%s/swagger/index.html", addr)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("🛑 Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown:", err)
	}

	log.Println("✓ Server exited gracefully")
}
