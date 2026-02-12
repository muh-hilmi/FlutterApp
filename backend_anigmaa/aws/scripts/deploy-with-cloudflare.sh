#!/bin/bash

# Deploy Script for AWS Lambda + Cloudflare
# This script automates the deployment process

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/aws/terraform"
AWS_REGION="ap-southeast-1"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_requirements() {
    log_info "Checking requirements..."

    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi

    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed"
        exit 1
    fi

    # Check Go
    if ! command -v go &> /dev/null; then
        log_error "Go is not installed"
        exit 1
    fi

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Run: aws configure"
        exit 1
    fi

    log_success "All requirements met"
}

verify_terraform_vars() {
    log_info "Verifying Terraform variables..."

    TFVARS="$TERRAFORM_DIR/terraform.tfvars"

    if [ ! -f "$TFVARS" ]; then
        log_error "terraform.tfvars not found at $TFVARS"
        exit 1
    fi

    # Check for placeholder values
    if grep -q "CHANGE_THIS" "$TFVARS"; then
        log_error "Found CHANGE_THIS placeholders in terraform.tfvars"
        log_error "Please update the following values:"
        grep "CHANGE_THIS" "$TFVARS" | sed 's/^/  - /'
        exit 1
    fi

    log_success "terraform.tfvars looks good"
}

terraform_init() {
    log_info "Initializing Terraform..."
    cd "$TERRAFORM_DIR"
    terraform init
    log_success "Terraform initialized"
}

terraform_validate() {
    log_info "Validating Terraform configuration..."
    cd "$TERRAFORM_DIR"
    terraform validate
    log_success "Terraform configuration is valid"
}

terraform_plan() {
    log_info "Planning Terraform deployment..."
    cd "$TERRAFORM_DIR"

    if terraform plan -out=tfplan; then
        log_success "Terraform plan created"
        log_warning "Review the plan above. Press Enter to continue or Ctrl+C to cancel..."
        read -r
    else
        log_error "Terraform plan failed"
        exit 1
    fi
}

terraform_apply() {
    log_info "Applying Terraform configuration..."
    cd "$TERRAFORM_DIR"

    if terraform apply tfplan; then
        log_success "Infrastructure deployed successfully"
    else
        log_error "Terraform apply failed"
        exit 1
    fi
}

get_api_endpoint() {
    log_info "Getting API Gateway endpoint..."
    cd "$TERRAFORM_DIR"
    API_ENDPOINT=$(terraform output -raw api_gateway_endpoint)
    echo "$API_ENDPOINT"
}

build_lambda_binary() {
    log_info "Building Go binary for Lambda..."
    cd "$PROJECT_ROOT"

    # Build for Linux/AMD64
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o bootstrap cmd/server/main.go

    if [ -f "bootstrap" ]; then
        BINARY_SIZE=$(du -h bootstrap | cut -f1)
        log_success "Lambda binary built successfully ($BINARY_SIZE)"
    else
        log_error "Failed to build binary"
        exit 1
    fi
}

deploy_lambda() {
    log_info "Deploying Lambda function..."
    cd "$PROJECT_ROOT"

    # Get function name
    FUNCTION_NAME=$(cd "$TERRAFORM_DIR" && terraform output -raw lambda_function_name)

    # Create deployment package
    zip -q lambda-function.zip bootstrap

    log_info "Uploading to Lambda..."
    if aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file fileb://lambda-function.zip \
        --region "$AWS_REGION" > /dev/null; then

        log_success "Lambda function uploaded"

        # Wait for update to complete
        log_info "Waiting for Lambda update to complete..."
        sleep 30

        # Verify update
        LAST_MODIFIED=$(aws lambda get-function-configuration \
            --function-name "$FUNCTION_NAME" \
            --region "$AWS_REGION" \
            --query 'LastModified' --output text)

        log_success "Lambda updated at: $LAST_MODIFIED"
    else
        log_error "Failed to upload Lambda function"
        exit 1
    fi

    # Cleanup
    rm -f lambda-function.zip bootstrap
}

test_lambda() {
    log_info "Testing Lambda function..."

    FUNCTION_NAME=$(cd "$TERRAFORM_DIR" && terraform output -raw lambda_function_name)

    # Test Lambda directly
    if aws lambda invoke \
        --function-name "$FUNCTION_NAME" \
        --region "$AWS_REGION" \
        --payload '{"requestContext":{"http":{"method":"GET","path":"/health"}},"body":""}' \
        response.json > /dev/null 2>&1; then

        if grep -q "statusCode" response.json; then
            log_success "Lambda test passed"
            rm -f response.json
        else
            log_error "Lambda returned invalid response"
            cat response.json
            exit 1
        fi
    else
        log_error "Lambda invocation failed"
        exit 1
    fi
}

test_api_gateway() {
    log_info "Testing API Gateway endpoint..."

    API_ENDPOINT=$(get_api_endpoint)

    # Wait for API Gateway to be ready
    log_info "Waiting for API Gateway to be ready..."
    sleep 10

    # Test health endpoint
    if curl -s -f "$API_ENDPOINT/health" > /dev/null; then
        log_success "API Gateway health check passed"
    else
        log_warning "API Gateway health check failed (may need more time to initialize)"
        log_info "Test again in 1-2 minutes"
    fi
}

cloudflare_instructions() {
    log_info "Cloudflare Configuration Instructions"
    echo ""
    echo "=========================================="
    echo "MANUAL CLOUDFLARE SETUP REQUIRED"
    echo "=========================================="
    echo ""
    echo "1. Go to Cloudflare Dashboard: https://dash.cloudflare.com"
    echo "2. Select domain: muhhilmi.site"
    echo "3. Go to DNS tab"
    echo "4. Create/Update CNAME record:"
    echo ""
    echo "   Name: api"
    echo "   Content: $(get_api_endpoint | sed 's|https://||g' | sed 's|/prod||g')"
    echo "   TTL: Auto"
    echo "   Proxy: ✓ Proxied (Orange Cloud)"
    echo ""
    echo "5. Go to SSL/TLS tab"
    echo "   - Mode: Full (strict) or Full"
    echo "   - Universal SSL: ✓ (should be auto)"
    echo ""
    echo "6. Wait 2-5 minutes for DNS propagation"
    echo ""
    echo "7. Test API:"
    echo "   curl https://api.muhhilmi.site/health"
    echo ""
    echo "=========================================="
    echo ""
}

cleanup_on_error() {
    log_error "Deployment failed. Checking for artifacts..."
    cd "$PROJECT_ROOT"
    rm -f bootstrap lambda-function.zip response.json tfplan
}

# Main execution
main() {
    log_info "Starting deployment to AWS Lambda with Cloudflare..."
    echo ""

    # Trap errors
    trap cleanup_on_error EXIT

    # Step 1: Check requirements
    check_requirements
    echo ""

    # Step 2: Verify variables
    verify_terraform_vars
    echo ""

    # Step 3: Terraform setup
    terraform_init
    echo ""

    terraform_validate
    echo ""

    terraform_plan
    echo ""

    # Step 4: Deploy infrastructure
    terraform_apply
    echo ""

    # Step 5: Build Lambda binary
    build_lambda_binary
    echo ""

    # Step 6: Deploy Lambda
    deploy_lambda
    echo ""

    # Step 7: Test Lambda
    test_lambda
    echo ""

    # Step 8: Test API Gateway
    test_api_gateway
    echo ""

    # Step 9: Show Cloudflare instructions
    cloudflare_instructions
    echo ""

    log_success "Deployment to AWS completed!"
    log_info "Next: Configure Cloudflare DNS (see instructions above)"

    trap - EXIT
}

# Show usage
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h          Show this help message"
    echo "  --tf-only            Run only Terraform (infrastructure)"
    echo "  --lambda-only        Run only Lambda deployment (code)"
    echo "  --test-only          Run only tests"
    echo ""
    echo "Example:"
    echo "  $0                   Full deployment"
    echo "  $0 --tf-only         Deploy infrastructure only"
    exit 0
fi

# Handle specific options
case "$1" in
    --tf-only)
        check_requirements
        verify_terraform_vars
        terraform_init
        terraform_validate
        terraform_plan
        terraform_apply
        get_api_endpoint
        cloudflare_instructions
        ;;
    --lambda-only)
        check_requirements
        build_lambda_binary
        deploy_lambda
        test_lambda
        ;;
    --test-only)
        test_lambda
        test_api_gateway
        ;;
    *)
        main
        ;;
esac
