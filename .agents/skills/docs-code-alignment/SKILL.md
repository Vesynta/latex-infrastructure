---
name: docs-code-alignment
description: Keeps latex-infrastructure documentation aligned with code and free of duplication. Use when adding, renaming or removing a stage, tool, target or workflow; editing README, AGENTS.md, skills or Dockerfile comments; changing image pins or tool versions. Designates canonical homes; link, never duplicate; never document unimplemented behaviour as current; keep the public tree free of private references.
---

# Documentation and code alignment

Documentation is part of the product: it mirrors the implementation, never duplicates itself, never lags the code. Skills are thin wrappers that link to canonical docs and add only agent behaviour.

## 1. Canonical homes

Each topic has exactly one home. Every other document links to it with at most a one-line summary.

| Topic                                                                  | Canonical home                                                                              |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Agent brief, hard rules, skills table, reading order                   | [AGENTS.md](../../../AGENTS.md)                                                             |
| Claude Code / Copilot pointers                                         | `CLAUDE.md`, `.github/copilot-instructions.md` (`@AGENTS.md` only)                          |
| Skill routing                                                          | [.agents/skills/README.md](../README.md)                                                    |
| Pull request body                                                      | [`.github/PULL_REQUEST_TEMPLATE.md`](../../../.github/PULL_REQUEST_TEMPLATE.md)             |
| What the image is, stage graph, pins, consumer usage, maintainer setup | [README.md](../../../README.md)                                                             |
| Why a package, mount or suppression exists                             | The comment beside it in the [Dockerfile](../../../Dockerfile)                              |
| Make targets and their one-line purpose                                | `## target:` comments in the [Makefile](../../../Makefile) (`make help`)                    |
| Hook set and formatter plugins                                         | [`.pre-commit-config.yaml`](../../../.pre-commit-config.yaml)                               |
| Image pins and update grouping                                         | `FROM` lines in the Dockerfile; [`.github/dependabot.yml`](../../../.github/dependabot.yml) |
| Vendored skill provenance                                              | [ATTRIBUTION.md](../ATTRIBUTION.md)                                                         |

If a concept is touched in two places, the second links to the first. When it is unclear whether new material extends an existing home or needs a new one, ask the operator before creating a second page.

## 2. Public tree

This repository is public. Tracked files never name private repositories, internal systems, ticket trackers, runner labels, or people; never link to documents readers cannot open. Where a private document held a rule that matters here, inline the one rule (as the Dockerfile does for cache-mount IDs) rather than the link. `ghcr.io/vesynta/latex-infrastructure` and the licence notice are the intended public surface.

## 3. DRY audit

Before adding a paragraph, search: `rg -n "<topic terms>" README.md AGENTS.md .agents/ Dockerfile Makefile`. If the topic has a home, link instead of restate.

## 4. Declarative over prose

When a concept is data plus a contract (a pin, a hook list, a compose file), point at the artefact rather than writing a recipe. Versions live in the Dockerfile, `.pre-commit-config.yaml` and the workflows — never repeat a version number in prose.

## 5. Never document unimplemented behaviour as current

If a capability is not in this tree, it is under an explicit later/follow-up heading or omitted. Git documents **the tree at this SHA**: no "when #N lands", no merge order of other PRs. Sequences, cutover checkboxes and companion PRs belong in the PR description as bare `https://github.com/<org>/<repo>/pull/<n>` lines (`engineering-discipline` §10). A one-line pointer from a doc to a tracker PR is allowed; copying its checklist is not. After a cited PR merges, rewrite the sentence as current fact. When doc and code conflict, ask which is right.

## 6. Propagation checklist

| Changed                               | Also update                                                                                         |
| ------------------------------------- | --------------------------------------------------------------------------------------------------- |
| A stage added, removed or re-parented | README "Image architecture" list and Mermaid graph; `ci-test.yml` targets                           |
| A tool added to `prod`                | README "What's included"; `test/run-tests.sh` smoke check for it                                    |
| A tool added to `dev`                 | README `dev` bullet; `.devcontainer/devcontainer.json` settings if an editor integration uses it    |
| A Make target                         | Its `## target:` comment; README "Local maintenance" block if user-facing                           |
| A hook or formatter plugin            | `.pre-commit-config.yaml` **and** the `/opt/docs-tools` install in the Dockerfile — they must agree |
| A skill added, renamed or removed     | `AGENTS.md` skills table; `.agents/skills/README.md` routing; `ATTRIBUTION.md` if vendored          |
| A vendor image (`FROM`)               | Dependabot group in `.github/dependabot.yml`                                                        |

## 7. Tone and gates

Strunk & White: active voice, no filler, tables for mappings, numbered lists for procedures, Mermaid for flows that branch, hyperlinks for every cross-reference. No time-sensitive language. `mdformat` (with `mdformat-gfm`, `mdformat-tables` and `mdformat-frontmatter`) owns layout — never hand-pad tables. Before declaring a doc change complete: `make format-docs`, `make check-docs`, and confirm every relative link resolves.

## 8. Anti-patterns

Two passages explaining one rule. A skill that restates a doc. A README bullet that drifted from the Dockerfile. A version number in prose. A new page overlapping an existing one (extend or supersede, then remove the stale one). A merge train or "not yet on `dev`" note in tracked docs. A link into a private repository.
