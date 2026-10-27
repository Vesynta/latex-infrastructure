______________________________________________________________________

## name: nested-context-work description: Work on other repositories cloned under .agents/context/ from this DevContainer. Use when local checks or hooks fail because tools are missing on this PATH; when the Docker daemon is tight on disk; or when a clone leaked .pnpm-store/ onto the workspace root. Load the clone’s own skills; run its checks via a one-shot compose run of its own DevContainer image with a host-path bind.

# Nested context work

Other repositories may be cloned into [`.agents/context/`](../../context/) for reference while working here. That directory is **gitignored**. Each clone is its own git repository with its own tooling.

This skill is the behaviour for **this repository vs a clone**. Pair with [`engineering-discipline`](../engineering-discipline/SKILL.md).

## 1. Detect the git root

```bash
git -C <path> rev-parse --show-toplevel
```

If that root is **not** this repository’s git root, the files belong to a clone. **Stop** applying this repository’s checks and `PATH` to that tree.

## 2. Load the clone’s skills

Read the clone’s `AGENTS.md` (or `CLAUDE.md`), its skill catalog when present, then the matching clone skills. Do not treat clone files as part of this git index (`git add .agents/context/<clone>` from this repo is always wrong).

## 3. Run the clone’s checks in its own image

The clone’s checks, `git commit`, and `git push` are a **one-shot** `compose run --rm --no-deps` (or `docker run --rm` of the clone’s `dev` image) with a **host-path bind**. Do **not** `compose up -d` a second replica. Do **not** run a clone `initializeCommand`; it may stop containers the clone expects to own.

Do not attach the clone’s compose networks. Use a distinct compose project (`-p nested-ctx-<clone>`).

Clone PRs use **that** clone’s `.github/PULL_REQUEST_TEMPLATE.md` when present (fill it; do not use Summary / Test plan). Commit conventions: that clone’s own contributor docs.

### Host-path bind

This DevContainer talks to the host Docker daemon, so compose bind mounts are resolved on the **host**, not inside this container. Rewrite binds to the clone’s **host** path.

```bash
host_ws=$(docker inspect "$(hostname)" --format '{{range .Mounts}}{{if eq .Destination "/workspaces/latex-infrastructure"}}{{.Source}}{{end}}{{end}}')
host_clone=$host_ws/.agents/context/<clone>
# derive compose, service, user, workdir from the clone’s .devcontainer/devcontainer.json

docker compose -p nested-ctx-<clone> -f "$compose" run --rm --no-deps \
  --volume "$host_clone:$workdir" \
  --workdir "$workdir" \
  --user "$user" \
  --entrypoint bash \
  "$service" -c '<clone checks>'
```

Equivalent: `docker run --rm --entrypoint bash -u "$user" -w "$workdir" -v "$host_clone:$workdir" <clone-dev-image> -c '…'`.

## 4. Package managers and caches

Never run the clone’s package manager or `pre-commit` on this container’s PATH (a relative store then lands at this workspace root). The clone’s checks are whatever **that** repo documents. Do not invent a `make check` target.

## 5. Safe Docker prune

Check `docker ps` first. Never prune volumes.

```bash
docker container prune -f
docker image prune -f
docker image prune -a -f
docker builder prune -f
```

## 6. Anti-patterns

- `git commit` / `git push` in a clone from this container’s own shell.
- `git commit --no-verify` because this container lacks the clone’s tools.
- Opening a clone PR with Summary / Test plan instead of that clone’s pull-request template.
- `docker volume prune` / `--volumes` to recover disk.
