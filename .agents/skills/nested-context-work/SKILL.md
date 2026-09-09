______________________________________________________________________

## name: nested-context-work description: Work on gitignored sibling clones under .agents/context/ from a host DevContainer. Use when editing, testing, or committing another Vesynta repo that is cloned into .agents/context/; when leftover-ci or hooks fail because pnpm/make/pre-commit are missing on the host PATH; or when a nested clone leaked .pnpm-store/ onto the workspace root. Load the clone’s own skills; run that repo’s Makefile and git hooks via docker exec into its DooD image.

# Nested context work

Related Vesynta repos are cloned into [`.agents/context/`](../../context/) for agentic turns. That directory is **gitignored** in the host. Each clone is its own git repository with its own skills, Makefile, and DevContainer.

This skill is the behaviour for **host vs clone**. Pair with [`engineering-discipline`](../engineering-discipline/SKILL.md) (surgical diffs, ask-don’t-assume). Do not restate [AGENTS.md](../../../AGENTS.md) hard rules.

This is **not** a QMS document. Do not write clinical-validation prose.

## 1. Detect the git root

```bash
git -C <path> rev-parse --show-toplevel
```

If that root is **not** this repository’s git root, the files belong to a nested clone. **Stop** applying this repository’s leftover-ci, domain skills, and host `PATH` to that tree.

Host leftover-ci still applies to **host** files in the same turn.

## 2. Load the clone’s skills

Read, in order:

1. The clone’s `AGENTS.md` (or `CLAUDE.md` / `.github/copilot-instructions.md` if that is all it has).
1. The clone’s [`.agents/skills/README.md`](../README.md) catalog when present.
1. The clone skills that match the task (`engineering-discipline`, `tooling-workflow`, `leftover-ci`, plus **one** domain skill).

Do not copy this repository’s domain skills into the clone. Do not treat the clone’s files as part of this git index (`git add .agents/context/<clone>` from `/app` is always wrong).

## 3. Exec into the clone’s DevContainer

The clone’s hooks expect **that** image (pnpm, uv, Django, LaTeX, …). This host image does not provide them. Baked Docker-outside-of-Docker on the host is how you reach the clone container.

**Derive** compose file, service, `workspaceFolder`, and `remoteUser` from the clone’s `.devcontainer/devcontainer.json`. Do not trust a remembered table.

```bash
compose=<clone>/.devcontainer/docker-compose.yaml   # or whatever dockerComposeFile says
service=<service>
user=<remoteUser>
workdir=<workspaceFolder>

docker compose -f "$compose" up -d
# build only if the service is missing — ask before a heavy rebuild

container=$(docker compose -f "$compose" ps -q "$service")
docker exec -u "$user" -w "$workdir" "$container" <clone leftover-ci>
docker exec -u "$user" -w "$workdir" "$container" git commit -m "$(cat <<'EOF'
…

EOF
)"
```

If `dockerComposeFile` is a list, pass every file in order (`-f` repeated).

### Example coordinates (verify before use)

| Clone                                 | Compose                                                            | Service                   | Workdir              |
| ------------------------------------- | ------------------------------------------------------------------ | ------------------------- | -------------------- |
| community-frontend                    | `.devcontainer/docker-compose.yaml`                                | `app`                     | `/app`               |
| clinical-frontend                     | `.devcontainer/docker-compose.yaml`                                | `frontend`                | `/app`               |
| pharmacometrics-engine                | `.devcontainer/docker-compose.yaml`                                | `engine`                  | `/app`               |
| clinical-backend                      | `docker-compose.yml` + `.devcontainer/docker-compose.override.yml` | `backend`                 | `/code`              |
| website                               | `docker-compose.dev.yaml`                                          | `website`                 | `/repo`              |
| clinical-docs                         | `compose.yaml`                                                     | `docs`                    | `/app`               |
| design-control-matrix                 | `.devcontainer/docker-compose.yaml`                                | `development_environment` | `/repo`              |
| organisation-matrix                   | `.devcontainer/docker-compose.yaml`                                | `development_environment` | `/repo`              |
| latex-infrastructure                  | `.devcontainer/docker-compose.yaml`                                | `devcontainer`            | `/workspaces/<name>` |
| infrastructure (when it is the clone) | `compose.yaml`                                                     | `infrastructure`          | `/app`               |

Ask (`AskQuestion`) before starting a sibling image you are not already using, or if `remoteUser` / service is missing from `devcontainer.json`.

## 4. Package managers and caches

Never run the clone’s `pnpm`, `npm`, `uv`, or `pre-commit` on the **host** PATH. Relative `store-dir=.pnpm-store` then lands at the host workspace root and shows up as tens of thousands of untracked files.

The clone’s leftover-ci is whatever **that** repo documents (`make check`, husky, `pre-commit`, …). Do not invent a `make check` target. If there is no aggregate, ask.

## 5. Anti-patterns

- `git commit` / `git push` in a nested clone from this container’s own shell.
- Host `make check` as the done gate for product-repo edits.
- `git commit --no-verify` because the host lacks `pnpm`.
- Copying host skills into `.cursor/skills` or duplicating them under the clone’s `.claude/skills` (that path must be a **symlink** to `.agents/skills`).
- Adding `.agents/context/` clones as git submodules.

## 6. Ask, don’t assume

Use `AskQuestion` when the human must choose: which clone is source of truth, whether to rebuild its image, commit subject / PR target, or which verification gate exists. A wrong assumption that skips hooks costs more than asking.
