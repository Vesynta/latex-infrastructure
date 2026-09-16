---
name: engineering-discipline
description: Behavioural contract for every change in latex-infrastructure. Use before writing, reviewing or refactoring anything, and before opening or updating a pull request. Surface assumptions; confirm the owning layer (prod, test, dev, gates, docs); pick the simplest sufficient design; keep diffs surgical and traceable; verify each step against a concrete check; ask the operator when ambiguous; land the PR on this repo's template with the description kept true.
---

# Engineering discipline

Rigour outranks speed of authorship. Every change is the *simplest* one that fully satisfies a verifiable goal, in the layer that owns it. Simplest is not smallest: do not skirt a materially cleaner, more maintainable or safer solution to keep a diff tiny — surface the wider change ([§7](#7-ask-dont-assume)) rather than silently taking the cramped path.

This repository is **public** and publishes a base image other projects pull. A change to `prod` reaches every consumer on their next pull; a change to `dev` reaches only maintainers.

Hard rules live in [AGENTS.md](../../../AGENTS.md). This skill adds behaviour; it does not restate them.

## 1. Think before coding

- **State your assumptions.** Two plausible readings → present both, pick one explicitly; if one is materially cheaper to verify, ask.
- **Confirm the owning layer.** The stage graph is documented under [Image architecture](../../../README.md#image-architecture).

| Layer                                                                         | Owns                                                                                 | Never                                                        |
| ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------ |
| `Dockerfile` — `base`, `prod`                                                 | The published image: TeX Live tree, system packages, `pandoc`, fonts, font caches    | Maintainer-only tooling; an unpinned `FROM` or `COPY --from` |
| `Dockerfile` — `test`, `test/`, `docker-compose.test.yaml`                    | `hadolint`, the smoke fixtures and `run-tests.sh`                                    | Anything a consumer needs at compile time                    |
| `Dockerfile` — `dev`, `.devcontainer/`                                        | The maintainer DevContainer: `mdformat`, `pre-commit`, Docker CLI, Node, zsh overlay | Anything published                                           |
| `Makefile`, `.pre-commit-config.yaml`, `.hadolint.yaml`, `.github/workflows/` | Gates and CI; the Makefile is the single entrypoint                                  | Logic that duplicates a Makefile target inline in a workflow |
| `README.md`, `AGENTS.md`, `.agents/skills/`                                   | Documentation and agent guidance                                                     | Restating one another (`docs-code-alignment`)                |

- **Name the unknowns.** Read the canonical document (`docs-code-alignment`) before guessing at a contract.
- **Pick the simplest sufficient design.** Add an abstraction when a second caller already needs it — but simplest, not smallest.
- **Keep each unit single-concern.** If a stage, script or target stretches across concerns, flag it and propose cohesive units rather than growing a catch-all.

For a non-trivial or ambiguous change, work **problem → context → solutions → select**:

1. **Problem.** State the problem or the benefit to materialise, without ambiguity.
1. **Context.** Surface background, related code and constraints; ask whether further requirements should inform the design.
1. **Solutions.** Two or three independent candidates before committing to one; say what each costs and risks.
1. **Select.** When the choice is the operator's, present the options and let them choose ([§7](#7-ask-dont-assume)).

If you cannot state a one-sentence success criterion, you are not ready to write code.

## 2. Surgical changes

Every modified line traces to the request.

| Do                                                        | Don't                                                         |
| --------------------------------------------------------- | ------------------------------------------------------------- |
| Edit the file, stage or target the request names          | Reformat adjacent unrelated code                              |
| Match the surrounding voice, naming and comment density   | Rewrite a working file because you prefer another style       |
| Remove packages, mounts or variables your change orphaned | Delete pre-existing dead code unless asked                    |
| Fail exactly where the invariant breaks                   | Add a fallback that hides a missing tool or a failed download |
| Suppress a linter rule inline, with the reason beside it  | Relax the rule globally in `.hadolint.yaml`                   |

Surgical is a discipline about *tracing*, not about *size*. When the honest fix touches associated code, say so: name the associated functionality, the risk of leaving it, and the coherent whole you propose. Then ask (§7) if scope is a real choice.

When a change spans files, walk them in dependency order and commit per logical unit.

## 3. Goal-driven loop

Decompose the task so each step has a check that proves it:

```text
1. [Step] -> verify: [command or assertion]
2. [Step] -> verify: [command or assertion]
```

Acceptable checks here: `make lint` (hadolint), `make check-docs` (mdformat), `make pre-commit`, `make ci-test` (builds `test` and runs the smoke suite), `make build-dev` (the DevContainer stage builds), a `docker run --rm <image> <tool> --version` for a tool you added.

"Looks right on inspection" is not a check. Prefer code that proves itself deterministically.

## 4. Push back when warranted

Say so **before coding**, and propose the closest faithful alternative, when a request would:

- Move maintainer or test tooling into `prod` — every consumer pays the size and attack surface ([README](../../../README.md#image-architecture)).
- Unpin a `FROM` / `COPY --from` digest or float the `TEXLIVE_IMAGE` default — Dependabot owns those bumps ([README](../../../README.md#image-pins-and-the-texlive_image-build-argument)).
- Change the semver tag behaviour or the `main` / `dev` / `v*.*.*` triggers of the build-and-push workflow, or move a workflow off `ubuntu-latest` (`AGENTS.md`).
- Relax a linter globally instead of suppressing one rule in source with a justification.
- Add Dev Container `features` — this image bakes its tooling directly so the build stays reproducible.
- Reference private repositories, internal systems or organisation-internal names in this public tree (`docs-code-alignment`).

## 5. No magic numbers, no magic strings

A literal that carries meaning becomes a named constant with a one-line rationale: `ARG` in the Dockerfile, a variable in the Makefile, a `Makefile`-driven override rather than a hard-coded tag. A string becomes a constant the moment it has two call sites.

## 6. Comments explain why, not what

Reserve comments for what the code cannot show: why a package is present, why a rule is suppressed, an upstream quirk, a trade-off. Never paraphrase the next line; never narrate your own change.

## 7. Ask, don't assume

When the request leaves a real choice open — a default, a name, a scope boundary, surgical versus holistic — surface it with concrete options and ask the operator (e.g. `AskQuestion` in Cursor; a short question otherwise). A wrong assumption that ships costs more than the seconds saved by not asking.

## 8. Define done

In order:

1. The failing test or check you wrote first now passes.
1. `make lint` and `make check-docs` are clean.
1. `make pre-commit` is clean.
1. If the Dockerfile, `test/` or the compose files changed: `make ci-test` passes; if the `dev` stage or `.devcontainer/` changed: `make build-dev` succeeds.
1. Documentation touched by the change is updated (`docs-code-alignment`).
1. Commits and the PR follow [§10](#10-landing-prs).

Do not stack incomplete work. If a step fails, fix it before moving on.

## 9. Signals these guidelines are working

Diffs read narrowly to the request; responsibilities land in the owning stage; clarifying questions arrive **before** implementation; refactors are framed "passes before, passes after"; hidden assumptions surface as named `ARG`s or documented defaults. Sprawling diffs or rework loops mean: return to §1.

## 10. Landing PRs

### Commits

One conventional commit per logical unit; do not batch a plan into one commit when the work splits, and do not split a coherent change to look surgical. Subject: imperative, ~72 characters. Body explains **why**. Types in use: `feat`, `fix`, `docs`, `chore`, `ci`, `refactor`; scope optional (`docker`, `devcontainer`, `skills`). No hook checks the message in this repository — the convention is binding anyway. Write the message with a heredoc. Never `--no-verify`.

### Before opening

Run `gh auth status`. If it is not authenticated, stop and ask the operator to run `gh auth login`; do not paste, print or log tokens (`gh auth token`, `GIT_TRACE`).

### Title and body

- Title: conventional, same types as commits; the squash-merge title too.
- Body: read [`.github/PULL_REQUEST_TEMPLATE.md`](../../../.github/PULL_REQUEST_TEMPLATE.md) and fill **every** section in place. Never replace it with a Summary / Test plan shape.
- Traceability: only real links; otherwise `N/A` and why. Do not invent tickets or records. Risk and verification are honest for this layer — empty honesty beats invented prose.
- Companion PRs (this repo or others): a list of **bare** `https://github.com/<org>/<repo>/pull/<n>` lines so the UI renders status and title. No `[label](url)` wrapping. Merge order and cutover checklists live here, never in tracked docs (`docs-code-alignment`).
- Proof: cite the commit SHA a verification ran against.

### People

- Assign the PR to whoever is guiding or committing this session — the operator — with `--assignee` at creation or `gh pr edit --add-assignee <handle>`. Ask if the handle is unknown.
- Leave reviewers to humans. Do not add or remove reviewers, request Copilot review, merge, or enable auto-merge unless told.
- Open as draft unless told otherwise; mark ready only when leftover-ci is green **and** the description is current.

### Keep the description true

After every landed commit, re-read the body and `gh pr edit --body-file` it so Objective, Approach, Decisions and Changelog describe the tree as pushed. Tick only checkboxes **this turn verified**; leave human-only items (branch strategy, reopen-in-DevContainer, review threads) unticked and say they are for a human. Answer every review thread with the commit that addressed it or the reason it is dismissed; resolve only what is addressed.

Green leftover-ci does not replace any of this.
