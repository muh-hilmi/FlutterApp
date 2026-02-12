package main

import (
	"log"
	"os"

	"github.com/anigmaa/backend/internal/delivery/http/handler"
	"github.com/anigmaa/backend/internal/infrastructure/payment"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env file
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	// Initialize Midtrans client
	midtransConfig := &payment.MidtransConfig{
		ServerKey:    getEnv("MIDTRANS_SERVER_KEY", "SB-Mid-server-xxxxx"),
		ClientKey:    getEnv("MIDTRANS_CLIENT_KEY", "SB-Mid-client-xxxxx"),
		IsProduction: getEnv("MIDTRANS_ENV", "sandbox") == "production",
	}
	midtransClient := payment.NewMidtransClient(midtransConfig)

	// Initialize handlers
	paymentHandler := handler.NewPaymentHandler(midtransClient)

	// Setup Gin router
	router := gin.Default()

	// CORS middleware
	router.Use(CORSMiddleware())

	// API Routes
	v1 := router.Group("/api/v1")
	{
		// Payment routes
		payments := v1.Group("/payments")
		{
			payments.POST("/initiate", paymentHandler.InitiatePayment)
			payments.POST("/status", paymentHandler.CheckPaymentStatus)
			payments.GET("/client-key", paymentHandler.GetClientKey)
		}

		// Webhook routes (no auth required)
		webhooks := v1.Group("/webhooks")
		{
			webhooks.POST("/midtrans", paymentHandler.MidtransWebhook)
		}
	}

	// Start server
	port := getEnv("PORT", "8080")
	log.Printf("Server starting on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

// CORSMiddleware handles CORS for Flutter app
func CORSMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}

func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
