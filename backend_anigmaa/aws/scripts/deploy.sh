#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="anigmaa"
AWS_REGION="ap-southeast-1"
TERRAFORM_DIR="./aws/terraform"

echo -e "${GREEN}🚀 Starting AWS deployment for ${PROJECT_NAME}${NC}"

# Check if required tools are installed
check_requirements() {
    echo -e "${YELLOW}📋 Checking requirements...${NC}"

    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}❌ Terraform is not installed${NC}"
        exit 1
    fi

    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed${NC}"
        exit 1
    fi

    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ All requirements met${NC}"
}

# Check AWS credentials
check_aws_credentials() {
    echo -e "${YELLOW}🔐 Checking AWS credentials...${NC}"

    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured${NC}"
        echo "Please run: aws configure"
        exit 1
    fi

    echo -e "${GREEN}✅ AWS credentials configured${NC}"
}

# Initialize Terraform
init_terraform() {
    echo -e "${YELLOW}🏗️  Initializing Terraform...${NC}"

    cd $TERRAFORM_DIR
    terraform init

    echo -e "${GREEN}✅ Terraform initialized${NC}"
}

# Plan Terraform deployment
plan_terraform() {
    echo -e "${YELLOW}📋 Planning Terraform deployment...${NC}"

    terraform plan -var-file="terraform.tfvars"

    echo -e "${YELLOW}⚠️  Please review the plan above${NC}"
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Deployment cancelled${NC}"
        exit 1
    fi
}

# Apply Terraform configuration
apply_terraform() {
    echo -e "${YELLOW}🚀 Applying Terraform configuration...${NC}"

    terraform apply -var-file="terraform.tfvars" -auto-approve

    echo -e "${GREEN}✅ Infrastructure deployed${NC}"
}

# Get ECR repository URL
get_ecr_url() {
    echo -e "${YELLOW}📍 Getting ECR repository URL...${NC}"

    ECR_URL=$(terraform output -raw ecr_repository_url)
    echo "ECR URL: $ECR_URL"

    echo -e "${GREEN}✅ ECR URL retrieved${NC}"
}

# Build and push Docker image
build_and_push_image() {
    echo -e "${YELLOW}🐳 Building and pushing Docker image...${NC}"

    # Go back to project root
    cd ../../

    # Get AWS account ID and region
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

    # Login to ECR
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

    # Build image
    docker build -t $PROJECT_NAME-backend .

    # Tag image
    docker tag $PROJECT_NAME-backend:latest $ECR_URL:latest

    # Push image
    docker push $ECR_URL:latest

    echo -e "${GREEN}✅ Docker image built and pushed${NC}"
}

# Update ECS service
update_ecs_service() {
    echo -e "${YELLOW}🔄 Updating ECS service...${NC}"

    cd $TERRAFORM_DIR

    # Get ECS cluster and service names
    CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
    SERVICE_NAME=$(terraform output -raw ecs_service_name)

    # Force new deployment
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --force-new-deployment \
        --region $AWS_REGION

    echo -e "${GREEN}✅ ECS service updated${NC}"
}

# Wait for deployment to complete
wait_for_deployment() {
    echo -e "${YELLOW}⏳ Waiting for deployment to complete...${NC}"

    CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
    SERVICE_NAME=$(terraform output -raw ecs_service_name)

    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $AWS_REGION

    echo -e "${GREEN}✅ Deployment completed${NC}"
}

# Show deployment information
show_deployment_info() {
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo
    echo -e "${YELLOW}📋 Deployment Information:${NC}"

    ALB_DNS=$(terraform output -raw alb_dns_name)
    echo "Application URL: http://$ALB_DNS"
    echo "Health Check: http://$ALB_DNS/health"

    echo
    echo -e "${YELLOW}📊 Useful Commands:${NC}"
    echo "View logs: aws logs tail /ecs/$PROJECT_NAME-backend --follow --region $AWS_REGION"
    echo "ECS Console: https://console.aws.amazon.com/ecs/home?region=$AWS_REGION#/clusters"
    echo "RDS Console: https://console.aws.amazon.com/rds/home?region=$AWS_REGION"
}

# Main deployment function
main() {
    check_requirements
    check_aws_credentials
    init_terraform
    plan_terraform
    apply_terraform
    get_ecr_url
    build_and_push_image
    update_ecs_service
    wait_for_deployment
    show_deployment_info
}

# Run main function
main