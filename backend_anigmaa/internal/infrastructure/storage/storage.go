package storage

import (
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/anigmaa/backend/config"
	"github.com/google/uuid"
)

// Storage interface defines methods for file storage operations
type Storage interface {
	Upload(ctx context.Context, file multipart.File, header *multipart.FileHeader) (*UploadResult, error)
	Delete(ctx context.Context, fileURL string) error
	GetURL(filename string) string
}

// UploadResult contains information about uploaded file
type UploadResult struct {
	URL      string `json:"url"`
	Filename string `json:"filename"`
	Size     int64  `json:"size"`
	MimeType string `json:"mime_type"`
}

// NewStorage creates a new storage instance based on configuration
func NewStorage(cfg *config.StorageConfig) (Storage, error) {
	switch cfg.Type {
	case "s3":
		return NewS3Storage(cfg)
	case "local":
		return NewLocalStorage(cfg)
	default:
		return NewLocalStorage(cfg)
	}
}

// LocalStorage implements Storage interface for local file system
type LocalStorage struct {
	uploadDir string
	baseURL   string
	maxSize   int64
}

// NewLocalStorage creates a new local storage instance
func NewLocalStorage(cfg *config.StorageConfig) (*LocalStorage, error) {
	// Create upload directory if it doesn't exist
	if err := os.MkdirAll(cfg.UploadDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create upload directory: %w", err)
	}

	return &LocalStorage{
		uploadDir: cfg.UploadDir,
		baseURL:   "/uploads",
		maxSize:   cfg.MaxUploadSize,
	}, nil
}

// Upload uploads a file to local storage
func (s *LocalStorage) Upload(ctx context.Context, file multipart.File, header *multipart.FileHeader) (*UploadResult, error) {
	// Check file size
	if header.Size > s.maxSize {
		return nil, fmt.Errorf("file size exceeds maximum allowed size of %d bytes", s.maxSize)
	}

	// Validate mime type
	mimeType := header.Header.Get("Content-Type")
	if !isValidImageType(mimeType) {
		return nil, fmt.Errorf("invalid file type: %s. Only images are allowed", mimeType)
	}

	// Generate unique filename
	ext := filepath.Ext(header.Filename)
	filename := fmt.Sprintf("%s_%d%s", uuid.New().String(), time.Now().Unix(), ext)

	// Create file path
	filePath := filepath.Join(s.uploadDir, filename)

	// Create destination file
	dst, err := os.Create(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to create destination file: %w", err)
	}
	defer dst.Close()

	// Copy uploaded file to destination
	if _, err := io.Copy(dst, file); err != nil {
		return nil, fmt.Errorf("failed to save file: %w", err)
	}

	return &UploadResult{
		URL:      fmt.Sprintf("%s/%s", s.baseURL, filename),
		Filename: filename,
		Size:     header.Size,
		MimeType: mimeType,
	}, nil
}

// Delete deletes a file from local storage
func (s *LocalStorage) Delete(ctx context.Context, fileURL string) error {
	// Extract filename from URL
	filename := filepath.Base(fileURL)
	filePath := filepath.Join(s.uploadDir, filename)

	// Delete file
	if err := os.Remove(filePath); err != nil {
		if os.IsNotExist(err) {
			return nil // File doesn't exist, consider it deleted
		}
		return fmt.Errorf("failed to delete file: %w", err)
	}

	return nil
}

// GetURL returns the public URL for a file
func (s *LocalStorage) GetURL(filename string) string {
	return fmt.Sprintf("%s/%s", s.baseURL, filename)
}

// isValidImageType checks if the mime type is a valid image type
func isValidImageType(mimeType string) bool {
	validTypes := []string{
		"image/jpeg",
		"image/jpg",
		"image/png",
		"image/gif",
		"image/webp",
	}

	for _, valid := range validTypes {
		if strings.EqualFold(mimeType, valid) {
			return true
		}
	}
	return false
}
