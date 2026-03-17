# CI/CD Pipeline Template

**Copy these GitHub Actions workflows into your repo → get automated testing and deployment in 30 minutes.**

---

## What is this?

Every time you push code, these workflows automatically:

```
You push code
     │
     ▼
Lint your code (catches style issues)
     │
     ▼
Run your tests (catches bugs)
     │
     ▼
Build a Docker image (packages your app)
     │
     ▼
Scan for security vulnerabilities
     │
     ▼
Deploy to Staging (automatically)
     │
     ▼
Run smoke tests (verify staging works)
     │
     ▼
Deploy to Production (you click a button → it deploys with auto-rollback if anything fails)
```

No more SSH-ing into servers to deploy. No more "it works on my machine." Push → everything happens automatically.

---

## What problem does this solve?

**Without this:** You deploy by SSH-ing into the server, running `git pull`, restarting the app, and hoping nothing breaks. If it does break, you scramble to figure out what changed. Your team is scared to deploy on Fridays.

**With this:** Deployments are automatic, tested, and reversible. Code gets linted and tested before it ever reaches a server. If a production deploy fails health checks, it automatically rolls back to the previous version. You can deploy on Friday at 5pm without stress.

---

## What's included?

| File | What it does | When it runs |
|------|-------------|-------------|
| `ci.yml` | Lint → Test → Build Docker image → Security scan | Every push to main and every pull request |
| `cd-staging.yml` | Deploy to staging → Run smoke tests → Slack notification | Automatically after CI passes on main |
| `cd-production.yml` | Deploy to production → Health check → Auto-rollback if it fails | When you manually click "Run workflow" |
| `pr-checks.yml` | Lint + type checking + test coverage must be >80% | Every pull request |
| `deploy-ec2.sh` | SSH-based deployment script | For simple single-server setups |
| `deploy-ecs.sh` | AWS ECS/Fargate deployment | For containerized apps with auto-scaling |
| `deploy-s3.sh` | S3 + CloudFront deployment | For static sites and SPAs |

---

## How to use it

```bash
# 1. Copy the workflows into your project
cp -r .github/ /path/to/your/project/

# 2. Add your secrets to GitHub
#    Go to: Your repo → Settings → Secrets → Actions
#    Add: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, etc.

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
│   ├── ci.yml                # Lint → Test → Build → Security scan
│   ├── cd-staging.yml        # Auto-deploy to staging after CI passes
│   ├── cd-production.yml     # Manual deploy to production with rollback
│   └── pr-checks.yml         # Quality gates for pull requests
├── scripts/
│   ├── deploy-ec2.sh         # Deploy via SSH (simple servers)
│   ├── deploy-ecs.sh         # Deploy to AWS ECS (containers)
│   ├── deploy-s3.sh          # Deploy to S3 + CloudFront (static sites)
│   └── smoke-test.sh         # Verify deployment is working
├── Dockerfile                # Sample Python app Dockerfile
├── Makefile                  # Shortcuts: make lint, make test, make build
└── docs/
    └── SETUP.md              # Step-by-step setup instructions
```

---

## Who is this for?

- Teams still deploying manually and want to automate it without spending weeks
- Solo developers who want safety nets (automated tests + rollback) for their deployments
- Anyone deploying to AWS (EC2, ECS, or S3)

---

Built by **Vikas Munjal** | Open source under MIT License
