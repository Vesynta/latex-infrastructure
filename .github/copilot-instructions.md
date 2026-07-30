# Project Guidelines

## Build and Test

- Use `make pre-commit` for full repository checks.
- Use `make ci-test` to run the Dockerized smoke suite.
- Use `make lint` for hadolint-only checks.
- Prefer `make build-prod` for production image validation.

## CI and Workflow Conventions

- Keep public repository workflows on `ubuntu-latest` unless explicitly requested otherwise.
- Preserve semantic version tagging behavior in `.github/workflows/build-and-push.yml` for `v*.*.*` tags.
- Treat CI lint warnings as actionable unless a rule is intentionally suppressed in source with justification.

## Commit Conventions

- Use conventional commits for all changes.
- Keep commits focused to one concern per commit.

## Repository Patterns

- Keep deterministic tooling config in-repo (for example `.hadolint.yaml` and `.pre-commit-config.yaml`).
- Prefer targeted suppressions in source over global linter relaxations.
