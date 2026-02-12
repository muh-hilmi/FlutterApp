#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TERRAFORM_DIR="./aws/terraform"

echo -e "${GREEN}🗃️  Database Migration Script${NC}"

# Get database connection details from Terraform outputs
get_db_details() {
    echo -e "${YELLOW}📋 Getting database connection details...${NC}"

    cd $TERRAFORM_DIR

    DB_HOST=$(terraform output -raw rds_endpoint)
    DB_NAME="anigmaa"
    DB_USER="postgres"

    # Get password from SSM Parameter Store
    DB_PASSWORD=$(aws ssm get-parameter --name "/anigmaa/prod/db/password" --with-decryption --query 'Parameter.Value' --output text)

    echo "Database Host: $DB_HOST"
    echo "Database Name: $DB_NAME"
    echo "Database User: $DB_USER"

    cd ../../

    echo -e "${GREEN}✅ Database details retrieved${NC}"
}

# Test database connection
test_connection() {
    echo -e "${YELLOW}🔌 Testing database connection...${NC}"

    # Use docker to run psql if not installed locally
    if ! command -v psql &> /dev/null; then
        echo "Using Docker to connect to database..."
        docker run --rm -it postgres:15-alpine psql "postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME" -c "SELECT version();"
    else
        psql "postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME" -c "SELECT version();"
    fi

    echo -e "${GREEN}✅ Database connection successful${NC}"
}

# Run migrations
run_migrations() {
    echo -e "${YELLOW}🚀 Running database migrations...${NC}"

    # Check if migrations directory exists
    if [ ! -d "./migrations" ]; then
        echo -e "${YELLOW}⚠️  No migrations directory found${NC}"
        return
    fi

    # Count migration files
    MIGRATION_COUNT=$(find ./migrations -name "*.sql" | wc -l)

    if [ $MIGRATION_COUNT -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No migration files found${NC}"
        return
    fi

    echo "Found $MIGRATION_COUNT migration files"

    # Option 1: Use golang-migrate tool (recommended)
    if command -v migrate &> /dev/null; then
        echo "Using golang-migrate tool..."
        migrate -path ./migrations -database "postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME?sslmode=require" up

    # Option 2: Use docker with migrate tool
    elif command -v docker &> /dev/null; then
        echo "Using Docker with migrate tool..."
        docker run --rm -v $(pwd)/migrations:/migrations migrate/migrate \
            -path=/migrations \
            -database "postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME?sslmode=require" \
            up

    # Option 3: Manual execution with psql
    else
        echo "Running migrations manually with psql..."
        for migration in $(ls ./migrations/*.sql | sort); do
            echo "Applying $migration..."
            if ! command -v psql &> /dev/null; then
                docker run --rm -i postgres:15-alpine psql "postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME" < $migration
            else
                psql "postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME" < $migration
            fi
        done
    fi

    echo -e "${GREEN}✅ Database migrations completed${NC}"
}

# Create initial admin user (optional)
create_admin_user() {
    echo -e "${YELLOW}👤 Creating initial admin user...${NC}"

    read -p "Do you want to create an initial admin user? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi

    read -p "Enter admin email: " ADMIN_EMAIL
    read -s -p "Enter admin password: " ADMIN_PASSWORD
    echo

    # Create SQL for admin user (adjust according to your user schema)
    ADMIN_SQL="
    INSERT INTO users (id, email, password, role, created_at, updated_at)
    VALUES (
        gen_random_uuid(),
        '$ADMIN_EMAIL',
        crypt('$ADMIN_PASSWORD', gen_salt('bf')),
        'admin',
        NOW(),
        NOW()
    ) ON CONFLICT (email) DO NOTHING;
    "

    if ! command -v psql &> /dev/null; then
        echo "$ADMIN_SQL" | docker run --rm -i postgres:15-alpine psql "postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME"
    else
        echo "$ADMIN_SQL" | psql "postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME"
    fi

    echo -e "${GREEN}✅ Admin user created${NC}"
}

# Check migration status
check_migration_status() {
    echo -e "${YELLOW}📊 Checking migration status...${NC}"

    # Check if schema_migrations table exists
    MIGRATION_STATUS_SQL="
    SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'schema_migrations'
    );
    "

    if ! command -v psql &> /dev/null; then
        echo "$MIGRATION_STATUS_SQL" | docker run --rm -i postgres:15-alpine psql "postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME"
    else
        echo "$MIGRATION_STATUS_SQL" | psql "postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME"
    fi

    echo -e "${GREEN}✅ Migration status checked${NC}"
}

# Main function
main() {
    echo -e "${GREEN}Starting database migration process...${NC}"

    get_db_details
    test_connection
    run_migrations
    check_migration_status
    create_admin_user

    echo -e "${GREEN}🎉 Database migration completed successfully!${NC}"
}

# Show help
show_help() {
    echo "Database Migration Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  migrate    Run database migrations"
    echo "  test       Test database connection"
    echo "  status     Check migration status"
    echo "  help       Show this help message"
    echo ""
}

# Parse command line arguments
case "${1:-migrate}" in
    migrate)
        main
        ;;
    test)
        get_db_details
        test_connection
        ;;
    status)
        get_db_details
        check_migration_status
        ;;
    help)
        show_help
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac