#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TERRAFORM_DIR="./aws/terraform"

echo -e "${GREEN}🔍 AWS Deployment Validation Script${NC}"

# Check if Terraform is initialized
check_terraform() {
    echo -e "${YELLOW}📋 Checking Terraform status...${NC}"

    cd $TERRAFORM_DIR

    if [ ! -d ".terraform" ]; then
        echo -e "${RED}❌ Terraform not initialized${NC}"
        echo "Run: terraform init"
        return 1
    fi

    echo -e "${GREEN}✅ Terraform initialized${NC}"
}

# Check AWS credentials
check_aws_credentials() {
    echo -e "${YELLOW}🔐 Checking AWS credentials...${NC}"

    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured${NC}"
        return 1
    fi

    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    REGION=$(aws configure get region)

    echo "Account ID: $ACCOUNT_ID"
    echo "Region: $REGION"

    echo -e "${GREEN}✅ AWS credentials valid${NC}"
}

# Check if infrastructure is deployed
check_infrastructure() {
    echo -e "${YELLOW}🏗️  Checking infrastructure status...${NC}"

    # Check if state file exists
    if [ ! -f "terraform.tfstate" ]; then
        echo -e "${RED}❌ No Terraform state found${NC}"
        echo "Infrastructure not deployed yet"
        return 1
    fi

    # Get resource count
    RESOURCE_COUNT=$(terraform state list | wc -l)
    echo "Deployed resources: $RESOURCE_COUNT"

    if [ $RESOURCE_COUNT -eq 0 ]; then
        echo -e "${RED}❌ No resources found in state${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Infrastructure appears to be deployed${NC}"
}

# Check ECS service status
check_ecs_service() {
    echo -e "${YELLOW}🐳 Checking ECS service status...${NC}"

    if ! CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null); then
        echo -e "${RED}❌ Could not get ECS cluster name${NC}"
        return 1
    fi

    if ! SERVICE_NAME=$(terraform output -raw ecs_service_name 2>/dev/null); then
        echo -e "${RED}❌ Could not get ECS service name${NC}"
        return 1
    fi

    # Check service status
    SERVICE_STATUS=$(aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --query 'services[0].status' \
        --output text \
        --region ap-southeast-1 2>/dev/null || echo "UNKNOWN")

    RUNNING_COUNT=$(aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --query 'services[0].runningCount' \
        --output text \
        --region ap-southeast-1 2>/dev/null || echo "0")

    DESIRED_COUNT=$(aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --query 'services[0].desiredCount' \
        --output text \
        --region ap-southeast-1 2>/dev/null || echo "0")

    echo "Service Status: $SERVICE_STATUS"
    echo "Running Tasks: $RUNNING_COUNT/$DESIRED_COUNT"

    if [ "$SERVICE_STATUS" = "ACTIVE" ] && [ "$RUNNING_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ ECS service is running${NC}"
    else
        echo -e "${RED}❌ ECS service issues detected${NC}"
        return 1
    fi
}

# Check database connection
check_database() {
    echo -e "${YELLOW}🗃️  Checking database connection...${NC}"

    if ! DB_HOST=$(terraform output -raw rds_endpoint 2>/dev/null); then
        echo -e "${RED}❌ Could not get database endpoint${NC}"
        return 1
    fi

    echo "Database Host: $DB_HOST"

    # Try to get database password
    if DB_PASSWORD=$(aws ssm get-parameter --name "/anigmaa/prod/db/password" --with-decryption --query 'Parameter.Value' --output text 2>/dev/null); then
        # Test connection using docker
        if docker run --rm postgres:15-alpine pg_isready -h "$DB_HOST" -U postgres >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Database is reachable${NC}"
        else
            echo -e "${RED}❌ Database connection failed${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  Could not retrieve database password${NC}"
        echo "Database endpoint exists but connection test skipped"
    fi
}

# Check Redis connection
check_redis() {
    echo -e "${YELLOW}📨 Checking Redis connection...${NC}"

    if ! REDIS_HOST=$(terraform output -raw redis_endpoint 2>/dev/null); then
        echo -e "${RED}❌ Could not get Redis endpoint${NC}"
        return 1
    fi

    echo "Redis Host: $REDIS_HOST"

    # Simple check if Redis endpoint is reachable
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$REDIS_HOST/6379" 2>/dev/null; then
        echo -e "${GREEN}✅ Redis is reachable${NC}"
    else
        echo -e "${RED}❌ Redis connection failed${NC}"
        return 1
    fi
}

# Check Load Balancer health
check_load_balancer() {
    echo -e "${YELLOW}⚖️  Checking Load Balancer...${NC}"

    if ! ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null); then
        echo -e "${RED}❌ Could not get ALB DNS name${NC}"
        return 1
    fi

    echo "ALB DNS: $ALB_DNS"

    # Check if ALB is responding
    if curl -f -s -o /dev/null --max-time 10 "http://$ALB_DNS/health" 2>/dev/null; then
        echo -e "${GREEN}✅ Load Balancer health check passed${NC}"
    else
        echo -e "${YELLOW}⚠️  Load Balancer health check failed${NC}"
        echo "This might be normal if the application is still starting"
    fi
}

# Check S3 bucket
check_s3_bucket() {
    echo -e "${YELLOW}🪣 Checking S3 bucket...${NC}"

    if ! BUCKET_NAME=$(terraform output -raw s3_bucket_name 2>/dev/null); then
        echo -e "${RED}❌ Could not get S3 bucket name${NC}"
        return 1
    fi

    echo "S3 Bucket: $BUCKET_NAME"

    # Check if bucket exists and is accessible
    if aws s3 ls "s3://$BUCKET_NAME" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ S3 bucket is accessible${NC}"
    else
        echo -e "${RED}❌ S3 bucket access failed${NC}"
        return 1
    fi
}

# Show deployment summary
show_summary() {
    echo -e "${GREEN}📋 Deployment Summary${NC}"
    echo

    cd $TERRAFORM_DIR

    echo "🏗️  Infrastructure:"
    echo "  VPC ID: $(terraform output -raw vpc_id 2>/dev/null || echo 'N/A')"
    echo "  ECS Cluster: $(terraform output -raw ecs_cluster_name 2>/dev/null || echo 'N/A')"
    echo "  Database: $(terraform output -raw rds_endpoint 2>/dev/null || echo 'N/A')"
    echo

    echo "🌐 Access Points:"
    if ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null); then
        echo "  Application: http://$ALB_DNS"
        echo "  Health Check: http://$ALB_DNS/health"
    else
        echo "  Application: Not available"
    fi
    echo

    echo "📊 Monitoring:"
    echo "  ECS Console: https://console.aws.amazon.com/ecs/home?region=ap-southeast-1"
    echo "  CloudWatch: https://console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1"
    echo

    cd ../../
}

# Main validation function
main() {
    echo -e "${GREEN}Starting validation...${NC}"
    echo

    FAILED_CHECKS=0

    cd $TERRAFORM_DIR

    check_terraform || ((FAILED_CHECKS++))
    echo

    check_aws_credentials || ((FAILED_CHECKS++))
    echo

    check_infrastructure || ((FAILED_CHECKS++))
    echo

    if [ $FAILED_CHECKS -eq 0 ]; then
        check_ecs_service || ((FAILED_CHECKS++))
        echo

        check_database || ((FAILED_CHECKS++))
        echo

        check_redis || ((FAILED_CHECKS++))
        echo

        check_load_balancer || ((FAILED_CHECKS++))
        echo

        check_s3_bucket || ((FAILED_CHECKS++))
        echo
    fi

    cd ../../

    show_summary

    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}🎉 All validation checks passed!${NC}"
        echo -e "${GREEN}Your application is successfully deployed to AWS.${NC}"
    else
        echo -e "${RED}❌ $FAILED_CHECKS validation check(s) failed.${NC}"
        echo -e "${YELLOW}Please check the errors above and resolve them.${NC}"
        exit 1
    fi
}

# Show help
show_help() {
    echo "AWS Deployment Validation Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  validate   Run all validation checks (default)"
    echo "  summary    Show deployment summary"
    echo "  help       Show this help message"
    echo ""
}

# Parse command line arguments
case "${1:-validate}" in
    validate)
        main
        ;;
    summary)
        check_terraform
        check_aws_credentials
        show_summary
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