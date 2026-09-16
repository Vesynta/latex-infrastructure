# Agent skills (latex-infrastructure)

IDE-agnostic [Agent Skills](https://agentskills.io) for this repository. Tools that support the standard discover skills from **`.agents/skills/`**; `.claude/skills` is a **symlink** to this directory, not a second tree. Do not copy skill payloads elsewhere.

Always-on brief, skills table and reading order: [`AGENTS.md`](../../AGENTS.md). Pointers only (never a second brief): [`CLAUDE.md`](../../CLAUDE.md), [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md). Provenance of vendored skills: [`ATTRIBUTION.md`](ATTRIBUTION.md).

This repository is **public**: skills name no private repositories, internal systems or people.

## Routing

| Task                                                    | Load                                                | Do not load |
| ------------------------------------------------------- | --------------------------------------------------- | ----------- |
| Any change                                              | [`engineering-discipline`](engineering-discipline/) | —           |
| Plan spanning several files or commits                  | [`plan-checkpoint`](plan-checkpoint/)               | —           |
| Running gates, hooks, the DevContainer, commit messages | [`tooling-workflow`](tooling-workflow/)             | `gh-stack`  |
| Finishing a turn                                        | [`leftover-ci`](leftover-ci/)                       | —           |
| README, `AGENTS.md`, skills, Dockerfile comments, pins  | [`docs-code-alignment`](docs-code-alignment/)       | —           |
| Stacked or dependent PRs                                | [`gh-stack`](gh-stack/)                             | —           |

Copilot-only assets live under `.github/`: [`skills/ci-triage`](../../.github/skills/ci-triage/SKILL.md) (failing-workflow triage) and [`agents/release-checker.agent.md`](../../.github/agents/release-checker.agent.md) (release-tag validation).

## Adding a skill

One directory per skill; the `name` in `SKILL.md` frontmatter equals the directory name; `description` states *when to use*. Add a row here and in `AGENTS.md`; record provenance in `ATTRIBUTION.md` if vendored. Format with `make format-docs` — the pinned `mdformat-frontmatter` plugin keeps the frontmatter intact.
