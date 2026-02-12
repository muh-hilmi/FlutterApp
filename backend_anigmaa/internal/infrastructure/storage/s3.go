package storage

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"path/filepath"
	"time"

	"github.com/anigmaa/backend/config"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/google/uuid"
)

// S3Storage implements Storage interface for AWS S3
type S3Storage struct {
	client  *s3.S3
	bucket  string
	region  string
	maxSize int64
}

// NewS3Storage creates a new S3 storage instance
func NewS3Storage(cfg *config.StorageConfig) (*S3Storage, error) {
	if cfg.AWSBucket == "" {
		return nil, fmt.Errorf("AWS_BUCKET is required for S3 storage")
	}
	if cfg.AWSAccessKey == "" {
		return nil, fmt.Errorf("AWS_ACCESS_KEY is required for S3 storage")
	}
	if cfg.AWSSecretKey == "" {
		return nil, fmt.Errorf("AWS_SECRET_KEY is required for S3 storage")
	}

	// Create AWS session
	sess, err := session.NewSession(&aws.Config{
		Region:      aws.String(cfg.AWSRegion),
		Credentials: credentials.NewStaticCredentials(cfg.AWSAccessKey, cfg.AWSSecretKey, ""),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create AWS session: %w", err)
	}

	return &S3Storage{
		client:  s3.New(sess),
		bucket:  cfg.AWSBucket,
		region:  cfg.AWSRegion,
		maxSize: cfg.MaxUploadSize,
	}, nil
}

// Upload uploads a file to S3
func (s *S3Storage) Upload(ctx context.Context, file multipart.File, header *multipart.FileHeader) (*UploadResult, error) {
	// Check file size
	if header.Size > s.maxSize {
		return nil, fmt.Errorf("file size exceeds maximum allowed size of %d bytes", s.maxSize)
	}

	// Validate mime type
	mimeType := header.Header.Get("Content-Type")
	if !isValidImageType(mimeType) {
		return nil, fmt.Errorf("invalid file type: %s. Only images are allowed", mimeType)
	}

	// Read file content
	buffer := make([]byte, header.Size)
	if _, err := file.Read(buffer); err != nil && err != io.EOF {
		return nil, fmt.Errorf("failed to read file: %w", err)
	}

	// Generate unique filename
	ext := filepath.Ext(header.Filename)
	filename := fmt.Sprintf("uploads/%s_%d%s", uuid.New().String(), time.Now().Unix(), ext)

	// Upload to S3
	_, err := s.client.PutObjectWithContext(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(s.bucket),
		Key:         aws.String(filename),
		Body:        bytes.NewReader(buffer),
		ContentType: aws.String(mimeType),
		ACL:         aws.String("public-read"),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to upload file to S3: %w", err)
	}

	// Generate public URL
	url := fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", s.bucket, s.region, filename)

	return &UploadResult{
		URL:      url,
		Filename: filename,
		Size:     header.Size,
		MimeType: mimeType,
	}, nil
}

// Delete deletes a file from S3
func (s *S3Storage) Delete(ctx context.Context, fileURL string) error {
	// Extract key from URL
	key := filepath.Base(fileURL)

	_, err := s.client.DeleteObjectWithContext(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return fmt.Errorf("failed to delete file from S3: %w", err)
	}

	return nil
}

// GetURL returns the public URL for a file
func (s *S3Storage) GetURL(filename string) string {
	return fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", s.bucket, s.region, filename)
}
