# Makefile for Anigmaa Consolidated Database Migrations

# Load environment variables from .env file if it exists
ifneq (,$(wildcard ../../.env))
    include ../../.env
    export
endif

# Default database URL (override with DATABASE_URL env var)
DB_URL ?= postgres://postgres:postgres@localhost:5432/anigmaa?sslmode=disable

# Colors for output
GREEN  := \033[0;32m
YELLOW := \033[1;33m
RED    := \033[0;31m
NC     := \033[0m # No Color

.PHONY: help up down fresh status clean test

help: ## Show this help message
	@echo "$(GREEN)Anigmaa Database Migration Commands$(NC)"
	@echo ""
	@echo "Usage: make [command]"
	@echo ""
	@echo "Commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Environment Variables:"
	@echo "  DATABASE_URL   PostgreSQL connection string"
	@echo "                 Current: $(DB_URL)"

up: ## Run forward migrations (setup database)
	@echo "$(GREEN)Running forward migrations...$(NC)"
	@./migrate.sh up $(DB_URL)

down: ## Run rollback migrations (tear down database)
	@echo "$(YELLOW)Running rollback migrations...$(NC)"
	@./migrate.sh down $(DB_URL)

fresh: down up ## Fresh migration (tear down and rebuild)
	@echo "$(GREEN)Fresh migration completed!$(NC)"

status: ## Check database connection
	@echo "$(YELLOW)Checking database status...$(NC)"
	@psql "$(DB_URL)" -c "SELECT 'Database connection successful!' as status, version();"

tables: ## List all tables in database
	@echo "$(YELLOW)Listing database tables...$(NC)"
	@psql "$(DB_URL)" -c "\dt"

users: ## Show user service tables
	@echo "$(YELLOW)User Service Tables:$(NC)"
	@psql "$(DB_URL)" -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND (tablename LIKE 'user%' OR tablename = 'follows' OR tablename = 'invitations') ORDER BY tablename;"

events: ## Show event service tables
	@echo "$(YELLOW)Event Service Tables:$(NC)"
	@psql "$(DB_URL)" -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE 'event%' OR tablename = 'reviews' ORDER BY tablename;"

posts: ## Show post service tables
	@echo "$(YELLOW)Post Service Tables:$(NC)"
	@psql "$(DB_URL)" -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND (tablename LIKE 'post%' OR tablename IN ('comments', 'likes', 'reposts', 'bookmarks', 'shares')) ORDER BY tablename;"

tickets: ## Show ticket service tables
	@echo "$(YELLOW)Ticket Service Tables:$(NC)"
	@psql "$(DB_URL)" -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE 'ticket%' ORDER BY tablename;"

count: ## Count records in all tables
	@echo "$(YELLOW)Record counts:$(NC)"
	@psql "$(DB_URL)" -c "SELECT 'users' as table_name, COUNT(*) FROM users UNION ALL SELECT 'events', COUNT(*) FROM events UNION ALL SELECT 'posts', COUNT(*) FROM posts UNION ALL SELECT 'tickets', COUNT(*) FROM tickets ORDER BY table_name;"

clean: ## Drop all tables (destructive!)
	@echo "$(RED)WARNING: This will drop all tables!$(NC)"
	@read -p "Are you sure? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		make down; \
	else \
		echo "Cancelled."; \
	fi

test: ## Test database connection
	@echo "$(YELLOW)Testing database connection...$(NC)"
	@psql "$(DB_URL)" -c "SELECT 1" > /dev/null 2>&1 && echo "$(GREEN)✓ Connection successful$(NC)" || echo "$(RED)✗ Connection failed$(NC)"

# Development helpers
dev-up: ## Setup development database
	@echo "$(GREEN)Setting up development database...$(NC)"
	@docker-compose up -d postgres
	@sleep 3
	@make up

seed: ## Run seed data (requires old migration files)
	@echo "$(YELLOW)Running seed data...$(NC)"
	@psql "$(DB_URL)" -f ../011_enhanced_seed_data.sql
	@psql "$(DB_URL)" -f ../016_seed_interactions_and_events.up.sql
	@echo "$(GREEN)Seed data loaded!$(NC)"

# Docker helpers
docker-up: ## Run migrations in Docker
	@docker run --rm -v $$(pwd):/migrations --network host \
		migrate/migrate \
		-path=/migrations \
		-database "$(DB_URL)" up

docker-down: ## Rollback migrations in Docker
	@docker run --rm -v $$(pwd):/migrations --network host \
		migrate/migrate \
		-path=/migrations \
		-database "$(DB_URL)" down

# Info
info: ## Show migration info
	@echo "$(GREEN)Migration Information:$(NC)"
	@echo "  Total Services: 4"
	@echo "  Migration Files: 8 (4 up + 4 down)"
	@echo "  Services:"
	@echo "    1. User Service    (01)"
	@echo "    2. Event Service   (02)"
	@echo "    3. Post Service    (03)"
	@echo "    4. Ticket Service  (04)"
	@echo ""
	@echo "  Database URL: $(DB_URL)"
