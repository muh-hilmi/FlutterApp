package payment

import (
	"bytes"
	"context"
	"crypto/sha512"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/anigmaa/backend/config"
)

// MidtransClient handles Midtrans API interactions
type MidtransClient struct {
	serverKey  string
	clientKey  string
	isSandbox  bool
	httpClient *http.Client
}

// NewMidtransClient creates a new Midtrans client
func NewMidtransClient(cfg *config.MidtransConfig) *MidtransClient {
	return &MidtransClient{
		serverKey: cfg.ServerKey,
		clientKey: cfg.ClientKey,
		isSandbox: !cfg.IsProduction,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// getBaseURL returns the appropriate Midtrans API URL
func (m *MidtransClient) getBaseURL() string {
	if m.isSandbox {
		return "https://app.sandbox.midtrans.com"
	}
	return "https://app.midtrans.com"
}

// getSnapBaseURL returns Snap API URL (always uses app domain)
func (m *MidtransClient) getSnapBaseURL() string {
	if m.isSandbox {
		return "https://app.sandbox.midtrans.com/snap/v1"
	}
	return "https://app.midtrans.com/snap/v1"
}

// SnapRequest represents the Snap API request
type SnapRequest struct {
	TransactionDetails TransactionDetails `json:"transaction_details"`
	CustomerDetails    CustomerDetails    `json:"customer_details"`
	ItemDetails        []ItemDetail       `json:"item_details"`
	EnabledPayments    []string           `json:"enabled_payments,omitempty"`
	Callbacks          *Callbacks         `json:"callbacks,omitempty"`
	Expiry             *Expiry             `json:"expiry,omitempty"`
}

// TransactionDetails contains transaction information
type TransactionDetails struct {
	OrderID     string  `json:"order_id"`
	GrossAmount float64 `json:"gross_amount"`
}

// CustomerDetails contains customer information
type CustomerDetails struct {
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name,omitempty"`
	Email     string `json:"email"`
	Phone     string `json:"phone,omitempty"`
}

// ItemDetail contains item information
type ItemDetail struct {
	ID       string  `json:"id"`
	Price    float64 `json:"price"`
	Quantity int     `json:"quantity"`
	Name     string  `json:"name"`
	Category string  `json:"category,omitempty"`
}

// Callbacks contains callback URLs
type Callbacks struct {
	Finish  string `json:"finish,omitempty"`
	Unfinish string `json:"unfinish,omitempty"`
	Error   string `json:"error,omitempty"`
}

// Expiry contains expiry configuration
type Expiry struct {
	Unit  string `json:"unit"`  // day, hour, minute
	Duration int  `json:"duration"`
}

// SnapResponse represents the Snap API response
type SnapResponse struct {
	Token       string `json:"token"`
	RedirectURL string `json:"redirect_url"`
}

// CreateSnapToken creates a Snap payment token
func (m *MidtransClient) CreateSnapToken(ctx context.Context, req *SnapRequest) (*SnapResponse, error) {
	url := fmt.Sprintf("%s/transactions", m.getSnapBaseURL())

	// Marshal request
	jsonData, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	// Create HTTP request
	httpReq, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers - Basic Auth using Server Key
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Accept", "application/json")
	httpReq.SetBasicAuth(m.serverKey, "")

	// Send request
	resp, err := m.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// Read response
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	// Check status code
	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		return nil, fmt.Errorf("midtrans API error (status %d): %s", resp.StatusCode, string(body))
	}

	// Parse response
	var snapResp SnapResponse
	if err := json.Unmarshal(body, &snapResp); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %w", err)
	}

	return &snapResp, nil
}

// TransactionStatus represents transaction status from webhook/notification
type TransactionStatus struct {
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

// GetTransactionStatus fetches transaction status from Midtrans
func (m *MidtransClient) GetTransactionStatus(ctx context.Context, orderID string) (*TransactionStatus, error) {
	url := fmt.Sprintf("%s/v2/%s/status", m.getBaseURL(), orderID)

	// Create HTTP request
	httpReq, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers - Basic Auth using Server Key
	httpReq.Header.Set("Accept", "application/json")
	httpReq.SetBasicAuth(m.serverKey, "")

	// Send request
	resp, err := m.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// Read response
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	// Check status code
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("midtrans API error (status %d): %s", resp.StatusCode, string(body))
	}

	// Parse response
	var status TransactionStatus
	if err := json.Unmarshal(body, &status); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %w", err)
	}

	return &status, nil
}

// VerifySignature verifies the webhook signature from Midtrans
// Signature = SHA512(order_id + status_code + gross_amount + server_key)
func (m *MidtransClient) VerifySignature(orderID, statusCode, grossAmount, signatureKey string) bool {
	payload := orderID + statusCode + grossAmount + m.serverKey
	hash := sha512.Sum512([]byte(payload))
	expectedSig := fmt.Sprintf("%x", hash)
	return expectedSig == signatureKey
}

// GenerateOrderID generates a unique order ID
func GenerateOrderID(prefix string) string {
	timestamp := time.Now().Unix()
	randomStr := fmt.Sprintf("%d", timestamp)
	return fmt.Sprintf("%s-%s", prefix, randomStr)
}

// GetClientKey returns the client key for frontend
func (m *MidtransClient) GetClientKey() string {
	return m.clientKey
}
