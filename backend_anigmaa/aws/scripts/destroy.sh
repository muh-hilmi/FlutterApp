#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_NAME="anigmaa"
TERRAFORM_DIR="./aws/terraform"

echo -e "${RED}🚨 DESTRUCTION SCRIPT - THIS WILL DELETE ALL AWS RESOURCES${NC}"

# Warning and confirmation
show_warning() {
    echo -e "${RED}⚠️  WARNING: This script will PERMANENTLY DELETE all AWS resources!${NC}"
    echo -e "${RED}⚠️  This includes:${NC}"
    echo "   - ECS Cluster and Services"
    echo "   - RDS Database (with all data)"
    echo "   - ElastiCache Redis"
    echo "   - S3 Bucket (with all files)"
    echo "   - Load Balancer"
    echo "   - VPC and all networking components"
    echo "   - All IAM roles and policies"
    echo ""
    echo -e "${YELLOW}📋 Make sure you have:${NC}"
    echo "   - Backed up your database"
    echo "   - Downloaded important files from S3"
    echo "   - Exported any necessary configuration"
    echo ""
}

# Final confirmation
get_confirmation() {
    echo -e "${RED}Are you absolutely sure you want to destroy everything?${NC}"
    read -p "Type 'DESTROY' in capital letters to continue: " confirmation

    if [ "$confirmation" != "DESTROY" ]; then
        echo -e "${GREEN}✅ Destruction cancelled${NC}"
        exit 0
    fi

    echo -e "${RED}Final confirmation: Type the project name '$PROJECT_NAME' to proceed:${NC}"
    read -p "> " project_confirmation

    if [ "$project_confirmation" != "$PROJECT_NAME" ]; then
        echo -e "${GREEN}✅ Destruction cancelled${NC}"
        exit 0
    fi
}

# Empty S3 bucket before destruction
empty_s3_bucket() {
    echo -e "${YELLOW}🗑️  Emptying S3 bucket...${NC}"

    cd $TERRAFORM_DIR

    # Get S3 bucket name
    if ! BUCKET_NAME=$(terraform output -raw s3_bucket_name 2>/dev/null); then
        echo -e "${YELLOW}⚠️  Could not retrieve S3 bucket name, skipping...${NC}"
        return
    fi

    echo "Emptying bucket: $BUCKET_NAME"

    # Delete all objects and versions
    aws s3api delete-objects \
        --bucket "$BUCKET_NAME" \
        --delete "$(aws s3api list-object-versions \
            --bucket "$BUCKET_NAME" \
            --output json \
            --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')" \
        --region ap-southeast-1 2>/dev/null || true

    # Delete all delete markers
    aws s3api delete-objects \
        --bucket "$BUCKET_NAME" \
        --delete "$(aws s3api list-object-versions \
            --bucket "$BUCKET_NAME" \
            --output json \
            --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')" \
        --region ap-southeast-1 2>/dev/null || true

    echo -e "${GREEN}✅ S3 bucket emptied${NC}"
}

# Delete ECR images
delete_ecr_images() {
    echo -e "${YELLOW}🐳 Deleting ECR images...${NC}"

    # Get ECR repository name
    if ! ECR_REPO=$(terraform output -raw ecr_repository_url 2>/dev/null); then
        echo -e "${YELLOW}⚠️  Could not retrieve ECR repository, skipping...${NC}"
        return
    fi

    # Extract repository name from URL
    REPO_NAME=$(echo $ECR_REPO | cut -d'/' -f2)

    # Delete all images
    aws ecr list-images \
        --repository-name "$REPO_NAME" \
        --region ap-southeast-1 \
        --query 'imageIds[*]' \
        --output json | \
    aws ecr batch-delete-image \
        --repository-name "$REPO_NAME" \
        --region ap-southeast-1 \
        --image-ids file:///dev/stdin || true

    echo -e "${GREEN}✅ ECR images deleted${NC}"
}

# Disable RDS deletion protection
disable_rds_protection() {
    echo -e "${YELLOW}🗃️  Disabling RDS deletion protection...${NC}"

    # Get RDS identifier
    if ! RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null); then
        echo -e "${YELLOW}⚠️  Could not retrieve RDS endpoint, skipping...${NC}"
        return
    fi

    # Extract identifier from endpoint
    RDS_IDENTIFIER=$(echo $RDS_ENDPOINT | cut -d'.' -f1)

    # Disable deletion protection
    aws rds modify-db-instance \
        --db-instance-identifier "$RDS_IDENTIFIER" \
        --no-deletion-protection \
        --apply-immediately \
        --region ap-southeast-1 || true

    echo -e "${GREEN}✅ RDS deletion protection disabled${NC}"
}

# Run Terraform destroy
destroy_infrastructure() {
    echo -e "${YELLOW}💥 Destroying infrastructure with Terraform...${NC}"

    terraform destroy -var-file="terraform.tfvars" -auto-approve

    echo -e "${GREEN}✅ Infrastructure destroyed${NC}"
}

# Clean up Terraform state
cleanup_terraform() {
    echo -e "${YELLOW}🧹 Cleaning up Terraform state...${NC}"

    # Remove .terraform directory
    rm -rf .terraform

    # Remove terraform.tfstate files
    rm -f terraform.tfstate*

    echo -e "${GREEN}✅ Terraform state cleaned${NC}"
}

# Main destruction function
main() {
    show_warning
    get_confirmation

    echo -e "${RED}🚀 Starting destruction process...${NC}"

    cd $TERRAFORM_DIR

    # Pre-destruction cleanup
    empty_s3_bucket
    delete_ecr_images
    disable_rds_protection

    # Wait a moment for changes to propagate
    echo -e "${YELLOW}⏳ Waiting for changes to propagate...${NC}"
    sleep 30

    # Destroy infrastructure
    destroy_infrastructure

    # Post-destruction cleanup
    cleanup_terraform

    echo -e "${GREEN}🎉 Destruction completed successfully!${NC}"
    echo -e "${GREEN}All AWS resources have been deleted.${NC}"
}

# Show help
show_help() {
    echo "Infrastructure Destruction Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  destroy    Destroy all AWS resources (default)"
    echo "  help       Show this help message"
    echo ""
    echo "This script will permanently delete:"
    echo "  - All ECS resources"
    echo "  - RDS database with all data"
    echo "  - S3 bucket with all files"
    echo "  - All networking resources"
    echo "  - All IAM resources"
    echo ""
}

# Parse command line arguments
case "${1:-destroy}" in
    destroy)
        main
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