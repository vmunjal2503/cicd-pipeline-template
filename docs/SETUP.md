# Setup Guide — CI/CD Pipeline

Step-by-step instructions to configure the CI/CD pipeline for your project.

## 1. AWS Setup

### Create an IAM User for CI/CD

```bash
# Create user
aws iam create-user --user-name github-actions-deployer

# Attach policies (scope these down for production)
aws iam attach-user-policy --user-name github-actions-deployer \
    --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess
aws iam attach-user-policy --user-name github-actions-deployer \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
aws iam attach-user-policy --user-name github-actions-deployer \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# Create access key
aws iam create-access-key --user-name github-actions-deployer
```

### Create ECR Repository

```bash
aws ecr create-repository --repository-name myapp --region us-east-1
```

## 2. GitHub Secrets

Go to your repo → Settings → Secrets and Variables → Actions.

Add these secrets:

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | From IAM user above |
| `AWS_SECRET_ACCESS_KEY` | From IAM user above |
| `AWS_REGION` | `us-east-1` |
| `ECR_REPOSITORY` | `123456789.dkr.ecr.us-east-1.amazonaws.com/myapp` |
| `ECS_CLUSTER_STAGING` | Your staging cluster name |
| `ECS_CLUSTER_PRODUCTION` | Your production cluster name |
| `ECS_SERVICE` | Your ECS service name |
| `SLACK_WEBHOOK_URL` | From Slack incoming webhook |

## 3. GitHub Environment (for Production Approval)

1. Go to Settings → Environments → New environment
2. Name: `production`
3. Enable "Required reviewers" → add yourself
4. This ensures production deploys require manual approval

## 4. First Deployment

```bash
# Push to main to trigger CI
git push origin main

# CI will: lint → test → build → push to ECR
# CD-staging will: deploy to ECS staging automatically
# CD-production: trigger manually from GitHub Actions tab
```

## 5. Slack Notifications

1. Go to api.slack.com → Create App → Incoming Webhooks
2. Add webhook to your #deployments channel
3. Copy the webhook URL to GitHub Secrets as `SLACK_WEBHOOK_URL`
