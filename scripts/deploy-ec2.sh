#!/bin/bash
# ──────────────────────────────────────────────────────────
# Deploy to EC2 via SSH
# Usage: ./deploy-ec2.sh <environment> <image_tag>
# ──────────────────────────────────────────────────────────
set -euo pipefail

ENVIRONMENT=${1:-staging}
IMAGE_TAG=${2:-latest}
EC2_HOST=${EC2_HOST:?"EC2_HOST environment variable is required"}
EC2_USER=${EC2_USER:-ubuntu}
APP_DIR=${APP_DIR:-/opt/app}

echo "═══════════════════════════════════════"
echo "  Deploying to EC2 ($ENVIRONMENT)"
echo "  Host: $EC2_HOST"
echo "  Image: $IMAGE_TAG"
echo "═══════════════════════════════════════"

# Save current version for rollback
PREVIOUS_VERSION=$(ssh -o StrictHostKeyChecking=no "$EC2_USER@$EC2_HOST" \
    "cat $APP_DIR/.current-version 2>/dev/null || echo 'none'")
echo "Previous version: $PREVIOUS_VERSION"

# Deploy
ssh -o StrictHostKeyChecking=no "$EC2_USER@$EC2_HOST" << DEPLOY
    set -e
    cd $APP_DIR

    # Pull latest code
    git fetch origin main
    git reset --hard origin/main

    # Pull and restart containers
    docker compose pull
    docker compose up -d --build --remove-orphans

    # Wait for health check
    echo "Waiting for app to be healthy..."
    for i in {1..30}; do
        if curl -sf http://localhost/health > /dev/null 2>&1; then
            echo "App is healthy!"
            echo "$IMAGE_TAG" > .current-version
            exit 0
        fi
        echo "  Attempt \$i/30 — waiting..."
        sleep 2
    done

    echo "ERROR: App failed health check after 60 seconds"
    exit 1
DEPLOY

if [ $? -ne 0 ]; then
    echo "Deployment failed — attempting rollback..."
    ssh -o StrictHostKeyChecking=no "$EC2_USER@$EC2_HOST" << ROLLBACK
        cd $APP_DIR
        git reset --hard $PREVIOUS_VERSION
        docker compose up -d --build
ROLLBACK
    echo "Rollback complete."
    exit 1
fi

echo "✅ EC2 deployment successful!"
