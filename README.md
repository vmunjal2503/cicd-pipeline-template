# CI/CD Pipeline Template

**Copy these GitHub Actions workflows into your repo — get automated testing and deployment in 30 minutes.**

---

## What is this?

Every time you push code, these workflows automatically:

```
You push code
     │
     ▼
Lint your code (flake8/eslint — catches style issues)
     │
     ▼
Run your tests (pytest/jest — catches bugs)
     │
     ▼
Build a Docker image (multi-stage build, tagged with git SHA)
     │
     ▼
Scan for vulnerabilities (Trivy — checks OS packages + Python/Node deps)
     │
     ▼
Deploy to Staging (automatic, zero-downtime via rolling update)
     │
     ▼
Run smoke tests (hit /health + key endpoints, verify 200 responses)
     │
     ▼
Deploy to Production (manual trigger, blue-green deployment, auto-rollback on failed health check)
```

No more SSH-ing into servers to deploy. No more "it works on my machine." Push → everything happens automatically.

---

## What problem does this solve?

**Without this:** You deploy by SSH-ing into the server, running `git pull`, restarting the app, and hoping nothing breaks. If it does break, you scramble to figure out what changed. Your team is scared to deploy on Fridays.

**With this:** Deployments are automatic, tested, and reversible. Code gets linted and tested before it ever reaches a server. If a production deploy fails health checks, it automatically rolls back to the previous version. You can deploy on Friday at 5pm without stress.

---

## What's included?

| File | What it does | When it runs | Key Technical Details |
|------|-------------|-------------|----------------------|
| `ci.yml` | Lint → Test → Build → Security scan | Every push to `main` and every PR | Matrix strategy: tests run on Python 3.10/3.11/3.12 in parallel. Docker build uses layer caching (`cache-from: type=gha`). Trivy scans with `--severity HIGH,CRITICAL`. |
| `cd-staging.yml` | Deploy to staging → Smoke tests → Slack notification | Triggers automatically after CI passes on `main` | Uses `workflow_run` trigger chained to CI. Rolling deployment with `--update-parallelism 1`. Smoke tests verify `/health`, `/api/status`, and key business endpoints. |
| `cd-production.yml` | Deploy to production → Health check → Auto-rollback | Manual trigger via `workflow_dispatch` | Blue-green deployment: spins up new task set, shifts traffic after health check passes. If health check fails 3 times, automatic rollback to previous task definition revision. |
| `pr-checks.yml` | Lint + type check + coverage gate | Every pull request | Enforces `--cov-fail-under=80`. Runs `mypy --strict` for type safety. Comments coverage diff on the PR. |
| `deploy-ec2.sh` | SSH-based deployment | For simple single-server setups | `ssh -o StrictHostKeyChecking=no`, pulls latest image, `docker compose up -d`, waits for health check, rolls back if it fails. |
| `deploy-ecs.sh` | AWS ECS/Fargate deployment | For containerized apps with auto-scaling | Registers new task definition, updates service with `--force-new-deployment`, waits for `services-stable` via `aws ecs wait`. |
| `deploy-s3.sh` | S3 + CloudFront deployment | For static sites and SPAs | `aws s3 sync --delete`, creates CloudFront invalidation for `/*`, waits for invalidation to complete. |

---

## Pipeline architecture

```
┌─────────────────────────────────────────────────────────┐
│                    CI Pipeline (ci.yml)                   │
│                                                          │
│  ┌──────┐    ┌──────┐    ┌───────┐    ┌───────────────┐ │
│  │ Lint │───▶│ Test │───▶│ Build │───▶│ Security Scan │ │
│  └──────┘    └──────┘    └───────┘    └───────────────┘ │
│   flake8     pytest       Docker        Trivy           │
│   eslint     jest         multi-stage   CVE database    │
│              3 Python     ghcr.io push                  │
│              versions                                    │
└────────────────────────────┬────────────────────────────┘
                             │ on success (main branch only)
                             ▼
┌─────────────────────────────────────────────────────────┐
│               CD Staging (cd-staging.yml)                 │
│                                                          │
│  Deploy ──▶ Wait for healthy ──▶ Smoke tests ──▶ Slack  │
│  (rolling)   (30s timeout)       (curl endpoints)        │
└────────────────────────────┬────────────────────────────┘
                             │ manual approval
                             ▼
┌─────────────────────────────────────────────────────────┐
│             CD Production (cd-production.yml)             │
│                                                          │
│  Blue-green deploy ──▶ Health check ──▶ Shift traffic   │
│                         (3 retries)     OR rollback       │
└─────────────────────────────────────────────────────────┘
```

---

## Design decisions

- **Workflow chaining, not monolith** — CI and CD are separate workflows linked via `workflow_run`. This means CI runs on PRs (no deploy), and CD only triggers after CI passes on `main`. Clean separation.
- **Docker layer caching** — Uses GitHub Actions cache (`cache-from: type=gha`) to avoid rebuilding unchanged layers. Cuts build time from ~4min to ~45s on typical Python apps.
- **Git SHA tagging** — Every Docker image is tagged with `${{ github.sha }}`. You always know exactly which commit is running in production. No `latest` tag ambiguity.
- **Matrix testing** — Tests run across 3 Python versions in parallel. Catches version-specific bugs before they reach production.
- **Rollback strategy** — Production deployment saves the previous task definition revision. If the new deployment fails health checks 3 times (30s apart), it redeploys the previous revision automatically. No manual intervention needed.
- **Coverage as a gate** — PRs must have >80% test coverage to merge. The workflow comments the coverage diff directly on the PR so reviewers see what's tested.
- **Secrets via GitHub Actions** — No credentials in code. AWS keys, Slack webhooks, and Docker registry tokens are stored in GitHub Secrets and injected at runtime via `${{ secrets.* }}`.

---

## How to use it

```bash
# 1. Copy the workflows into your project
cp -r .github/ /path/to/your/project/

# 2. Add your secrets to GitHub
#    Go to: Your repo → Settings → Secrets → Actions
#    Add: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, SLACK_WEBHOOK_URL

# 3. Customize the Dockerfile for your app

# 4. Push to main — CI/CD runs automatically
git push origin main
```

See [docs/SETUP.md](docs/SETUP.md) for the full step-by-step setup guide.

---

## How is the code organized?

```
cicd-pipeline-template/
├── .github/workflows/
│   ├── ci.yml                # Lint → Test → Build → Security scan (matrix: 3 Python versions)
│   ├── cd-staging.yml        # Auto-deploy after CI, rolling update, smoke tests, Slack notify
│   ├── cd-production.yml     # Manual trigger, blue-green deploy, health check, auto-rollback
│   └── pr-checks.yml        # Coverage gate (>80%), type checking (mypy), lint
├── scripts/
│   ├── deploy-ec2.sh         # SSH deploy: pull image → docker compose up → health check → rollback
│   ├── deploy-ecs.sh         # ECS deploy: register task def → update service → wait stable
│   ├── deploy-s3.sh          # S3 deploy: sync files → CloudFront invalidation → wait
│   └── smoke-test.sh         # Hit key endpoints, assert 200, report pass/fail
├── Dockerfile                # Multi-stage Python app: builder (deps) → production (slim runtime)
├── Makefile                  # Shortcuts: make lint, make test, make build, make deploy-staging
└── docs/
    └── SETUP.md              # Step-by-step: secrets setup, Dockerfile customization, first deploy
```

---

## Who is this for?

- Teams still deploying manually and want to automate it without spending weeks
- Solo developers who want safety nets (automated tests + rollback) for their deployments
- Anyone deploying to AWS (EC2, ECS, or S3) who wants a battle-tested pipeline template

---

Built by **Vikas Munjal** | Open source under MIT License
