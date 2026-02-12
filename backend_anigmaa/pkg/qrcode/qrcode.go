package qrcode

import (
	"encoding/base64"
	"encoding/json"
	"fmt"

	"github.com/google/uuid"
	"github.com/skip2/go-qrcode"
)

// TicketQRData represents the data encoded in a ticket QR code
type TicketQRData struct {
	TicketID       uuid.UUID `json:"ticket_id"`
	EventID        uuid.UUID `json:"event_id"`
	AttendanceCode string    `json:"attendance_code"`
	UserID         uuid.UUID `json:"user_id"`
}

// GenerateTicketQR generates a QR code for a ticket and returns it as a base64-encoded PNG
func GenerateTicketQR(ticketID, eventID, userID uuid.UUID, attendanceCode string) (string, error) {
	// Create QR data payload
	data := TicketQRData{
		TicketID:       ticketID,
		EventID:        eventID,
		AttendanceCode: attendanceCode,
		UserID:         userID,
	}

	// Marshal to JSON
	jsonData, err := json.Marshal(data)
	if err != nil {
		return "", fmt.Errorf("failed to marshal QR data: %w", err)
	}

	// Generate QR code (256x256 pixels, medium error correction)
	qrCode, err := qrcode.Encode(string(jsonData), qrcode.Medium, 256)
	if err != nil {
		return "", fmt.Errorf("failed to generate QR code: %w", err)
	}

	// Convert to base64
	base64QR := base64.StdEncoding.EncodeToString(qrCode)

	// Return as data URI for direct use in <img> tags
	return fmt.Sprintf("data:image/png;base64,%s", base64QR), nil
}

// DecodeTicketQR decodes a JSON string from QR code back into TicketQRData
func DecodeTicketQR(qrContent string) (*TicketQRData, error) {
	var data TicketQRData
	if err := json.Unmarshal([]byte(qrContent), &data); err != nil {
		return nil, fmt.Errorf("failed to decode QR data: %w", err)
	}
	return &data, nil
}
