#!/bin/bash

# Monitoring and Logs Script
# Tail logs dari Lambda dan API Gateway

REGION="ap-southeast-1"
PROJECT_NAME="anigmaa"

# Colors
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_menu() {
    echo ""
    echo "=========================================="
    echo "CloudWatch Logs & Monitoring"
    echo "=========================================="
    echo "1. Tail Lambda logs (real-time)"
    echo "2. Tail API Gateway logs (real-time)"
    echo "3. Show Lambda metrics (last hour)"
    echo "4. Show API Gateway metrics (last hour)"
    echo "5. Search for errors in Lambda logs"
    echo "6. Get Lambda function info"
    echo "7. Exit"
    echo "=========================================="
    echo -n "Select option: "
}

tail_lambda_logs() {
    log_info "Tailing Lambda logs (press Ctrl+C to stop)..."
    aws logs tail "/aws/lambda/${PROJECT_NAME}-backend" \
        --follow \
        --region "$REGION" \
        --format short
}

tail_api_logs() {
    log_info "Tailing API Gateway logs (press Ctrl+C to stop)..."
    aws logs tail "/aws/apigateway/${PROJECT_NAME}" \
        --follow \
        --region "$REGION" \
        --format short
}

lambda_metrics() {
    log_info "Lambda metrics for last hour..."
    echo ""

    FUNCTION_NAME="${PROJECT_NAME}-backend"

    echo -e "${GREEN}Invocations:${NC}"
    aws cloudwatch get-metric-statistics \
        --namespace AWS/Lambda \
        --metric-name Invocations \
        --dimensions Name=FunctionName,Value="$FUNCTION_NAME" \
        --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
        --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
        --period 300 \
        --statistics Sum \
        --region "$REGION" \
        --output table

    echo ""
    echo -e "${GREEN}Errors:${NC}"
    aws cloudwatch get-metric-statistics \
        --namespace AWS/Lambda \
        --metric-name Errors \
        --dimensions Name=FunctionName,Value="$FUNCTION_NAME" \
        --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
        --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
        --period 300 \
        --statistics Sum \
        --region "$REGION" \
        --output table

    echo ""
    echo -e "${GREEN}Duration (milliseconds):${NC}"
    aws cloudwatch get-metric-statistics \
        --namespace AWS/Lambda \
        --metric-name Duration \
        --dimensions Name=FunctionName,Value="$FUNCTION_NAME" \
        --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
        --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
        --period 300 \
        --statistics Average,Maximum \
        --region "$REGION" \
        --output table

    echo ""
    echo -e "${GREEN}Throttles:${NC}"
    aws cloudwatch get-metric-statistics \
        --namespace AWS/Lambda \
        --metric-name Throttles \
        --dimensions Name=FunctionName,Value="$FUNCTION_NAME" \
        --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
        --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
        --period 300 \
        --statistics Sum \
        --region "$REGION" \
        --output table
}

api_gateway_metrics() {
    log_info "API Gateway metrics for last hour..."
    echo ""

    API_NAME="${PROJECT_NAME}-backend-api"

    echo -e "${GREEN}Count (requests):${NC}"
    aws cloudwatch get-metric-statistics \
        --namespace AWS/ApiGateway \
        --metric-name Count \
        --dimensions Name=ApiName,Value="$API_NAME" \
        --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
        --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
        --period 300 \
        --statistics Sum \
        --region "$REGION" \
        --output table

    echo ""
    echo -e "${GREEN}4XXError (client errors):${NC}"
    aws cloudwatch get-metric-statistics \
        --namespace AWS/ApiGateway \
        --metric-name 4XXError \
        --dimensions Name=ApiName,Value="$API_NAME" \
        --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
        --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
        --period 300 \
        --statistics Sum \
        --region "$REGION" \
        --output table

    echo ""
    echo -e "${GREEN}5XXError (server errors):${NC}"
    aws cloudwatch get-metric-statistics \
        --namespace AWS/ApiGateway \
        --metric-name 5XXError \
        --dimensions Name=ApiName,Value="$API_NAME" \
        --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
        --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
        --period 300 \
        --statistics Sum \
        --region "$REGION" \
        --output table

    echo ""
    echo -e "${GREEN}Latency (milliseconds):${NC}"
    aws cloudwatch get-metric-statistics \
        --namespace AWS/ApiGateway \
        --metric-name Latency \
        --dimensions Name=ApiName,Value="$API_NAME" \
        --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
        --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
        --period 300 \
        --statistics Average,Maximum \
        --region "$REGION" \
        --output table
}

search_errors() {
    log_warn "Searching for errors in Lambda logs (last 1 hour)..."
    echo ""

    aws logs start-query \
        --log-group-name "/aws/lambda/${PROJECT_NAME}-backend" \
        --start-time "$(date -d '1 hour ago' +%s)" \
        --end-time "$(date +%s)" \
        --query-string 'fields @timestamp, @message | filter @message like /error|Error|ERROR|exception|Exception|failed|Failed/i | limit 100' \
        --region "$REGION" > /tmp/query.json

    QUERY_ID=$(grep -o '"queryId":"[^"]*' /tmp/query.json | head -1 | cut -d'"' -f4)

    echo "Query ID: $QUERY_ID"
    echo "Waiting for results..."

    # Wait for query to complete
    sleep 2

    # Get results
    aws logs get-query-results \
        --query-id "$QUERY_ID" \
        --region "$REGION" \
        --output table

    rm -f /tmp/query.json
}

lambda_info() {
    log_info "Lambda function information..."
    echo ""

    FUNCTION_NAME="${PROJECT_NAME}-backend"

    aws lambda get-function-configuration \
        --function-name "$FUNCTION_NAME" \
        --region "$REGION" \
        --output table

    echo ""
    echo -e "${GREEN}VPC Configuration:${NC}"
    aws lambda get-function-configuration \
        --function-name "$FUNCTION_NAME" \
        --region "$REGION" \
        --query 'VpcConfig' \
        --output table

    echo ""
    echo -e "${GREEN}Environment Variables:${NC}"
    aws lambda get-function-configuration \
        --function-name "$FUNCTION_NAME" \
        --region "$REGION" \
        --query 'Environment.Variables' \
        --output table

    echo ""
    echo -e "${GREEN}Recent Invocations:${NC}"
    aws logs tail "/aws/lambda/${PROJECT_NAME}-backend" \
        --region "$REGION" \
        --format short \
        --max-items 20
}

# Main loop
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  (none)           Interactive menu"
    echo "  --lambda-logs    Tail Lambda logs"
    echo "  --api-logs       Tail API Gateway logs"
    echo "  --errors         Search for errors"
    echo "  --lambda-info    Show Lambda info"
    echo ""
    exit 0
fi

if [ -n "$1" ]; then
    case "$1" in
        --lambda-logs)
            tail_lambda_logs
            ;;
        --api-logs)
            tail_api_logs
            ;;
        --errors)
            search_errors
            ;;
        --lambda-info)
            lambda_info
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
else
    while true; do
        show_menu
        read -r option

        case $option in
            1) tail_lambda_logs ;;
            2) tail_api_logs ;;
            3) lambda_metrics ;;
            4) api_gateway_metrics ;;
            5) search_errors ;;
            6) lambda_info ;;
            7)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                log_error "Invalid option"
                ;;
        esac
    done
fi
