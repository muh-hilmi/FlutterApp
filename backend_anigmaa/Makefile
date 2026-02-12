.PHONY: help run dev build test test-coverage migrate-up migrate-down migrate-create clean fmt lint swagger

# Default target
help:
	@echo "Available commands:"
	@echo "  make run              - Run the application"
	@echo "  make dev              - Run with hot reload (requires air)"
	@echo "  make build            - Build the application"
	@echo "  make test             - Run tests"
	@echo "  make test-coverage    - Run tests with coverage"
	@echo "  make migrate-up       - Run database migrations"
	@echo "  make migrate-down     - Rollback database migrations"
	@echo "  make migrate-create   - Create new migration (use name=xxx)"
	@echo "  make swagger          - Generate Swagger documentation"
	@echo "  make clean            - Clean build artifacts"
	@echo "  make fmt              - Format code"
	@echo "  make lint             - Lint code"

# Run the application
run:
	go run cmd/server/main.go

# Run with hot reload
dev:
	air

# Build the application
build:
	go build -o bin/server cmd/server/main.go

# Run tests
test:
	go test -v ./...

# Run tests with coverage
test-coverage:
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

# Run database migrations up
migrate-up:
	migrate -path migrations -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=$(DB_SSLMODE)" up

# Run database migrations down
migrate-down:
	migrate -path migrations -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=$(DB_SSLMODE)" down

# Create new migration
migrate-create:
	@if [ -z "$(name)" ]; then \
		echo "Error: name is required. Usage: make migrate-create name=create_users_table"; \
		exit 1; \
	fi
	migrate create -ext sql -dir migrations $(name)

# Clean build artifacts
clean:
	rm -rf bin/
	rm -rf dist/
	rm -f coverage.out coverage.html

# Format code
fmt:
	go fmt ./...
	gofmt -s -w .

# Lint code
lint:
	golangci-lint run

# Generate Swagger documentation
swagger:
	swag init -g cmd/server/main.go -o docs
	@echo "Swagger documentation generated at docs/"

# Install development dependencies
install-dev:
	go install github.com/cosmtrek/air@latest
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
	go install github.com/swaggo/swag/cmd/swag@latest

# Load environment variables from .env
include .env
export
