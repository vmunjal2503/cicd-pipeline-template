#!/bin/bash
# ──────────────────────────────────────────────────────────
# Deploy static site to S3 + CloudFront
# Usage: ./deploy-s3.sh <build_dir>
# ──────────────────────────────────────────────────────────
set -euo pipefail

BUILD_DIR=${1:-./build}
S3_BUCKET=${S3_BUCKET:?"S3_BUCKET env var required"}
DISTRIBUTION_ID=${CLOUDFRONT_DISTRIBUTION_ID:-""}

echo "═══════════════════════════════════════"
echo "  Deploying static site to S3"
echo "  Bucket: $S3_BUCKET"
echo "  Source: $BUILD_DIR"
echo "═══════════════════════════════════════"

# Verify build directory exists
if [ ! -d "$BUILD_DIR" ]; then
    echo "ERROR: Build directory '$BUILD_DIR' not found."
    echo "Run your build command first (e.g., npm run build)"
    exit 1
fi

# Sync files to S3
echo "Syncing files to S3..."
aws s3 sync "$BUILD_DIR" "s3://$S3_BUCKET" \
    --delete \
    --cache-control "public, max-age=31536000" \
    --exclude "*.html" \
    --exclude "service-worker.js"

# Upload HTML files with shorter cache
aws s3 sync "$BUILD_DIR" "s3://$S3_BUCKET" \
    --cache-control "public, max-age=0, must-revalidate" \
    --include "*.html" \
    --include "service-worker.js"

echo "S3 sync complete."

# Invalidate CloudFront cache
if [ -n "$DISTRIBUTION_ID" ]; then
    echo "Invalidating CloudFront cache..."
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id "$DISTRIBUTION_ID" \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)
    echo "CloudFront invalidation created: $INVALIDATION_ID"
fi

echo "✅ S3 deployment successful!"
