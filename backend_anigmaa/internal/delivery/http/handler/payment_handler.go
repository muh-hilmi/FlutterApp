package handler

import (
	"fmt"
	"log"
	"net/http"

	"github.com/anigmaa/backend/internal/domain/ticket"
	"github.com/anigmaa/backend/internal/infrastructure/payment"
	ticket_uc "github.com/anigmaa/backend/internal/usecase/ticket"
	"github.com/anigmaa/backend/pkg/response"
	"github.com/gin-gonic/gin"
)

// PaymentHandler handles payment-related HTTP requests
type PaymentHandler struct {
	midtransClient *payment.MidtransClient
	ticketUsecase  *ticket_uc.Usecase
}

// NewPaymentHandler creates a new payment handler for Midtrans
func NewPaymentHandler(midtransClient *payment.MidtransClient, ticketUsecase *ticket_uc.Usecase) *PaymentHandler {
	return &PaymentHandler{
		midtransClient: midtransClient,
		ticketUsecase:  ticketUsecase,
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
	var req InitiatePaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "Invalid request format", err.Error())
		return
	}

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

	itemDetails := []payment.ItemDetail{
		{
			ID:       req.ItemID,
			Price:    req.Amount,
			Quantity: 1,
			Name:     req.ItemName,
		},
	}

	callbacks := &payment.Callbacks{
		Finish: "anigmaa://payment/finish",
		Error:  "anigmaa://payment/error",
	}

	expiry := &payment.Expiry{
		Unit:     "hour",
		Duration: 1,
	}

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

	snapResp, err := h.midtransClient.CreateSnapToken(c.Request.Context(), snapReq)
	if err != nil {
		response.InternalError(c, "Failed to create payment token", err.Error())
		return
	}

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

// mapMidtransStatus converts a Midtrans transaction_status string to the
// internal TransactionStatus enum.
// Returns (status, ok) — ok is false for statuses that require no DB action
// (e.g. "pending" means payment not yet attempted, nothing to update).
func mapMidtransStatus(midtransStatus string) (ticket.TransactionStatus, bool) {
	switch midtransStatus {
	case "capture", "settlement":
		return ticket.TransactionSuccess, true
	case "deny", "cancel", "expire", "failure":
		return ticket.TransactionFailed, true
	case "refund", "partial_refund":
		return ticket.TransactionRefunded, true
	default:
		// "pending" and unknown statuses: no action needed
		return "", false
	}
}

// MidtransWebhook handles payment notifications from Midtrans.
//
// Security: SHA-512 signature is verified before any processing.
// Idempotency: ProcessPaymentCallback skips already-terminal transactions,
// so duplicate webhook deliveries are safe.
//
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
	var notification MidtransWebhookRequest
	if err := c.ShouldBindJSON(&notification); err != nil {
		response.BadRequest(c, "Invalid notification format", err.Error())
		return
	}

	// Verify SHA-512 signature: SHA512(order_id + status_code + gross_amount + server_key)
	if !h.midtransClient.VerifySignature(
		notification.OrderID,
		notification.StatusCode,
		notification.GrossAmount,
		notification.SignatureKey,
	) {
		log.Printf("[Webhook] INVALID signature for order_id=%s status=%s — rejecting",
			notification.OrderID, notification.TransactionStatus)
		response.BadRequest(c, "Invalid signature", "Webhook signature verification failed")
		return
	}

	log.Printf("[Webhook] received order_id=%s midtrans_status=%s payment_type=%s",
		notification.OrderID, notification.TransactionStatus, notification.PaymentType)

	// Map Midtrans status to internal status.
	internalStatus, shouldProcess := mapMidtransStatus(notification.TransactionStatus)
	if !shouldProcess {
		// "pending" or unknown: acknowledge without touching the DB.
		log.Printf("[Webhook] no action needed for status=%s order_id=%s",
			notification.TransactionStatus, notification.OrderID)
		response.Success(c, http.StatusOK, "Webhook acknowledged", gin.H{
			"order_id": notification.OrderID,
			"action":   "none",
		})
		return
	}

	// Process the payment outcome — activates or cancels ticket accordingly.
	// Pass gross_amount so the usecase can validate it against the DB record.
	if err := h.ticketUsecase.ProcessPaymentCallback(
		c.Request.Context(),
		notification.OrderID,
		internalStatus,
		notification.GrossAmount,
	); err != nil {
		// Log the error but still return 200 to prevent Midtrans from retrying
		// indefinitely (the error is likely a DB issue, not a bad payload).
		log.Printf("[Webhook] ERROR processing order_id=%s: %v", notification.OrderID, err)
		// Return 200 so Midtrans stops retrying; the issue will be visible in logs.
		response.Success(c, http.StatusOK, "Webhook received", gin.H{
			"order_id": notification.OrderID,
			"warning":  fmt.Sprintf("processing error: %v", err),
		})
		return
	}

	log.Printf("[Webhook] SUCCESS order_id=%s internal_status=%s", notification.OrderID, internalStatus)
	response.Success(c, http.StatusOK, "Webhook processed successfully", gin.H{
		"order_id":        notification.OrderID,
		"internal_status": string(internalStatus),
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
