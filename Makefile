.DEFAULT_GOAL := help
COMPOSE ?= docker compose

.PHONY: help install fmt lint test check up down logs ps clean

help: ## Show this help
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

install: ## Install dependencies into .venv
	uv sync

fmt: ## Auto-format code
	uv run ruff format .
	uv run ruff check --fix .

lint: ## Lint, format check, security scan
	uv run ruff check .
	uv run ruff format --check .
	uv run bandit -q -r src

test: ## Run tests
	uv run pytest -q

check: lint test ## Everything CI runs on code

# Compose targets below work once compose.yaml exists (we write it live).
up: ## Start the full stack (db, migrate, api, worker)
	$(COMPOSE) up --build -d

down: ## Stop the stack (keeps data)
	$(COMPOSE) down

logs: ## Follow api + worker logs
	$(COMPOSE) logs -f api worker

ps: ## Show running services and memory usage
	$(COMPOSE) ps
	docker stats --no-stream

clean: ## Stop the stack and delete data
	$(COMPOSE) down -v
