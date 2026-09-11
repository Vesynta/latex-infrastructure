PROJECT := $(notdir $(CURDIR))
IMAGE ?= latex-infrastructure
TAG ?= local
PROGRESS ?= auto

# Optional TeX Live override. Unset keeps the Dockerfile digest pin.
#   make build TEX_IMAGE_TAG=latest-medium
#   make build TEXLIVE_IMAGE=texlive/texlive:latest-medium@sha256:...
TEX_IMAGE_TAG ?=
TEXLIVE_IMAGE ?=

ifneq ($(TEXLIVE_IMAGE),)
BUILD_ARGS += --build-arg TEXLIVE_IMAGE=$(TEXLIVE_IMAGE)
else ifneq ($(TEX_IMAGE_TAG),)
BUILD_ARGS += --build-arg TEXLIVE_IMAGE=texlive/texlive:$(TEX_IMAGE_TAG)
endif

.PHONY: build build-prod build-local build-dev ci-test lint lint-tex format-docs check-docs \
	setup pre-commit install-hooks clean help

## build: alias for build-prod
build: build-prod

## build-prod: build the published production image
build-prod:
	docker build --target prod $(BUILD_ARGS) --progress=$(PROGRESS) -t $(IMAGE):$(TAG) .

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

## format-docs: format tracked markdown with mdformat
format-docs:
	mdformat $(shell git ls-files '*.md')

## check-docs: check tracked markdown formatting without writing
check-docs:
	mdformat --check $(shell git ls-files '*.md')

## setup: install git hooks
setup: install-hooks

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
