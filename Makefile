# Makefile — create-hermes-workspace
#
# Run `make help` for a list of targets.
# All targets are intentionally idempotent — safe to re-run.

.DEFAULT_GOAL := help

# ── Variables ────────────────────────────────────────────────────────────────
COMPOSE  := docker compose
NAME     ?= my-app
PORT     ?= 3000

# ── Help ─────────────────────────────────────────────────────────────────────
.PHONY: help
help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# ── Lifecycle ────────────────────────────────────────────────────────────────
.PHONY: up
up: ## Start the workspace container in the background.
	$(COMPOSE) up -d
	@echo ""
	@echo "✓  Workspace running. Next: make shell"

.PHONY: down
down: ## Stop the workspace container (keeps volumes).
	$(COMPOSE) down

.PHONY: shell
shell: ## Open a bash shell inside the workspace container.
	$(COMPOSE) exec hermes bash

.PHONY: logs
logs: ## Tail the workspace container's logs.
	$(COMPOSE) logs -f --tail=100

.PHONY: restart
restart: down up ## Restart the workspace container.

.PHONY: reset
reset: ## Nuke the container, .env, and node_modules. Re-run quickstart from step 2.
	$(COMPOSE) down -v 2>/dev/null || true
	rm -rf node_modules .env
	@echo "✓  Workspace reset. Re-run the quickstart from the README."

# ── Apps ─────────────────────────────────────────────────────────────────────
.PHONY: new-project
new-project: ## Scaffold a new app via @edd_remonts/create-edd-app. Usage: make new-project NAME=foo
	@if [ -z "$(NAME)" ] || [ "$(NAME)" = "my-app" ]; then \
		echo "ERROR: pass NAME=<your-app-name>"; \
		echo "Usage: make new-project NAME=my-cool-app"; \
		exit 1; \
	fi
	$(COMPOSE) exec hermes bash -c "npx --yes @edd_remonts/create-edd-app $(NAME) --package-manager pnpm"
	@echo ""
	@echo "✓  Project $(NAME) created. To run it:"
	@echo "    cd worktrees/$(NAME)   # or wherever the CLI put it"
	@echo "    pnpm install"
	@echo "    pnpm dev"

# ── Maintenance ──────────────────────────────────────────────────────────────
.PHONY: pull
pull: ## Pull the latest from the upstream repo.
	git pull --rebase origin main
	$(COMPOSE) pull 2>/dev/null || true

.PHONY: rebuild
rebuild: ## Rebuild the container image (after changing the Dockerfile).
	$(COMPOSE) build --pull
	$(COMPOSE) up -d

.PHONY: test
test: ## Run tests for the workspace (if any are defined).
	$(COMPOSE) exec hermes bash -c "cd /opt/data && pnpm test 2>/dev/null || npm test 2>/dev/null || echo 'No tests defined.'"

# ── Publishing (for repo maintainers) ────────────────────────────────────────
.PHONY: publish-pkg
publish-pkg: ## Re-publish @edd_remonts/create-hermes-workspace to npm.
	@if [ ! -f scripts/publish.sh ]; then \
		echo "ERROR: scripts/publish.sh not found. Are you in the npm package repo?"; \
		exit 1; \
	fi
	./scripts/publish.sh
