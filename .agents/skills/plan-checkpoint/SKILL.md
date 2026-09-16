---
name: plan-checkpoint
description: Mandates a structured Execution Checkpoint at the top of every multi-step plan so non-goals, constraints and locked decisions survive context compaction or hand-off. Use when drafting a plan spanning several files or commits, when the operator mentions summarising, clearing or handing off, or whenever a plan carries explicit do-not-change details.
---

# Plan checkpoints for context-resilient execution

A plan has to survive compaction. A fresh agent sees the plan file and whatever the operator types next. Constraints buried in prose are what summarisation discards; constraints enumerated in a dedicated section survive verbatim.

## 1. When

Add an **Execution Checkpoint** to any plan that spans three or more todos or two or more independent commits; carries explicit "do not change" constraints; was reached by iterative narrowing in conversation; will plausibly run in a later session; or touches the published `prod` stage, an image pin, or the release workflow. Single-file plans do not need one.

## 2. Six subsections, in this order, enumerative not narrative

1. **Goal and scope** — two or three sentences: where the work starts and ends.
1. **Non-goals (DO NOT)** — explicit. "DO NOT change `<thing>`. Reason." — not "we will not refactor unrelated code".
1. **Constraints and guardrails** — binding skills, the owning-layer table, frozen contracts, gates, operator-specified rules.
1. **Files and components to touch** — flat, per step, grep-friendly, so an agent can resume mid-flight.
1. **Test and verification plan** — exact commands, per-step success criteria, end-of-work gate (`make lint`, `make check-docs`, `make pre-commit`; `make ci-test` when the image changed — do not invent a `make check`), final `rg` checks for renames.
1. **Open risks and locked decisions** — two labelled blocks. Risks are what the executor may hit; locked decisions are settled and not re-litigated.

## 3. Placement and density

- Immediately after the frontmatter, before any detailed section. One or two screens; bullets, tables, fences.
- Use MUST and DO NOT. A conditional belongs under Risks, never under Locked decisions.
- Never manufacture a lock-in the operator did not make — ask first; a later agent treats the checkpoint as agreed.
- A locked decision has a matching non-goal.
- The checkpoint lives in the plan file and, when the work ships, in the PR description. It never lands in tracked documentation (`docs-code-alignment`).

## 4. Anti-patterns

A "do not" inside per-step prose. A checkpoint that paraphrases the body (it *is* the durable summary). Mixing decided with open. Separate "out of scope" or "decisions" sections. Reading the checkpoint as a task list — it states invariants; steps live in the body.

## 5. Template

```markdown
## Execution Checkpoint

> Read first. The durable summary of intent, constraints and decisions.

### Goal and scope
### Non-goals (DO NOT)
- DO NOT change <thing>. Reason: <one line>.
### Constraints and guardrails
- Binding skills: `engineering-discipline`, `leftover-ci`, `tooling-workflow`.
- Frozen: digest pins on every `FROM` / `COPY --from`; `prod` contents; semver tag behaviour.
- Gates: `make lint`, `make check-docs`, `make pre-commit`; `make ci-test` for image changes.
- Operator-specified rules: <…>.
### Files and components to touch
**Step 1 — <name>:** New: <path> · Edit: <path> — <reason>
### Test and verification plan
- Step 1: `<command>` passes; <assertion>.
- End-of-work: `make pre-commit` clean; `rg -n '<OldName>'` returns nothing.
### Open risks and locked decisions
**Risks (be vigilant):** <risk>: <mitigation>.
**Locked decisions (do not revisit):** <decision>.
```

`engineering-discipline` §8 supplies the gates; `tooling-workflow` defines the commands. The checkpoint enumerates; the body explains.
