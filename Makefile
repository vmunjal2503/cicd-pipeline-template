.PHONY: lint test build deploy-staging deploy-prod

lint:
	flake8 . --max-line-length=120 --exclude=venv,.git
	black --check --line-length=120 .

test:
	pytest --cov=. --cov-report=term-missing -v

build:
	docker build -t app:local .

deploy-staging:
	./scripts/deploy-ecs.sh staging latest

deploy-prod:
	@echo "⚠️  Are you sure? This deploys to PRODUCTION."
	@read -p "Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ] || exit 1
	./scripts/deploy-ecs.sh production latest
