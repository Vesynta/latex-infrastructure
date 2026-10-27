______________________________________________________________________

## name: local-checks description: Local checks for latex-infrastructure. Runs make lint, make check-docs, and make pre-commit. Do not invent make check.

# Local checks

The local aggregate is `make lint`, `make check-docs`, and `make pre-commit`. There is **no** `make check` target.

If the files you changed live under `.agents/context/`, load [`nested-context-work`](../nested-context-work/SKILL.md) first. Disk quota: that skill’s safe prune (never volumes). Passing local checks does **not** replace filling [`.github/PULL_REQUEST_TEMPLATE.md`](../../../.github/PULL_REQUEST_TEMPLATE.md).
