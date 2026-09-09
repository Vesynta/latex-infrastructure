______________________________________________________________________

## name: nested-context-work description: Work on gitignored sibling clones under .agents/context/ from a host DevContainer. Use when leftover-ci or hooks fail because tools are missing on the host PATH; when the Docker daemon is tight on disk; or when a nested clone leaked .pnpm-store/ onto the workspace root. Load the clone’s own skills; run leftover-ci via a one-shot compose run into its DooD image with a host-path bind.

# Nested context work

Related repos may be cloned into [`.agents/context/`](../../context/) for agentic turns. That directory is **gitignored** in the host. Each clone is its own git repository.

This skill is the behaviour for **host vs clone**. Pair with [`engineering-discipline`](../engineering-discipline/SKILL.md). This is a **public** repository: do not add company MCP configs or internal ticket links to skills.

## 1. Detect the git root

```bash
git -C <path> rev-parse --show-toplevel
```

If that root is **not** this repository’s git root, the files belong to a nested clone. **Stop** applying this repository’s leftover-ci and host `PATH` to that tree.

## 2. Load the clone’s skills

Read the clone’s `AGENTS.md` (or `CLAUDE.md`), its skill catalog when present, then the matching clone skills. Do not treat clone files as part of this git index (`git add .agents/context/<clone>` from this repo is always wrong).

## 3. Leftover-ci in the clone’s image

Leftover-ci, `git commit`, and `git push` are a **one-shot** `compose run --rm --no-deps` (or `docker run --rm` of that `dev` image) with a **host-path bind**. Do **not** `compose up -d` a second replica. Do **not** run a clone `initializeCommand` that stops another stack.

Do not attach foreign compose networks. Use a distinct compose project (`-p nested-ctx-<clone>`).

Clone PRs use **that** clone’s `.github/PULL_REQUEST_TEMPLATE.md` when present (fill it; do not use Summary / Test plan). Incremental conventional commits: that clone’s [`engineering-discipline`](../engineering-discipline/SKILL.md).

### DooD host-path bind

When **this host is itself a DevContainer**, compose bind mounts such as `.:/app` are resolved by the **daemon on the laptop**, not by this container. Rewrite binds to the clone’s **host** path.

```bash
host_ws=$(docker inspect "$(hostname)" --format '{{range .Mounts}}{{if eq .Destination "/app"}}{{.Source}}{{end}}{{end}}')
host_clone=$host_ws/.agents/context/<clone>
# derive compose, service, user, workdir from the clone’s .devcontainer/devcontainer.json

docker compose -p nested-ctx-<clone> -f "$compose" run --rm --no-deps \
  --volume "$host_clone:$workdir" \
  --workdir "$workdir" \
  --user "$user" \
  --entrypoint bash \
  "$service" -c '<clone leftover-ci>'
```

Equivalent: `docker run --rm --entrypoint bash -u "$user" -w "$workdir" -v "$host_clone:$workdir" <clone-dev-image> -c '…'`.

## 4. Package managers and caches

Never run the clone’s package manager or `pre-commit` on the **host** PATH (a relative store then lands at this workspace root). The clone’s leftover-ci is whatever **that** repo documents. Do not invent a `make check` target.

## 5. Safe Docker prune

Check `docker ps` first. Never prune volumes.

```bash
docker container prune -f
docker image prune -f
docker image prune -a -f
docker builder prune -f
```

## 6. Anti-patterns

- `git commit` / `git push` in a nested clone from this container’s own shell.
- `git commit --no-verify` because the host lacks tools.
- Opening a clone PR with Summary / Test plan instead of that clone’s pull-request template.
- Adding company MCP client configs or internal ticket URLs to skills in this public tree.
- `docker volume prune` / `--volumes` to recover disk.
