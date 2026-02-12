package handler

import (
	"fmt"
	"net/http"

	"github.com/anigmaa/backend/internal/infrastructure/payment"
	"github.com/anigmaa/backend/pkg/response"
	"github.com/gin-gonic/gin"
)

// PaymentHandler handles payment-related HTTP requests
type PaymentHandler struct {
	midtransClient *payment.MidtransClient
}

// NewPaymentHandler creates a new payment handler for Midtrans
func NewPaymentHandler(midtransClient *payment.MidtransClient) *PaymentHandler {
	return &PaymentHandler{
		midtransClient: midtransClient,
	}
}

// InitiatePaymentRequest represents the request to initiate a payment
type InitiatePaymentRequest struct {
	OrderID   string  `json:"order_id" binding:"required"`
	Amount    float64 `json:"amount" binding:"required,gt=0"`
	FirstName string  `json:"first_name" binding:"required"`
	LastName  string  `json:"last_name"`
	Email     string  `json:"email" binding:"required,email"`
	Phone     string  `json:"phone"`
	ItemName  string  `json:"item_name" binding:"required"`
	ItemID    string  `json:"item_id" binding:"required"`
}

// InitiatePaymentResponse represents the response after initiating payment
type InitiatePaymentResponse struct {
	Token       string `json:"token"`
	RedirectURL string `json:"redirect_url"`
}

// InitiatePayment creates a Midtrans Snap token for payment
// @Summary Initiate payment
// @Description Create a Midtrans Snap token for payment
// @Tags payments
// @Accept json
// @Produce json
// @Param request body InitiatePaymentRequest true "Payment initiation request"
// @Success 200 {object} response.Response{data=InitiatePaymentResponse}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/payments/initiate [post]
func (h *PaymentHandler) InitiatePayment(c *gin.Context) {
	// Parse request
	var req InitiatePaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request format", err.Error())
		return
	}

	// Prepare customer details
	customerDetails := payment.CustomerDetails{
		FirstName: req.FirstName,
		Email:     req.Email,
	}
	if req.LastName != "" {
		customerDetails.LastName = req.LastName
	}
	if req.Phone != "" {
		customerDetails.Phone = req.Phone
	}

	// Prepare item details
	itemDetails := []payment.ItemDetail{
		{
			ID:       req.ItemID,
			Price:    req.Amount,
			Quantity: 1,
			Name:     req.ItemName,
		},
	}

	// Prepare callbacks
	callbacks := &payment.Callbacks{
		Finish:  "anigmaa://payment/finish",
		Error:   "anigmaa://payment/error",
	}

	// Set expiry to 1 hour
	expiry := &payment.Expiry{
		Unit:     "hour",
		Duration: 1,
	}

	// Prepare Snap request
	snapReq := &payment.SnapRequest{
		TransactionDetails: payment.TransactionDetails{
			OrderID:     req.OrderID,
			GrossAmount: req.Amount,
		},
		CustomerDetails: customerDetails,
		ItemDetails:     itemDetails,
		EnabledPayments: []string{
			"qris", "gopay", "shopeepay", "ovo", "dana",
		},
		Callbacks: callbacks,
		Expiry:    expiry,
	}

	// Create Snap token
	snapResp, err := h.midtransClient.CreateSnapToken(c.Request.Context(), snapReq)
	if err != nil {
		response.InternalError(c, "Failed to create payment token", err.Error())
		return
	}

	// Return response
	response.Success(c, http.StatusOK, "Payment initiated successfully", InitiatePaymentResponse{
		Token:       snapResp.Token,
		RedirectURL: snapResp.RedirectURL,
	})
}

// CheckPaymentStatusRequest represents the request to check payment status
type CheckPaymentStatusRequest struct {
	OrderID string `json:"order_id" binding:"required"`
}

// CheckPaymentStatusResponse represents the payment status response
type CheckPaymentStatusResponse struct {
	OrderID           string `json:"order_id"`
	TransactionID     string `json:"transaction_id"`
	GrossAmount       string `json:"gross_amount"`
	Currency          string `json:"currency"`
	PaymentType       string `json:"payment_type"`
	TransactionStatus string `json:"transaction_status"`
	TransactionTime   string `json:"transaction_time"`
	FraudStatus       string `json:"fraud_status,omitempty"`
}

// CheckPaymentStatus gets the current status of a payment transaction
// @Summary Check payment status
// @Description Get the current status of a payment transaction
// @Tags payments
// @Accept json
// @Produce json
// @Param request body CheckPaymentStatusRequest true "Check status request"
// @Success 200 {object} response.Response{data=CheckPaymentStatusResponse}
// @Failure 400 {object} response.Response
// @Failure 500 {object} response.Response
// @Router /api/v1/payments/status [post]
func (h *PaymentHandler) CheckPaymentStatus(c *gin.Context) {
	var req CheckPaymentStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request format", err.Error())
		return
	}

	// Query Midtrans for transaction status
	status, err := h.midtransClient.GetTransactionStatus(c.Request.Context(), req.OrderID)
	if err != nil {
		response.InternalError(c, "Failed to get transaction status", err.Error())
		return
	}

	response.Success(c, http.StatusOK, "Transaction status retrieved", CheckPaymentStatusResponse{
		OrderID:           status.OrderID,
		TransactionID:     status.TransactionID,
		GrossAmount:       status.GrossAmount,
		Currency:          status.Currency,
		PaymentType:       status.PaymentType,
		TransactionStatus: status.TransactionStatus,
		TransactionTime:   status.TransactionTime,
		FraudStatus:       status.FraudStatus,
	})
}

// MidtransWebhookRequest represents the webhook notification from Midtrans
type MidtransWebhookRequest struct {
	TransactionID     string `json:"transaction_id"`
	OrderID           string `json:"order_id"`
	GrossAmount       string `json:"gross_amount"`
	Currency          string `json:"currency"`
	PaymentType       string `json:"payment_type"`
	TransactionTime   string `json:"transaction_time"`
	TransactionStatus string `json:"transaction_status"`
	FraudStatus       string `json:"fraud_status,omitempty"`
	StatusCode        string `json:"status_code"`
	SignatureKey      string `json:"signature_key"`
}

// MidtransWebhook handles payment notifications from Midtrans
// @Summary Midtrans payment notification webhook
// @Description Handle payment notifications from Midtrans
// @Tags payments
// @Accept json
// @Produce json
// @Param notification body MidtransWebhookRequest true "Payment notification"
// @Success 200 {object} response.Response
// @Failure 400 {object} response.Response
// @Router /api/v1/webhooks/midtrans [post]
func (h *PaymentHandler) MidtransWebhook(c *gin.Context) {
	// Parse notification from Midtrans
	var notification MidtransWebhookRequest
	if err := c.ShouldBindJSON(&notification); err != nil {
		response.BadRequest(c, "Invalid notification format", err.Error())
		return
	}

	// Verify signature for security
	isValid := h.midtransClient.VerifySignature(
		notification.OrderID,
		notification.StatusCode,
		notification.GrossAmount,
		notification.SignatureKey,
	)

	if !isValid {
		response.BadRequest(c, "Invalid signature", "Webhook signature verification failed")
		return
	}

	// TODO: Update transaction status in your database based on notification.TransactionStatus
	// Possible statuses: capture, settlement, pending, deny, cancel, expire, refund

	// Log the notification for debugging
	fmt.Printf("[Midtrans Webhook] OrderID: %s, Status: %s, PaymentType: %s\n",
		notification.OrderID, notification.TransactionStatus, notification.PaymentType)

	// Always return 200 to Midtrans to prevent retries
	response.Success(c, http.StatusOK, "Webhook processed successfully", gin.H{
		"order_id":           notification.OrderID,
		"transaction_status": notification.TransactionStatus,
	})
}

// GetClientKey returns the client key for frontend initialization (sandbox only)
// @Summary Get Midtrans Client Key
// @Description Returns the client key for frontend initialization (sandbox only)
// @Tags payments
// @Produce json
// @Success 200 {object} response.Response
// @Router /api/v1/payments/client-key [get]
func (h *PaymentHandler) GetClientKey(c *gin.Context) {
	response.Success(c, http.StatusOK, "Client key retrieved", gin.H{
		"client_key": h.midtransClient.GetClientKey(),
		"is_sandbox": true,
	})
}

// getFrontendURL returns the frontend URL (should be from config)
func getFrontendURL() string {
	// TODO: Get from config
	return "https://anigmaa.id"
}
