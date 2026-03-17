#!/bin/bash
# ──────────────────────────────────────────────────────────
# Deploy to AWS ECS (Fargate)
# Usage: ./deploy-ecs.sh <environment> <image_tag>
# ──────────────────────────────────────────────────────────
set -euo pipefail

ENVIRONMENT=${1:-staging}
IMAGE_TAG=${2:-latest}
CLUSTER=${ECS_CLUSTER:?"ECS_CLUSTER env var required"}
SERVICE=${ECS_SERVICE:?"ECS_SERVICE env var required"}
ECR_REPO=${ECR_REPOSITORY:?"ECR_REPOSITORY env var required"}

echo "═══════════════════════════════════════"
echo "  Deploying to ECS ($ENVIRONMENT)"
echo "  Cluster: $CLUSTER"
echo "  Service: $SERVICE"
echo "  Image:   $ECR_REPO:$IMAGE_TAG"
echo "═══════════════════════════════════════"

# Step 1: Get current task definition
echo "Fetching current task definition..."
TASK_DEF_ARN=$(aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --query 'services[0].taskDefinition' \
    --output text)
echo "Current task definition: $TASK_DEF_ARN"

# Step 2: Create new task definition with updated image
echo "Creating new task definition..."
TASK_DEF=$(aws ecs describe-task-definition \
    --task-definition "$TASK_DEF_ARN" \
    --query 'taskDefinition')

NEW_TASK_DEF=$(echo "$TASK_DEF" | jq \
    --arg IMAGE "$ECR_REPO:$IMAGE_TAG" \
    '.containerDefinitions[0].image = $IMAGE |
     del(.taskDefinitionArn, .revision, .status, .requiresAttributes,
         .compatibilities, .registeredAt, .registeredBy)')

NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
    --cli-input-json "$NEW_TASK_DEF" \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)
echo "New task definition: $NEW_TASK_DEF_ARN"

# Step 3: Update service with new task definition
echo "Updating ECS service..."
aws ecs update-service \
    --cluster "$CLUSTER" \
    --service "$SERVICE" \
    --task-definition "$NEW_TASK_DEF_ARN" \
    --force-new-deployment \
    --query 'service.serviceName' \
    --output text

# Step 4: Wait for service to stabilize
echo "Waiting for service to stabilize (this may take 2-5 minutes)..."
aws ecs wait services-stable \
    --cluster "$CLUSTER" \
    --services "$SERVICE"

echo "✅ ECS deployment successful!"
