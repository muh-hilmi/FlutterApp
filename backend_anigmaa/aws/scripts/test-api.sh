#!/bin/bash

# API Testing Script for Cloudflare + AWS Lambda
# Tests various endpoints and functionality

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

API_ENDPOINT="${1:-https://api.muhhilmi.site}"

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

test_health() {
    log_test "Testing /health endpoint..."

    RESPONSE=$(curl -s -w "\n%{http_code}" "$API_ENDPOINT/health")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n-1)

    if [ "$HTTP_CODE" == "200" ]; then
        log_pass "Health check passed (HTTP $HTTP_CODE)"
        log_info "Response: $BODY"
    else
        log_fail "Health check failed (HTTP $HTTP_CODE)"
        return 1
    fi
}

test_cloudflare_headers() {
    log_test "Testing Cloudflare headers..."

    HEADERS=$(curl -s -I "$API_ENDPOINT/health")

    if echo "$HEADERS" | grep -q "CF-Ray"; then
        log_pass "Cloudflare proxy detected (CF-Ray header found)"
        CFRAY=$(echo "$HEADERS" | grep "CF-Ray" | cut -d' ' -f2)
        log_info "CF-Ray: $CFRAY"
    else
        log_fail "Cloudflare proxy not detected"
        return 1
    fi

    if echo "$HEADERS" | grep -q "Server: cloudflare"; then
        log_pass "Cloudflare server header confirmed"
    else
        log_fail "Cloudflare server header not found"
    fi
}

test_cors() {
    log_test "Testing CORS headers..."

    HEADERS=$(curl -s -I \
        -H "Origin: https://muhhilmi.site" \
        -H "Access-Control-Request-Method: GET" \
        "$API_ENDPOINT/health")

    if echo "$HEADERS" | grep -q "Access-Control-Allow-Origin"; then
        log_pass "CORS headers present"
        ORIGIN=$(echo "$HEADERS" | grep "Access-Control-Allow-Origin" | cut -d' ' -f2)
        log_info "Allow-Origin: $ORIGIN"
    else
        log_fail "CORS headers not found"
        return 1
    fi
}

test_ssl_tls() {
    log_test "Testing SSL/TLS..."

    if curl -s --ssl-reqd "$API_ENDPOINT/health" > /dev/null 2>&1; then
        log_pass "SSL/TLS connection successful"
    else
        log_fail "SSL/TLS connection failed"
        return 1
    fi

    # Check certificate
    CERT_INFO=$(echo | openssl s_client -servername api.muhhilmi.site -connect api.muhhilmi.site:443 2>/dev/null | openssl x509 -noout -text 2>/dev/null)

    if echo "$CERT_INFO" | grep -q "Cloudflare"; then
        log_pass "Cloudflare certificate detected"
    else
        log_fail "Certificate check inconclusive"
    fi
}

test_response_time() {
    log_test "Testing response time..."

    TIME=$(curl -s -o /dev/null -w "%{time_total}" "$API_ENDPOINT/health")
    TIME_MS=$(echo "$TIME * 1000" | bc)

    log_info "Response time: ${TIME_MS}ms"

    if (( $(echo "$TIME < 2" | bc -l) )); then
        log_pass "Response time is good (< 2 seconds)"
    elif (( $(echo "$TIME < 5" | bc -l) )); then
        log_fail "Response time is acceptable but could be better (< 5 seconds)"
    else
        log_fail "Response time is slow (> 5 seconds)"
        return 1
    fi
}

test_concurrent_requests() {
    log_test "Testing concurrent requests (10 simultaneous)..."

    SUCCESS=0
    TOTAL=10

    for i in $(seq 1 $TOTAL); do
        {
            if curl -s -o /dev/null -w "%{http_code}" "$API_ENDPOINT/health" | grep -q "200"; then
                ((SUCCESS++))
            fi
        } &
    done

    wait

    if [ $SUCCESS -eq $TOTAL ]; then
        log_pass "All concurrent requests succeeded ($SUCCESS/$TOTAL)"
    else
        log_fail "Some concurrent requests failed ($SUCCESS/$TOTAL)"
        return 1
    fi
}

test_dns_resolution() {
    log_test "Testing DNS resolution..."

    if command -v dig &> /dev/null; then
        RESULT=$(dig +short api.muhhilmi.site @8.8.8.8 | head -1)
        if [ -z "$RESULT" ]; then
            log_fail "DNS resolution failed"
            return 1
        else
            log_pass "DNS resolves to: $RESULT"
        fi
    else
        log_info "dig not available, skipping detailed DNS test"
    fi
}

show_summary() {
    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo "API Endpoint: $API_ENDPOINT"
    echo ""
    echo "Tests completed. Check results above."
    echo ""
}

main() {
    echo "=========================================="
    echo "API Testing Suite"
    echo "=========================================="
    echo "Endpoint: $API_ENDPOINT"
    echo ""

    # Check if endpoint is reachable
    if ! curl -s -o /dev/null -w "%{http_code}" "$API_ENDPOINT/health" | grep -q "200"; then
        log_fail "API endpoint is not reachable at $API_ENDPOINT"
        echo ""
        echo "Make sure:"
        echo "  1. Cloudflare DNS is configured (api.muhhilmi.site → API Gateway endpoint)"
        echo "  2. DNS has propagated (wait 2-5 minutes)"
        echo "  3. Lambda function is deployed and running"
        exit 1
    fi

    # Run tests
    test_dns_resolution
    echo ""

    test_health
    echo ""

    test_cloudflare_headers
    echo ""

    test_ssl_tls
    echo ""

    test_cors
    echo ""

    test_response_time
    echo ""

    test_concurrent_requests
    echo ""

    show_summary
}

# Show usage
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "Usage: $0 [API_ENDPOINT]"
    echo ""
    echo "Examples:"
    echo "  $0                                          # Test api.muhhilmi.site"
    echo "  $0 https://d-xxxxx.execute-api.ap-southeast-1.amazonaws.com/prod  # Test direct API Gateway"
    exit 0
fi

main
