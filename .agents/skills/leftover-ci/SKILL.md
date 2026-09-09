______________________________________________________________________

## name: leftover-ci description: >- Binds agents to latex-infrastructure leftover-ci. Runs make lint, make check-docs, and make pre-commit. Do not invent make check. Public repo; no company MCP portal URLs in skills.

# Leftover-CI

The local aggregate is `make lint`, `make check-docs`, and `make pre-commit`. There is **no** `make check` target.

If the files you changed live under `.agents/context/`, load [`nested-context-work`](../nested-context-work/SKILL.md) first.
