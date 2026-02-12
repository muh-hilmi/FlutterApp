package services

import (
	"context"
	"fmt"
	"log"
	"net/smtp"
	"strings"

	"github.com/anigmaa/backend/internal/domain/user"
)

// EmailConfig holds email service configuration
type EmailConfig struct {
	SMTPHost     string
	SMTPPort     int
	SMTPUsername string
	SMTPPassword string
	FromEmail    string
	FromName     string
}

// EmailService handles email sending functionality
type EmailService struct {
	config *EmailConfig
}

// NewEmailService creates a new email service
func NewEmailService(config *EmailConfig) *EmailService {
	return &EmailService{
		config: config,
	}
}

// SendEmailVerification sends verification email to user
func (es *EmailService) SendEmailVerification(ctx context.Context, user *user.User, token string) error {
	if es.config == nil || es.config.SMTPHost == "" {
		log.Printf("Email service not configured, skipping verification email to %s", user.Email)
		return nil
	}

	subject := "Verify Your Anigmaa Account"
	body := fmt.Sprintf(`
Hello %s,

Thank you for registering with Anigmaa! To complete your registration, please verify your email address by clicking the link below:

https://anigmaa.com/verify?token=%s

This link will expire in 24 hours.

If you did not create an account with Anigmaa, please ignore this email.

Best regards,
The Anigmaa Team
`, user.Name, token)

	return es.sendEmail(user.Email, subject, body)
}

// SendPasswordReset sends password reset email to user
func (es *EmailService) SendPasswordReset(ctx context.Context, user *user.User, token string) error {
	if es.config == nil || es.config.SMTPHost == "" {
		log.Printf("Email service not configured, skipping password reset email to %s", user.Email)
		return nil
	}

	subject := "Reset Your Anigmaa Password"
	body := fmt.Sprintf(`
Hello %s,

We received a request to reset the password for your Anigmaa account. Click the link below to reset your password:

https://anigmaa.com/reset-password?token=%s

This link will expire in 1 hour for security reasons.

If you did not request a password reset, please ignore this email or contact our support team.

Best regards,
The Anigmaa Team
`, user.Name, token)

	return es.sendEmail(user.Email, subject, body)
}

// SendWelcomeEmail sends welcome email to newly verified user
func (es *EmailService) SendWelcomeEmail(ctx context.Context, user *user.User) error {
	if es.config == nil || es.config.SMTPHost == "" {
		log.Printf("Email service not configured, skipping welcome email to %s", user.Email)
		return nil
	}

	subject := "Welcome to Anigmaa!"
	body := fmt.Sprintf(`
Welcome to Anigmaa, %s!

Your email has been successfully verified and your account is now active.

What's next?
- Complete your profile to connect with others
- Discover exciting events in your area
- Join communities that match your interests

If you have any questions, feel free to reach out to our support team.

Best regards,
The Anigmaa Team
`, user.Name)

	return es.sendEmail(user.Email, subject, body)
}

// sendEmail sends an email using SMTP
func (es *EmailService) sendEmail(to, subject, body string) error {
	if es.config == nil {
		return fmt.Errorf("email service not configured")
	}

	// Create message
	message := fmt.Sprintf("From: %s <%s>\r\n", es.config.FromName, es.config.FromEmail)
	message += fmt.Sprintf("To: %s\r\n", to)
	message += fmt.Sprintf("Subject: %s\r\n", subject)
	message += "MIME-version: 1.0;\nContent-Type: text/plain; charset=\"UTF-8\"\r\n\r\n"
	message += body

	// SMTP authentication
	auth := smtp.PlainAuth("", es.config.SMTPUsername, es.config.SMTPPassword, es.config.SMTPHost)

	// Send email
	addr := fmt.Sprintf("%s:%d", es.config.SMTPHost, es.config.SMTPPort)
	err := smtp.SendMail(addr, auth, es.config.FromEmail, []string{to}, []byte(message))
	if err != nil {
		return fmt.Errorf("failed to send email: %w", err)
	}

	log.Printf("Email sent successfully to %s", to)
	return nil
}

// IsConfigured returns true if email service is properly configured
func (es *EmailService) IsConfigured() bool {
	return es.config != nil && 
		   es.config.SMTPHost != "" && 
		   es.config.SMTPUsername != "" && 
		   es.config.SMTPPassword != "" && 
		   es.config.FromEmail != ""
}

// SendBulkEmail sends email to multiple recipients (for newsletters, announcements, etc.)
func (es *EmailService) SendBulkEmail(ctx context.Context, recipients []string, subject, body string) error {
	var errors []string
	
	for _, recipient := range recipients {
		if err := es.sendEmail(recipient, subject, body); err != nil {
			errors = append(errors, fmt.Sprintf("Failed to send to %s: %v", recipient, err))
		}
	}
	
	if len(errors) > 0 {
		return fmt.Errorf("bulk email completed with errors: %s", strings.Join(errors, "; "))
	}
	
	return nil
}
