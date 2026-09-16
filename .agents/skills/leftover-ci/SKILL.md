---
name: leftover-ci
description: Binds agents to the same local verification aggregate as humans. Use when finishing a turn, declaring done, or after edits to the Dockerfile, .devcontainer/, test/, Makefile, workflows or any Markdown. Runs make lint, make check-docs and make pre-commit (plus make ci-test for image changes); if red, fix and re-run; never skip leftover-ci or git hooks with --no-verify.
---

# Leftover-CI

Agents finish a turn only when the local aggregate is green. The command is `make lint`, `make check-docs` and `make pre-commit`, run in that order. The gate list lives in [`tooling-workflow`](../tooling-workflow/SKILL.md); this skill adds the agent behaviour.

The pre-commit hook installed by `make setup` runs the same hook set on staged files at commit time; the full aggregate across the tree is still yours to run. This repository installs no IDE stop hooks.

## Behaviour

1. Run `make format-docs` if you touched Markdown, then the aggregate.
1. If it fails, fix the reported gate. Do not disable hooks, skip leftover-ci, or pass `--no-verify`.
1. Re-run until green.
1. If the Dockerfile, `test/` or a compose file changed, also run `make ci-test` (needs a Docker daemon; it builds the `test` stage and runs the smoke suite). If the `dev` stage or `.devcontainer/` changed, run `make build-dev`. Publishing (`build-and-push`) runs only in CI on `main`, `dev` and `v*.*.*` tags — never locally.

There is no aggregate other than the one named above. Do not invent a `make check` (or any target) that this repository does not define; if the aggregate is genuinely missing, ask the operator.

Green leftover-ci does **not** replace landing the PR properly — template filled, assignee set, description current ([engineering-discipline](../engineering-discipline/SKILL.md) §10).

## Anti-patterns

- Declaring done while the aggregate is red.
- `git commit --no-verify` / `git push --no-verify`, including "because the host lacks the toolchain" — run inside the DevContainer instead.
- Treating leftover-ci as optional because CI will catch it.
- Opening or updating a PR with a Summary / Test plan body instead of the repo's template.
- Running `mdformat` without the plugins pinned in [`.pre-commit-config.yaml`](../../../.pre-commit-config.yaml) — without `mdformat-frontmatter` it destroys skill frontmatter.
