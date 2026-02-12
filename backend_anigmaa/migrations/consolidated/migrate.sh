#!/bin/bash

# Database Migration Script for Anigmaa Consolidated Migrations
# Usage: ./migrate.sh [up|down] [database_url]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
ACTION="${1:-up}"
DB_URL="${2:-${DATABASE_URL}}"

# Migration files in order
UP_MIGRATIONS=(
    "01_user_service.up.sql"
    "02_event_service.up.sql"
    "03_post_service.up.sql"
    "04_ticket_service.up.sql"
    "05_community_service.up.sql"
    "06_notification_service.up.sql"
    "09_event_qna.sql"
    "07_comprehensive_seed.sql"
    "08_mailhilmi_user_seed.sql"
)

DOWN_MIGRATIONS=(
    "06_notification_service.down.sql"
    "05_community_service.down.sql"
    "04_ticket_service.down.sql"
    "03_post_service.down.sql"
    "02_event_service.down.sql"
    "01_user_service.down.sql"
)

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Help function
show_help() {
    echo "Usage: $0 [up|down] [database_url]"
    echo ""
    echo "Arguments:"
    echo "  up          Run forward migrations (default)"
    echo "  down        Run rollback migrations"
    echo "  database_url PostgreSQL connection string"
    echo ""
    echo "Environment Variables:"
    echo "  DATABASE_URL  PostgreSQL connection string"
    echo "                Format: postgres://user:password@host:port/database"
    echo ""
    echo "Examples:"
    echo "  $0 up postgres://user:pass@localhost:5432/anigmaa"
    echo "  $0 down postgres://user:pass@localhost:5432/anigmaa"
    echo "  DATABASE_URL=postgres://user:pass@localhost:5432/anigmaa $0 up"
    exit 0
}

# Parse command line arguments
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
fi

# Validate action
if [[ "$ACTION" != "up" ]] && [[ "$ACTION" != "down" ]]; then
    echo -e "${RED}Error: Invalid action '$ACTION'. Use 'up' or 'down'${NC}"
    show_help
fi

# Check if database URL is provided
if [[ -z "$DB_URL" ]]; then
    echo -e "${RED}Error: Database URL not provided${NC}"
    echo "Please provide database URL as second argument or set DATABASE_URL environment variable"
    echo ""
    show_help
fi

# Parse database URL
parse_db_url() {
    # postgres://user:password@host:port/database
    if [[ $DB_URL =~ postgres://([^:]+):([^@]+)@([^:]+):([^/]+)/(.+) ]]; then
        DB_USER="${BASH_REMATCH[1]}"
        DB_PASS="${BASH_REMATCH[2]}"
        DB_HOST="${BASH_REMATCH[3]}"
        DB_PORT="${BASH_REMATCH[4]}"
        DB_NAME="${BASH_REMATCH[5]}"
    else
        echo -e "${RED}Error: Invalid database URL format${NC}"
        echo "Expected format: postgres://user:password@host:port/database"
        exit 1
    fi
}

# Test database connection
test_connection() {
    echo -e "${YELLOW}Testing database connection...${NC}"
    PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Database connection successful${NC}"
    else
        echo -e "${RED}✗ Database connection failed${NC}"
        exit 1
    fi
}

# Run SQL file
run_sql_file() {
    local file=$1
    local filepath="${SCRIPT_DIR}/${file}"

    if [ ! -f "$filepath" ]; then
        echo -e "${RED}✗ File not found: $file${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Running: $file${NC}"
    PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$filepath"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully executed: $file${NC}"
    else
        echo -e "${RED}✗ Failed to execute: $file${NC}"
        exit 1
    fi
}

# Run migrations
run_migrations() {
    if [[ "$ACTION" == "up" ]]; then
        echo -e "${GREEN}Running forward migrations...${NC}\n"
        for migration in "${UP_MIGRATIONS[@]}"; do
            run_sql_file "$migration"
            echo ""
        done
        echo -e "${GREEN}✓ All migrations completed successfully!${NC}"
    else
        echo -e "${YELLOW}Running rollback migrations...${NC}\n"
        for migration in "${DOWN_MIGRATIONS[@]}"; do
            run_sql_file "$migration"
            echo ""
        done
        echo -e "${GREEN}✓ All rollbacks completed successfully!${NC}"
    fi
}

# Main execution
main() {
    echo -e "${GREEN}=== Anigmaa Database Migration Tool ===${NC}\n"

    parse_db_url

    echo "Database: $DB_NAME"
    echo "Host: $DB_HOST:$DB_PORT"
    echo "User: $DB_USER"
    echo "Action: $ACTION"
    echo ""

    test_connection
    echo ""

    # Confirm before proceeding
    if [[ "$ACTION" == "down" ]]; then
        echo -e "${RED}WARNING: This will DELETE all data in the database!${NC}"
        read -p "Are you sure you want to proceed? (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            echo "Migration cancelled."
            exit 0
        fi
    fi

    run_migrations

    echo ""
    echo -e "${GREEN}Migration completed at $(date)${NC}"
}

# Run main function
main
