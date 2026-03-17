# CI/CD Pipeline Template — GitHub Actions

Production-ready CI/CD pipelines for deploying to AWS (EC2, ECS, S3). Copy, customize, deploy.

```
  ┌─────────┐    ┌──────┐    ┌──────┐    ┌───────┐    ┌─────────┐    ┌──────────┐
  │  Push /  │───▶│ Lint │───▶│ Test │───▶│ Build │───▶│ Deploy  │───▶│  Deploy   │
  │   PR     │    │      │    │      │    │Docker │    │ Staging │    │Production │
  └─────────┘    └──────┘    └──────┘    └───────┘    └─────────┘    └──────────┘
                  flake8      pytest      ECR          Auto           Manual
                  black       coverage    Trivy scan   + Smoke test   + Approval
                  mypy        >80%                                    + Rollback
```

## What's Included

| Workflow | Trigger | What it does |
|---|---|---|
| `ci.yml` | Push to main, PRs | Lint → Test → Build Docker → Security Scan |
| `cd-staging.yml` | CI passes on main | Deploy to staging → Smoke tests → Notify |
| `cd-production.yml` | Manual trigger | Blue-green deploy → Health check → Auto-rollback |
| `pr-checks.yml` | Pull requests | Lint + Type check + Coverage gate (>80%) |

## Deployment Targets

Includes scripts for 3 deployment methods:

| Method | Script | Best for |
|---|---|---|
| **EC2 (SSH)** | `scripts/deploy-ec2.sh` | Simple apps, single server |
| **ECS (Fargate)** | `scripts/deploy-ecs.sh` | Containerized apps, auto-scaling |
| **S3 + CloudFront** | `scripts/deploy-s3.sh` | Static sites, SPAs |

## Quick Start

1. Copy `.github/workflows/` to your repo
2. Set up GitHub Secrets (see [Setup Guide](docs/SETUP.md))
3. Customize the Dockerfile for your app
4. Push to main — CI/CD runs automatically

## GitHub Secrets Required

```
AWS_ACCESS_KEY_ID         # IAM user access key
AWS_SECRET_ACCESS_KEY     # IAM user secret key
AWS_REGION                # e.g., us-east-1
ECR_REPOSITORY            # ECR repo URI
ECS_CLUSTER_STAGING       # ECS cluster name (staging)
ECS_CLUSTER_PRODUCTION    # ECS cluster name (production)
ECS_SERVICE               # ECS service name
EC2_HOST                  # EC2 public IP (for SSH deploy)
EC2_SSH_KEY               # Private SSH key (base64 encoded)
SLACK_WEBHOOK_URL         # Slack incoming webhook
S3_BUCKET                 # S3 bucket (for static deploy)
CLOUDFRONT_DISTRIBUTION_ID # CloudFront ID (for cache invalidation)
```

## Commands

```bash
make lint           # Run linters (flake8 + black check)
make test           # Run tests with coverage
make build          # Build Docker image locally
make deploy-staging # Deploy to staging via ECS
make deploy-prod    # Deploy to production via ECS
```

---

Built by **Vikas Munjal** | Open source under MIT License
