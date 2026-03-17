#!/bin/bash
# ──────────────────────────────────────────────────────────
# Post-deployment smoke tests
# Usage: ./smoke-test.sh <environment>
# ──────────────────────────────────────────────────────────
set -euo pipefail

ENVIRONMENT=${1:-staging}

# Set URL based on environment
case $ENVIRONMENT in
    staging)    BASE_URL=${STAGING_URL:-"https://staging.example.com"} ;;
    production) BASE_URL=${PRODUCTION_URL:-"https://example.com"} ;;
    *)          BASE_URL="http://localhost" ;;
esac

echo "═══════════════════════════════════════"
echo "  Smoke Tests ($ENVIRONMENT)"
echo "  URL: $BASE_URL"
echo "═══════════════════════════════════════"

PASSED=0
FAILED=0

run_test() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}
    local max_time=${4:-10}

    response=$(curl -s -o /dev/null -w "%{http_code}:%{time_total}" \
        --connect-timeout 5 --max-time "$max_time" "$url" 2>/dev/null || echo "000:0")

    http_code=$(echo "$response" | cut -d: -f1)
    response_time=$(echo "$response" | cut -d: -f2)

    if [ "$http_code" = "$expected_code" ]; then
        echo "  ✅ $name — HTTP $http_code (${response_time}s)"
        PASSED=$((PASSED + 1))
    else
        echo "  ❌ $name — HTTP $http_code (expected $expected_code)"
        FAILED=$((FAILED + 1))
    fi
}

# ──────────────── Run Tests ────────────────
echo ""
echo "Running tests..."

run_test "Health endpoint"    "$BASE_URL/health"     200
run_test "Root endpoint"      "$BASE_URL/"           200
run_test "API info"           "$BASE_URL/api/info"   200
run_test "404 handling"       "$BASE_URL/nonexistent" 404

echo ""
echo "═══════════════════════════════════════"
echo "  Results: $PASSED passed, $FAILED failed"
echo "═══════════════════════════════════════"

if [ $FAILED -gt 0 ]; then
    echo "❌ Smoke tests FAILED"
    exit 1
fi

echo "✅ All smoke tests passed"
