PROJECT := $(notdir $(CURDIR))
IMAGE ?= latex-infrastructure
TAG ?= local
TEX_IMAGE_TAG ?= latest-full
PROGRESS ?= auto

.PHONY: build build-prod build-local build-dev ci-test lint lint-tex format-docs check-docs \
	setup mcp-sync mcp-check mcp-check-config mcp-auth-help pre-commit install-hooks clean help

## build: alias for build-prod
build: build-prod

## build-prod: build the published production image
build-prod:
	docker build --target prod --build-arg TEX_IMAGE_TAG=$(TEX_IMAGE_TAG) --progress=$(PROGRESS) -t $(IMAGE):$(TAG) .

## build-local: build + tag the prod image locally as latex-infrastructure:local
build-local: build-prod

## build-dev: build the devcontainer (dev stage) image via compose
build-dev:
	docker compose -p "$(PROJECT)_devcontainer" -f .devcontainer/docker-compose.yaml build --progress=$(PROGRESS)

## ci-test: run the Dockerized hadolint + LaTeX smoke test suite
ci-test:
	docker compose -f docker-compose.test.yaml up --build --abort-on-container-exit --exit-code-from ci-test

## lint: run hadolint against the Dockerfile
lint:
	@if command -v hadolint >/dev/null 2>&1; then \
		hadolint --config .hadolint.yaml Dockerfile; \
	else \
		docker run --rm -v "$(CURDIR):/work:ro" -w /work hadolint/hadolint hadolint --config .hadolint.yaml Dockerfile; \
	fi

## lint-tex: run chktex against smoke-test fixtures with repo config
lint-tex:
	chktex -l .chktexrc test/sample.tex

## format-docs: format markdown with mdformat
format-docs:
	mdformat $$(find . -name '*.md' ! -path './.git/*' ! -path './.agents/mcp/*')

## check-docs: check markdown formatting without writing
check-docs: mcp-check-config
	mdformat --check $$(find . -name '*.md' ! -path './.git/*' ! -path './.agents/mcp/*')

## setup: install git hooks and sync MCP configs
setup: install-hooks mcp-sync

## mcp-sync: symlink Cursor/Claude MCP configs; generate .vscode/mcp.json
mcp-sync:
	bash .agents/mcp/sync-mcp-configs.sh

## mcp-check: verify MCP configs and portal reachability
mcp-check:
	bash .agents/mcp/check-mcp-configs.sh

## mcp-check-config: verify MCP config structure (no network)
mcp-check-config:
	MCP_CHECK_OFFLINE=1 bash .agents/mcp/check-mcp-configs.sh

## mcp-auth-help: print IDE Access OAuth steps (no tokens stored)
mcp-auth-help:
	@echo "MCP authentication (interactive — nothing is written to the repo)"
	@echo ""
	@echo "1. make mcp-sync"
	@echo "2. Open this repo in a DevContainer"
	@echo "3. Enable workspace MCP servers (vesynta, aws-mcp, wrike, userback, chrome-devtools)"
	@echo "4. vesynta: complete Cloudflare Access login for mcp.vesynta.com"
	@echo "5. wrike: copy Client ID and Secret from Passbolt into gitignored .env (WRIKE_MCP_*), rebuild, then Authenticate"
	@echo "6. aws-mcp and userback: complete that product OAuth; disable writes in the IDE if needed"
	@echo "7. OAuth callbacks: auto-forward 8787 (Cursor) and 33418 (VS Code) onto the laptop"
	@echo "8. chrome-devtools: laptop Chrome --remote-debugging-port=9222 and reverse-forward 9222"
	@echo "9. Never paste API tokens into git or mcp.json"
	@echo ""
	@echo "Policy: read/docs-first. Details: .agents/mcp/README.md"

## install-hooks: install the git pre-commit hooks
install-hooks:
	pre-commit install

## pre-commit: run all pre-commit hooks against the whole repo
pre-commit:
	pre-commit run --all-files

## clean: tear down the test compose stack
clean:
	-docker compose -f docker-compose.test.yaml down -v --remove-orphans

## help: list available targets
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## //'
