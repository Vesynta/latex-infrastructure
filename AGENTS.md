# Agent guidance

This repository builds and publishes `ghcr.io/vesynta/latex-infrastructure`, a TeX Live base image that other projects pull into their Dev Containers. It is **public**: everything tracked here is readable by anyone, so it names no private repositories, internal systems or people. Consumers only ever pull the `prod` stage; `test` and `dev` exist for CI and maintainers and are never published.

## Docs are canonical; skills link, never duplicate

| Canonical source                                     | Owns                                                                       |
| ---------------------------------------------------- | -------------------------------------------------------------------------- |
| [README.md](README.md)                               | What the image is, the stage graph, pins, consumer usage, maintainer setup |
| [Dockerfile](Dockerfile)                             | Every stage, pin and cache mount, with the reason beside it                |
| [Makefile](Makefile)                                 | Every gate and build command (`make help`)                                 |
| [`.pre-commit-config.yaml`](.pre-commit-config.yaml) | The hook set and the `mdformat` plugins                                    |
| [`.github/workflows/`](.github/workflows/)           | Pre-commit, CI test, and build-and-push behaviour                          |

## Skills

Skills live in `.agents/skills/<name>/SKILL.md` (`name` == directory). `.claude/skills` is a symlink to the same tree. Routing: [`.agents/skills/README.md`](.agents/skills/README.md).

| Skill                    | Use when                                                                                                    |
| ------------------------ | ----------------------------------------------------------------------------------------------------------- |
| `engineering-discipline` | Before any change: assumptions, owning stage, simplest sufficient design, surgical diffs, landing the PR    |
| `plan-checkpoint`        | Any plan spanning several files or commits                                                                  |
| `leftover-ci`            | Before declaring done: `make lint`, `make check-docs`, `make pre-commit` (`make ci-test` for image changes) |
| `docs-code-alignment`    | Touching README, `AGENTS.md`, skills, Dockerfile comments or pins                                           |
| `tooling-workflow`       | Running gates, hooks, the DevContainer, commit conventions                                                  |
| `gh-stack`               | Stacked PRs                                                                                                 |

Copilot-only assets: `.github/skills/ci-triage` (failing-workflow triage) and `.github/agents/release-checker.agent.md` (release-tag validation).

## Reading order

1. `engineering-discipline` — the behavioural contract.
1. The narrow skill that matches the change (table above; load **one**).
1. Verify; then `leftover-ci`; then land the PR (`engineering-discipline` §10 Landing PRs).

Use `plan-checkpoint` whenever the work spans more than a couple of files.

## Build and test

- `make lint` — hadolint on the Dockerfile. `make check-docs` / `make format-docs` — mdformat. `make pre-commit` — the full hook set.
- `make ci-test` — the Dockerized smoke suite (`test` stage). `make build-prod` — validate the published image. `make build-dev` — the DevContainer stage.
- There is **no** `make check`; do not invent one.

## Conventions

- Conventional commits, one concern per commit. Fill [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md); assign the operator; keep the body true as commits land.
- Public workflows stay on `ubuntu-latest` unless explicitly requested otherwise.
- Preserve semantic-version tagging in `build-and-push.yml` for `v*.*.*` tags; pull requests never publish.
- Treat CI lint warnings as actionable unless the rule is suppressed in source with a justification. Prefer a targeted inline suppression over a global relaxation.
- Deterministic tooling config lives in-repo (`.hadolint.yaml`, `.pre-commit-config.yaml`, `.editorconfig`).

## Things that get a change rejected

- Moving maintainer or test tooling into `prod` — every consumer pays for it (`engineering-discipline` §4).
- Unpinning a `FROM` / `COPY --from` digest or floating the `TEXLIVE_IMAGE` default — Dependabot owns those bumps (README).
- A link into a private repository, or any internal name, in this public tree (`docs-code-alignment` §2).
- Running `mdformat` without the pinned plugins — it destroys skill frontmatter (`tooling-workflow` §2).
- A PR body in a Summary / Test plan shape instead of the template (`engineering-discipline` §10).
